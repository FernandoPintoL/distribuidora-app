import 'dart:convert' show base64Encode;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../constants/estados_venta.dart';
import '../../models/venta.dart';
import '../../services/image_compression_service.dart';
import 'confirmacion/confirmacion_pago_card.dart';
import 'confirmacion/fotos_card.dart';
import 'confirmacion/section_title.dart';
import 'confirmacion/resumen_venta_card.dart';

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

  // Venta específica a confirmar
  Venta? _ventaActual;

  // Estado de venta seleccionado
  String? _estadoVentaSeleccionado; // ENTREGADA o CANCELADA

  // ✅ FASE 1: Confirmación de Pago
  String? _estadoPago; // PAGADO, PARCIAL, NO_PAGADO
  final TextEditingController _montoRecibidoController =
      TextEditingController();
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

  // ✅ Validar formulario según el estado
  bool _validarFormulario() {
    if (_estadoVentaSeleccionado == null) {
      return false;
    }

    if (_estadoVentaSeleccionado == EstadosVenta.CANCELADA) {
      return _fotosCapturadas.isNotEmpty;
    } else if (_estadoVentaSeleccionado == EstadosVenta.ENTREGADA) {
      return _estadoPago != null &&
          (_estadoPago != 'PAGADO' || _montoRecibidoController.text.isNotEmpty);
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _cargarTiposPago();
    _cargarEntrega();
  }

  // Cargar información de la entrega y venta específica
  Future<void> _cargarEntrega() async {
    try {
      final provider = context.read<EntregaProvider>();
      // Solo cargar si no está ya cargada o si es diferente
      if (provider.entregaActual == null ||
          provider.entregaActual!.id != widget.entregaId) {
        await provider.obtenerEntrega(widget.entregaId);
      }

      // Si se especificó un ventaId, buscar esa venta en particular
      if (widget.ventaId != null && provider.entregaActual != null) {
        final venta = provider.entregaActual!.ventas.firstWhere(
          (v) => v.id == widget.ventaId,
          orElse: () => Venta(
            id: 0,
            numero: 'N/A',
            total: 0,
            subtotal: 0,
            descuento: 0,
            impuesto: 0,
            estadoLogistico: 'N/A',
            estadoPago: 'N/A',
            fecha: DateTime.now(),
          ),
        );

        if (mounted) {
          // ✅ Cargar datos en dos pasos para evitar loops
          setState(() {
            _ventaActual = venta.id != 0 ? venta : null;
          });

          // Actualizar controller DESPUÉS del setState
          if (_ventaActual != null && _montoRecibidoController.text.isEmpty) {
            _montoRecibidoController.text = _ventaActual!.subtotal
                .toStringAsFixed(2);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando entrega: $e');
    }
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
        final tiposPago = List<Map<String, dynamic>>.from(response.data ?? []);

        setState(() {
          _tiposPago = tiposPago;
          _cargandoTiposPago = false;

          // ✅ Seleccionar EFECTIVO por defecto
          final efectivo = tiposPago.firstWhere(
            (tipo) =>
                tipo['codigo']?.toString().toUpperCase() == 'EFECTIVO' ||
                tipo['nombre']?.toString().toUpperCase().contains('EFECTIVO') ==
                    true,
            orElse: () => <String, dynamic>{},
          );

          if (efectivo.isNotEmpty && efectivo['id'] != null) {
            _tipoPagoId = efectivo['id'] as int;
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _cargandoTiposPago = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudieron cargar los tipos de pago'),
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

  /// Comprime y valida una imagen antes de agregarla
  Future<File?> _procesarImagenAntesDeSumar(File foto) async {
    try {
      final imagenComprimida =
          await ImageCompressionService.comprimirYValidarImagen(foto);
      return imagenComprimida;
    } on ImageTooLargeException catch (e) {
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ImageCompressionService.obtenerMensajeError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    } catch (e) {
      // Error genérico
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ImageCompressionService.obtenerMensajeError(e),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    }
  }

  void _onFotosChanged(List<File> fotos) async {
    // Procesar cada foto (comprimir y validar)
    final fotosComprimidas = <File>[];

    for (final foto in fotos) {
      final fotoComprimida = await _procesarImagenAntesDeSumar(foto);
      if (fotoComprimida != null) {
        fotosComprimidas.add(fotoComprimida);
      }
      // Si fotoComprimida es null, significa que fue rechazada por tamaño
      // No se agrega a la lista
    }

    setState(() {
      _fotosCapturadas.clear();
      _fotosCapturadas.addAll(fotosComprimidas);
    });
  }

  void _onFotoComprobanteChanged(List<File> fotos) async {
    if (fotos.isEmpty) {
      setState(() {
        _fotoComprobante = null;
      });
      return;
    }

    // Procesar la foto (comprimir y validar)
    final fotoComprimida = await _procesarImagenAntesDeSumar(fotos.first);

    setState(() {
      _fotoComprobante = fotoComprimida;
    });
  }

  Future<void> _confirmarEntrega() async {
    // Mostrar pantalla de cargando
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando afuera
      builder: (BuildContext dialogContext) {
        final isDarkMode =
            Theme.of(dialogContext).brightness == Brightness.dark;
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? colorScheme.surface.withValues(alpha: 0.95)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                  Text(
                    widget.ventaId != null
                        ? 'Confirmando venta...'
                        : 'Confirmando entrega...',
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? colorScheme.onSurface
                              : colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    'Por favor espera',
                    style: Theme.of(dialogContext).textTheme.bodySmall
                        ?.copyWith(
                          color: isDarkMode
                              ? colorScheme.onSurfaceVariant
                              : Colors.grey[600],
                        ),
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
      // ✅ Estado de venta (ENTREGADA o CANCELADA)
      estadoVenta: _estadoVentaSeleccionado,
      // ✅ FASE 1: Parámetros de confirmación de pago (solo para ENTREGADA)
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
      // ✅ Mostrar loading si se está cargando la venta
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading &&
              _ventaActual == null &&
              widget.ventaId != null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ✅ SELECTOR DE ESTADO: ENTREGADA o CANCELADA
        SectionTitle(title: '📦 Estado de la Venta'),
        const SizedBox(height: 12),
        Card(
          color: isDarkMode
              ? colorScheme.surfaceContainerHigh
              : colorScheme.primaryContainer.withValues(alpha: 0.06),
          elevation: isDarkMode ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 12,
              children: [
                Text(
                  'Selecciona el estado de la venta *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildEstadoButton(
                        label: '✅ Entregada',
                        value: EstadosVenta.ENTREGADA,
                        isSelected:
                            _estadoVentaSeleccionado == EstadosVenta.ENTREGADA,
                        color: Colors.green,
                        onTap: () {
                          setState(() {
                            _estadoVentaSeleccionado = EstadosVenta.ENTREGADA;
                            // Limpiar datos de cancelación
                            _fotosCapturadas.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEstadoButton(
                        label: '❌ Cancelada',
                        value: EstadosVenta.CANCELADA,
                        isSelected:
                            _estadoVentaSeleccionado == EstadosVenta.CANCELADA,
                        color: Colors.red,
                        onTap: () {
                          setState(() {
                            _estadoVentaSeleccionado = EstadosVenta.CANCELADA;
                            // Limpiar datos de pago
                            _estadoPago = null;
                            _montoRecibidoController.clear();
                            _tipoPagoId = null;
                            _motivoNoPagoController.clear();
                            _fotoComprobante = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Mostrar resumen de la venta
        if (_ventaActual != null)
          Column(
            spacing: 24,
            children: [ResumenVentaCard(venta: _ventaActual!)],
          ),

        // ✅ SI CANCELADA: Mostrar card de fotos de evidencia
        if (_estadoVentaSeleccionado == EstadosVenta.CANCELADA) ...[
          SectionTitle(title: '📸 Fotos de Evidencia'),
          const SizedBox(height: 12),
          FotosCard(
            title: '📸 Fotografía de Cancelación',
            description:
                'Captura fotos que demuestren por qué se canceló la venta',
            maxPhotos: 3,
            fotos: _fotosCapturadas,
            onFotosChanged: _onFotosChanged,
            accentColor: Colors.red,
          ),
          const SizedBox(height: 24),
        ],

        // ✅ SI ENTREGADA: Mostrar resumen de venta + opciones de pago
        if (_estadoVentaSeleccionado == EstadosVenta.ENTREGADA) ...[
          SectionTitle(title: '💰 Confirmación de Pago'),
          const SizedBox(height: 12),
          ConfirmacionPagoCard(
            estadoPago: _estadoPago,
            montoRecibidoController: _montoRecibidoController,
            tipoPagoId: _tipoPagoId,
            motivoNoPagoController: _motivoNoPagoController,
            tiposPago: _tiposPago,
            cargandoTiposPago: _cargandoTiposPago,
            onEstadoPagoChanged: (value) {
              setState(() {
                _estadoPago = value;
                if (value == 'PAGADO') {
                  _motivoNoPagoController.clear();
                }
              });
            },
            onTipoPagoChanged: (value) {
              setState(() {
                _tipoPagoId = value;
              });
            },
          ),
          const SizedBox(height: 24),
          SectionTitle(title: '📸 Foto de Comprobante de Pago'),
          const SizedBox(height: 12),
          FotosCard(
            title: '📸 Comprobante',
            description: 'Captura foto del dinero, transferencia o cheque',
            maxPhotos: 1,
            fotos: _fotoComprobante != null ? [_fotoComprobante!] : [],
            onFotosChanged: _onFotoComprobanteChanged,
            accentColor: Colors.green,
          ),
          const SizedBox(height: 24),
          SectionTitle(title: '📷 Fotografía de Entrega'),
          const SizedBox(height: 12),
          FotosCard(
            title: '📷 Fotografía de Entrega',
            maxPhotos: 3,
            fotos: _fotosCapturadas,
            onFotosChanged: _onFotosChanged,
          ),
          const SizedBox(height: 24),
        ],

        // ✅ SIEMPRE VISIBLE: Sección de Observaciones
        SectionTitle(title: '📝 Observaciones (Opcional)'),
        const SizedBox(height: 12),
        TextField(
          controller: _observacionesController,
          maxLines: 4,
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
            color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 32),

        // Botones
        Consumer<EntregaProvider>(
          builder: (context, provider, _) {
            final puedeConfirmar = !provider.isLoading && _validarFormulario();

            return Column(
              spacing: 8,
              children: [
                // ✅ Mensaje de validación si falta algo
                if (!_validarFormulario())
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _estadoVentaSeleccionado == null
                                ? 'Falta: Seleccionar estado'
                                : _estadoVentaSeleccionado ==
                                      EstadosVenta.CANCELADA
                                ? 'Falta: Fotos de evidencia'
                                : 'Falta: Estado de pago y monto (si es pagado)',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: AppTextStyles.bodySmall(context).fontSize!,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: puedeConfirmar ? _confirmarEntrega : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      provider.isLoading
                          ? 'Confirmando...'
                          : 'Confirmar ${_estadoVentaSeleccionado == EstadosVenta.CANCELADA ? 'Cancelación' : 'Entrega'}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _estadoVentaSeleccionado == EstadosVenta.CANCELADA
                          ? Colors.red
                          : colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: isDarkMode
                          ? colorScheme.surface.withValues(alpha: 0.3)
                          : colorScheme.surfaceContainerHighest,
                      disabledForegroundColor: isDarkMode
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
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
    );
  }

  // ✅ Widget helper para los botones de estado
  Widget _buildEstadoButton({
    required String label,
    required String value,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDarkMode
                    ? colorScheme.surface.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
