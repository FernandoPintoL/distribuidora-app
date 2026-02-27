import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert' show base64Encode;
import 'package:flutter/services.dart';  // ✅ Necesario para FilteringTextInputFormatter
import '../../../models/entrega.dart';
import '../../../models/venta.dart';
import '../../../providers/entrega_provider.dart';
import '../../../services/image_compression_service.dart';  // ✅ NUEVO: Para comprimir imágenes
import '../../../services/entrega_service.dart';  // ✅ NUEVO: Para obtener tipos de pago

// ✅ NUEVA 2026-02-12: Modelo para pagos múltiples
class PagoEntrega {
  int tipoPagoId;
  double monto;
  String? referencia;

  PagoEntrega({
    required this.tipoPagoId,
    required this.monto,
    this.referencia,
  });

  Map<String, dynamic> toJson() => {
    'tipo_pago_id': tipoPagoId,
    'monto': monto,
    'referencia': referencia,
  };
}

// ✅ NUEVA 2026-02-15: Modelo para productos rechazados en devolución parcial
class ProductoRechazado {
  int detalleVentaId;
  int? productoId;  // ✅ NUEVO: ID del producto (requerido por backend)
  String nombreProducto;
  double cantidadOriginal;  // ✅ Cantidad original en la venta
  double cantidadRechazada;  // ✅ Cantidad que el cliente rechaza (editable)
  double precioUnitario;
  double subtotalOriginal;

  ProductoRechazado({
    required this.detalleVentaId,
    this.productoId,  // ✅ NUEVO: Opcional en constructor, requerido en JSON
    required this.nombreProducto,
    required this.cantidadOriginal,
    required this.cantidadRechazada,
    required this.precioUnitario,
    required this.subtotalOriginal,
  });

  /// Calcular el subtotal basado en cantidad rechazada
  double get subtotalRechazado => cantidadRechazada * precioUnitario;

  /// Calcular cantidad entregada
  double get cantidadEntregada => cantidadOriginal - cantidadRechazada;

  Map<String, dynamic> toJson() => {
    'producto_id': productoId ?? 0,  // ✅ Backend lo requiere
    'producto_nombre': nombreProducto,  // ✅ Backend espera producto_nombre
    'cantidad': cantidadRechazada,  // ✅ CAMBIO: Backend espera "cantidad" (lo rechazado)
    'precio_unitario': precioUnitario,  // ✅ Backend lo requiere
    'subtotal': subtotalRechazado,  // ✅ CAMBIO: Backend espera "subtotal" (no subtotal_rechazado)

    // ✅ CAMPOS OPCIONALES PARA AUDITORÍA (no requeridos por validación):
    'detalle_venta_id': detalleVentaId,
    'cantidad_original': cantidadOriginal,
    'cantidad_entregada': cantidadEntregada,
  };
}

class ConfirmarEntregaVentaScreen extends StatefulWidget {
  final Entrega entrega;
  final Venta venta;
  final EntregaProvider provider;

  // ✅ NUEVO 2026-02-21: Parámetros para modo edición
  final bool isEditing;
  final String? tipoEntregaExistente;
  final String? tipoNovedadExistente;

  const ConfirmarEntregaVentaScreen({
    Key? key,
    required this.entrega,
    required this.venta,
    required this.provider,
    this.isEditing = false,
    this.tipoEntregaExistente,
    this.tipoNovedadExistente,
  }) : super(key: key);

  @override
  State<ConfirmarEntregaVentaScreen> createState() =>
      _ConfirmarEntregaVentaScreenState();
}

class _ConfirmarEntregaVentaScreenState
    extends State<ConfirmarEntregaVentaScreen> {
  // Estados de la pantalla
  int _paso = 1; // 1: Seleccionar tipo, 2: Detalles de novedad, 3: Confirmación

  // Datos capturados
  String? _tipoEntrega; // COMPLETA o CON_NOVEDAD
  String? _tipoNovedad; // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADA, NO_CONTACTADO
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  List<File> _fotosCapturadas = [];

  final ImagePicker _imagePicker = ImagePicker();
  final EntregaService _entregaService = EntregaService();  // ✅ NUEVO: Para obtener tipos de pago

  // ✅ NUEVO 2026-02-12: Múltiples pagos + Crédito
  List<Map<String, dynamic>> _tiposPago = [];
  bool _cargandoTiposPago = false;
  List<PagoEntrega> _pagos = [];  // Lista de pagos múltiples
  bool _esCredito = false;  // ✅ CAMBIO: Checkbox en lugar de input de monto
  String _tipoConfirmacion = 'COMPLETA';  // COMPLETA o CON_NOVEDAD

  // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
  List<ProductoRechazado> _productosRechazados = [];  // Productos marcados como rechazados

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
      'value': 'RECHAZADA',
      'label': '❌ Rechazo Total',
      'description': 'El cliente rechazó toda la mercancía',
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarTiposPago();

    // ✅ NUEVO 2026-02-13: Si la venta es a crédito, pre-marcar el checkbox
    if (widget.venta.estadoPago == 'CREDITO') {
      _esCredito = true;
      debugPrint('💳 [VENTA CRÉDITO] Venta #${widget.venta.numero} es a crédito - pre-marcando checkbox');
    }

    // ✅ NUEVO 2026-02-21: Si está en modo edición, cargar datos existentes
    if (widget.isEditing && widget.tipoEntregaExistente != null) {
      _tipoEntrega = widget.tipoEntregaExistente;
      _tipoNovedad = widget.tipoNovedadExistente;
      debugPrint('📝 [EDITAR ENTREGA] Cargando datos existentes: tipo=$_tipoEntrega, novedad=$_tipoNovedad');
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

  /// Cargar tipos de pago disponibles
  Future<void> _cargarTiposPago() async {
    setState(() => _cargandoTiposPago = true);

    try {
      final response = await _entregaService.obtenerTiposPago();

      if (response.success && response.data != null) {
        setState(() {
          _tiposPago = response.data!.cast<Map<String, dynamic>>();
          _cargandoTiposPago = false;
        });
      } else {
        setState(() => _cargandoTiposPago = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar tipos de pago: ${response.message}'),
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
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
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
            final tamanMB =
                await ImageCompressionService.obtenerTamanoEnMB(imagenComprimida);
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
                content: Text(
                  ImageCompressionService.obtenerMensajeError(e),
                ),
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
      final tipoLabel = _tiposNovedad
          .firstWhere((t) => t['value'] == _tipoNovedad)['label']!;

      return observaciones.isEmpty
          ? tipoLabel
          : '$tipoLabel - $observaciones';
    }
  }

  /// Obtener tipos de pago disponibles que no están ya registrados
  List<Map<String, dynamic>> _obtenerTiposPagoDisponibles() {
    final tipoPagoYaUsados = _pagos.map((p) => p.tipoPagoId).toSet();
    return _tiposPago
        .where((tipo) => !tipoPagoYaUsados.contains(tipo['id']))
        .toList();
  }

  /// Obtener sugerencias inteligentes de pago basado en saldo pendiente
  Map<String, dynamic>? _obtenerSugerenciaPago() {
    if (_pagos.isEmpty) return null;

    double totalRecibido = _pagos.fold(0.0, (sum, pago) => sum + pago.monto);
    double saldoPendiente = widget.venta.total - totalRecibido;

    if (saldoPendiente <= 0) return null;

    // Obtener tipos de pago disponibles
    final tiposDisponibles = _obtenerTiposPagoDisponibles();
    if (tiposDisponibles.isEmpty) return null;

    // ✅ FIXED: Preferencia: TRANSFERENCIA > CHEQUE > otros
    Map<String, dynamic>? tipoPagoSugerido;
    final preferencia = ['TRANSFERENCIA', 'CHEQUE', 'QR'];

    for (final nombre in preferencia) {
      try {
        tipoPagoSugerido = tiposDisponibles.firstWhere(
          (t) => (t['nombre'] as String?)?.toUpperCase().contains(nombre) ?? false,
        );
        if (tipoPagoSugerido.isNotEmpty && tipoPagoSugerido.containsKey('nombre')) {
          break;
        }
      } catch (e) {
        // No encontró en esta preferencia, continúa a la siguiente
        continue;
      }
    }

    // Si no encuentra por preferencia, toma el primero disponible
    if (tipoPagoSugerido == null || tipoPagoSugerido.isEmpty) {
      try {
        tipoPagoSugerido = tiposDisponibles.firstWhere(
          (t) => t.containsKey('nombre') && ((t['nombre'] as String?)?.isNotEmpty ?? false),
        );
      } catch (e) {
        tipoPagoSugerido = null;
      }
    }

    return tipoPagoSugerido != null && tipoPagoSugerido.isNotEmpty && tipoPagoSugerido.containsKey('nombre')
        ? {
            'tipo': tipoPagoSugerido,
            'saldo': saldoPendiente,
            'totalRecibido': totalRecibido,
          }
        : null;
  }

  /// ✅ NUEVA 2026-02-15: Sugerencia inteligente de pago
  Widget _buildSugerenciaPago({bool isDarkMode = false}) {
    final sugerencia = _obtenerSugerenciaPago();
    if (sugerencia == null) return const SizedBox.shrink();

    final tipoPago = sugerencia['tipo'] as Map<String, dynamic>;
    final saldoPendiente = sugerencia['saldo'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.blue[900]!, Colors.blue[800]!]
              : [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.blue[700]! : Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Sugerencia Inteligente',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.blue[100] : Colors.blue[900],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Te quedan Bs. ${saldoPendiente.toStringAsFixed(2)} por recibir',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de pago sugerido con botón rápido
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Pago Sugerido',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (tipoPago['nombre'] as String?) ?? 'Tipo de Pago',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monto: Bs. ${saldoPendiente.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Pre-llenar formulario con sugerencia
                    _montoController.text = saldoPendiente.toStringAsFixed(2);
                    setState(() {});
                    // Scroll hacia el formulario
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Monto de Bs. ${saldoPendiente.toStringAsFixed(2)} pre-completado en ${(tipoPago['nombre'] as String?) ?? 'Tipo de Pago'}',
                          ),
                          backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.blue[700] : Colors.blue[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text(
                    'Usar\nSugerencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVA 2026-02-15: Formulario para agregar pago
  Widget _buildPagoForm({bool isDarkMode = false}) {
    int? tipoPagoSeleccionado;
    final tiposDisponibles = _obtenerTiposPagoDisponibles();

    return StatefulBuilder(
      builder: (context, setFormState) {
        return Column(
          children: [
            // Sugerencia inteligente
            if (_pagos.isNotEmpty) ...[
              _buildSugerenciaPago(isDarkMode: isDarkMode),
              const SizedBox(height: 16),
            ],

            // Formulario para agregar nuevo pago
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '➕ Agregar Nuevo Pago',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selector de tipo de pago
                  if (_cargandoTiposPago)
                    const Center(child: CircularProgressIndicator())
                  else if (tiposDisponibles.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: tipoPagoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Pago',
                        hintText: 'Selecciona método',
                        prefixIcon: const Icon(Icons.payment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      items: tiposDisponibles.map((tipo) {
                        return DropdownMenuItem<int>(
                          value: tipo['id'] as int,
                          child: Text(tipo['nombre'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setFormState(() => tipoPagoSeleccionado = value);
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✅ Pago Completo Registrado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No hay más tipos de pago disponibles',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Campo de monto (solo si hay tipos disponibles)
                  if (tiposDisponibles.isNotEmpty) ...[
                    TextField(
                      controller: _montoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto (Bs.)',
                        hintText: 'Ej: 100.50',
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (_) {
                        setFormState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Botón para agregar (solo si hay tipos disponibles)
                  if (tiposDisponibles.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: tipoPagoSeleccionado == null ||
                                _montoController.text.isEmpty
                            ? null
                            : () {
                                try {
                                  final monto = double.parse(_montoController.text);
                                  if (monto <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('El monto debe ser mayor a 0'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _pagos.add(
                                      PagoEntrega(
                                        tipoPagoId: tipoPagoSeleccionado!,
                                        monto: monto,
                                        referencia: _referenciaController.text
                                                .isNotEmpty
                                            ? _referenciaController.text
                                            : null,
                                      ),
                                    );
                                  });

                                  _montoController.clear();
                                  _referenciaController.clear();
                                  setFormState(
                                    () => tipoPagoSeleccionado = null,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Pago agregado'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ NUEVA 2026-02-12: Checkbox simple para marcar como crédito
  Widget _buildSeccionCredito() {
    return CheckboxListTile(
      value: _esCredito,
      onChanged: (value) {
        setState(() {
          _esCredito = value ?? false;
        });
      },
      title: const Text(
        '💳 Esta venta es a Crédito',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Marcar si el cliente no paga ahora (promesa de pago)',
        style: TextStyle(fontSize: 12),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  /// Confirmar entrega
  Future<void> _confirmarEntrega() async {
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
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Convertir fotos a base64 si existen
      List<String>? fotosBase64;
      if (_fotosCapturadas.isNotEmpty) {
        fotosBase64 = [];
        for (final foto in _fotosCapturadas) {
          final bytes = await foto.readAsBytes();
          final base64 = _bytesToBase64(bytes);
          fotosBase64.add(base64);
        }
      }

      final observacionesFinales = _construirObservacionesFinales();

      // ✅ NUEVA 2026-02-12: Validar que al menos hay un pago registrado o es a crédito
      double totalDineroRecibido = _pagos.fold(0, (sum, pago) => sum + pago.monto);

      // ✅ CAMBIO 2026-02-13: Solo requiere pago si es COMPLETA
      // Si es NOVEDAD, NO se requiere pago (ya se registró la novedad)
      if (_tipoEntrega == 'COMPLETA' && totalDineroRecibido == 0 && !_esCredito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Debes registrar al menos un pago o marcar como crédito'),
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
      debugPrint('   - Pagos múltiples: ${_pagos.length}');  // ✅ NUEVO
      debugPrint('   - Total dinero recibido: $totalDineroRecibido');  // ✅ NUEVO
      debugPrint('   - Es Crédito: $_esCredito');  // ✅ CAMBIO

      // ✅ NUEVA 2026-02-12: Construir array de pagos en formato backend
      final pagosArray = _pagos.map((pago) => pago.toJson()).toList();

      // ✅ NUEVA 2026-02-15: Construir array de productos rechazados
      final productosRechazadosArray = _productosRechazados.map((prod) => prod.toJson()).toList();

      // ✅ DEBUG: Ver qué se envía al backend
      debugPrint('📦 PRODUCTOS RECHAZADOS AL BACKEND:');
      debugPrint('   - Total: ${productosRechazadosArray.length}');
      if (productosRechazadosArray.isNotEmpty) {
        for (var prod in productosRechazadosArray) {
          debugPrint('   - ${prod['producto_nombre']}: ${prod['cantidad_rechazada']}/${prod['cantidad_original']}');
        }
      } else {
        debugPrint('   ⚠️ ARRAY VACÍO - No hay productos marcados como rechazados');
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
        pagos: pagosArray,  // Array de {tipo_pago_id, monto, referencia}
        esCredito: _esCredito,  // ✅ CAMBIO: Enviar si es a crédito
        tipoConfirmacion: _tipoConfirmacion,
        // ✅ NUEVA 2026-02-15: Enviar productos rechazados para devolución parcial
        productosRechazados: productosRechazadosArray,
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
          // Cerrar la pantalla después de 1.5s
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(context);
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
      if (_tipoEntrega == 'NOVEDAD' && _tipoNovedad == null) {
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
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      debugPrint('📝 [EDITAR ENTREGA] Guardando cambios:');
      debugPrint('   - Tipo: $_tipoEntrega');
      debugPrint('   - Novedad: $_tipoNovedad');

      // Llamar al provider para guardar
      await widget.provider.cambiarTipoEntrega(
        entregaId: widget.entrega.id,
        ventaId: widget.venta.id,
        tipoEntrega: _tipoEntrega == 'COMPLETA' ? 'COMPLETA' : 'CON_NOVEDAD',
        tipoNovedad: _tipoNovedad,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (widget.provider.isLoading == false && widget.provider.errorMessage == null) {
          // Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tipoEntrega == 'COMPLETA'
                    ? '✅ Entrega marcada como completa'
                    : '⚠️ Entrega marcada con novedad',
              ),
              backgroundColor: _tipoEntrega == 'COMPLETA' ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );

          // Cerrar pantalla
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${widget.provider.errorMessage ?? 'Error desconocido'}'),
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
          title: Text(_paso == 1
              ? (widget.isEditing
                  ? '✏️ Editar Tipo de Entrega F.${widget.venta.id}'
                  : 'Entrega a Venta F.${widget.venta.id}')
              : _tipoEntrega == 'NOVEDAD'
                  ? 'Registrar Novedad'
                  : 'Confirmar Entrega'),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_paso > 1) {
                setState(() => _paso--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          // ✅ NUEVO: Botón de confirmación en AppBar (solo en PASO 2 o 3)
          actions: [
            if (_paso > 1)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: _paso == 2 && _tipoEntrega == 'CON_NOVEDAD' && _tipoNovedad == null
                      ? Tooltip(
                          message: 'Selecciona un tipo de novedad',
                          child: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: null,
                            color: Colors.grey,
                            disabledColor: Colors.grey,
                          ),
                        )
                      : _paso == 2 && _tipoEntrega == 'CON_NOVEDAD' &&
                              (_tipoNovedad == 'CLIENTE_CERRADO' &&
                                  _fotosCapturadas.isEmpty)
                          ? Tooltip(
                              message: 'Captura al menos una foto',
                              child: IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: null,
                                color: Colors.grey,
                                disabledColor: Colors.grey,
                              ),
                            )
                          : // ✅ FIXED: Cambiar _paso == 3 por _paso == 2 para habilitar botón cuando pagos están completos
                          _paso == 2 &&
                                  (_tipoEntrega == 'COMPLETA' &&
                                      _pagos.isEmpty &&
                                      !_esCredito)
                              ? Tooltip(
                                  message:
                                      'Registra un pago o marca como crédito',
                                  child: IconButton(
                                    icon: const Icon(Icons.check_circle_outline),
                                    onPressed: null,
                                    color: Colors.grey,
                                    disabledColor: Colors.grey,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.check_circle),
                                  onPressed: widget.isEditing ? _guardarCambiosTipoEntrega : _confirmarEntrega,
                                  color: Colors.green,
                                  tooltip: widget.isEditing ? 'Guardar cambios' : 'Confirmar y guardar',
                                ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _paso == 1
              ? _buildPasoSeleccionar(context, isDarkMode)
              : _tipoEntrega == 'COMPLETA'
                  ? _buildPasoConfirmacionCompleta(context, isDarkMode)
                  : _buildPasoNovedad(context, isDarkMode),
        ),
      ),
    );
  }

  // PASO 1: Seleccionar tipo de entrega
  Widget _buildPasoSeleccionar(BuildContext context, bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Información de la venta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Encabezado con indicador de crédito si aplica
                  Row(
                    children: [
                      Text(
                        'Venta a Entregar Folio: ${widget.venta.id}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ NUEVO: Badge si es a crédito
                      if (widget.venta.estadoPago == 'CREDITO')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            border: Border.all(color: Colors.orange[700]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '💳 CRÉDITO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Número:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.venta.numero,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cliente:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.venta.clienteNombre ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Instrucción
            Text(
              '¿Cómo fue la entrega?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona el estado de la entrega para registrar los detalles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón Entrega Completa
            SizedBox(
              width: double.infinity,
              height: 120,
              child: Material(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _tipoEntrega = 'COMPLETA';
                      _paso = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Entrega Completa',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Entrega con Novedad
            SizedBox(
              width: double.infinity,
              height: 120,
              child: Material(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _tipoEntrega = 'NOVEDAD';
                      _paso = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Entrega con Novedad',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PASO 2: Confirmación de Entrega Completa
  Widget _buildPasoConfirmacionCompleta(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: isDarkMode ? Colors.green[400] : Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Entrega Completa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.green[900]!.withOpacity(0.2)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.green[700]!.withOpacity(0.5)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Venta',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Número:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.venta.numero,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cliente:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.venta.clienteNombre ?? 'Sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Bs. ${widget.venta.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ NUEVA 2026-02-12: Resumen de montos
                  _buildResumenMontos(widget.venta.total),

                  const SizedBox(height: 24),

                  // ✅ NUEVA 2026-02-12: Sección de Pagos Múltiples
                  Text(
                    '💳 Registrar Pagos (Múltiples Métodos)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente puede pagar en efectivo, transferencia, o combinación. También puede dejar crédito.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ NUEVA: Lista de pagos registrados
                  if (_pagos.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.blue[900]!.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.blue[700]!.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ NUEVA 2026-02-15: Header con botón de edición
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '✅ Pagos Registrados (${_pagos.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // ✅ NUEVA: Botón para corregir pagos
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _mostrarDialogoCorregirPagos(context, isDarkMode),
                                    tooltip: '✏️ Editar Pagos',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._pagos.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final pago = entry.value;
                                final tipoNombre = _tiposPago
                                    .firstWhere(
                                      (t) => t['id'] == pago.tipoPagoId,
                                      orElse: () => {'nombre': 'Desconocido'},
                                    )['nombre'] ??
                                    'Desconocido';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tipoNombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Bs. ${pago.monto.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (pago.referencia != null &&
                                                pago.referencia!.isNotEmpty)
                                              Text(
                                                'Ref: ${pago.referencia}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          setState(() {
                                            _pagos.removeAt(idx);
                                          });
                                        },
                                        color: Colors.red,
                                        tooltip: 'Eliminar pago',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              Divider(color: Colors.blue.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Recibido:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${_pagos.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // ✅ CAMBIO 2026-02-13: Solo mostrar formulario de pago si es COMPLETA
                  if (_tipoEntrega == 'COMPLETA') ...[
                    // ✅ NUEVA: Formulario para agregar nuevo pago
                    // Si es a crédito, mostrar aviso; si no, mostrar formulario
                    if (widget.venta.estadoPago == 'CREDITO')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Venta a Crédito',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Esta venta es una promesa de pago. El cliente NO paga ahora.',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildPagoForm(isDarkMode: isDarkMode),

                    const SizedBox(height: 24),

                    // ✅ NUEVA: Sección de crédito (checkbox)
                    _buildSeccionCredito(),

                    const SizedBox(height: 24),
                    Text(
                      '✅ La entrega será registrada como completa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    // ✅ CAMBIO 2026-02-13: Si es NOVEDAD, mostrar resumen de la novedad
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Novedad Registrada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '📋 Tipo de Novedad: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _tiposNovedad
                                                .firstWhere(
                                                  (t) => t['value'] == _tipoNovedad,
                                                  orElse: () => {'label': '⚠️ No especificado'},
                                                )['label'] ??
                                            '⚠️ No especificado',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: _tipoNovedad == null ? Colors.red[700] : Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_observacionesController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Observaciones: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _observacionesController.text,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (_fotosCapturadas.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Fotos: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '${_fotosCapturadas.length} capturada${_fotosCapturadas.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '⚠️ NO se requiere registro de pago para novedades. La entrega será registrada con la novedad.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '✅ La entrega será registrada con novedad',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // ✅ CAMBIO: Botones Atrás/Confirmar movidos al AppBar
      ],
    );
  }

  // PASO 2: Registro de Novedad
  Widget _buildPasoNovedad(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de Novedad
                  Text(
                    'Tipo de Novedad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._tiposNovedad.map((tipo) {
                    final isSelected = _tipoNovedad == tipo['value'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isSelected
                            ? isDarkMode
                                ? Colors.orange[900]!.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.15)
                            : isDarkMode
                                ? Colors.grey.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _tipoNovedad = tipo['value'];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? isDarkMode ? Colors.orange[600]! : Colors.orange
                                    : isDarkMode
                                        ? Colors.grey.withOpacity(0.4)
                                        : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: tipo['value']!,
                                  groupValue: _tipoNovedad,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _tipoNovedad = value;
                                      });
                                    }
                                  },
                                  activeColor:
                                      isDarkMode ? Colors.orange[400] : Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tipo['label']!,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tipo['description']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // ✅ NUEVA 2026-02-15: Mostrar tabla de productos SOLO para devolución parcial
                  if (_tipoNovedad == 'DEVOLUCION_PARCIAL')
                    Column(
                      children: [
                        _buildTablaProductosRechazados(isDarkMode: isDarkMode),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Campo de Observaciones
                  Text(
                    'Observaciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detalla lo sucedido para mejor seguimiento',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacionesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Ej: Cliente no está en la dirección, volveré a intentar...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ NUEVA 2026-02-12: Resumen de montos (también en Novedad)
                  // ✅ MEJORADA 2026-02-15: Si hay devolución parcial, usar monto entregado
                  _buildResumenMontos(
                    _tipoNovedad == 'DEVOLUCION_PARCIAL'
                        ? (widget.venta.total -
                            _productosRechazados.fold(0.0, (sum, p) => sum + p.subtotalRechazado))
                        : widget.venta.total,
                  ),

                  const SizedBox(height: 24),

                  // Sección de Fotos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fotos de la Novedad',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_fotosCapturadas.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captura fotos como evidencia de la novedad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Galería de fotos capturadas
                  if (_fotosCapturadas.isNotEmpty)
                    Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _fotosCapturadas.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _fotosCapturadas[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _eliminarFoto(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  // Botón para capturar foto
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _capturarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ NUEVA 2026-02-15: Sección de Pagos SOLO para Devolución Parcial
                  if (_tipoNovedad == 'DEVOLUCION_PARCIAL') ...[
                    Text(
                      '💳 Registrar Pagos (Múltiples Métodos)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),

                  // ✅ NUEVA: Lista de pagos registrados
                  if (_pagos.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.blue[900]!.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.blue[700]!.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ Pagos Registrados (${_pagos.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._pagos.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final pago = entry.value;
                                final tipoNombre = _tiposPago
                                    .firstWhere(
                                      (t) => t['id'] == pago.tipoPagoId,
                                      orElse: () => {'nombre': 'Desconocido'},
                                    )['nombre'] ??
                                    'Desconocido';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tipoNombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Bs. ${pago.monto.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (pago.referencia != null &&
                                                pago.referencia!.isNotEmpty)
                                              Text(
                                                'Ref: ${pago.referencia}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          setState(() {
                                            _pagos.removeAt(idx);
                                          });
                                        },
                                        color: Colors.red,
                                        tooltip: 'Eliminar pago',
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              Divider(color: Colors.blue.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Recibido:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${_pagos.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // ✅ NUEVA: Formulario para agregar nuevo pago
                  // Si es a crédito, mostrar aviso; si no, mostrar formulario
                  if (widget.venta.estadoPago == 'CREDITO')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Venta a Crédito',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Esta venta es una promesa de pago. El cliente NO paga ahora.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildPagoForm(isDarkMode: isDarkMode),

                  const SizedBox(height: 24),

                    // ✅ NUEVA: Sección de crédito (checkbox)
                    _buildSeccionCredito(),
                  ],  // ✅ Cierre de if (_tipoNovedad == 'DEVOLUCION_PARCIAL')
                ],
              ),
            ),
          ),
        ),
        // ✅ CAMBIO: Botones Atrás/Confirmar movidos al AppBar
      ],
    );
  }

  /// ✅ MEJORADA 2026-02-15: Tabla de productos con rechazos PARCIALES editables
  Widget _buildTablaProductosRechazados({bool isDarkMode = false}) {
    if (widget.venta.detalles == null || widget.venta.detalles!.isEmpty) {
      return SizedBox.shrink();
    }

    // Calcular totales
    double totalOriginal = widget.venta.detalles!.fold(0.0, (sum, det) => sum + (det.subtotal ?? 0));
    double montoRechazado = _productosRechazados.fold(0.0, (sum, prod) => sum + prod.subtotalRechazado);
    double montoEntregado = totalOriginal - montoRechazado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado mejorado
        Text(
          '📦 Productos de la Venta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Marca productos con rechazo parcial e ingresa cantidad rechazada',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        // Tabla de productos mejorada
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.orange.withOpacity(0.1),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    '✗',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Producto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Orig',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Rech',  // ✅ NUEVO: Cantidad Rechazada (editable)
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Entre',  // ✅ NUEVO: Cantidad Entregada (calculada)
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Precio',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Subtotal Rech',  // ✅ NUEVO: Subtotal de rechazadas
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: widget.venta.detalles!.asMap().entries.map((entry) {
                final detalle = entry.value;
                // ✅ FIX: Buscar producto rechazado de forma segura
                ProductoRechazado? productoRechazado;
                try {
                  productoRechazado = _productosRechazados.firstWhere(
                    (p) => p.detalleVentaId == detalle.id,
                  );
                } catch (e) {
                  productoRechazado = null;  // No encontrado
                }
                final isRechazado = productoRechazado != null;

                return DataRow(
                  color: MaterialStateColor.resolveWith((states) {
                    if (isRechazado) {
                      return Colors.orange.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  }),
                  cells: [
                    // ✅ Checkbox para marcar como rechazado
                    DataCell(
                      Checkbox(
                        value: isRechazado,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              // ✅ MEJORADO: Crear con cantidad rechazada = 1 (el usuario edita)
                              _productosRechazados.add(
                                ProductoRechazado(
                                  detalleVentaId: detalle.id,
                                  productoId: detalle.producto?.id,  // ✅ NUEVO: Backend lo requiere
                                  nombreProducto: detalle.producto?.nombre ?? detalle.nombreProducto ?? 'Producto',
                                  cantidadOriginal: detalle.cantidad.toDouble(),
                                  cantidadRechazada: 1.0,  // ✅ Sugerir 1, usuario edita
                                  precioUnitario: detalle.precioUnitario.toDouble(),
                                  subtotalOriginal: detalle.subtotal?.toDouble() ?? 0,
                                ),
                              );
                              // ✅ Crear controller para este producto si no existe
                              if (!_cantidadRechazadaControllers.containsKey(detalle.id)) {
                                _cantidadRechazadaControllers[detalle.id] = TextEditingController(text: '1.0');
                              }
                            } else {
                              // Remover producto rechazado
                              _productosRechazados.removeWhere(
                                (p) => p.detalleVentaId == detalle.id,
                              );
                              // ✅ Disposer y remover controller cuando se unchecks
                              _cantidadRechazadaControllers[detalle.id]?.dispose();
                              _cantidadRechazadaControllers.remove(detalle.id);
                            }
                            debugPrint(
                              '📦 Productos rechazados: ${_productosRechazados.length}',
                            );
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ),
                    // Nombre del producto
                    DataCell(
                      Text(
                        detalle.producto?.nombre ?? detalle.nombreProducto ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: isRechazado ? FontWeight.w600 : FontWeight.normal,
                          color: isRechazado ? Colors.orange[700] : null,
                        ),
                      ),
                    ),
                    // Cantidad original
                    DataCell(
                      Text(
                        '${detalle.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.orange[700] : null,
                        ),
                      ),
                    ),
                    // ✅ NUEVO: Input editable para cantidad rechazada
                    DataCell(
                      isRechazado
                          ? SizedBox(
                              width: 70,
                              child: Builder(
                                builder: (context) {
                                  // ✅ CRITICAL FIX: Get or create controller for this product
                                  // Using the same controller instance prevents focus loss on rebuild
                                  if (!_cantidadRechazadaControllers.containsKey(detalle.id)) {
                                    _cantidadRechazadaControllers[detalle.id] = TextEditingController(
                                      text: '${productoRechazado?.cantidadRechazada ?? 0}',
                                    );
                                  }
                                  final controller = _cantidadRechazadaControllers[detalle.id]!;

                                  return TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                    ],
                                    onChanged: (value) {
                                      final cantidad = double.tryParse(value) ?? 0;
                                      // ✅ Validar que no exceda cantidad original
                                      if (cantidad > detalle.cantidad) {
                                        productoRechazado?.cantidadRechazada = detalle.cantidad.toDouble();
                                        // ✅ Actualizar controller si el usuario excedió
                                        controller.text = detalle.cantidad.toStringAsFixed(1);
                                      } else if (cantidad >= 0) {
                                        productoRechazado?.cantidadRechazada = cantidad;
                                      }
                                      // ✅ OPTIMIZACIÓN: Solo hacer setState para recalcular totales
                                      // NO reconstruir el DataTable completo
                                      setState(() {
                                        debugPrint(
                                          '📝 ${detalle.producto?.nombre}: Rechazadas = ${productoRechazado?.cantidadRechazada}',
                                        );
                                      });
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                    ),
                    // ✅ NUEVO: Cantidad entregada (calculada)
                    DataCell(
                      Text(
                        isRechazado
                            ? '${productoRechazado?.cantidadEntregada.toStringAsFixed(1)}'
                            : '${detalle.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.green[700] : null,
                        ),
                      ),
                    ),
                    // Precio unitario
                    DataCell(
                      Text(
                        'Bs. ${detalle.precioUnitario.toStringAsFixed(2)}',
                      ),
                    ),
                    // ✅ NUEVO: Subtotal de rechazadas (calculado)
                    DataCell(
                      Text(
                        isRechazado
                            ? 'Bs. ${productoRechazado?.subtotalRechazado.toStringAsFixed(2)}'
                            : '-',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.red[700] : null,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ MEJORADO: Resumen de montos basado en cantidades rechazadas editables
        if (_productosRechazados.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                  ? [Colors.grey[800]!, Colors.grey[700]!]
                  : [Colors.green[50]!, Colors.orange[50]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.orange[700]! : Colors.green[300]!,
              ),
            ),
            child: Column(
              children: [
                // ✅ Desglose por producto rechazado
                Text(
                  '📋 Desglose de Rechazos Parciales:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.blue[300]! : Colors.blue[800]!,
                  ),
                ),
                const SizedBox(height: 8),
                ..._productosRechazados.map((prod) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '  • ${prod.nombreProducto}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${prod.cantidadRechazada.toStringAsFixed(1)}/${prod.cantidadOriginal.toStringAsFixed(0)} rechazadas',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.orange[400]! : Colors.orange[700]!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: isDarkMode ? Colors.orange[600]! : Colors.orange[300]!,
                ),
                const SizedBox(height: 8),
                // ✅ Total Entregado (con cantidades editadas)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✓ Total Entregado:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.green[400]! : Colors.green[700]!,
                      ),
                    ),
                    Text(
                      'Bs. ${montoEntregado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.green[400]! : Colors.green[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ✅ Total Rechazado (con cantidades editadas)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✗ Total Rechazado:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.red[400]! : Colors.red[700]!,
                      ),
                    ),
                    Text(
                      'Bs. ${montoRechazado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.red[400]! : Colors.red[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  color: isDarkMode ? Colors.orange[600]! : Colors.orange[300]!,
                ),
                const SizedBox(height: 8),
                // Total Original
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Original:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                      ),
                    ),
                    Text(
                      'Bs. ${totalOriginal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// ✅ MEJORADA 2026-02-15: Resumen de montos de la venta con estados visuales mejorados
  Widget _buildResumenMontos(double totalVenta) {
    // Calcular totales
    double totalRecibido = _pagos.fold(0.0, (sum, pago) => sum + pago.monto);
    double montoCredito = _esCredito ? (totalVenta - totalRecibido).clamp(0.0, double.infinity) : 0;
    double totalComprometido = totalRecibido + montoCredito;
    double faltaPorRecibir = _esCredito ? 0 : (totalVenta - totalRecibido).clamp(0.0, double.infinity);
    double porcentajePagado = totalVenta > 0 ? (totalRecibido / totalVenta * 100) : 0;

    // Determinar estado
    bool estaPerfecto = (totalRecibido + montoCredito) >= totalVenta && totalRecibido > 0;
    bool esParcial = totalRecibido > 0 && totalRecibido < totalVenta;
    bool esCredito = totalRecibido == 0 && _esCredito;
    bool faltaRegistrar = totalRecibido == 0 && !_esCredito;

    // Colores según estado
    Color statusColor = faltaRegistrar
      ? Colors.grey[600]!
      : estaPerfecto
        ? Colors.green
        : esParcial
          ? Colors.orange
          : Colors.blue;

    String statusLabel = faltaRegistrar
      ? '⏳ Pendiente de Registrar'
      : estaPerfecto
        ? '✅ PAGO COMPLETADO'
        : esParcial
          ? '⚠️ Pago Parcial'
          : esCredito
            ? '💳 Crédito Total'
            : 'Registrando...';

    // Icono según estado
    IconData statusIcon = faltaRegistrar
      ? Icons.hourglass_empty
      : estaPerfecto
        ? Icons.check_circle
        : esParcial
          ? Icons.warning_amber
          : esCredito
            ? Icons.credit_card
            : Icons.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Gradiente para pagos completados, color sólido para otros
        gradient: estaPerfecto
            ? LinearGradient(
                colors: [Colors.green[50]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: estaPerfecto ? null : statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(estaPerfecto ? 0.5 : 0.3),
          width: estaPerfecto ? 2.5 : 2,
        ),
        boxShadow: estaPerfecto
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con estado mejorado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '💰 Resumen de Pagos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: estaPerfecto
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total de la venta (prominente) - mejorado si está pagado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estaPerfecto
                  ? Colors.green[50]
                  : Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: estaPerfecto
                  ? Border.all(color: Colors.green[200]!, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de la Venta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${totalVenta.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: estaPerfecto ? Colors.green[700] : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                if (estaPerfecto)
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Desglose mejorado
          Column(
            children: [
              // Total recibido con indicador visual
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: totalRecibido > 0 ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: totalRecibido > 0 ? Colors.green[200]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 18, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Dinero Recibido:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Bs. ${totalRecibido.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: totalRecibido > 0 ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                        if (totalRecibido > 0) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Crédito registrado (si existe)
              if (montoCredito > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card, size: 18, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Crédito Otorgado:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bs. ${montoCredito.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Falta por recibir (si existe) - más prominente
              if (faltaPorRecibir > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, size: 18, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Falta por Recibir:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bs. ${faltaPorRecibir.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Barra de progreso mejorada con animación visual
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etiqueta de porcentaje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Pago',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${porcentajePagado.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Barra de progreso con sombra
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalVenta > 0 ? (totalRecibido / totalVenta).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      estaPerfecto ? Colors.green : esParcial ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Estado final claro
          const SizedBox(height: 12),
          if (estaPerfecto)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pago completado y verificado ✓',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (esParcial)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registra el saldo pendiente para completar el pago',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ NUEVA 2026-02-15: Diálogo para corregir/editar pagos
  /// Permite editar los pagos registrados antes de confirmar la entrega
  void _mostrarDialogoCorregirPagos(BuildContext context, bool isDarkMode) {
    List<PagoEntrega> pagosCopia = _pagos.map((p) => PagoEntrega(
      tipoPagoId: p.tipoPagoId,
      monto: p.monto,
      referencia: p.referencia,
    )).toList();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('✏️ Corregir Pagos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Resumen de totales
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Venta:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Bs. ${widget.venta.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Recibido:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Bs. ${pagosCopia.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pendiente:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Bs. ${(widget.venta.total - pagosCopia.fold(0.0, (sum, p) => sum + p.monto)).clamp(0, double.infinity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista editable de pagos
              if (pagosCopia.isNotEmpty)
                Column(
                  children: pagosCopia.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pago = entry.value;
                    final tipoNombre = _tiposPago
                        .firstWhere(
                          (t) => t['id'] == pago.tipoPagoId,
                          orElse: () => {'nombre': 'Desconocido'},
                        )['nombre'] ??
                        'Desconocido';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipoNombre,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 32,
                                  child: Builder(
                                    builder: (ctx) {
                                      // ✅ FIX 2026-02-15: Usar persistent controller para evitar focus loss
                                      final controllerKey = 'pago_$idx';
                                      if (!_pagoMontoControllers.containsKey(controllerKey)) {
                                        _pagoMontoControllers[controllerKey] = TextEditingController(
                                          text: pago.monto.toStringAsFixed(2),
                                        );
                                      }
                                      return TextField(
                                        controller: _pagoMontoControllers[controllerKey],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        onChanged: (value) {
                                          setState(() {
                                            pagosCopia[idx].monto = double.tryParse(value) ?? 0.0;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: '0.00',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                pagosCopia.removeAt(idx);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay pagos registrados',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pagos = pagosCopia;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Pagos actualizados exitosamente'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
  }

  /// Convertir bytes a base64
  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }
}
