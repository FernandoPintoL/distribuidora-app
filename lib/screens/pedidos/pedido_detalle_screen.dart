import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../widgets/widgets.dart';
import '../../widgets/venta/venta_info_card.dart';
import '../../widgets/dialogs/renovacion_reservas_dialog.dart';
import '../../widgets/dialogs/print_format_dialog.dart';
import '../../widgets/dialogs/payment_registration_dialog.dart';
import '../../config/config.dart';
import '../../services/estados_helpers.dart'; // âœ… AGREGADO para estados dinÃ¡micos
import '../../services/print_service.dart';
import '../../extensions/theme_extension.dart'; // âœ… AGREGADO para dark mode
import '../reportes/nuevo_reporte_screen.dart'; // âœ… NUEVO: Para reportar productos daÃ±ados
import '../ventas/venta_detalle_screen.dart'; // âœ… NUEVO: Para ver detalles de venta
import 'pedido_detalle/widgets/index.dart'; // âœ… REFACTORIZADO: Widgets separados

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

  /// Reportar producto daÃ±ado
  Future<void> _reportarProductoDanado(Pedido pedido) async {
    if (pedido.venta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay venta asociada a este pedido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegar a la pantalla de nuevo reporte con el ID de la venta
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevoReporteScreen(
          ventaId: pedido.venta!.id,
        ),
      ),
    );

    // Mostrar mensaje de Ã©xito si el reporte fue creado
    if (resultado != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            content: Text('âœ… Reservas renovadas. Reintentando conversiÃ³n...'),
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

  /// Imprimir ticket de venta
  Future<void> _printTicket(int ventaId) async {
    try {
      // 1. Mostrar diÃ¡logo de selecciÃ³n de formato
      final selectedFormat = await showPrintFormatDialog(context);
      if (selectedFormat == null) {
        // Usuario cancelÃ³
        return;
      }

      if (!mounted) return;

      // 2. Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abriendo ticket...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // 3. Llamar PrintService
      final printService = PrintService();
      final success = await printService.printTicket(
        ventaId: ventaId,
        format: selectedFormat,
      );

      if (!mounted) return;

      // 4. Mostrar feedback
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abriendo ticket en ${selectedFormat.label}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el navegador. Verifica tu conexiÃ³n.',
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

  /// Registrar pago rÃ¡pido
  Future<void> _registerPayment(Venta venta) async {
    try {
      // Mostrar diÃ¡logo de registraciÃ³n de pago
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => PaymentRegistrationDialog(
          venta: venta,
          onPaymentSuccess: _onPaymentSuccess,
        ),
      );

      // Si el pago fue registrado exitosamente, recargar la venta
      if (result == true && mounted) {
        await _cargarPedido();
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

  /// Callback cuando el pago se registra exitosamente
  void _onPaymentSuccess() {
    // Recargar datos cuando se registra un pago
    // El diÃ¡logo ya muestra el mensaje de Ã©xito
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

  /// Mostrar menÃº de mÃ¡s opciones
  Future<void> _showMoreOptions(Venta venta) async {
    // TODO: Implementar despuÃ©s de crear diÃ¡logos adicionales
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MÃ¡s opciones prÃ³ximamente disponibles'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// âœ… NUEVO: Navegar a detalles de venta
  Future<void> _irADetallesVenta(int ventaId) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VentaDetalleScreen(
          ventaId: ventaId,
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  String _formatearSoloFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMMM yyyy', 'es_ES');
    return formatter.format(fecha);
  }

  String _getLocalidadNombre(Client cliente) {
    // âœ… El backend carga la relaciÃ³n localidad como objeto Localidad
    if (cliente.localidad != null) {
      if (cliente.localidad is Map) {
        // Si viene como Map (aunque no deberÃ­a)
        return (cliente.localidad as Map)['nombre'] ?? 'No disponible';
      }
      // Si viene como objeto Localidad
      try {
        return cliente.localidad.nombre ?? 'No disponible';
      } catch (e) {
        return 'No disponible';
      }
    }
    return 'No disponible';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Detalle del Pedido',
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
                            onPressed: () => _irADetallesVenta(pedido.venta!.id),
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
                return ErrorStateWidget(error: pedidoProvider.errorMessage!, onRetry: _cargarPedido, parentContext: context,);
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
                      // Header con estado
                      HeaderWidget(pedido: pedido, parentContext: context, hexToColor: _hexToColor,),

                      // âœ… NUEVO: InformaciÃ³n del cliente
                      if (pedido.cliente != null)
                        ClienteSection(cliente: pedido.cliente!, parentContext: context),

                      // âœ… NUEVO: Estados de venta convertida (si estÃ¡ convertida)
                      if (pedido.venta != null)
                        VentaConvertidaSection(pedido: pedido, colorScheme: Theme.of(context).colorScheme, parentContext: context,),

                      // âœ… NUEVO: InformaciÃ³n de venta (si es una venta convertida)
                      Consumer<PedidoProvider>(
                        builder: (context, provider, _) {
                          debugPrint(
                            'ðŸ” PedidoDetalle Debug: estadoCategoria=${pedido.estadoCategoria}, '
                            'ventaActual=${provider.ventaActual != null}, '
                            'isLoadingVenta=${provider.isLoadingVenta}',
                          );

                          if (provider.isLoadingVenta) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final venta = provider.ventaActual;
                          if (venta != null &&
                              pedido.estadoCategoria == 'venta') {
                            debugPrint(
                              'âœ… Mostrando VentaInfoCard: ${venta.numero}',
                            );
                            return VentaInfoCard(
                              venta: venta,
                              onPrintTicket: () => _printTicket(venta.id),
                              onRegisterPayment: () => _registerPayment(venta),
                              onMoreOptions: () => _showMoreOptions(venta),
                            );
                          }

                          if (pedido.estadoCategoria != 'venta') {
                            debugPrint(
                              'âš ï¸ No es una venta, es: ${pedido.estadoCategoria}',
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      // BotÃ³n de tracking (si estÃ¡ en ruta)
                      // âœ… ACTUALIZADO: Usar cÃ³digos de estado String en lugar de enum
                      if (pedido.estadoCodigo == 'EN_RUTA' ||
                          pedido.estadoCodigo == 'LLEGO')
                        TrackingSection(pedido: pedido, parentContext: context,),

                      // Timeline de estados
                      if (pedido.historialEstados.isNotEmpty)
                        TimelineEstadosWidget(pedido: pedido, parentContext: context, hexToColor: _hexToColor,),

                      const SizedBox(height: 16),

                      // InformaciÃ³n general
                      InfoSection(pedido: pedido, parentContext: context,),

                      // DirecciÃ³n de entrega
                      if (pedido.direccionEntrega != null)
                        DireccionSection(pedido: pedido, parentContext: context,),

                      // Fecha programada
                      if (pedido.fechaProgramada != null)
                        FechaProgramadaSection(pedido: pedido, parentContext: context,),

                      // Productos
                      ProductosSection(pedido: pedido, parentContext: context,),

                      // Reservas de stock
                      if (pedido.reservas.isNotEmpty)
                        ReservasSection(pedido: pedido, parentContext: context,),

                      // Resumen de montos
                      ResumenSection(pedido: pedido, parentContext: context,),

                      // Observaciones
                      if (pedido.observaciones != null &&
                          pedido.observaciones!.isNotEmpty)
                        ObservacionesSection(pedido: pedido, parentContext: context,),

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


  /// âœ… HELPER: Convertir hex string (#RRGGBB) a Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey; // Fallback
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

