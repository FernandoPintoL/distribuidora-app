import 'dart:convert' show base64Encode;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/quick_camera_capture.dart';
import '../../config/config.dart';

class ConfirmacionEntregaScreen extends StatefulWidget {
  final int entregaId;
  final int? ventaId; // Opcional: si viene, confirma una venta específica

  const ConfirmacionEntregaScreen({
    Key? key,
    required this.entregaId,
    this.ventaId,
  }) : super(key: key);

  @override
  State<ConfirmacionEntregaScreen> createState() =>
      _ConfirmacionEntregaScreenState();
}

class _ConfirmacionEntregaScreenState extends State<ConfirmacionEntregaScreen> {
  final _observacionesController = TextEditingController();
  final List<File> _fotosCapturadas = [];

  // ✅ Nuevos campos para contexto de entrega
  bool? _tiendaAbierta;
  bool? _clientePresente;
  String? _motivoRechazo;

  // ✅ Opciones de motivos de rechazo
  static const List<String> _motivosRechazo = [
    'TIENDA_CERRADA',
    'CLIENTE_AUSENTE',
    'CLIENTE_RECHAZA',
    'DIRECCION_INCORRECTA',
    'CLIENTE_NO_IDENTIFICADO',
    'OTRO',
  ];

  static const Map<String, String> _motivosRechazoLabels = {
    'TIENDA_CERRADA': '🏪 Tienda Cerrada',
    'CLIENTE_AUSENTE': '👤 Cliente Ausente',
    'CLIENTE_RECHAZA': '🚫 Cliente Rechaza',
    'DIRECCION_INCORRECTA': '📍 Dirección Incorrecta',
    'CLIENTE_NO_IDENTIFICADO': '🆔 Cliente No Identificado',
    'OTRO': '❓ Otro Motivo',
  };

  // ✅ FASE 1: Confirmación de Pago
  String? _estadoPago; // PAGADO, PARCIAL, NO_PAGADO
  final TextEditingController _montoRecibidoController = TextEditingController();
  int? _tipoPagoId;
  final TextEditingController _motivoNoPagoController = TextEditingController();

  // ✅ FASE 2: Foto de comprobante
  File? _fotoComprobante;

  // ✅ Tipos de pago (cargados dinámicamente desde API)
  List<Map<String, dynamic>> _tiposPago = [];
  bool _cargandoTiposPago = true;

  static const List<String> _estadosPago = ['PAGADO', 'PARCIAL', 'NO_PAGADO'];
  static const Map<String, String> _estadosPagoLabels = {
    'PAGADO': '✅ Pagado Completo',
    'PARCIAL': '⚠️ Pago Parcial',
    'NO_PAGADO': '❌ No Pagado',
  };

  @override
  void initState() {
    super.initState();
    _cargarTiposPago();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _montoRecibidoController.dispose();
    _motivoNoPagoController.dispose();
    super.dispose();
  }

  // ✅ Cargar tipos de pago desde la API
  Future<void> _cargarTiposPago() async {
    try {
      final provider = context.read<EntregaProvider>();
      final response = await provider.obtenerTiposPago();

      if (mounted && response.success && response.data != null) {
        setState(() {
          _tiposPago = List<Map<String, dynamic>>.from(response.data ?? []);
          _cargandoTiposPago = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _cargandoTiposPago = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No se pudieron cargar los tipos de pago',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error cargando tipos de pago: $e');
      if (mounted) {
        setState(() {
          _cargandoTiposPago = false;
        });
      }
    }
  }

  String _convertirFotoABase64(File foto) {
    final bytes = foto.readAsBytesSync();
    return base64Encode(bytes);
  }

  void _onFotosChanged(List<File> fotos) {
    setState(() {
      _fotosCapturadas.clear();
      _fotosCapturadas.addAll(fotos);
    });
  }

  void _onFotoComprobanteChanged(List<File> fotos) {
    setState(() {
      _fotoComprobante = fotos.isNotEmpty ? fotos.first : null;
    });
  }

  Future<void> _confirmarEntrega() async {
    // Mostrar pantalla de cargando
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando afuera
      builder: (BuildContext dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  Text(
                    widget.ventaId != null
                        ? 'Confirmando venta...'
                        : 'Confirmando entrega...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Por favor espera',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Convertir todas las fotos capturadas a Base64
    final fotosBase64 = <String>[];
    for (final foto in _fotosCapturadas) {
      fotosBase64.add(_convertirFotoABase64(foto));
    }

    final provider = context.read<EntregaProvider>();

    final exito = await provider.confirmarEntrega(
      widget.entregaId,
      ventaId: widget.ventaId, // Pasar ventaId si existe
      fotosBase64: fotosBase64.isNotEmpty ? fotosBase64 : null,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
      // ✅ Nuevos parámetros de contexto
      tiendaAbierta: _tiendaAbierta,
      clientePresente: _clientePresente,
      motivoRechazo: _motivoRechazo,
      // ✅ FASE 1: Parámetros de confirmación de pago
      estadoPago: _estadoPago,
      montoRecibido: _montoRecibidoController.text.isNotEmpty
          ? double.tryParse(_montoRecibidoController.text)
          : null,
      tipoPagoId: _tipoPagoId,
      motivoNoPago: _motivoNoPagoController.text.isNotEmpty
          ? _motivoNoPagoController.text
          : null,
      // ✅ FASE 2: Foto de comprobante
      fotoComprobanteBase64: _fotoComprobante != null
          ? _convertirFotoABase64(_fotoComprobante!)
          : null,
    );

    debugPrint('Confirmación de entrega resultó en: $exito');

    // Cerrar el dialog de cargando
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ventaId != null
                ? '✅ Venta entregada correctamente'
                : '✅ Entrega confirmada exitosamente',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // Pequeña pausa antes de navegar
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Detectar modo oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: widget.ventaId != null
            ? 'Confirmar Venta #${widget.ventaId}'
            : 'Confirmar Entrega',
        customGradient: AppGradients.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Sección de Contexto de Entrega
          _SectionTitle(title: '📋 Contexto de Entrega'),
          const SizedBox(height: 12),
          Card(
            // ✅ Color adaptativo al modo oscuro
            color: isDarkMode
                ? colorScheme.surface.withValues(alpha: 0.8)
                : colorScheme.primary.withValues(alpha: 0.08),
            elevation: isDarkMode ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 16,
                children: [
                  // Tienda abierta
                  Row(
                    children: [
                      Checkbox(
                        value: _tiendaAbierta ?? false,
                        onChanged: (value) {
                          setState(() {
                            _tiendaAbierta = value;
                            // Si deselecciona, limpiar motivo de rechazo
                            if (_tiendaAbierta == true &&
                                _clientePresente == true) {
                              _motivoRechazo = null;
                            }
                          });
                        },
                        // ✅ Color adaptativo
                        activeColor: colorScheme.primary,
                      ),
                      Expanded(
                        child: Text(
                          '✅ Tienda abierta',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDarkMode
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                  // Cliente presente
                  Row(
                    children: [
                      Checkbox(
                        value: _clientePresente ?? false,
                        onChanged: (value) {
                          setState(() {
                            _clientePresente = value;
                            // Si deselecciona, limpiar motivo de rechazo
                            if (_tiendaAbierta == true &&
                                _clientePresente == true) {
                              _motivoRechazo = null;
                            }
                          });
                        },
                        // ✅ Color adaptativo
                        activeColor: colorScheme.primary,
                      ),
                      Expanded(
                        child: Text(
                          '✅ Cliente presente',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDarkMode
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                  // ✅ Motivo de rechazo (solo si alguno es false)
                  if (_tiendaAbierta == false || _clientePresente == false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          'Motivo de rechazo *',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface,
                              ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _motivoRechazo,
                          items: _motivosRechazo.map((motivo) {
                            return DropdownMenuItem(
                              value: motivo,
                              child: Text(
                                _motivosRechazoLabels[motivo] ?? motivo,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _motivoRechazo = value;
                            });
                          },
                          // ✅ Decoración adaptativa
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? colorScheme.outline.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? colorScheme.outline.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? colorScheme.surface.withValues(alpha: 0.5)
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.1,
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: Text(
                            '-- Seleccionar --',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ✅ FASE 1: Sección de Confirmación de Pago
          _SectionTitle(title: '💰 Confirmación de Pago'),
          const SizedBox(height: 12),
          Card(
            color: isDarkMode
                ? colorScheme.surface.withValues(alpha: 0.8)
                : Color(0xFF2196F3).withValues(alpha: 0.08),
            elevation: isDarkMode ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 16,
                children: [
                  // Estado de Pago - Radio Buttons
                  Text(
                    'Estado de Pago *',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? colorScheme.onSurface
                          : colorScheme.onSurface,
                    ),
                  ),
                  Wrap(
                    spacing: 16,
                    children: _estadosPago.map((estado) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: estado,
                            groupValue: _estadoPago,
                            onChanged: (value) {
                              setState(() {
                                _estadoPago = value;
                                // Limpiar motivo_no_pago si es PAGADO
                                if (value == 'PAGADO') {
                                  _motivoNoPagoController.clear();
                                }
                              });
                            },
                            activeColor: colorScheme.primary,
                          ),
                          Text(
                            _estadosPagoLabels[estado] ?? estado,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              color: isDarkMode
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Monto Recibido
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Monto Recibido (Bs.) ${_estadoPago == 'PAGADO' ? '*' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? colorScheme.onSurface
                              : colorScheme.onSurface,
                        ),
                      ),
                      TextField(
                        controller: _montoRecibidoController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: isDarkMode
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Bs. ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? colorScheme.outline.withValues(alpha: 0.5)
                                  : colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? colorScheme.outline.withValues(alpha: 0.5)
                                  : colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? colorScheme.surface.withValues(alpha: 0.5)
                              : colorScheme.primaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? colorScheme.onSurface
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  // Tipo de Pago (cargado dinámicamente desde API)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Tipo de Pago ${_estadoPago == 'PAGADO' ? '*' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? colorScheme.onSurface
                              : colorScheme.onSurface,
                        ),
                      ),
                      _cargandoTiposPago
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode
                                      ? colorScheme.outline.withValues(alpha: 0.5)
                                      : colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode
                                    ? colorScheme.surface.withValues(alpha: 0.5)
                                    : colorScheme.primaryContainer.withValues(
                                        alpha: 0.1,
                                      ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Cargando tipos de pago...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: isDarkMode
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              initialValue: _tipoPagoId,
                              items: _tiposPago.map((tipo) {
                                return DropdownMenuItem(
                                  value: tipo['id'] as int,
                                  child: Text(tipo['nombre'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _tipoPagoId = value;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDarkMode
                                        ? colorScheme.outline.withValues(alpha: 0.5)
                                        : colorScheme.outline,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDarkMode
                                        ? colorScheme.outline.withValues(alpha: 0.5)
                                        : colorScheme.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDarkMode
                                    ? colorScheme.surface.withValues(alpha: 0.5)
                                    : colorScheme.primaryContainer.withValues(
                                        alpha: 0.1,
                                      ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              hint: Text(
                                '-- Seleccionar --',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: isDarkMode
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ],
                  ),

                  // Motivo No Pago (condicional)
                  if (_estadoPago == 'NO_PAGADO' || _estadoPago == 'PARCIAL')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          'Motivo (${_estadoPago == 'NO_PAGADO' ? 'Obligatorio' : 'Opcional'})',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? colorScheme.onSurface
                                : colorScheme.onSurface,
                          ),
                        ),
                        TextField(
                          controller: _motivoNoPagoController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                '¿Por qué no pagó o por qué pagó parcial?',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: isDarkMode
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? colorScheme.outline.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? colorScheme.outline.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? colorScheme.surface.withValues(alpha: 0.5)
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.1,
                                  ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                            color: isDarkMode
                                ? colorScheme.onSurface
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ✅ FASE 2: Sección de Foto de Comprobante (Opcional)
          _SectionTitle(title: '📸 Foto de Comprobante (Opcional)'),
          const SizedBox(height: 12),
          Card(
            color: isDarkMode
                ? colorScheme.surface.withValues(alpha: 0.8)
                : Color(0xFF4CAF50).withValues(alpha: 0.08),
            elevation: isDarkMode ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 8,
                children: [
                  Text(
                    'Captura foto del dinero o comprobante de pago (Transferencia, Cheque)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  QuickCameraCapture(
                    maxPhotos: 1,
                    onPhotosChanged: _onFotoComprobanteChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Fotos
          _SectionTitle(
            title: '📷 Fotografía de Entrega (${_fotosCapturadas.length}/3)',
          ),
          const SizedBox(height: 12),
          Card(
            // ✅ Card adaptativo al modo oscuro
            color: isDarkMode
                ? colorScheme.surface.withValues(alpha: 0.9)
                : colorScheme.surfaceContainerLowest,
            elevation: isDarkMode ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: QuickCameraCapture(
                maxPhotos: 3,
                onPhotosChanged: _onFotosChanged,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Observaciones
          _SectionTitle(title: '📝 Observaciones (Opcional)'),
          const SizedBox(height: 12),
          TextField(
            controller: _observacionesController,
            maxLines: 4,
            // ✅ Decoración adaptativa al modo oscuro
            decoration: InputDecoration(
              hintText: 'Ingrese cualquier observación adicional',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? colorScheme.outline.withValues(alpha: 0.5)
                      : colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? colorScheme.outline.withValues(alpha: 0.5)
                      : colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? colorScheme.surface.withValues(alpha: 0.5)
                  : colorScheme.primaryContainer.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode
                  ? colorScheme.onSurface
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),

          // Botones
          Consumer<EntregaProvider>(
            builder: (context, provider, _) {
              return Column(
                spacing: 8,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _confirmarEntrega,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        provider.isLoading
                            ? 'Confirmando...'
                            : 'Confirmar Entrega',
                      ),
                      // ✅ Botones adaptativos al modo oscuro
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: isDarkMode
                            ? colorScheme.surface.withValues(alpha: 0.3)
                            : colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: isDarkMode
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : colorScheme.onSurfaceVariant,
                        elevation: isDarkMode ? 2 : 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        // ✅ Bordes adaptativos
                        side: BorderSide(
                          color: isDarkMode
                              ? colorScheme.outline.withValues(alpha: 0.5)
                              : colorScheme.outline,
                          width: 1.5,
                        ),
                        foregroundColor: colorScheme.primary,
                      ),
                      child: Text(
                        'Cancelar',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Adaptativo al modo oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
    );
  }
}
