import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/app_gradients.dart';
import '../../config/app_text_styles.dart';
import '../../extensions/theme_extension.dart';
import '../../services/estados_helpers.dart';
import '../../utils/date_picker_utils.dart';

/// Pantalla de listado de ventas para preventistas/admins
class VentasListScreen extends StatefulWidget {
  const VentasListScreen({super.key});

  @override
  State<VentasListScreen> createState() => _VentasListScreenState();
}

class _VentasListScreenState extends State<VentasListScreen> {
  late VentasProvider _ventasProvider;
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);

    // Cargar ventas cuando se abre la pantalla
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _ventasProvider = context.read<VentasProvider>();
      _ventasProvider.loadVentas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _ventasProvider.loadMoreVentas();
    }
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
    Navigator.pushNamed(context, '/venta-detalle', arguments: venta.id);
  }

  void _mostrarFiltrosAvanzados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFiltrosModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _mostrarFiltrosAvanzados,
            tooltip: 'Filtros avanzados',
          ),
        ],
      ),
      body: Consumer<VentasProvider>(
        builder: (context, ventasProvider, _) {
          if (ventasProvider.isLoading && ventasProvider.ventas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ventasProvider.errorMessage != null &&
              ventasProvider.ventas.isEmpty) {
            return _buildErrorState(ventasProvider);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Búsqueda
                SliverToBoxAdapter(child: _buildSearchBar(ventasProvider)),

                // Estadísticas rápidas
                SliverToBoxAdapter(child: _buildStatsBar(ventasProvider)),

                // Lista de ventas o estado vacío
                if (ventasProvider.ventas.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(ventasProvider),
                  )
                else
                  _buildVentasListSliver(ventasProvider),

                // Indicador de carga
                if (ventasProvider.isLoadingMore && ventasProvider.ventas.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
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
      color: context.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          provider.aplicarBusqueda(value.isEmpty ? null : value);
        },
        decoration: InputDecoration(
          hintText: 'Número, cliente o NIT...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.aplicarBusqueda(null);
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(VentasProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            provider.totalItems.toString(),
            Icons.shopping_bag_outlined,
          ),
          _buildStatItem(
            'Pagadas',
            provider.ventasPagadas.length.toString(),
            Icons.check_circle_outline,
          ),
          _buildStatItem(
            'Parcial',
            provider.ventasParciales.length.toString(),
            Icons.schedule_outlined,
          ),
          _buildStatItem(
            'Pendiente',
            provider.ventasPendientes.length.toString(),
            Icons.pending_actions_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: context.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVentasListSliver(VentasProvider provider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final venta = provider.ventas[index];
          return _buildVentaCard(venta);
        },
        childCount: provider.ventas.length,
      ),
    );
  }

  Widget _buildVentaCard(Venta venta) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () => _onVentaTapped(venta),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Número y Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${venta.numero}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MMM/yyyy HH:mm').format(venta.fecha),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Bs. ${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cliente y Dirección
              if (venta.cliente != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venta.cliente!.nombre,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (venta.direccionCliente?.direccion != null)
                      Text(
                        venta.direccionCliente!.direccion,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                  ],
                ),

              // Estados: Documento, Pago y Logístico
              Wrap(
                spacing: 8,
                children: [
                  // ✅ NUEVO: Estado del Documento (Aprobado, Anulado, Rechazado, etc)
                  if (venta.estadoDocumentoObj != null)
                    _buildEstadoBadge(
                      label: venta.estadoDocumentoObj!.codigo ?? venta.estadoDocumentoObj!.nombre,
                      icon: _getIconForEstadoDocumento(venta.estadoDocumentoObj!.codigo ?? ''),
                      color: _getColorForEstadoDocumento(venta.estadoDocumentoObj!.codigo ?? ''),
                      tooltip: venta.estadoDocumentoObj!.nombre,
                    ),
                  // Estado de pago
                  _buildEstadoBadge(
                    label: venta.estadoPago,
                    icon: _getIconForEstadoPago(venta.estadoPago),
                    color: _getColorForEstadoPago(venta.estadoPago),
                  ),
                  // Estado logístico
                  if (venta.estadoLogistico.isNotEmpty)
                    _buildEstadoBadge(
                      label: venta.estadoLogistico,
                      icon: Icons.local_shipping_outlined,
                      color: colorScheme.tertiary,
                    ),
                ],
              ),

              // ✅ NUEVO: Información de Entrega y Proforma (con IDs)
              if (venta.numeroEntrega != null || venta.proforma != null || venta.entregaId != null || venta.proformaId != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    // Información de Entrega
                    if (venta.entregaId != null || venta.numeroEntrega != null)
                      _buildInfoChip(
                        icon: Icons.local_shipping_outlined,
                        label: venta.numeroEntrega != null
                            ? '${venta.numeroEntrega} (#${venta.entregaId ?? '?'})'
                            : '#${venta.entregaId}',
                        color: colorScheme.tertiary,
                        tooltip: 'Entrega ID: ${venta.entregaId}',
                      ),
                    // Información de Proforma
                    if (venta.proformaId != null || venta.proforma != null)
                      _buildInfoChip(
                        icon: Icons.receipt_outlined,
                        label: venta.proforma != null
                            ? '${venta.proforma!.numero} (#${venta.proformaId ?? '?'})'
                            : '#${venta.proformaId}',
                        color: colorScheme.secondary,
                        tooltip: 'Proforma ID: ${venta.proformaId}',
                      ),
                  ],
                ),
              ],

              // Productos (resumido)
              if (venta.detalles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${venta.detalles.length} producto${venta.detalles.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ NUEVO: Widget para mostrar información de entrega/proforma con IDs
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        child: chip,
      );
    }
    return chip;
  }

  Widget _buildEstadoBadge({
    required String label,
    required IconData icon,
    required Color color,
    String? tooltip,
  }) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );

    // Si hay tooltip, envolver en Tooltip
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        child: badge,
      );
    }
    return badge;
  }

  IconData _getIconForEstadoPago(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return Icons.check_circle_outlined;
      case 'PARCIAL':
        return Icons.schedule_outlined;
      case 'PENDIENTE':
      default:
        return Icons.pending_actions_outlined;
    }
  }

  Color _getColorForEstadoPago(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return Colors.green;
      case 'PARCIAL':
        return Colors.orange;
      case 'PENDIENTE':
      default:
        return Colors.red;
    }
  }

  // ✅ NUEVO: Métodos para Estado del Documento
  IconData _getIconForEstadoDocumento(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'APROBADO':
        return Icons.verified_outlined;
      case 'ANULADO':
        return Icons.cancel_outlined;
      case 'RECHAZADO':
        return Icons.block_outlined;
      case 'PENDIENTE':
        return Icons.hourglass_empty_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _getColorForEstadoDocumento(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'APROBADO':
        return Colors.green;
      case 'ANULADO':
        return Colors.grey;
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildErrorState(VentasProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: context.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar ventas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Intenta nuevamente',
            style: TextStyle(color: context.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: _onRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VentasProvider provider) {
    final hasFilters = _searchController.text.isNotEmpty ||
        provider.filtroEstado != null ||
        provider.filtroFechaDesde != null ||
        provider.filtroFechaHasta != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ventas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'No hay ventas que coincidan con los filtros aplicados'
                : 'Las ventas aparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colorScheme.onSurfaceVariant),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.limpiarFiltros();
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltrosModal() {
    final provider = context.read<VentasProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros avanzados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Filtro por estado
          Text('Estado', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['PAGADO', 'PARCIAL', 'PENDIENTE', null].map((estado) {
              final isSelected = provider.filtroEstado == estado;
              return FilterChip(
                label: Text(estado ?? 'Todos'),
                selected: isSelected,
                onSelected: (_) {
                  provider.aplicarFiltroEstado(estado);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Filtro por fechas
          Text('Fecha desde', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              provider.filtroFechaDesde != null
                  ? DateFormat('dd/MMM/yyyy').format(provider.filtroFechaDesde!)
                  : 'Seleccionar fecha',
            ),
            onPressed: () async {
              final fecha = await DatePickerUtils.showThemedDatePicker(
                context: context,
                initialDate: provider.filtroFechaDesde ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (fecha != null) {
                await provider.aplicarFiltroFechas(
                  fecha,
                  provider.filtroFechaHasta,
                );
              }
            },
          ),
          const SizedBox(height: 16),

          Text('Fecha hasta', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              provider.filtroFechaHasta != null
                  ? DateFormat('dd/MMM/yyyy').format(provider.filtroFechaHasta!)
                  : 'Seleccionar fecha',
            ),
            onPressed: () async {
              final fecha = await showDatePicker(
                context: context,
                initialDate: provider.filtroFechaHasta ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context),
                    child: child!,
                  );
                },
              );
              if (fecha != null) {
                await provider.aplicarFiltroFechas(
                  provider.filtroFechaDesde,
                  fecha,
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    provider.limpiarFiltros();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
