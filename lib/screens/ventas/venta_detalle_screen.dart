import 'package:distribuidora/extensions/theme_extension.dart';
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

  Color _parseHexColor(String? hexColor) {
    if (hexColor == null) return Colors.transparent;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasProvider>(
      builder: (context, ventasProvider, _) {
        final venta = ventasProvider.ventaDetalle;
        final estadoDocColor = venta?.estadoDocumentoObj?.color != null
            ? _parseHexColor(venta?.estadoDocumentoObj?.color)
            : Theme.of(context).colorScheme.primary;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venta #${widget.ventaId}'),
                if (venta?.estadoDocumentoObj != null)
                  Text(
                    venta!.estadoDocumentoObj!.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            backgroundColor: estadoDocColor.withOpacity(0.85),
            elevation: 0,
          ),
          body: Builder(
            builder: (context) {
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
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
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
                    // Sección de productos
                    Text('Productos'),
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
                          comboItemsSeleccionados:
                              detalle.comboItemsSeleccionados,
                          comboItems: detalle.producto?.comboItems,
                          parentContext: context,
                        );
                      }),
                    const SizedBox(height: 8),
                    // Sección de entregas - Solo visible para roles que no sean cliente
                    if (venta.confirmaciones.isNotEmpty &&
                        _canViewDeliveries(context))
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
                                side: BorderSide(
                                  color: tipoEntregaColor,
                                  width: 2,
                                ),
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
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Desglose de pagos si existe
                                    if (confirmacion.tipoConfirmacion ==
                                            'COMPLETA' ||
                                        confirmacion.tipoConfirmacion ==
                                                'DEVOLUCION_PARCIAL' &&
                                            confirmacion
                                                .desglosePageos
                                                .isNotEmpty) ...[
                                      const Divider(height: 16),
                                      Text(
                                        'Desglose de Pagos:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: context.colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...confirmacion.desglosePageos.map((
                                        pago,
                                      ) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
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
                                    // ✅ NUEVO: Productos Devueltos (Devolución Parcial)
                                    if (confirmacion.tipoConfirmacion ==
                                            'DEVOLUCION_PARCIAL' &&
                                        confirmacion.productosDevueltos !=
                                            null &&
                                        (confirmacion.productosDevueltos
                                                as List)
                                            .isNotEmpty) ...[
                                      const Divider(height: 16),
                                      Text(
                                        'Productos Devueltos:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: context.colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...((confirmacion.productosDevueltos
                                                  as List<dynamic>?)
                                              ?.map((prod) {
                                                final producto =
                                                    prod
                                                        as Map<String, dynamic>;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.red
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          producto['producto_nombre'] ??
                                                              'N/A',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Cantidad: ${producto['cantidad'] ?? 0}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                            Text(
                                                              'Bs. ${(producto['subtotal'] ?? 0).toString().contains('.') ? double.parse(producto['subtotal'].toString()).toStringAsFixed(2) : (producto['subtotal'] ?? 0).toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }) ??
                                          []),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Devuelto:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            Text(
                                              'Bs. ${confirmacion.montoDevuelto?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Fecha y observaciones
                                    const Divider(height: 16),
                                    Text(
                                      'Confirmado: ${confirmacion.fechaConfirmacionFormato}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  confirmacion.fotos![index],
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
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
                  ],
                ),
              );
            },
          ),
        );
      },
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

  /// Verifica si el usuario actual puede ver la sección de entregas
  /// Solo usuarios sin el rol "cliente" pueden verla (case-insensitive)
  bool _canViewDeliveries(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) return false;

    // No mostrar si el usuario tiene el rol "cliente" (cualquier caso: cliente, Cliente, CLIENTE)
    final hasClientRole =
        currentUser.roles?.any((role) => role.toLowerCase() == 'cliente') ??
        false;
    return !hasClientRole;
  }
}
