import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert' show base64Encode, base64Decode;
import 'dart:typed_data';
import 'package:flutter/services.dart'; // ✅ Necesario para FilteringTextInputFormatter
import '../../../config/app_text_styles.dart';
import '../../../models/entrega.dart';
import '../../../models/venta.dart';
import '../../../providers/entrega_provider.dart';
import '../../../services/image_compression_service.dart'; // ✅ NUEVO: Para comprimir imágenes
import '../../../services/entrega_service.dart'; // ✅ NUEVO: Para obtener tipos de pago

// ✅ Importar widgets separados para mayor mantenibilidad
import 'confirmar_entrega_widgets/formulario_novedad_widget.dart';
import 'confirmar_entrega_widgets/models.dart';

// ✅ NUEVO 2026-03-12: Importar widgets de registro de pagos
import 'widgets/tabla_productos_rechazados_widget.dart' as tabla_widget;
import 'widgets/venta_detalles_card.dart';
import 'widgets/registro_pagos_completo_widget.dart';

class ConfirmarEntregaVentaScreen extends StatefulWidget {
  final Entrega entrega;
  final Venta venta;
  final EntregaProvider provider;

  // ✅ NUEVO 2026-02-21: Parámetros para modo edición
  final bool isEditing;
  final int? confirmacionId;  // ✅ NUEVO 2026-06-13: ID de confirmación para usar PUT /confirmaciones/{id}
  final String? tipoEntregaExistente;
  final String? tipoNovedadExistente;

  // ✅ NUEVO 2026-03-05: Información del cliente y tipo de pago desde resumen
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? tipoPago;

  // ✅ NUEVO 2026-03-05: Información previa de fotos, observaciones y pagos para edición
  final List<String> fotosExistentes;
  final String observacionesExistentes;
  final List<Map<String, dynamic>> pagosExistentes;

  // ✅ NUEVA 2026-03-05: Campos de novedad existentes
  final bool? tiendaAbiertaExistente;
  final bool? clientePresenteExistente;
  final String? motivoRechazoExistente;

  // ✅ NUEVO 2026-03-05: Productos devueltos existentes en modo edición
  final List<Map<String, dynamic>> productosDevueltosExistentes;

  const ConfirmarEntregaVentaScreen({
    Key? key,
    required this.entrega,
    required this.venta,
    required this.provider,
    this.isEditing = false,
    this.confirmacionId,  // ✅ NUEVO: ID de confirmación para editar
    this.tipoEntregaExistente,
    this.tipoNovedadExistente,
    this.cliente,
    this.tipoPago,
    this.fotosExistentes = const [],
    this.observacionesExistentes = '',
    this.tiendaAbiertaExistente,
    this.clientePresenteExistente,
    this.motivoRechazoExistente,
    this.productosDevueltosExistentes = const [],
    this.pagosExistentes = const [],
  }) : super(key: key);

  @override
  State<ConfirmarEntregaVentaScreen> createState() =>
      _ConfirmarEntregaVentaScreenState();
}

class _ConfirmarEntregaVentaScreenState
    extends State<ConfirmarEntregaVentaScreen> {
  // Estados de la pantalla
  int _paso = 1; // 1: Seleccionar tipo + detalles, 2: Confirmación

  // Datos capturados
  String _tipoEntrega =
      'COMPLETA'; // ✅ NUEVO 2026-03-05: Inicializar con COMPLETA
  String? _tipoNovedad; // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADO

  // ✅ NUEVA 2026-03-05: Campos de novedad
  bool _tiendaAbierta = false;
  bool _clientePresente = false;
  String? _motivoRechazo;

  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  // ✅ NUEVO 2026-03-15: Controladores para 2 inputs fijos
  final TextEditingController _montoEfectivoController =
      TextEditingController();
  final TextEditingController _montoTransferenciaController =
      TextEditingController();
  // ✅ FIX 2026-03-05: Manejar tanto File (fotos nuevas) como String (URLs/base64 de API)
  List<dynamic> _fotosCapturadas = [];

  final ImagePicker _imagePicker = ImagePicker();
  final EntregaService _entregaService =
      EntregaService(); // ✅ NUEVO: Para obtener tipos de pago

  // ✅ NUEVO 2026-02-12: Múltiples pagos + Crédito
  List<Map<String, dynamic>> _tiposPago = [];
  bool _cargandoTiposPago = false;
  List<PagoEntrega> _pagos = []; // Lista de pagos múltiples
  bool _esCredito = false; // ✅ CAMBIO: Checkbox en lugar de input de monto
  String _tipoConfirmacion = 'COMPLETA'; // COMPLETA o CON_NOVEDAD
  int?
  _tipoPagoSeleccionado; // ✅ NUEVO: Mantener selección de tipo de pago entre rebuilds

  // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
  List<tabla_widget.ProductoRechazado> _productosRechazados =
      []; // Productos marcados como rechazados

  // ✅ CRITICAL FIX: Map de TextEditingControllers para mantener focus en cantidad rechazada
  // Keyed by detalleVentaId para reutilizar el mismo controller en cada rebuild
  final Map<int, TextEditingController> _cantidadRechazadaControllers = {};

  // ✅ FIX 2026-02-15: Map de controllers para monto de pagos (evitar focus loss en modal)
  // Keyed by 'pago_{idx}' para reutilizar el mismo controller en cada rebuild
  final Map<String, TextEditingController> _pagoMontoControllers = {};

  final List<Map<String, String>> _tiposNovedad = [
    {
      'value': 'CLIENTE_CERRADO',
      'label': '🔒 Cliente Cerrado/No Disponible',
      'description': 'El cliente no estaba disponible para recibir',
    },
    {
      'value': 'DEVOLUCION_PARCIAL',
      'label': '↩️ Devolución Parcial',
      'description': 'El cliente rechazó parte de la mercancía',
    },
    {
      'value': 'RECHAZADO',
      'label': '❌ Rechazo Total',
      'description': 'El cliente rechazó toda la mercancía',
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarTiposPago();

    // ✅ Listeners para actualizar resumen mientras escribes
    _montoEfectivoController.addListener(() => setState(() {}));
    _montoTransferenciaController.addListener(() => setState(() {}));

    // ✅ DEBUG: Verificar que cliente y tipoPago llegan correctamente
    debugPrint('👤 [CLIENTE DATA] cliente: ${widget.cliente}');
    debugPrint('💳 [TIPO PAGO DATA] tipoPago: ${widget.tipoPago}');

    // ✅ NUEVO 2026-03-05: Detectar si es crédito desde widget.tipoPago o widget.venta.estadoPago
    final esCredito =
        (widget.tipoPago?['codigo']?.toString().toUpperCase().contains(
              'CREDITO',
            ) ??
            false) ||
        widget.venta.estadoPago == 'CREDITO';

    if (esCredito) {
      _esCredito = true;
      debugPrint(
        '💳 [VENTA CRÉDITO] Venta #${widget.venta.numero} es a crédito - no mostrar sección pagos',
      );
    }

    // ✅ NUEVO 2026-02-21: Si está en modo edición, cargar datos existentes
    if (widget.isEditing && widget.tipoEntregaExistente != null) {
      _tipoEntrega = widget.tipoEntregaExistente!;
      _tipoNovedad = widget.tipoNovedadExistente;
      // ✅ FIX 2026-03-05: Si hay novedad existente, tipo_confirmacion debe ser CON_NOVEDAD
      if (_tipoNovedad != null) {
        _tipoConfirmacion = 'CON_NOVEDAD';
      } else {
        _tipoConfirmacion = 'COMPLETA';
      }

      // ✅ NUEVA 2026-03-05: Sin Paso 1/2, mostrar directo el formulario seleccionable

      // ✅ NUEVO 2026-03-05: Cargar productos devueltos existentes para DEVOLUCION_PARCIAL
      if (_tipoNovedad == 'DEVOLUCION_PARCIAL' &&
          widget.productosDevueltosExistentes.isNotEmpty) {
        _productosRechazados = widget.productosDevueltosExistentes
            .map(
              (prod) => tabla_widget.ProductoRechazado(
                detalleVentaId:
                    prod['detalle_venta_id'] as int? ??
                    (prod['id'] as int?) ??
                    0,
                productoId: prod['producto_id'] as int?,
                nombreProducto:
                    prod['producto_nombre'] as String? ?? 'Desconocido',
                cantidadOriginal:
                    (prod['cantidad_original'] as num?)?.toDouble() ?? 0,
                cantidadRechazada: (prod['cantidad'] as num?)?.toDouble() ?? 0,
                precioUnitario:
                    (prod['precio_unitario'] as num?)?.toDouble() ?? 0,
                subtotalOriginal: (prod['subtotal'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList();
        debugPrint(
          '✅ Cargados ${_productosRechazados.length} productos devueltos existentes',
        );
      }
      debugPrint(
        '📝 [EDITAR ENTREGA] Cargando datos existentes: tipo=$_tipoEntrega, novedad=$_tipoNovedad, confirmacion=$_tipoConfirmacion',
      );

      // ✅ NUEVO 2026-03-05: Cargar fotos existentes (URLs/base64 de API)
      if (widget.fotosExistentes.isNotEmpty) {
        _fotosCapturadas = List<dynamic>.from(widget.fotosExistentes);
        debugPrint(
          '📸 [FOTOS CARGADAS] ${_fotosCapturadas.length} fotos existentes cargadas (URLs/base64)',
        );
      }

      // ✅ NUEVO 2026-03-05: Cargar observaciones existentes
      if (widget.observacionesExistentes.isNotEmpty) {
        _observacionesController.text = widget.observacionesExistentes;
        debugPrint(
          '📝 [OBSERVACIONES CARGADAS] Observaciones existentes cargadas',
        );
      }

      // ✅ NUEVA 2026-03-05: Cargar campos de novedad existentes
      if (widget.tiendaAbiertaExistente != null) {
        _tiendaAbierta = widget.tiendaAbiertaExistente!;
      }
      if (widget.clientePresenteExistente != null) {
        _clientePresente = widget.clientePresenteExistente!;
      }
      if (widget.motivoRechazoExistente != null) {
        _motivoRechazo = widget.motivoRechazoExistente;
      }
      debugPrint(
        '⚠️ [CAMPOS NOVEDAD CARGADOS] tienda_abierta=$_tiendaAbierta, cliente_presente=$_clientePresente, motivo_rechazo=$_motivoRechazo',
      );

      // ✅ FIX 2026-03-05: NO cargar pagosExistentes en _pagos
      // _pagos debe contener SOLO pagos NUEVOS que el usuario agrega
      // Los pagos existentes se mantienen en el backend automáticamente
      debugPrint(
        '💳 [PAGOS MODO EDICIÓN] No se cargan pagos existentes - _pagos inicia vacío para nuevos pagos',
      );
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _montoController.dispose();
    _referenciaController.dispose();
    // ✅ Disposer todos los controllers de cantidad rechazada
    for (final controller in _cantidadRechazadaControllers.values) {
      controller.dispose();
    }
    // ✅ FIX 2026-02-15: Disposer todos los controllers de monto de pagos
    for (final controller in _pagoMontoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// ✅ FIX 2026-03-05: Decodificar base64 a bytes para mostrar imagen
  Uint8List _decodificarBase64(String base64String) {
    // Remover prefijo de data URI si existe
    String cleanBase64 = base64String.replaceAll(
      RegExp(r'^data:image/[^;]+;base64,'),
      '',
    );

    try {
      return base64Decode(cleanBase64);
    } catch (_) {
      // Si falla, intentar sin limpiar
      try {
        return base64Decode(base64String);
      } catch (_) {
        // Retornar bytes vacíos si falla todo
        return Uint8List(0);
      }
    }
  }

  /// ✅ FIX 2026-03-05: Constructor inteligente de imagen que maneja File, URL y base64
  Widget _construirImagenFoto(
    dynamic foto, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (foto is File) {
      // Foto local capturada
      return Image.file(
        foto,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width ?? double.infinity,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      );
    } else if (foto is String) {
      // URL o base64 de API
      final esBase64 =
          foto.startsWith('data:') ||
          foto.startsWith('/9j/') ||
          foto.startsWith('iVBORw0KGgo');

      if (esBase64) {
        // Base64
        return Image.memory(
          _decodificarBase64(foto),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width ?? double.infinity,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          ),
        );
      } else {
        // URL
        return Image.network(
          foto,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width ?? double.infinity,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          ),
        );
      }
    } else {
      // Tipo desconocido
      return Container(
        width: width ?? double.infinity,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      );
    }
  }

  /// Cargar tipos de pago disponibles
  Future<void> _cargarTiposPago() async {
    setState(() => _cargandoTiposPago = true);

    try {
      final response = await _entregaService.obtenerTiposPago();

      if (response.success && response.data != null) {
        setState(() {
          // Filtrar: excluir tipo de pago CREDITO en pantalla de confirmación
          _tiposPago = (response.data as List)
              .cast<Map<String, dynamic>>()
              .where((tipo) {
                final codigo = (tipo['codigo'] as String?)?.toUpperCase();
                return codigo == null || !codigo.contains('CREDITO');
              })
              .toList();
          _cargandoTiposPago = false;
        });
      } else {
        setState(() => _cargandoTiposPago = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al cargar tipos de pago: ${response.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _cargandoTiposPago = false);
      debugPrint('Error cargando tipos de pago: $e');
    }
  }

  /// Capturar foto con cámara y comprimir
  Future<void> _capturarFoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null && mounted) {
        // ✅ NUEVO: Mostrar loading mientras se comprime
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // ✅ NUEVO: Comprimir la imagen (asegura que pese < 1MB)
          final imagenComprimida =
              await ImageCompressionService.comprimirYValidarImagen(
                File(photo.path),
              );

          if (mounted) {
            Navigator.pop(context); // Cerrar loading

            setState(() {
              _fotosCapturadas.add(imagenComprimida);
            });

            // Mostrar tamaño de la imagen comprimida
            final tamanMB = await ImageCompressionService.obtenerTamanoEnMB(
              imagenComprimida,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📸 Foto capturada (${_fotosCapturadas.length}) - ${tamanMB.toStringAsFixed(2)} MB',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ImageCompressionService.obtenerMensajeError(e)),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Error al capturar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al acceder a la cámara'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Eliminar foto capturada
  void _eliminarFoto(int index) {
    setState(() {
      _fotosCapturadas.removeAt(index);
    });
  }

  /// Construir observaciones finales
  String _construirObservacionesFinales() {
    if (_tipoEntrega == 'COMPLETA') {
      return 'Entrega completa';
    } else {
      final observaciones = _observacionesController.text.trim();
      final tipoLabel = _tiposNovedad.firstWhere(
        (t) => t['value'] == _tipoNovedad,
      )['label']!;

      return observaciones.isEmpty ? tipoLabel : '$tipoLabel - $observaciones';
    }
  }

  /// ✅ NUEVO 2026-03-05: Validar que todos los datos requeridos estén completos
  /// ✅ NUEVO 2026-06-14: Construir pagos automáticamente desde los inputs
  void _construirPagosAutomaticamente() {
    // Limpiar pagos anteriores si los hubiera
    _pagos.clear();

    double montoEfectivo = double.tryParse(_montoEfectivoController.text) ?? 0;
    double montoTransferencia =
        double.tryParse(_montoTransferenciaController.text) ?? 0;

    // Buscar IDs por código
    int? idEfectivo;
    int? idTransferencia;
    for (var tipo in _tiposPago) {
      final codigo = (tipo['codigo'] as String?)?.toUpperCase() ?? '';
      if (codigo == 'EFECTIVO') idEfectivo = tipo['id'] as int;
      if (codigo == 'TRANSFERENCIA/QR') idTransferencia = tipo['id'] as int;
    }

    // Agregar pagos si hay montos y están configurados en el backend
    if (montoEfectivo > 0 && idEfectivo != null) {
      _pagos.add(
        PagoEntrega(
          tipoPagoId: idEfectivo,
          monto: montoEfectivo,
          referencia: null,
        ),
      );
    }

    if (montoTransferencia > 0 && idTransferencia != null) {
      _pagos.add(
        PagoEntrega(
          tipoPagoId: idTransferencia,
          monto: montoTransferencia,
          referencia: null,
        ),
      );
    }

    debugPrint(
      '✅ Pagos construidos automáticamente: ${_pagos.length} pagos',
    );
  }

  /// ✅ MODIFICADO 2026-06-14: Validar incluyendo inputs de Efectivo/QR
  bool _validarDatos() {
    if (_tipoEntrega == 'COMPLETA') {
      // Para entrega completa: requiere pagos O crédito O valores en inputs
      final esCredito = _esVentaCredito();
      double montoEfectivo =
          double.tryParse(_montoEfectivoController.text) ?? 0;
      double montoTransferencia =
          double.tryParse(_montoTransferenciaController.text) ?? 0;
      double totalEnInputs = montoEfectivo + montoTransferencia;

      if (!esCredito && _pagos.isEmpty && totalEnInputs == 0) {
        return false;
      }
    } else if (_tipoEntrega == 'CON_NOVEDAD') {
      // Para novedad: requiere tipo de novedad
      if (_tipoNovedad == null) return false;
      // Si es cliente cerrado: requiere fotos
      if (_tipoNovedad == 'CLIENTE_CERRADO' && _fotosCapturadas.isEmpty)
        return false;
    }
    return true;
  }

  /// ✅ MODIFICADO 2026-06-14: Obtener razón del error incluyendo inputs
  String _obtenerRazonError() {
    if (_tipoEntrega == 'COMPLETA') {
      final esCredito = _esVentaCredito();
      double montoEfectivo =
          double.tryParse(_montoEfectivoController.text) ?? 0;
      double montoTransferencia =
          double.tryParse(_montoTransferenciaController.text) ?? 0;
      double totalEnInputs = montoEfectivo + montoTransferencia;

      if (!esCredito && _pagos.isEmpty && totalEnInputs == 0) {
        return 'Escribe un monto en Efectivo o QR, o marca como crédito';
      }
    } else if (_tipoEntrega == 'CON_NOVEDAD') {
      if (_tipoNovedad == null) {
        return 'Selecciona un tipo de novedad';
      }
      if (_tipoNovedad == 'CLIENTE_CERRADO' && _fotosCapturadas.isEmpty) {
        return 'Captura al menos una foto';
      }
    }
    return 'Completa los datos requeridos';
  }

  /// Confirmar entrega
  Future<void> _confirmarEntrega() async {
    // ✅ NUEVO 2026-06-14: Construir pagos automáticamente desde los inputs
    _construirPagosAutomaticamente();

    // ✅ NUEVO: Validar que Cliente Cerrado/No Disponible requiere fotos
    if (_tipoNovedad == 'CLIENTE_CERRADO' && _fotosCapturadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Debes capturar al menos una foto para reportar cliente cerrado/no disponible',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // ✅ FIX 2026-03-05: Convertir SOLO fotos nuevas a base64 (dejar el merge al backend)
      // Para edición: enviar SOLO las fotos que son File (nuevas), no las String (existentes)
      List<String>? fotosBase64;
      final fotosNuevas = _fotosCapturadas.whereType<File>().toList();

      if (fotosNuevas.isNotEmpty) {
        fotosBase64 = [];
        for (final foto in fotosNuevas) {
          final bytes = await foto.readAsBytes();
          final base64 = _bytesToBase64(bytes);
          fotosBase64.add(base64);
        }
      }

      final observacionesFinales = _construirObservacionesFinales();

      // ✅ NUEVA 2026-02-12: Validar que al menos hay un pago registrado o es a crédito
      double totalDineroRecibido = _pagos.fold(
        0,
        (sum, pago) => sum + pago.monto,
      );

      // ✅ CAMBIO 2026-02-13: Solo requiere pago si es COMPLETA
      // Si es NOVEDAD, NO se requiere pago (ya se registró la novedad)
      if (_tipoEntrega == 'COMPLETA' &&
          totalDineroRecibido == 0 &&
          !_esCredito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Debes registrar al menos un pago o marcar como crédito',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      debugPrint('📤 Confirmando entrega:');
      debugPrint('   - Tipo: $_tipoEntrega');
      debugPrint('   - Tipo Novedad: $_tipoNovedad');
      debugPrint('   - Observaciones: $observacionesFinales');
      debugPrint('   - Fotos: ${_fotosCapturadas.length}');
      debugPrint('   - Pagos múltiples: ${_pagos.length}'); // ✅ NUEVO
      debugPrint('   - Total dinero recibido: $totalDineroRecibido'); // ✅ NUEVO
      debugPrint('   - Es Crédito: $_esCredito'); // ✅ CAMBIO

      // ✅ NUEVA 2026-02-12: Construir array de pagos en formato backend
      final pagosArray = _pagos.map((pago) => pago.toJson()).toList();

      // ✅ NUEVA 2026-02-15: Construir array de productos rechazados
      final productosRechazadosArray = _productosRechazados
          .map(
            (prod) => {
              'detalleVentaId': prod.detalleVentaId,
              'cantidadRechazada': prod.cantidadRechazada,
            },
          )
          .toList();

      // ✅ DEBUG: Ver qué se envía al backend
      debugPrint('📦 PRODUCTOS RECHAZADOS AL BACKEND:');
      debugPrint('   - Total: ${productosRechazadosArray.length}');
      if (productosRechazadosArray.isNotEmpty) {
        for (var prod in productosRechazadosArray) {
          debugPrint(
            '   - ${prod['producto_nombre']}: ${prod['cantidad_rechazada']}/${prod['cantidad_original']}',
          );
        }
      } else {
        debugPrint(
          '   ⚠️ ARRAY VACÍO - No hay productos marcados como rechazados',
        );
      }

      // ✅ NUEVA 2026-03-05: Limpiar campos según tipo de confirmación
      String? tipoNovedadFinal = _tipoNovedad;
      bool? tiendaAbiertaFinal = _tiendaAbierta;
      bool? clientePresenteFinal = _clientePresente;
      String? motivoRechazoFinal = _motivoRechazo;

      // Si es COMPLETA, no enviar campos de novedad
      if (_tipoConfirmacion == 'COMPLETA') {
        tipoNovedadFinal = null;
        tiendaAbiertaFinal = null;
        clientePresenteFinal = null;
        motivoRechazoFinal = null;
        debugPrint('✅ COMPLETA: Limpiando campos de novedad');
      } else {
        debugPrint('✅ CON_NOVEDAD: Enviando campos de novedad');
      }

      final success = await widget.provider.confirmarVentaEntregada(
        widget.entrega.id,
        widget.venta.id,
        onSuccess: (mensaje) {
          debugPrint('✅ Venta entregada: $mensaje');
        },
        onError: (error) {
          debugPrint('❌ Error: $error');
        },
        fotosBase64: fotosBase64,
        observacionesLogistica: observacionesFinales,
        // ✅ NUEVA 2026-02-12: Enviar múltiples pagos en lugar de uno solo
        pagos: pagosArray, // Array de {tipo_pago_id, monto, referencia}
        esCredito: _esCredito, // ✅ CAMBIO: Enviar si es a crédito
        tipoConfirmacion: _tipoConfirmacion,
        // ✅ NUEVA 2026-02-15: Enviar productos rechazados para devolución parcial
        productosRechazados: productosRechazadosArray,
        // ✅ NUEVA 2026-03-05: Enviar campos de novedad SOLO si es CON_NOVEDAD
        tipoNovedad: tipoNovedadFinal,
        tiendaAbierta: tiendaAbiertaFinal,
        clientePresente: clientePresenteFinal,
        motivoRechazo: motivoRechazoFinal,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (success) {
          debugPrint('✅ Entrega confirmada correctamente');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrega confirmada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Recargar datos de entrega para que pantalla anterior vea cambios
          await widget.provider.obtenerEntrega(widget.entrega.id);

          // Cerrar la pantalla después de 1.5s, retornando true para indicar cambio
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(
              context,
              true,
            ); // ✅ NUEVO: Retornar true para indicar que hubo cambios
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción: $e');
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NUEVO 2026-02-21: Guardar cambios en modo edición
  Future<void> _guardarCambiosTipoEntrega() async {
    try {
      // Validar que haya seleccionado un tipo
      if (_tipoEntrega == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes seleccionar un tipo de entrega'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Si es CON_NOVEDAD, validar que haya seleccionado tipo de novedad
      if (_tipoEntrega == 'CON_NOVEDAD' && _tipoNovedad == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes seleccionar un tipo de novedad'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      debugPrint('📝 [EDITAR ENTREGA] Guardando cambios:');
      debugPrint('   - Tipo: $_tipoEntrega');
      debugPrint('   - Novedad: $_tipoNovedad');
      debugPrint('   - Fotos: ${_fotosCapturadas.length}');
      debugPrint('   - Observaciones: ${_observacionesController.text}');

      // ✅ FIX 2026-03-05: Convertir SOLO fotos nuevas a base64
      List<String>? fotosBase64;
      final fotosNuevas = _fotosCapturadas.whereType<File>().toList();

      if (fotosNuevas.isNotEmpty) {
        fotosBase64 = [];
        for (final foto in fotosNuevas) {
          final bytes = await foto.readAsBytes();
          final base64 = _bytesToBase64(bytes);
          fotosBase64.add(base64);
        }
      }

      final observacionesFinales = _construirObservacionesFinales();

      // ✅ FIX 2026-03-05: En modo edición, solo enviar pagos si hay nuevos
      List<Map<String, dynamic>>? pagosArray;
      if (_pagos.isNotEmpty) {
        pagosArray = _pagos.map((pago) => pago.toJson()).toList();
      }

      // ✅ NUEVA 2026-03-05: Construir array de productos rechazados (FALTABA en edición)
      final productosRechazadosArray = _productosRechazados
          .map(
            (prod) => {
              'detalleVentaId': prod.detalleVentaId,
              'cantidadRechazada': prod.cantidadRechazada,
            },
          )
          .toList();

      debugPrint('📦 PRODUCTOS RECHAZADOS EN EDICIÓN:');
      debugPrint('   - Total: ${productosRechazadosArray.length}');
      if (productosRechazadosArray.isNotEmpty) {
        for (var prod in productosRechazadosArray) {
          debugPrint(
            '   - ${prod['producto_nombre']}: ${prod['cantidad_rechazada']}/${prod['cantidad_original']}',
          );
        }
      }

      // ✅ NUEVA 2026-03-05: Calcular tipo_confirmacion correctamente
      // tipo_confirmacion debe ser: COMPLETA | CLIENTE_CERRADO | DEVOLUCION_PARCIAL | RECHAZADO
      final tipoConfirmacionFinal = _tipoEntrega == 'COMPLETA'
          ? 'COMPLETA'
          : _tipoNovedad;  // ✅ FIX: Enviar el tipo específico de novedad, no 'CON_NOVEDAD'

      String? tipoNovedadFinal = _tipoNovedad;
      bool? tiendaAbiertaFinal = _tiendaAbierta;
      bool? clientePresenteFinal = _clientePresente;
      String? motivoRechazoFinal = _motivoRechazo;

      // Si es COMPLETA, no enviar campos de novedad
      if (tipoConfirmacionFinal == 'COMPLETA') {
        tipoNovedadFinal = null;
        tiendaAbiertaFinal = null;
        clientePresenteFinal = null;
        motivoRechazoFinal = null;
        debugPrint('✅ EDICIÓN COMPLETA: Limpiando campos de novedad');
      } else {
        debugPrint('✅ EDICIÓN CON_NOVEDAD: Enviando campos de novedad');
      }

      // ✅ 2026-06-13: Detectar si es edición o creación nueva
      bool success;

      if (widget.confirmacionId != null) {
        // ✅ EDICIÓN: Usar PUT /api/confirmaciones/{id}
        success = await widget.provider.editarConfirmacionEntrega(
          widget.confirmacionId!,
          onSuccess: (mensaje) {
            debugPrint('✅ Confirmación actualizada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
          fotosBase64: fotosBase64,
          observacionesLogistica: observacionesFinales,
          tipoConfirmacion: tipoConfirmacionFinal,
          tipoNovedad: tipoNovedadFinal,
          tiendaAbierta: tiendaAbiertaFinal,
          clientePresente: clientePresenteFinal,
          motivoRechazo: motivoRechazoFinal,
        );
      } else {
        // ✅ CREACIÓN NUEVA: Usar POST /api/chofer/entregas/{id}/ventas/{id}/confirmar-entrega
        success = await widget.provider.confirmarVentaEntregada(
          widget.entrega.id,
          widget.venta.id,
          onSuccess: (mensaje) {
            debugPrint('✅ Nueva confirmación registrada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
          fotosBase64: fotosBase64,
          observacionesLogistica: observacionesFinales,
          pagos: pagosArray,
          esCredito: _esCredito,
          tipoConfirmacion: tipoConfirmacionFinal,
          productosRechazados: productosRechazadosArray,
          tipoNovedad: tipoNovedadFinal,
          tiendaAbierta: tiendaAbiertaFinal,
          clientePresente: clientePresenteFinal,
          motivoRechazo: motivoRechazoFinal,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (success) {
          // Éxito - mostrar mensaje y cerrar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tipoEntrega == 'COMPLETA'
                    ? '✅ Entrega marcada como completa'
                    : '⚠️ Entrega marcada con novedad',
              ),
              backgroundColor: _tipoEntrega == 'COMPLETA'
                  ? Colors.green
                  : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );

          // Recargar datos de entrega para que pantalla anterior vea cambios
          await widget.provider.obtenerEntrega(widget.entrega.id);

          // Cerrar pantalla después de 1.5s, retornando true para indicar cambio
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(
              context,
              true,
            ); // ✅ NUEVO: Retornar true para indicar que hubo cambios
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        if (_paso > 1) {
          setState(() => _paso--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: widget.isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'EDITAR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Folio #${widget.venta.id}',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Entrega del Folio #${widget.venta.id}',
                  style: const TextStyle(fontSize: 16),
                ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // ✅ NUEVA 2026-03-05: Selector simple de tipo de entrega en AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ SIMPLIFICADO: SegmentedButton para elegir tipo
                  SegmentedButton<String>(
                    selected: {_tipoEntrega},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _tipoEntrega = newSelection.first;
                        // ✅ FIX CRÍTICO: Actualizar _tipoConfirmacion cuando cambia _tipoEntrega
                        if (_tipoEntrega == 'COMPLETA') {
                          _tipoConfirmacion = 'COMPLETA';
                          _tipoNovedad = null;
                          _tiendaAbierta = false;
                          _clientePresente = false;
                          _motivoRechazo = null;
                          _productosRechazados.clear();
                          debugPrint(
                            '✅ Cambiado a COMPLETA - _tipoConfirmacion: COMPLETA - campos de novedad limpiados',
                          );
                        } else {
                          _tipoConfirmacion = 'CON_NOVEDAD';
                          _pagos.clear();
                          debugPrint(
                            '✅ Cambiado a CON_NOVEDAD - _tipoConfirmacion: CON_NOVEDAD - pagos limpiados',
                          );
                        }
                      });
                    },
                    segments: const [
                      ButtonSegment(
                        value: 'COMPLETA',
                        label: Text('✅ Completa'),
                        // icon: Icon(Icons.check_circle),
                      ),
                      ButtonSegment(
                        value: 'CON_NOVEDAD',
                        label: Text('⚠️ Con Novedad'),
                        // icon: Icon(Icons.warning),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ✅ NUEVO: Botón de confirmación/guardado en AppBar
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _construirBotonAccion()),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ✅ NUEVO: Mostrar detalles de la venta en ambos formularios
              VentaDetallesCard(venta: widget.venta, isDarkMode: isDarkMode),
              // ✅ FORMULARIOS: SIEMPRE mostrar el formulario según tipo seleccionado
              if (_tipoEntrega == 'COMPLETA')
                Expanded(
                  child: RegistroPagosCompletoWidget(
                    totalVenta: widget.venta.total,
                    pagos: _pagos,
                    tiposPago: _tiposPago,
                    esCredito: _esVentaCredito(),
                    montoEfectivoController: _montoEfectivoController,
                    montoTransferenciaController: _montoTransferenciaController,
                    onAgregarPago: (tipoPagoId, monto) {
                      setState(() {
                        _pagos.add(
                          PagoEntrega(
                            tipoPagoId: tipoPagoId,
                            monto: monto,
                            referencia: null,
                          ),
                        );
                      });
                    },
                    onEliminarPago: (index) {
                      setState(() {
                        if (index >= 0 && index < _pagos.length) {
                          _pagos.removeAt(index);
                        }
                      });
                    },
                  ),
                )
              else
                Expanded(child: _buildFormularioNovedad(isDarkMode)),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Detectar si la venta es a CRÉDITO basado en estadoPago
  bool _esVentaCredito() {
    return widget.venta.tipoPago?.codigo == 'CREDITO';
  }

  /// ✅ Helper para crear el widget consolidado de pagos
  Widget _buildRegistroPagosWidget() {
    final esCredito = _esVentaCredito();

    return RegistroPagosCompletoWidget(
      totalVenta: widget.venta.total,
      pagos: _pagos,
      tiposPago: _tiposPago,
      esCredito: esCredito,
      montoEfectivoController: _montoEfectivoController,
      montoTransferenciaController: _montoTransferenciaController,
      onAgregarPago: (tipoPagoId, monto) {
        setState(() {
          _pagos.add(
            PagoEntrega(tipoPagoId: tipoPagoId, monto: monto, referencia: null),
          );
        });
      },
      onEliminarPago: (index) {
        setState(() {
          if (index >= 0 && index < _pagos.length) {
            _pagos.removeAt(index);
          }
        });
      },
    );
  }

  /// ✅ Helper para crear FormularioNovedadWidget
  Widget _buildFormularioNovedad(bool isDarkMode) {
    return FormularioNovedadWidget(
      screenContext: context,
      isDarkMode: isDarkMode,
      tipoNovedad: _tipoNovedad,
      tiposNovedad: _tiposNovedad,
      venta: widget.venta,
      observacionesController: _observacionesController,
      fotosCapturadas: _fotosCapturadas,
      eliminarFoto: _eliminarFoto,
      capturarFoto: _capturarFoto,
      construirImagenFoto: (foto) => _construirImagenFoto(foto),
      buildTablaProductosRechazados: (ctx, dark) =>
          tabla_widget.TablaProductosRechazadosWidget(
            detalles: widget.venta.detalles ?? [],
            productosRechazados: _productosRechazados,
            cantidadRechazadaControllers: _cantidadRechazadaControllers,
            isDarkMode: dark,
            onMarcarRechazo: (detalleId, producto) {
              setState(() {
                if (!_productosRechazados.any(
                  (p) => p.detalleVentaId == detalleId,
                )) {
                  _productosRechazados.add(producto);
                }
              });
            },
            onDesmarcarRechazo: (detalleId) {
              setState(() {
                _productosRechazados.removeWhere(
                  (p) => p.detalleVentaId == detalleId,
                );
              });
            },
            onCantidadRechazadaChanged: (detalleId, cantidad) {
              final producto = _productosRechazados.firstWhere(
                (p) => p.detalleVentaId == detalleId,
                orElse: () => tabla_widget.ProductoRechazado(
                  detalleVentaId: detalleId,
                  productoId: null,
                  nombreProducto: '',
                  cantidadOriginal: 0,
                  cantidadRechazada: 0,
                  precioUnitario: 0,
                  subtotalOriginal: 0,
                ),
              );
              if (producto.detalleVentaId == detalleId) {
                setState(() {
                  producto.cantidadRechazada = cantidad;
                });
              }
            },
          ),
      registroPagosWidget: _buildRegistroPagosWidget(),
      onTipoNovedadChanged: (value) {
        setState(() {
          _tipoNovedad = value;
          // ✅ FIX: Automáticamente actualizar _tipoEntrega a CON_NOVEDAD (siempre, porque value es String)
          _tipoEntrega = 'CON_NOVEDAD';
          // ✅ FIX CRÍTICO: También actualizar _tipoConfirmacion para que refleje el cambio
          _tipoConfirmacion = value;
          debugPrint('🔄 [AUTO] _tipoEntrega actualizado a CON_NOVEDAD (tipo: $value)');
          debugPrint('🔄 [AUTO] _tipoConfirmacion actualizado a $value');
          _productosRechazados.clear();
          _cantidadRechazadaControllers.clear();
        });
      },
    );
  }

  /// ✅ NUEVO 2026-03-05: Construir botón de acción dinámico para AppBar
  Widget _construirBotonAccion() {
    // Si está en modo edición, siempre mostrar botón de guardar
    if (widget.isEditing) {
      final puedGuardar = _validarDatos();
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: puedGuardar
                ? 'Guardar cambios'
                : 'Completa los datos requeridos',
            child: ElevatedButton.icon(
              onPressed: puedGuardar ? _guardarCambiosTipoEntrega : null,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey[400],
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // En paso 1, 2 o 3, mostrar botón de confirmar con validaciones
    final puedeConfirmar = _validarDatos();

    if (!puedeConfirmar) {
      final razonError = _obtenerRazonError();
      return Tooltip(
        message: razonError,
        child: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: null,
          color: Colors.grey,
          disabledColor: Colors.grey,
          tooltip: razonError,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _confirmarEntrega,
      icon: const Icon(Icons.save, size: 18),
      label: const Text('Guardar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// ✅ MEJORADA 2026-02-15: Tabla de productos con rechazos PARCIALES editables

  // Métodos auxiliares privados
  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }
}
