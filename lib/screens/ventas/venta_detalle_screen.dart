import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_urls.dart'; // ✅ NUEVO: Para BASE_URL_IMG
import '../../providers/providers.dart';
import '../../services/print_service.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/map_location_selector.dart';
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../models/entrega_venta_confirmacion.dart';
import '../chofer/entrega_detalle/confirmar_entrega_venta_screen.dart';
import '../shared/widgets/index.dart'; // NUEVO: ProductoCardWidget
import 'venta_detalle/contact_button_widget.dart';
import 'venta_detalle/cliente_avatar_widget.dart';
import 'venta_detalle/venta_cliente_header_widget.dart';
import 'venta_detalle/producto_avatar_widget.dart';
import 'venta_detalle/widgets/entrega_info_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class VentaDetalleScreen extends StatefulWidget {
  final int ventaId;

  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  State<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ventasProvider = context.read<VentasProvider>();
      ventasProvider.loadVentaDetalle(widget.ventaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Venta #${widget.ventaId}'), elevation: 0),
      body: Consumer<VentasProvider>(
        builder: (context, ventasProvider, _) {
          // Loading state
          if (ventasProvider.isLoadingDetalle) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (ventasProvider.errorMessage != null &&
              ventasProvider.ventaDetalle == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ventasProvider.errorMessage ?? 'Error desconocido',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ventasProvider.loadVentaDetalle(widget.ventaId);
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final venta = ventasProvider.ventaDetalle;
          if (venta == null) {
            return const Center(child: Text('Sin datos de venta'));
          }

          // Success state - show venta details
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header: Estados, Cliente, Ubicación y Botones
                VentaClienteHeaderWidget(
                  venta: venta,
                  parentContext: context,
                  onDescargarPDF: (ventaId) => _descargarPDFVenta(ventaId),
                  onAbrirMapa: (venta) => _abrirMapa(venta),
                ),
                const SizedBox(height: 8),
                // ✅ Información de Entrega (chofer, vehículo, estado)
                if (venta.entrega != null)
                  EntregaInfoWidget(entrega: venta.entrega!)
                else
                  const SizedBox(height: 8),
                const SizedBox(height: 16),
                // Sección de productos
                Text('Productos'),
                const SizedBox(height: 12),
                if (venta.detalles.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Sin productos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ...venta.detalles.map((detalle) {
                    return ProductoCardWidget(
                      imagenUrl: detalle.producto?.imagenPrincipal?.url,
                      nombreProducto: detalle.producto?.nombre,
                      cantidad: detalle.cantidad,
                      precioUnitario: detalle.precioUnitario,
                      subtotal: detalle.subtotal,
                      mostrarAvatarWidget: true,
                      comboItemsSeleccionados: detalle.comboItemsSeleccionados,
                      comboItems: detalle.producto?.comboItems,
                      parentContext: context,
                    );
                  }),
                const SizedBox(height: 24),
                // Sección de entregas
                if (venta.confirmaciones.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      // ✅ NUEVO 2026-06-13: Header con título y botón "Registrar otra"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Entregas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _navegarARegistrarOtraConfirmacion(
                                    context,
                                    venta,
                                  ),
                              icon: const Icon(Icons.note_add, size: 16),
                              label: const Text('Registrar otra'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...venta.confirmaciones.map((confirmacion) {
                        final tipoEntregaColor = _getTipoEntregaColor(
                          confirmacion.tipoEntrega,
                        );

                        final tipoConfirmacion = _getTipoEntregaColor(
                          confirmacion.tipoConfirmacion,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: tipoEntregaColor, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con tipo de entrega y estado
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        confirmacion.tipoEntregaFormato,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: tipoEntregaColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        confirmacion.tipoConfirmacion,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: tipoConfirmacion,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEstadoPagoColor(
                                            confirmacion.estadoPago,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          confirmacion.estadoPagoFormato,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Información de pago (no mostrar si es RECHAZADO o CLIENTE_CERRADO)
                                if (confirmacion.tipoConfirmacion !=
                                        'RECHAZADO' &&
                                    confirmacion.tipoConfirmacion !=
                                        'CLIENTE_CERRADO') ...[
                                  const Divider(height: 16),
                                  _buildPaymentInfoRow(
                                    'Monto Recibido',
                                    'Bs. ${confirmacion.montoRecibido.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPaymentInfoRow(
                                    'Monto Aceptado',
                                    'Bs. ${confirmacion.montoAceptado.toStringAsFixed(2)}',
                                  ),
                                  if (confirmacion.montoPendiente > 0) ...[
                                    const SizedBox(height: 8),
                                    _buildPaymentInfoRow(
                                      'Monto Pendiente',
                                      'Bs. ${confirmacion.montoPendiente.toStringAsFixed(2)}',
                                      color: Colors.orange,
                                    ),
                                  ],
                                ],
                                // Desglose de pagos si existe
                                if (confirmacion.tipoConfirmacion ==
                                        'COMPLETA' ||
                                    confirmacion.tipoConfirmacion ==
                                            'DEVOLUCION_PARCIAL' &&
                                        confirmacion
                                            .desglosePageos
                                            .isNotEmpty) ...[
                                  const Divider(height: 16),
                                  const Text(
                                    'Desglose de Pagos:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...confirmacion.desglosePageos.map((pago) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(pago.tipoPagoNombre),
                                          Text(
                                            'Bs. ${pago.monto.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                // Fecha y observaciones
                                const Divider(height: 16),
                                Text(
                                  'Confirmado: ${confirmacion.fechaConfirmacionFormato}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (confirmacion.observacionesLogistica !=
                                        null &&
                                    confirmacion
                                        .observacionesLogistica!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Observaciones: ${confirmacion.observacionesLogistica}',
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // ✅ NUEVO: Galería de fotos
                                if (confirmacion.fotos != null &&
                                    confirmacion.fotos!.isNotEmpty) ...[
                                  const Text(
                                    'Fotos de Entrega:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: confirmacion.fotos!.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              confirmacion.fotos![index],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // ✅ NUEVO 2026-06-13: Botón Editar esta confirmación
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _navegarAEditarConfirmacion(
                                          context,
                                          venta,
                                          confirmacion,
                                        ),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text(
                                      'Editar esta confirmación',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Abrir ubicación de entrega en mapa interactivo o Google Maps
  // ✅ ACTUALIZADO: Recibe venta completa para mostrar info del cliente y color del estado
  Future<void> _abrirMapa(Venta venta) async {
    // Primero intentar abrir el mapa interactivo
    try {
      if (mounted) {
        // ✅ NUEVO: Construir URL completa de foto usando BASE_URL_IMG
        final fotoPerfil = venta.cliente?.fotoPerfil != null
            ? '${AppUrls.baseUrlImg}${venta.cliente!.fotoPerfil}'
            : null;

        // ✅ NUEVO: Crear MapLocation con información completa del cliente
        final ubicacionVenta = MapLocation(
          latitude: venta.direccionCliente!.latitud!,
          longitude: venta.direccionCliente!.longitud!,
          title: venta.cliente?.nombre ?? 'Sin nombre',
          subtitle: venta.id.toString(),
          isSelected: false,
          razonSocial: venta.cliente?.razonSocial,
          telefono: venta.cliente?.telefono,
          ventaId: venta.id,
          markerColor:
              venta.estadoLogisticoColor, // ✅ Color del estado logístico
          fotoPerfil: fotoPerfil, // ✅ Foto con URL completa
        );

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Scaffold(
              body: MapLocationSelector(
                initialLatitude: venta.direccionCliente!.latitud!,
                initialLongitude: venta.direccionCliente!.longitud!,
                additionalLocations: [
                  ubicacionVenta,
                ], // ✅ Pasar ubicación con info del cliente
                onLocationSelected: (lat, lng, address) {
                  // En modo lectura, solo cerramos el diálogo
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 ${address ?? "Ubicación: $lat, $lng"}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          },
        );
      }
    } catch (e) {
      // Si hay error con el mapa interactivo, fallback a Google Maps externo
      debugPrint('⚠️ Error abriendo mapa interactivo: $e');
      _abrirGoogleMaps(
        venta.direccionCliente!.latitud!,
        venta.direccionCliente!.longitud!,
      );
    }
  }

  /// Fallback: Abrir Google Maps en aplicación externa
  Future<void> _abrirGoogleMaps(double latitud, double longitud) async {
    try {
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        final mapsUrl = Uri.parse(
          'geo:$latitud,$longitud?q=$latitud,$longitud',
        );
        if (await canLaunchUrl(mapsUrl)) {
          await launchUrl(mapsUrl);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ No se pudo abrir Google Maps')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  /// Descargar PDF de la venta
  Future<void> _descargarPDFVenta(int ventaId) async {
    try {
      final printService = PrintService();
      final success = await printService.downloadDocument(
        documentoId: ventaId,
        documentType: PrintDocumentType.venta,
        format: PrintFormat.ticket58,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo descargar el PDF'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nota de venta descargada'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getEstadoPagoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return Colors.green;
      case 'PARCIAL':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getTipoEntregaColor(String? tipoEntrega) {
    switch (tipoEntrega?.toUpperCase()) {
      case 'COMPLETA':
        return Colors.green;
      case 'CLIENTE_CERRADO':
        return Colors.deepOrangeAccent;
      case 'RECHAZADO':
        return Colors.red;
      case 'CON_NOVEDAD':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildPaymentInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// ✅ REFACTORIZADO 2026-06-14: Registrar NUEVA confirmación
  /// Si confirmacion != null, usa sus datos como referencia
  /// Si confirmacion == null, crea una nueva desde cero
  void _navegarARegistrarOtraConfirmacion(
    BuildContext context,
    Venta venta, [
    EntregaVentaConfirmacion? confirmacion,
  ]) {
    final entregaMinima = Entrega(
      id: confirmacion?.entregaId ?? venta.entregaId ?? 0,
      estado: 'ENTREGADA',
      historialEstados: [],
      ventas: [venta],
      productosGenerico: [],
    );

    final entregaProvider = context.read<EntregaProvider>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmarEntregaVentaScreen(
          entrega: entregaMinima,
          venta: venta,
          provider: entregaProvider,
          confirmacionExistente: confirmacion,
        ),
      ),
    );
  }

  /// ✅ REFACTORIZADO 2026-06-14: EDITAR confirmación existente pasando objeto completo
  void _navegarAEditarConfirmacion(
    BuildContext context,
    Venta venta,
    EntregaVentaConfirmacion confirmacion,
  ) {
    final entregaMinima = Entrega(
      id: confirmacion.entregaId,
      estado: 'ENTREGADA',
      historialEstados: [],
      ventas: [venta],
      productosGenerico: [],
    );

    final entregaProvider = context.read<EntregaProvider>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmarEntregaVentaScreen(
          entrega: entregaMinima,
          venta: venta,
          provider: entregaProvider,
          confirmacionExistente: confirmacion, // ✅ Pasar objeto completo
        ),
      ),
    );
  }
}
