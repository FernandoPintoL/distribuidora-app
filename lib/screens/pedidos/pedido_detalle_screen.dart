import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final int pedidoId;

  const PedidoDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  @override
  void initState() {
    super.initState();
    // Usar SchedulerBinding para posponer la carga después de que termine la construcción
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
          '¿Deseas extender el tiempo de reserva de stock para este pedido?',
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

  String _formatearFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  String _formatearSoloFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMMM yyyy', 'es_ES');
    return formatter.format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, _) {
          if (pedidoProvider.isLoading && pedidoProvider.pedidoActual == null) {
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

                  // Botón de tracking (si está en ruta)
                  if (pedido.estado == EstadoPedido.EN_RUTA ||
                      pedido.estado == EstadoPedido.LLEGO)
                    _buildSeccionTracking(pedido),

                  // Timeline de estados
                  if (pedido.historialEstados.isNotEmpty)
                    _buildTimelineEstados(pedido),

                  const SizedBox(height: 16),

                  // Información general
                  _buildSeccionInfo(pedido),

                  // Dirección de entrega
                  if (pedido.direccionEntrega != null)
                    _buildSeccionDireccion(pedido),

                  // Fecha programada
                  if (pedido.fechaProgramada != null)
                    _buildSeccionFechaProgramada(pedido),

                  // Productos
                  _buildSeccionProductos(pedido),

                  // Reservas de stock
                  if (pedido.reservas.isNotEmpty) _buildSeccionReservas(pedido),

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
      bottomNavigationBar: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, _) {
          final pedido = pedidoProvider.pedidoActual;

          if (pedido == null || !pedido.puedeExtenderReservas) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _extenderReserva,
                icon: const Icon(Icons.access_time),
                label: const Text('Extender Reserva'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Pedido pedido) {
    final estadoInfo = pedido.estadoInfo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: estadoInfo.color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: estadoInfo.color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pedido.numero,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estadoInfo.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(estadoInfo.icono, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  estadoInfo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estadoInfo.descripcion,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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
        label: const Text(
          'Ver Tracking en Tiempo Real',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          const Text(
            'Historial de Estados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...pedido.historialEstados.asMap().entries.map((entry) {
            final index = entry.key;
            final historial = entry.value;
            final isFirst = index == 0;
            final isLast = index == pedido.historialEstados.length - 1;
            final estadoInfo = EstadoInfo.getInfo(historial.estadoNuevo);

            return TimelineTile(
              isFirst: isFirst,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 32,
                height: 32,
                indicator: Container(
                  decoration: BoxDecoration(
                    color: estadoInfo.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(estadoInfo.icono, color: Colors.white, size: 18),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: estadoInfo.color.withOpacity(0.3),
                thickness: 2,
              ),
              endChild: Container(
                padding: const EdgeInsets.only(left: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estadoInfo.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(historial.fecha),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (historial.nombreUsuario != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Por: ${historial.nombreUsuario}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (historial.comentario != null &&
                        historial.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
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

  Widget _buildSeccionInfo(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información General',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha de creación',
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
                  'Fecha de aprobación',
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
              const Text(
                'Dirección de Entrega',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          direccion.direccion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (direccion.ciudad != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ciudad: ${direccion.ciudad}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                        if (direccion.departamento != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            direccion.departamento!,
                            style: const TextStyle(color: Colors.grey),
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Obs: ${direccion.observaciones}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
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
              const Text(
                'Fecha Programada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          const Text(
            'Productos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          item.producto?.imagenes != null &&
                              item.producto!.imagenes!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.producto!.imagenes!.first.url,
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: ${item.cantidad.toStringAsFixed(item.cantidad.truncateToDouble() == item.cantidad ? 0 : 2)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bs. ${item.precioUnitario.toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtotal
                    Text(
                      'Bs. ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
              const Text(
                'Reservas de Stock',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              ...pedido.reservas.map((reserva) {
                final isActiva = reserva.estado == EstadoReserva.ACTIVA;
                final estaVencida = reserva.estaVencida;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estaVencida
                          ? Colors.red.shade50
                          : isActiva
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: estaVencida
                            ? Colors.red.shade200
                            : isActiva
                            ? Colors.green.shade200
                            : Colors.grey.shade200,
                      ),
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
                            fontSize: 12,
                            color: estaVencida
                                ? Colors.red.shade700
                                : isActiva
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 16)),
                  Text(
                    'Bs. ${pedido.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Impuesto', style: TextStyle(fontSize: 16)),
                  Text(
                    'Bs. ${pedido.impuesto.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Bs. ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  Widget _buildSeccionObservaciones(Pedido pedido) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Observaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Text(pedido.observaciones!, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
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
              style: TextStyle(color: Colors.grey.shade600),
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
}
