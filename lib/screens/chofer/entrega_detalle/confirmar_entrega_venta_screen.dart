import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert' show base64Encode, base64Decode;
import 'dart:typed_data';
import 'package:flutter/services.dart'; // ✅ Necesario para FilteringTextInputFormatter
import '../../../config/app_text_styles.dart';
import '../../../models/entrega.dart';
import '../../../models/venta.dart';
import '../../../models/entrega_venta_confirmacion.dart';
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

  // ✅ REFACTORIZADO 2026-06-14: Usar objeto completo en lugar de parámetros individuales
  final EntregaVentaConfirmacion? confirmacionExistente;

  const ConfirmarEntregaVentaScreen({
    super.key,
    required this.entrega,
    required this.venta,
    required this.provider,
    this.confirmacionExistente,
  });

  @override
  State<ConfirmarEntregaVentaScreen> createState() =>
      _ConfirmarEntregaVentaScreenState();
}

class _ConfirmarEntregaVentaScreenState
    extends State<ConfirmarEntregaVentaScreen> {
  // ✅ 2026-07-02: Usar modelo EntregaVentaConfirmacion como fuente única de verdad
  late EntregaVentaConfirmacion _confirmacion;

  // Estados de la pantalla
  int _paso = 1; // 1: Seleccionar tipo + detalles, 2: Confirmación

  // ✅ Variables locales que no pertenecen al modelo
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _montoEfectivoController =
      TextEditingController();
  final TextEditingController _montoTransferenciaController =
      TextEditingController();
  List<dynamic> _fotosCapturadas = [];

  final ImagePicker _imagePicker = ImagePicker();
  final EntregaService _entregaService = EntregaService();

  // ✅ Datos de UI que no se persisten en el modelo
  List<Map<String, dynamic>> _tiposPago = [];
  bool _cargandoTiposPago = false;
  List<PagoEntrega> _pagos = [];
  int? _tipoPagoSeleccionado;

  List<tabla_widget.ProductoRechazado> _productosRechazados = [];

  final Map<int, TextEditingController> _cantidadRechazadaControllers = {};
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

    // ✅ 2026-07-02: Inicializar confirmación desde modelo existente o crear nueva
    if (widget.confirmacionExistente != null) {
      _confirmacion = widget.confirmacionExistente!;

      // ✅ Cargar fotos existentes
      if (_confirmacion.fotos != null && _confirmacion.fotos!.isNotEmpty) {
        _fotosCapturadas = List<dynamic>.from(_confirmacion.fotos!);
        debugPrint(
          '📸 [FOTOS CARGADAS] ${_fotosCapturadas.length} fotos existentes',
        );
      }

      // ✅ Cargar observaciones existentes
      if (_confirmacion.observacionesLogistica != null &&
          _confirmacion.observacionesLogistica!.isNotEmpty) {
        _observacionesController.text = _confirmacion.observacionesLogistica!;
      }

      // ✅ Cargar pagos existentes en los controllers
      if (_confirmacion.desglosePageos.isNotEmpty) {
        for (final desglose in _confirmacion.desglosePageos) {
          _pagos.add(
            PagoEntrega(
              tipoPagoId: desglose.tipoPagoId,
              monto: desglose.monto,
              referencia: desglose.referencia,
            ),
          );

          if (desglose.tipoPagoNombre.toUpperCase().contains('EFECTIVO')) {
            _montoEfectivoController.text = desglose.monto.toString();
          } else if (desglose.tipoPagoNombre.toUpperCase().contains(
                'Tranferencia / QR',
              ) ||
              desglose.tipoPagoNombre.toUpperCase().contains('QR')) {
            _montoTransferenciaController.text = desglose.monto.toString();
          }
        }
        debugPrint(
          '💳 [PAGOS CARGADOS] ${_confirmacion.desglosePageos.length} desgloses de pago cargados',
        );
      }

      debugPrint(
        '📝 [EDITAR CONFIRMACIÓN] ID: ${_confirmacion.id} | tipo=${_confirmacion.tipoEntrega} | novedad=${_confirmacion.tipoNovedad} | confirmacion=${_confirmacion.tipoConfirmacion}',
      );
    } else {
      // ✅ Crear nueva confirmación inicial
      _confirmacion = EntregaVentaConfirmacion.inicial(
        entregaId: widget.entrega.id,
        ventaId: widget.venta.id,
      );

      // ✅ Detectar si es crédito desde venta.estadoPago
      if (widget.venta.estadoPago == 'CREDITO') {
        debugPrint(
          '💳 [VENTA CRÉDITO] Venta #${widget.venta.numero} es a crédito',
        );
      }
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

  /// ✅ 2026-07-02: Construir observaciones usando el modelo
  String _construirObservacionesFinales() {
    if (_confirmacion.tipoEntrega == 'COMPLETA') {
      return 'Entrega completa';
    } else {
      final observaciones = _observacionesController.text.trim();
      final tipoLabel = _tiposNovedad.firstWhere(
        (t) => t['value'] == _confirmacion.tipoNovedad,
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

    debugPrint('✅ Pagos construidos automáticamente: ${_pagos.length} pagos');
  }

  /// ✅ 2026-07-02: Validar usando el modelo EntregaVentaConfirmacion
  bool _validarDatos() {
    if (_confirmacion.tipoEntrega == 'COMPLETA') {
      final esCredito = _esVentaCredito();
      double montoEfectivo =
          double.tryParse(_montoEfectivoController.text) ?? 0;
      double montoTransferencia =
          double.tryParse(_montoTransferenciaController.text) ?? 0;
      double totalEnInputs = montoEfectivo + montoTransferencia;

      if (!esCredito && _pagos.isEmpty && totalEnInputs == 0) {
        return false;
      }
    } else if (_confirmacion.tipoEntrega == 'CON_NOVEDAD') {
      if (_confirmacion.tipoNovedad == null) return false;
      if (_confirmacion.tipoNovedad == 'CLIENTE_CERRADO' &&
          _fotosCapturadas.isEmpty) return false;
    }
    return true;
  }

  /// ✅ 2026-07-02: Obtener razón del error usando el modelo
  String _obtenerRazonError() {
    if (_confirmacion.tipoEntrega == 'COMPLETA') {
      final esCredito = _esVentaCredito();
      double montoEfectivo =
          double.tryParse(_montoEfectivoController.text) ?? 0;
      double montoTransferencia =
          double.tryParse(_montoTransferenciaController.text) ?? 0;
      double totalEnInputs = montoEfectivo + montoTransferencia;

      if (!esCredito && _pagos.isEmpty && totalEnInputs == 0) {
        return 'Escribe un monto en Efectivo o QR, o marca como crédito';
      }
    } else if (_confirmacion.tipoEntrega == 'CON_NOVEDAD') {
      if (_confirmacion.tipoNovedad == null) {
        return 'Selecciona un tipo de novedad';
      }
      if (_confirmacion.tipoNovedad == 'CLIENTE_CERRADO' &&
          _fotosCapturadas.isEmpty) {
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
    if (_confirmacion.tipoNovedad == 'CLIENTE_CERRADO' &&
        _fotosCapturadas.isEmpty) {
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
      if (_confirmacion.tipoEntrega == 'COMPLETA' &&
          totalDineroRecibido == 0 &&
          !_esVentaCredito()) {
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
      debugPrint('   - Tipo: ${_confirmacion.tipoEntrega}');
      debugPrint('   - Tipo Novedad: ${_confirmacion.tipoNovedad}');
      debugPrint('   - Observaciones: $observacionesFinales');
      debugPrint('   - Fotos: ${_fotosCapturadas.length}');
      debugPrint('   - Pagos múltiples: ${_pagos.length}');
      debugPrint('   - Total dinero recibido: $totalDineroRecibido');
      debugPrint('   - Es Crédito: ${_esVentaCredito()}');

      // ✅ 2026-07-02: REFACTORIZADO - Construir modelo completo
      // Construir lista de desglose de pagos desde _pagos
      final desglosePageos = _pagos
          .asMap()
          .entries
          .map((entry) {
            final pago = entry.value;
            final tipoPago = _tiposPago.firstWhere(
              (t) => t['id'] == pago.tipoPagoId,
              orElse: () => {'nombre': 'Desconocido'},
            );
            return DesglosePago(
              tipoPagoId: pago.tipoPagoId,
              tipoPagoNombre: tipoPago['nombre'] ?? 'Desconocido',
              monto: pago.monto,
              referencia: pago.referencia,
            );
          })
          .toList();

      // Construir lista de productos devueltos
      final productos_devueltos = _productosRechazados
          .map((prod) => {
                'detalleVentaId': prod.detalleVentaId,
                'cantidadRechazada': prod.cantidadRechazada,
              })
          .toList();

      // Actualizar el modelo con TODOS los datos
      _confirmacion = _confirmacion.copyWith(
        fotos: _fotosCapturadas.whereType<String>().toList(),
        observacionesLogistica: observacionesFinales,
        tiendaAbierta: _confirmacion.tiendaAbierta,
        clientePresente: _confirmacion.clientePresente,
        motivoRechazo: _confirmacion.motivoRechazo,
        desglosePageos: desglosePageos,
        totalDineroRecibido: totalDineroRecibido,
        montoAceptado: _confirmacion.tipoEntrega == 'COMPLETA'
            ? widget.venta.total
            : (widget.venta.total - _productosRechazados.fold(0.0, (sum, prod) => sum + (prod.cantidadRechazada * prod.precioUnitario))),
        productosDevueltos: productos_devueltos,
      );

      debugPrint('📦 CONFIRMACION FINAL:');
      debugPrint('   - tipoConfirmacion: ${_confirmacion.tipoConfirmacion}');
      debugPrint('   - tipoNovedad: ${_confirmacion.tipoNovedad}');
      debugPrint('   - tipoEntrega: ${_confirmacion.tipoEntrega}');
      debugPrint('   - desglosePageos: ${_confirmacion.desglosePageos.length}');
      debugPrint('   - productosDevueltos: ${_confirmacion.productosDevueltos}');

      // ✅ 2026-07-02: Enviar usando toJson() del modelo
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
        pagos: _confirmacion.desglosePageos.map((d) => d.toJson()).toList(),
        esCredito: _esVentaCredito(),
        tipoConfirmacion: _confirmacion.tipoConfirmacion,
        productosRechazados: productos_devueltos,
        tipoNovedad: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.tipoNovedad,
        tiendaAbierta: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.tiendaAbierta,
        clientePresente: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.clientePresente,
        motivoRechazo: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.motivoRechazo,
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
      if (_confirmacion.tipoEntrega == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes seleccionar un tipo de entrega'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Si es CON_NOVEDAD, validar que haya seleccionado tipo de novedad
      if (_confirmacion.tipoEntrega == 'CON_NOVEDAD' &&
          _confirmacion.tipoNovedad == null) {
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
      debugPrint('   - Tipo: ${_confirmacion.tipoEntrega}');
      debugPrint('   - Novedad: ${_confirmacion.tipoNovedad}');
      debugPrint('   - Fotos: ${_fotosCapturadas.length}');
      debugPrint('   - Observaciones: ${_observacionesController.text}');

      // ✅ 2026-07-02: Convertir fotos nuevas a base64
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

      // ✅ 2026-07-02: Construir desglose de pagos desde _pagos
      final desglosePageos = _pagos
          .map((pago) {
            final tipoPago = _tiposPago.firstWhere(
              (t) => t['id'] == pago.tipoPagoId,
              orElse: () => {'nombre': 'Desconocido'},
            );
            return DesglosePago(
              tipoPagoId: pago.tipoPagoId,
              tipoPagoNombre: tipoPago['nombre'] ?? 'Desconocido',
              monto: pago.monto,
              referencia: pago.referencia,
            );
          })
          .toList();

      // ✅ Construir lista de productos devueltos
      final productos_devueltos = _productosRechazados
          .map((prod) => {
                'detalleVentaId': prod.detalleVentaId,
                'cantidadRechazada': prod.cantidadRechazada,
              })
          .toList();

      // ✅ 2026-07-02: Actualizar modelo con todos los datos en edición
      _confirmacion = _confirmacion.copyWith(
        fotos: _fotosCapturadas.whereType<String>().toList(),
        observacionesLogistica: observacionesFinales,
        desglosePageos: desglosePageos,
        productosDevueltos: productos_devueltos,
        tipoEntrega: _confirmacion.tipoEntrega,
        tipoNovedad: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.tipoNovedad,
        tiendaAbierta: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.tiendaAbierta,
        clientePresente: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.clientePresente,
        motivoRechazo: _confirmacion.tipoConfirmacion == 'COMPLETA'
            ? null
            : _confirmacion.motivoRechazo,
      );

      debugPrint('📦 CONFIRMACION ACTUALIZADA EN EDICIÓN:');
      debugPrint('   - tipoConfirmacion: ${_confirmacion.tipoConfirmacion}');
      debugPrint('   - desglosePageos: ${_confirmacion.desglosePageos.length}');
      debugPrint('   - productosDevueltos: ${_confirmacion.productosDevueltos}');

      // ✅ 2026-07-02: Calcular valores finales para envío
      final tipoConfirmacionFinal = _confirmacion.tipoConfirmacion;
      final tipoNovedadFinal = _confirmacion.tipoConfirmacion == 'COMPLETA'
          ? null
          : _confirmacion.tipoNovedad;
      final tiendaAbiertaFinal = _confirmacion.tipoConfirmacion == 'COMPLETA'
          ? null
          : _confirmacion.tiendaAbierta;
      final clientePresenteFinal = _confirmacion.tipoConfirmacion == 'COMPLETA'
          ? null
          : _confirmacion.clientePresente;
      final motivoRechazoFinal = _confirmacion.tipoConfirmacion == 'COMPLETA'
          ? null
          : _confirmacion.motivoRechazo;
      final pagosArray = _confirmacion.desglosePageos
          .map((d) => d.toJson())
          .toList();
      final productosRechazadosArray =
          (_confirmacion.productosDevueltos ?? []).cast<Map<String, dynamic>>();

      // ✅ 2026-06-14: Detectar si es edición o creación nueva
      bool success;

      if (widget.confirmacionExistente != null) {
        // ✅ EDICIÓN: Usar PUT /api/confirmaciones/{id}
        success = await widget.provider.editarConfirmacionEntrega(
          widget.confirmacionExistente!.id,
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
          esCredito: _esVentaCredito(),
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
                _confirmacion.tipoEntrega == 'COMPLETA'
                    ? '✅ Entrega marcada como completa'
                    : '⚠️ Entrega marcada con novedad',
              ),
              backgroundColor: _confirmacion.tipoEntrega == 'COMPLETA'
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
          title: widget.confirmacionExistente != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Editar',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
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
                  Flexible(
                    child: SegmentedButton<String>(
                      selected: {_confirmacion.tipoEntrega},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          final tipoSeleccionado = newSelection.first;
                          if (tipoSeleccionado == 'COMPLETA') {
                            // ✅ 2026-07-02: Usar copyWith para actualizar el modelo
                            _confirmacion = _confirmacion.copyWith(
                              tipoEntrega: 'COMPLETA',
                              tipoConfirmacion: 'COMPLETA',
                              tipoNovedad: null,
                              tiendaAbierta: false,
                              clientePresente: false,
                              motivoRechazo: null,
                            );
                            _productosRechazados.clear();
                            debugPrint(
                              '✅ [MODELO] Cambiado a COMPLETA - tipos y novedad reseteados',
                            );
                          } else {
                            _confirmacion = _confirmacion.copyWith(
                              tipoEntrega: 'CON_NOVEDAD',
                              tipoConfirmacion: 'CON_NOVEDAD',
                              tipoNovedad: null,
                            );
                            _pagos.clear();
                            debugPrint(
                              '✅ [MODELO] Cambiado a CON_NOVEDAD - pagos limpiados',
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
              if (_confirmacion.tipoEntrega == 'COMPLETA')
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: RegistroPagosCompletoWidget(
                      totalVenta: widget.venta.total,
                      pagos: _pagos,
                      tiposPago: _tiposPago,
                      esCredito: _esVentaCredito(),
                      montoEfectivoController: _montoEfectivoController,
                      montoTransferenciaController:
                          _montoTransferenciaController,
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
      key: ValueKey(
        'novedad_${_confirmacion.tipoNovedad ?? "none"}',
      ),
      screenContext: context,
      isDarkMode: isDarkMode,
      tipoNovedad: _confirmacion.tipoNovedad,
      tipoConfirmacion: _confirmacion.tipoConfirmacion,
      tiposNovedad: _tiposNovedad,
      venta: widget.venta,
      observacionesController: _observacionesController,
      fotosCapturadas: _fotosCapturadas,
      eliminarFoto: _eliminarFoto,
      capturarFoto: _capturarFoto,
      construirImagenFoto: (foto) => _construirImagenFoto(foto),
      buildTablaProductosRechazados: (ctx, dark) =>
          tabla_widget.TablaProductosRechazadosWidget(
            key: ValueKey(
              'tabla_${_confirmacion.tipoNovedad ?? "none"}',
            ),
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
          // ✅ 2026-07-02: Usar copyWith para actualizar el modelo
          _confirmacion = _confirmacion.copyWith(
            tipoNovedad: value,
            tipoEntrega: 'CON_NOVEDAD',
            tipoConfirmacion: value,
          );
          debugPrint(
            '🔄 [MODELO] Confirmación actualizada: tipoEntrega=CON_NOVEDAD | tipoConfirmacion=$value | tipoNovedad=$value',
          );
          _productosRechazados.clear();
          _cantidadRechazadaControllers.clear();
        });
      },
    );
  }

  /// ✅ NUEVO 2026-03-05: Construir botón de acción dinámico para AppBar
  Widget _construirBotonAccion() {
    // Si está en modo edición, siempre mostrar botón de guardar
    if (widget.confirmacionExistente != null) {
      final puedGuardar = _validarDatos();
      return Tooltip(
        message: puedGuardar
            ? 'Guardar cambios'
            : 'Completa los datos requeridos',
        child: IconButton(
          onPressed: puedGuardar ? _guardarCambiosTipoEntrega : null,
          icon: const Icon(Icons.save, size: 20),
          color: Colors.blue,
          disabledColor: Colors.grey[400],
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
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
