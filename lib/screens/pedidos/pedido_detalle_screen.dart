import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/pedido.dart'; // NUEVO: Para el tipo Pedido en _abrirMapa
import '../../widgets/widgets.dart';
import '../../widgets/dialogs/renovacion_reservas_dialog.dart';
import '../../widgets/map_location_selector.dart'; // NUEVO: Para mapa
import '../../utils/phone_utils.dart'; // NUEVO: Para contacto
import '../../config/app_urls.dart'; // NUEVO: Para URLs
import '../../extensions/theme_extension.dart'; // AGREGADO para dark mode
import '../ventas/venta_detalle_screen.dart'; // NUEVO: Para ver detalles de venta
import '../ventas/venta_detalle/cliente_avatar_widget.dart'; // NUEVO: Avatar del cliente
import 'pedido_detalle/widgets/index.dart'; // REFACTORIZADO: Widgets separados

class PedidoDetalleScreen extends StatefulWidget {
  final int pedidoId;

  const PedidoDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  // Estado para el flujo de conversiÃ³n
  bool _showRenovacionDialog = false;

  @override
  void initState() {
    super.initState();
    print("Iniciando detalle de pedido ID: ${widget.pedidoId}");
    // Usar SchedulerBinding para posponer la carga despuÃ©s de que termine la construcciÃ³n
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _cargarPedido();
    });
  }

  Future<void> _cargarPedido() async {
    final pedidoProvider = context.read<PedidoProvider>();
    await pedidoProvider.loadPedido(widget.pedidoId);
  }

  Future<void> _onRefresh() async {
    await _cargarPedido();
  }

  Future<void> _extenderReserva() async {
    final pedidoProvider = context.read<PedidoProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extender Reserva'),
        content: const Text(
          'Â¿Deseas extender el tiempo de reserva de stock para este pedido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Extender'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await pedidoProvider.extenderReserva(widget.pedidoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Reserva extendida exitosamente'
                  : pedidoProvider.errorMessage ?? 'Error al extender reserva',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  /// Convertir proforma a venta
  Future<void> _convertirAVenta() async {
    final pedidoProvider = context.read<PedidoProvider>();
    final pedido = pedidoProvider.pedidoActual;

    if (pedido == null) return;

    try {
      // Intentar confirmaciÃ³n
      final success = await pedidoProvider.confirmarProforma(
        proformaId: pedido.id,
      );

      if (!mounted) return;

      if (success) {
        // âœ… Ã‰xito - Recargar y mostrar mensaje
        await _cargarPedido();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ… Proforma convertida a venta exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (pedidoProvider.errorCode == 'RESERVAS_EXPIRADAS') {
        // âš ï¸ Reservas expiradas - Mostrar diÃ¡logo de renovaciÃ³n
        setState(() {
          _showRenovacionDialog = true;
        });
      } else {
        // âŒ Otro error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pedidoProvider.errorMessage ?? 'Error al convertir proforma',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Renovar reservas expiradas
  Future<void> _renovarReservas() async {
    final pedidoProvider = context.read<PedidoProvider>();
    final pedido = pedidoProvider.pedidoActual;

    if (pedido == null) return;

    try {
      final success = await pedidoProvider.renovarReservas(pedido.id);

      if (!mounted) return;

      if (success) {
        // âœ… Reservas renovadas - Cerrar diÃ¡logo y reintentar conversiÃ³n
        setState(() {
          _showRenovacionDialog = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'âœ… Reservas renovadas. Reintentando conversiÃ³n...',
            ),
            backgroundColor: Colors.blue,
          ),
        );

        // Esperar un poco y reintentar conversiÃ³n automÃ¡ticamente
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;

        // Reintentar conversiÃ³n
        await _convertirAVenta();
      } else {
        // âŒ Error al renovar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pedidoProvider.errorMessage ?? 'Error al renovar reservas',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// âœ… NUEVO: Navegar a ProductListScreen para editar carrito y actualizar proforma
  Future<void> _editarProductos() async {
    final pedidoProvider = context.read<PedidoProvider>();
    final carritoProvider = context.read<CarritoProvider>();
    final pedido = pedidoProvider.pedidoActual;

    if (pedido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Pedido no encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1. Cargar la proforma en el carrito (esto limpia y carga los items automÃ¡ticamente)
      final cargadoExitosamente = await carritoProvider.cargarProformaEnCarrito(
        pedido,
      );

      if (!cargadoExitosamente) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                carritoProvider.errorMessage ??
                    'Error al cargar proforma en carrito',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint(
        'ðŸ“¥ Carrito cargado con ${pedido.items.length} items de la proforma',
      );

      // 2. Navegar a ProductListScreen y esperar resultado
      if (!mounted) return;

      final result = await Navigator.pushNamed(
        context,
        '/products', // âœ… CORREGIDO: usar /products (inglÃ©s) segÃºn rutas registradas
      );

      // 3. Si el usuario regresa (cambiÃ³ algo), actualizar la proforma
      if (mounted && result != null && result is bool && result) {
        debugPrint(
          'ðŸ“ Actualizando proforma con items del carrito modificado...',
        );
        await _actualizarProformaConCarrito();
      }
    } catch (e) {
      debugPrint('âŒ Error al editar productos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// âœ… NUEVO: Actualizar la proforma con los items del carrito modificado
  Future<void> _actualizarProformaConCarrito() async {
    final pedidoProvider = context.read<PedidoProvider>();
    final carritoProvider = context.read<CarritoProvider>();
    final pedido = pedidoProvider.pedidoActual;

    if (pedido == null) return;

    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('â³ Actualizando proforma...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Preparar detalles desde los items del carrito
      final detalles = carritoProvider.items
          .map(
            (item) => {
              'producto_id': item.producto.id,
              'cantidad': item.cantidad,
              'precio_unitario': item.precioUnitario,
            },
          )
          .toList();

      // Actualizar detalles de la proforma con los items del carrito
      final success = await pedidoProvider.actualizarDetallesProforma(
        proformaId: pedido.id,
        detalles: detalles,
      );

      if (!mounted) return;

      if (success) {
        // Recargar pedido para obtener datos actualizados
        await _cargarPedido();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('âœ… Proforma actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pedidoProvider.errorMessage ?? 'Error al actualizar proforma',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('âŒ Error al actualizar proforma: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// âœ… NUEVO: Navegar a detalles de venta
  Future<void> _irADetallesVenta(int ventaId) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaDetalleScreen(ventaId: ventaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Pedido #${widget.pedidoId.toString()}',
        actions: [RefreshAction(isLoading: false, onRefresh: _onRefresh)],
      ),
      bottomNavigationBar: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, _) {
          final pedido = pedidoProvider.pedidoActual;
          // âœ… ACTUALIZADO: Permitir editar solo si estÃ¡ en PENDIENTE
          final puedeEditarProductos = pedido?.estadoCodigo == 'PENDIENTE';

          if (pedido == null) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // âœ… NUEVO: BotÃ³n para editar productos (solo en PENDIENTE)
                  if (puedeEditarProductos) ...[
                    ElevatedButton.icon(
                      onPressed: _editarProductos,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Productos'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (pedido.puedeExtenderReservas)
                    ElevatedButton.icon(
                      onPressed: _extenderReserva,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Extender Reserva'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  // âœ… NUEVO: BotÃ³n para reportar producto daÃ±ado (si es una venta confirmada)
                  if (pedido.venta != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _irADetallesVenta(pedido.venta!.id),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Ver Venta'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        /* Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _reportarProductoDanado(pedido),
                            icon: const Icon(Icons.report_problem),
                            label: const Text('Reportar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.red.shade600,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ), */
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      // DiÃ¡logo de renovaciÃ³n de reservas
      body: Stack(
        children: [
          Consumer<PedidoProvider>(
            builder: (context, pedidoProvider, child) {
              if (pedidoProvider.isLoading &&
                  pedidoProvider.pedidoActual == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (pedidoProvider.errorMessage != null &&
                  pedidoProvider.pedidoActual == null) {
                return ErrorStateWidget(
                  error: pedidoProvider.errorMessage!,
                  onRetry: _cargarPedido,
                  parentContext: context,
                );
              }

              final pedido = pedidoProvider.pedidoActual;
              if (pedido == null) {
                return const Center(child: Text('Pedido no encontrado'));
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // âœ… CABECERA: Estado, Cliente, DirecciÃ³n y Botones (formato venta_cliente_header_widget)
                      if (pedido.cliente != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Estado del Pedido
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Estado',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            pedido.estadoNombre ??
                                                pedido.estadoCodigo ??
                                                'Desconocido',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Cliente, Dirección y Botones
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar y Nombre del Cliente
                                    Row(
                                      children: [
                                        ClienteAvatarWidget(
                                          clienteNombre: pedido.cliente?.nombre,
                                          clienteFotoPerfil: pedido.cliente?.fotoPerfil,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pedido.cliente?.nombre ??
                                                    'Cliente desconocido',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                pedido.cliente?.razonSocial ??
                                                    'N/A',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (pedido.cliente?.localidad !=
                                                  null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  '📍 ${pedido.cliente?.localidad?.nombre ?? 'Localidad desconocida'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Dirección de Entrega
                                    if (pedido.direccionEntrega != null) ...[
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Dirección de Entrega',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  pedido
                                                          .direccionEntrega
                                                          ?.observaciones ??
                                                      pedido
                                                          .direccionEntrega
                                                          ?.direccion ??
                                                      'Sin dirección',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    // Botones de Contacto
                                    if (pedido.cliente?.telefono != null) ...[
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Tooltip(
                                            message: 'Llamar',
                                            child: IconButton(
                                              icon: const Icon(Icons.phone),
                                              color: Colors.green,
                                              onPressed: () => PhoneUtils.llamarCliente(
                                                context,
                                                pedido.cliente?.telefono,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
                                              ),
                                            ),
                                          ),
                                          Tooltip(
                                            message: 'WhatsApp',
                                            child: IconButton(
                                              icon: const Icon(Icons.chat),
                                              color: Colors.green,
                                              onPressed: () => PhoneUtils.enviarWhatsApp(
                                                context,
                                                pedido.cliente?.telefono,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
                                              ),
                                            ),
                                          ),
                                          // ✅ Botón Mapa (solo si hay dirección con coordenadas)
                                          if (pedido.direccionEntrega?.latitud != null &&
                                              pedido.direccionEntrega?.longitud != null)
                                            Tooltip(
                                              message: 'Ver en Mapa',
                                              child: IconButton(
                                                icon: const Icon(Icons.map),
                                                color: Colors.lightGreen,
                                                onPressed: () => _abrirMapa(pedido),
                                                constraints: const BoxConstraints(
                                                  minWidth: 40,
                                                  minHeight: 40,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // DirecciÃ³n de entrega
                      if (pedido.direccionEntrega != null)
                        DireccionSection(
                          pedido: pedido,
                          parentContext: context,
                        ),

                      // Fecha programada
                      if (pedido.fechaProgramada != null)
                        FechaProgramadaSection(
                          pedido: pedido,
                          parentContext: context,
                        ),

                      // Productos
                      ProductosSection(pedido: pedido, parentContext: context),

                      // Reservas de stock
                      if (pedido.reservas.isNotEmpty)
                        ReservasSection(pedido: pedido, parentContext: context),

                      // Resumen de montos
                      ResumenSection(pedido: pedido, parentContext: context),

                      // Observaciones
                      if (pedido.observaciones != null &&
                          pedido.observaciones!.isNotEmpty)
                        ObservacionesSection(
                          pedido: pedido,
                          parentContext: context,
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            },
          ),
          // DiÃ¡logo de renovaciÃ³n superpuesto
          if (_showRenovacionDialog)
            Consumer<PedidoProvider>(
              builder: (context, pedidoProvider, _) {
                final pedido = pedidoProvider.pedidoActual;
                return Dialog(
                  child: RenovacionReservasDialog(
                    proformaNumero: pedido?.numero ?? 'N/A',
                    reservasExpiradas:
                        pedidoProvider.errorData?['reservas_expiradas'] ?? 1,
                    isLoading: pedidoProvider.isRenovandoReservas,
                    onRenovar: _renovarReservas,
                    onCancelar: () {
                      setState(() {
                        _showRenovacionDialog = false;
                      });
                      pedidoProvider.limpiarErrores();
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _abrirMapa(Pedido pedido) async {
    try {
      if (mounted) {
        final fotoPerfil = pedido.cliente?.fotoPerfil != null
            ? '${AppUrls.baseUrlImg}${pedido.cliente!.fotoPerfil}'
            : null;

        final ubicacionPedido = MapLocation(
          latitude: pedido.direccionEntrega!.latitud!,
          longitude: pedido.direccionEntrega!.longitud!,
          title: pedido.cliente?.nombre ?? 'Sin nombre',
          subtitle: pedido.id.toString(),
          isSelected: false,
          razonSocial: pedido.cliente?.razonSocial,
          telefono: pedido.cliente?.telefono,
          ventaId: pedido.id,
          markerColor: '#1E90FF',
          fotoPerfil: fotoPerfil,
        );

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Scaffold(
              body: MapLocationSelector(
                initialLatitude: pedido.direccionEntrega!.latitud!,
                initialLongitude: pedido.direccionEntrega!.longitud!,
                additionalLocations: [ubicacionPedido],
                onLocationSelected: (lat, lng, address) {
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
      debugPrint('⚠️ Error abriendo mapa: $e');
    }
  }
}
