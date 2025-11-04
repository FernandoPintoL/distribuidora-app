import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'package:intl/intl.dart';

class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen> {
  final ScrollController _scrollController = ScrollController();
  EstadoPedido? _filtroEstadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPedidos();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Cargar más cuando estamos al 90% del scroll
      final pedidoProvider = context.read<PedidoProvider>();
      if (!pedidoProvider.isLoadingMore && pedidoProvider.hasMorePages) {
        pedidoProvider.loadMorePedidos();
      }
    }
  }

  Future<void> _cargarPedidos() async {
    final pedidoProvider = context.read<PedidoProvider>();
    await pedidoProvider.loadPedidos();
  }

  Future<void> _onRefresh() async {
    final pedidoProvider = context.read<PedidoProvider>();
    await pedidoProvider.loadPedidos(
      estado: _filtroEstadoSeleccionado,
      refresh: true,
    );
  }

  void _mostrarFiltroEstado() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por estado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFiltroEstadoOption(null, 'Todos los pedidos'),
            const Divider(),
            _buildFiltroEstadoOption(EstadoPedido.PENDIENTE, 'Pendientes'),
            _buildFiltroEstadoOption(EstadoPedido.APROBADA, 'Aprobadas'),
            _buildFiltroEstadoOption(EstadoPedido.PREPARANDO, 'Preparando'),
            _buildFiltroEstadoOption(EstadoPedido.EN_RUTA, 'En Ruta'),
            _buildFiltroEstadoOption(EstadoPedido.ENTREGADO, 'Entregados'),
            _buildFiltroEstadoOption(EstadoPedido.RECHAZADA, 'Rechazadas'),
            _buildFiltroEstadoOption(EstadoPedido.NOVEDAD, 'Con Novedad'),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroEstadoOption(EstadoPedido? estado, String label) {
    final isSelected = _filtroEstadoSeleccionado == estado;

    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          _filtroEstadoSeleccionado = estado;
        });
        Navigator.pop(context);
        context.read<PedidoProvider>().aplicarFiltroEstado(estado);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filtroEstadoSeleccionado != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _mostrarFiltroEstado,
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, _) {
          // Estado de carga inicial
          if (pedidoProvider.isLoading && pedidoProvider.pedidos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de error
          if (pedidoProvider.errorMessage != null &&
              pedidoProvider.pedidos.isEmpty) {
            return _buildErrorState(pedidoProvider.errorMessage!);
          }

          // Estado vacío
          if (pedidoProvider.pedidos.isEmpty) {
            return _buildEmptyState();
          }

          // Lista de pedidos
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // Header con información
                if (_filtroEstadoSeleccionado != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mostrando: ${EstadoInfo.getInfo(_filtroEstadoSeleccionado!).nombre}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filtroEstadoSeleccionado = null;
                            });
                            pedidoProvider.limpiarFiltros();
                          },
                          child: const Text('Limpiar filtro'),
                        ),
                      ],
                    ),
                  ),

                // Lista de pedidos
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        pedidoProvider.pedidos.length +
                        (pedidoProvider.isLoadingMore ? 1 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      // Indicador de carga al final
                      if (index == pedidoProvider.pedidos.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final pedido = pedidoProvider.pedidos[index];
                      return _PedidoCard(
                        pedido: pedido,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/pedido-detalle',
                            arguments: pedido.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 120,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            _filtroEstadoSeleccionado != null
                ? 'No hay pedidos con este estado'
                : 'No tienes pedidos aún',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Text(
            _filtroEstadoSeleccionado != null
                ? 'Intenta con otro filtro'
                : 'Crea tu primer pedido desde el catálogo',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          if (_filtroEstadoSeleccionado == null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/products'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Ver Productos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
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
            'Error al cargar pedidos',
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
            onPressed: _cargarPedidos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  String _formatearFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final estadoInfo = pedido.estadoInfo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Número de pedido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proforma',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pedido.numero,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: estadoInfo.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estadoInfo.icono,
                          size: 16,
                          color: estadoInfo.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estadoInfo.nombre,
                          style: TextStyle(
                            color: estadoInfo.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Información del pedido
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatearFecha(pedido.fechaCreacion),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pedido.cantidadItems} ${pedido.cantidadItems == 1 ? 'producto' : 'productos'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),

              if (pedido.direccionEntrega != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pedido.direccionEntrega!.direccion,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Bs. ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Alerta de reserva próxima a vencer
              if (pedido.tieneReservasProximasAVencer) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reserva expira en ${pedido.reservaMasProximaAVencer?.tiempoRestanteFormateado ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
