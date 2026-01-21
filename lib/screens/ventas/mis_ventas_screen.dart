import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../services/estados_helpers.dart';

class MisVentasScreen extends StatefulWidget {
  const MisVentasScreen({super.key});

  @override
  State<MisVentasScreen> createState() => _MisVentasScreenState();
}

class _MisVentasScreenState extends State<MisVentasScreen> {
  late VentasProvider _ventasProvider;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Cargar ventas cuando se abre la pantalla
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _ventasProvider = context.read<VentasProvider>();
      _ventasProvider.loadVentas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _ventasProvider.loadVentas(
      estado: _ventasProvider.filtroEstado,
      busqueda: _ventasProvider.filtroBusqueda,
      fechaDesde: _ventasProvider.filtroFechaDesde,
      fechaHasta: _ventasProvider.filtroFechaHasta,
      refresh: true,
    );
  }

  void _onVentaTapped(Venta venta) {
    // Navegar al detalle de la venta/pedido
    Navigator.pushNamed(
      context,
      '/pedido-detalle',
      arguments: venta.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ventas'),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<VentasProvider>(
        builder: (context, ventasProvider, _) {
          if (ventasProvider.isLoading && ventasProvider.ventas.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (ventasProvider.errorMessage != null &&
              ventasProvider.ventas.isEmpty) {
            return _buildErrorState(ventasProvider);
          }

          if (ventasProvider.ventas.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: [
                // Búsqueda y filtros
                _buildSearchBar(ventasProvider),

                // Estadísticas rápidas
                _buildStatsBar(ventasProvider),

                // Lista de ventas
                _buildVentasList(ventasProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(VentasProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) {
              provider.aplicarBusqueda(value.isEmpty ? null : value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por número de venta...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  isSelected: provider.filtroEstado == null,
                  onSelected: () => provider.limpiarFiltros(),
                ),
                _buildFilterChip(
                  label: 'Pagados',
                  isSelected: provider.filtroEstado == 'PAGADO',
                  onSelected: () =>
                      provider.aplicarFiltroEstado('PAGADO'),
                ),
                _buildFilterChip(
                  label: 'Parciales',
                  isSelected: provider.filtroEstado == 'PARCIAL',
                  onSelected: () =>
                      provider.aplicarFiltroEstado('PARCIAL'),
                ),
                _buildFilterChip(
                  label: 'Pendientes',
                  isSelected: provider.filtroEstado == 'PENDIENTE',
                  onSelected: () =>
                      provider.aplicarFiltroEstado('PENDIENTE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.transparent,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _buildStatsBar(VentasProvider provider) {
    final stats = [
      ('Total', provider.totalItems.toString(), Colors.blue),
      ('Pagadas', provider.ventasPagadas.length.toString(), Colors.green),
      ('Pendientes', provider.ventasPendientes.length.toString(), Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats
            .map(
              (stat) => Column(
                children: [
                  Text(
                    stat.$2,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildVentasList(VentasProvider provider) {
    final isDark = context.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.ventas.length +
          (provider.hasMorePages ? 1 : 0) +
          (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more trigger
        if (index == provider.ventas.length && provider.hasMorePages) {
          provider.loadMoreVentas();
          return const SizedBox.shrink();
        }

        // Loading indicator
        if (index == provider.ventas.length && provider.isLoadingMore) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final venta = provider.ventas[index];
        return _buildVentaCard(venta, isDark, colorScheme);
      },
    );
  }

  Widget _buildVentaCard(Venta venta, bool isDark, ColorScheme colorScheme) {
    final estadoPagoColor = _getEstadoPagoColor(venta.estadoPago);
    final estadoPagoIcon = _getEstadoPagoIcon(venta.estadoPago);
    final fechaFormato = DateFormat('dd MMM yyyy', 'es_ES').format(venta.fecha);

    return GestureDetector(
      onTap: () => _onVentaTapped(venta),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono estado
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: estadoPagoColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      estadoPagoIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Info venta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${venta.numero}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fechaFormato,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estadoPagoColor.withOpacity(isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getEstadoPagoLabel(venta.estadoPago),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: estadoPagoColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Monto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bs. ${venta.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (venta.estadoLogistico.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColorFromHex(
                            venta.estadoLogisticoColor,
                          ).withOpacity(isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          venta.estadoLogistico,
                          style: TextStyle(
                            fontSize: 10,
                            color: _parseColorFromHex(
                              venta.estadoLogisticoColor,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 8),

                // Flecha
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes ventas aún',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tus compras confirmadas aparecerán aquí',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VentasProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar ventas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onRefresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Color _getEstadoPagoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return Colors.green;
      case 'PARCIAL':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoPagoIcon(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return '✅';
      case 'PARCIAL':
        return '⏳';
      case 'PENDIENTE':
        return '⏰';
      default:
        return '❓';
    }
  }

  String _getEstadoPagoLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return 'Pagado';
      case 'PARCIAL':
        return 'Pago Parcial';
      case 'PENDIENTE':
        return 'Pendiente de Pago';
      default:
        return estado;
    }
  }

  Color _parseColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }

    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    } else if (hexColor.length == 8 || hexColor.length == 9) {
      buffer.write(hexColor.replaceFirst('#', ''));
    } else {
      return Colors.grey;
    }

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
