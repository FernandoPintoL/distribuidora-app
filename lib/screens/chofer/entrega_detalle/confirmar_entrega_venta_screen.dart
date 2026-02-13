import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert' show base64Encode;
import 'package:flutter/services.dart';
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

class ConfirmarEntregaVentaScreen extends StatefulWidget {
  final Entrega entrega;
  final Venta venta;
  final EntregaProvider provider;

  const ConfirmarEntregaVentaScreen({
    Key? key,
    required this.entrega,
    required this.venta,
    required this.provider,
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
  String? _tipoEntrega; // COMPLETA o NOVEDAD
  String? _tipoNovedad; // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADO
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

    // ✅ NUEVO 2026-02-13: Si la venta es a crédito, pre-marcar el checkbox
    if (widget.venta.estadoPago == 'CREDITO') {
      _esCredito = true;
      debugPrint('💳 [VENTA CRÉDITO] Venta #${widget.venta.numero} es a crédito - pre-marcando checkbox');
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _montoController.dispose();
    _referenciaController.dispose();
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

  /// ✅ NUEVA 2026-02-12: Formulario para agregar pago
  Widget _buildPagoForm() {
    int? tipoPagoSeleccionado;

    return StatefulBuilder(
      builder: (context, setFormState) {
        return Container(
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
              else if (_tiposPago.isNotEmpty)
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
                  items: _tiposPago.map((tipo) {
                    return DropdownMenuItem<int>(
                      value: tipo['id'] as int,
                      child: Text(tipo['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setFormState(() => tipoPagoSeleccionado = value);
                  },
                ),

              const SizedBox(height: 12),

              // Campo de monto
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

              // Botón para agregar
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

      // Permitir entrega sin dinero si es crédito total
      if (totalDineroRecibido == 0 && !_esCredito) {
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
              ? 'Confirmar Entrega'
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
        ),
        body: SafeArea(
          child: _paso == 1
              ? _buildPasoSeleccionar()
              : _tipoEntrega == 'COMPLETA'
                  ? _buildPasoConfirmacionCompleta()
                  : _buildPasoNovedad(),
        ),
      ),
    );
  }

  // PASO 1: Seleccionar tipo de entrega
  Widget _buildPasoSeleccionar() {
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
                        'Venta a Entregar',
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      Expanded(
                        child: Column(
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
  Widget _buildPasoConfirmacionCompleta() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
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
                              style: TextStyle(color: Colors.grey[600]),
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
                              style: TextStyle(color: Colors.grey[600]),
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
                              style: TextStyle(color: Colors.grey[600]),
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
                      color: Colors.grey[600],
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
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
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
                                                color: Colors.blue[700],
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
                    _buildPagoForm(),

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
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _paso = 1);
                  },
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _confirmarEntrega,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PASO 2: Registro de Novedad
  Widget _buildPasoNovedad() {
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
                            ? Colors.orange.withOpacity(0.15)
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
                                    ? Colors.orange
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
                                  activeColor: Colors.orange,
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
                  _buildResumenMontos(widget.venta.total),

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

                  // ✅ NUEVA 2026-02-12: Sección de Pagos Múltiples (también en Novedad)
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
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
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
                                                color: Colors.blue[700],
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
                    _buildPagoForm(),

                  const SizedBox(height: 24),

                  // ✅ NUEVA: Sección de crédito (checkbox)
                  _buildSeccionCredito(),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _paso = 1);
                  },
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: _tipoNovedad == null ||
                          (_tipoNovedad == 'CLIENTE_CERRADO' && _fotosCapturadas.isEmpty)  // ✅ NUEVO: Requiere foto para Cliente Cerrado
                      ? null
                      : _confirmarEntrega,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ NUEVA 2026-02-12: Resumen de montos de la venta
  Widget _buildResumenMontos(double totalVenta) {
    // Calcular totales
    double totalRecibido = _pagos.fold(0.0, (sum, pago) => sum + pago.monto);
    double montoCredito = _esCredito ? (totalVenta - totalRecibido).clamp(0.0, double.infinity) : 0;
    double totalComprometido = totalRecibido + montoCredito;
    double faltaPorRecibir = _esCredito ? 0 : (totalVenta - totalRecibido).clamp(0.0, double.infinity);

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
        ? '✅ Pago Completo'
        : esParcial
          ? '⚠️ Pago Parcial'
          : esCredito
            ? '💳 Crédito Total'
            : 'Registrando...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con estado
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total de la venta (prominente)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
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
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Desglose
          Column(
            children: [
              // Total recibido
              Row(
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
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Bs. ${totalRecibido.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: totalRecibido > 0 ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Crédito registrado (si existe)
              if (montoCredito > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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

              // Falta por recibir (si existe)
              if (faltaPorRecibir > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 0),
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
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Bs. ${faltaPorRecibir.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Barra de progreso
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalVenta > 0 ? (totalRecibido / totalVenta).clamp(0.0, 1.0) : 0,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                estaPerfecto ? Colors.green : esParcial ? Colors.orange : Colors.blue,
              ),
            ),
          ),

          // Indicador porcentaje
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${(totalVenta > 0 ? (totalRecibido / totalVenta * 100) : 0).toStringAsFixed(1)}% del total comprometido',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
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
