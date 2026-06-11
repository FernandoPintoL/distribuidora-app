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
                return _buildErrorState(pedidoProvider.errorMessage!);
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
                      _buildHeader(pedido),

                      // âœ… NUEVO: InformaciÃ³n del cliente
                      if (pedido.cliente != null)
                        _buildSeccionCliente(pedido.cliente!),

                      // âœ… NUEVO: Estados de venta convertida (si estÃ¡ convertida)
                      if (pedido.venta != null)
                        _buildSeccionEstadosVentaConvertida(pedido),

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
                        _buildSeccionTracking(pedido),

                      // Timeline de estados
                      if (pedido.historialEstados.isNotEmpty)
                        _buildTimelineEstados(pedido),

                      const SizedBox(height: 16),

                      // InformaciÃ³n general
                      _buildSeccionInfo(pedido),

                      // DirecciÃ³n de entrega
                      if (pedido.direccionEntrega != null)
                        _buildSeccionDireccion(pedido),

                      // Fecha programada
                      if (pedido.fechaProgramada != null)
                        _buildSeccionFechaProgramada(pedido),

                      // Productos
                      _buildSeccionProductos(pedido),

                      // Reservas de stock
                      if (pedido.reservas.isNotEmpty)
                        _buildSeccionReservas(pedido),

                      // Resumen de montos
                      _buildSeccionResumen(pedido),

                      // Observaciones
                      if (pedido.observaciones != null &&
                          pedido.observaciones!.isNotEmpty)
                        _buildSeccionObservaciones(pedido),

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

  Widget _buildHeader(Pedido pedido) {
    // âœ… ACTUALIZADO: Usar datos dinÃ¡micos en lugar de enum EstadoInfo
    final colorHex = EstadosHelper.getEstadoColor(
      pedido.estadoCategoria,
      pedido.estadoCodigo,
    );
    final estadoColor = _hexToColor(colorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: estadoColor.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pedido.numero,
            style: TextStyle(
              fontSize: AppTextStyles.displaySmall(context).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // âœ… El icono puede ser un emoji (string) o nombre de icono
                Text(
                  EstadosHelper.getEstadoIcon(
                    pedido.estadoCategoria,
                    pedido.estadoCodigo,
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  pedido.estadoNombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTracking(Pedido pedido) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/pedido-tracking', arguments: pedido);
        },
        icon: const Icon(Icons.location_on, size: 28),
        label: Text(
          'Ver Tracking en Tiempo Real',
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineEstados(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Estados',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(context).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...pedido.historialEstados.asMap().entries.map((entry) {
            final index = entry.key;
            final historial = entry.value;
            final isFirst = index == 0;
            final isLast = index == pedido.historialEstados.length - 1;
            // âœ… ACTUALIZADO: Usar EstadosHelper en lugar de EstadoInfo enum
            final colorHex = EstadosHelper.getEstadoColor(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );
            final estadoColor = _hexToColor(colorHex);
            final estadoNombre = EstadosHelper.getEstadoLabel(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );
            final estadoIcon = EstadosHelper.getEstadoIcon(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );

            return TimelineTile(
              isFirst: isFirst,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 32,
                height: 32,
                indicator: Container(
                  decoration: BoxDecoration(
                    color: estadoColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    estadoIcon as IconData?,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: estadoColor.withOpacity(0.3),
                thickness: 2,
              ),
              endChild: Container(
                padding: const EdgeInsets.only(left: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estadoNombre,
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(historial.fecha),
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (historial.nombreUsuario != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Por: ${historial.nombreUsuario}',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    if (historial.comentario != null &&
                        historial.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          historial.comentario!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeccionCliente(Client cliente) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'InformaciÃ³n del Cliente',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyMedium(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cliente.nombre,
                            style: TextStyle(
                              fontSize: AppTextStyles.headlineSmall(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Fila 1: TelÃ©fono y Ciudad
                Row(
                  children: [
                    Expanded(
                      child: _buildClientInfoItem(
                        icon: Icons.phone,
                        label: 'TelÃ©fono',
                        value: cliente.telefono ?? 'No disponible',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClientInfoItem(
                        icon: Icons.location_on,
                        label: 'Localidad',
                        value: _getLocalidadNombre(cliente),
                      ),
                    ),
                  ],
                ),
                // Fila 2: Estado y CrÃ©dito
                if (cliente.puedeAtenerCredito || !cliente.activo) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildClientInfoItem(
                          icon: Icons.check_circle,
                          label: 'Estado',
                          value: cliente.activo ? 'Activo' : 'Inactivo',
                          valueColor: cliente.activo
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      /* if (cliente.puedeAtenerCredito &&
                          cliente.limiteCredito != null &&
                          cliente.creditoUtilizado != null)
                        Expanded(
                          child: _buildClientInfoItem(
                            icon: Icons.credit_card,
                            label: 'CrÃ©dito Disponible',
                            value:
                                '\$${(cliente.limiteCredito! - cliente.creditoUtilizado!).toStringAsFixed(2)}',
                            valueColor: Colors.blue,
                          ),
                        ), */
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTextStyles.labelSmall(context).fontSize!,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTextStyles.bodyMedium(context).fontSize!,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // âœ… NUEVO 2026-02-27: Widget para mostrar estados de venta convertida
  Widget _buildSeccionEstadosVentaConvertida(Pedido pedido) {
    final colorScheme = Theme.of(context).colorScheme;
    final venta = pedido.venta;

    if (venta == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÃ­tulo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estados de Venta Convertida',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyMedium(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Folio: #${venta.id}',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyLarge(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${venta.numero}',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyLarge(
                                context,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Estado del documento
                if (venta.estadoDocumento != null) ...[
                  _buildEstadoRow(
                    icon: Icons.description,
                    label: 'Estado Documento',
                    estadoData: venta.estadoDocumento!,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],

                // Estado de logÃ­stica
                if (venta.estadoLogistica != null) ...[
                  _buildEstadoRow(
                    icon: Icons.local_shipping,
                    label: 'Estado LogÃ­stica',
                    estadoData: venta.estadoLogistica!,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],

                // âœ… NUEVO 2026-02-27: Motivo de anulaciÃ³n si estÃ¡ anulada
                if (venta.estadoDocumento?.codigo == 'ANULADA' &&
                    venta.observaciones != null &&
                    venta.observaciones!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de AnulaciÃ³n',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          venta.observaciones!,
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Confirmaciones de entrega
                if (venta.confirmacionesEntrega.isNotEmpty) ...[
                  Text(
                    'Confirmaciones de Entrega',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...venta.confirmacionesEntrega.map((confirmacion) {
                    final isCompleted =
                        confirmacion.estado.toUpperCase() == 'COMPLETADA';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.schedule,
                              color: isCompleted ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    confirmacion.estado,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  if (confirmacion.chofer != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Chofer: ${confirmacion.chofer}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          context,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (confirmacion.cliente != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cliente: ${confirmacion.cliente}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          context,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (confirmacion.fecha != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(confirmacion.fecha!)}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          context,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // âœ… NUEVO: Helper para renderizar un estado con estilo
  Widget _buildEstadoRow({
    required IconData icon,
    required String label,
    required EstadoDocumento estadoData,
    required ColorScheme colorScheme,
  }) {
    // Intentar parsear color hex del backend
    Color estadoColor = Colors.grey;
    try {
      if (estadoData.color.startsWith('#')) {
        estadoColor = Color(
          int.parse(estadoData.color.replaceFirst('#', '0xff')),
        );
      }
    } catch (e) {
      debugPrint('âš ï¸ Error parsing color: ${estadoData.color}');
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: estadoColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(context).fontSize!,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: estadoColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      estadoData.nombre,
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: estadoColor,
                      ),
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

  Widget _buildSeccionInfo(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'InformaciÃ³n General',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha de creaciÃ³n',
                _formatearFecha(pedido.fechaCreacion),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.source,
                'Canal de origen',
                pedido.canalOrigen,
              ),
              if (pedido.fechaAprobacion != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.check_circle,
                  'Fecha de aprobaciÃ³n',
                  _formatearFecha(pedido.fechaAprobacion!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionDireccion(Pedido pedido) {
    final direccion = pedido.direccionEntrega!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DirecciÃ³n de Entrega',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direccion.direccion ?? '',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (direccion.ciudad != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ciudad: ${direccion.ciudad}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (direccion.departamento != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            direccion.departamento!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        if (direccion.observaciones != null &&
                            direccion.observaciones!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withOpacity(context.isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Obs: ${direccion.observaciones}',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionFechaProgramada(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha Programada',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.event,
                'Fecha',
                _formatearSoloFecha(pedido.fechaProgramada!),
              ),
              if (pedido.horaInicioPreferida != null ||
                  pedido.horaFinPreferida != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Horario',
                  '${pedido.horaInicioPreferida != null ? DateFormat('HH:mm').format(pedido.horaInicioPreferida!) : '--:--'} - ${pedido.horaFinPreferida != null ? DateFormat('HH:mm').format(pedido.horaFinPreferida!) : '--:--'}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionProductos(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(context).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...pedido.items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Imagen
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.producto?.imagenPrincipal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.producto!.imagenPrincipal!.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image),
                              ),
                            )
                          : const Icon(Icons.image, size: 32),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.producto?.nombre ?? 'Producto',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: ${item.cantidad}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: AppTextStyles.bodyMedium(
                                context,
                              ).fontSize!,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bs. ${item.precioUnitario.toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: AppTextStyles.bodySmall(
                                context,
                              ).fontSize!,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtotal
                    Text(
                      'Bs. ${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionReservas(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reservas de Stock',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              ...pedido.reservas.map((reserva) {
                final isActiva = reserva.estado == EstadoReserva.ACTIVA;
                final estaVencida = reserva.estaVencida;

                // Determinar colores segÃºn estado
                Color bgColor;
                Color borderColor;
                Color statusColor;

                if (estaVencida) {
                  bgColor = Theme.of(
                    context,
                  ).colorScheme.error.withOpacity(context.isDark ? 0.15 : 0.1);
                  borderColor = Theme.of(
                    context,
                  ).colorScheme.error.withOpacity(0.3);
                  statusColor = Theme.of(context).colorScheme.error;
                } else if (isActiva) {
                  bgColor = Colors.green.withOpacity(
                    context.isDark ? 0.15 : 0.1,
                  );
                  borderColor = Colors.green.withOpacity(0.3);
                  statusColor = Colors.green;
                } else {
                  bgColor = Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3);
                  borderColor = Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.2);
                  statusColor = Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.producto?.nombre ?? 'Producto',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cantidad: ${reserva.cantidad}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estaVencida
                              ? 'Vencida'
                              : 'Expira en: ${reserva.tiempoRestanteFormateado}',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionResumen(Pedido pedido) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Resumen',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Divider(
                height: 20,
                color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
              ),

              // Subtotal
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Bs. ${pedido.subtotal.toStringAsFixed(2)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Impuesto
              /* Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Impuesto',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Bs. ${pedido.impuesto.toStringAsFixed(2)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ), */
              Divider(
                height: 20,
                color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
              ),

              // Total
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(
                    isDark ? 0.3 : 0.2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Bs. ${pedido.total.toStringAsFixed(2)}',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionObservaciones(Pedido pedido) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observaciones',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Divider(
                height: 20,
                color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
              ),
              Text(
                pedido.observaciones!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Error al cargar pedido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _cargarPedido,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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

