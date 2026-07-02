import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../extensions/theme_extension.dart';
import '../../utils/date_picker_utils.dart';

/// Pantalla de listado de cuentas por cobrar
class CuentasPorCobrarListScreen extends StatefulWidget {
  const CuentasPorCobrarListScreen({super.key});

  @override
  State<CuentasPorCobrarListScreen> createState() =>
      _CuentasPorCobrarListScreenState();
}

class _CuentasPorCobrarListScreenState
    extends State<CuentasPorCobrarListScreen> {
  late CuentasPorCobrarProvider _provider;
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<CuentasPorCobrarProvider>();
      _provider.loadCuentas();
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
      _provider.loadMoreCuentas();
    }
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

  Color _getColorForCxCEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ANULADO':
        return Colors.red;
      case 'PARCIAL':
        return Colors.blue;
      case 'PAGADO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _onRefresh() async {
    await _provider.loadCuentas(
      estado: _provider.filtroEstado,
      busqueda: _provider.filtroBusqueda,
      fechaDesde: _provider.filtroFechaDesde,
      fechaHasta: _provider.filtroFechaHasta,
      soloVencidas: _provider.filtroSoloVencidas,
      refresh: true,
    );
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
        title: const Text('Cuentas por Cobrar'),
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
      body: Consumer<CuentasPorCobrarProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.cuentas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.cuentas.isEmpty) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Búsqueda
                SliverToBoxAdapter(child: _buildSearchBar(provider)),

                // Estadísticas rápidas
                SliverToBoxAdapter(child: _buildStatsBar(provider)),

                // Lista de cuentas o estado vacío
                if (provider.cuentas.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  _buildCuentasListSliver(provider),

                // Indicador de carga
                if (provider.isLoadingMore && provider.cuentas.isNotEmpty)
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

  Widget _buildSearchBar(CuentasPorCobrarProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        onSubmitted: (value) {
          provider.aplicarBusqueda(value.isEmpty ? null : value);
        },
        decoration: InputDecoration(
          hintText: 'Referencia, cliente o NIT...',
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(CuentasPorCobrarProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem(
              'Total',
              provider.totalCuentas.toString(),
              Icons.receipt_outlined,
              context.colorScheme.primary,
            ),
            _buildStatItem(
              'Pendientes',
              provider.cuentasPendientes.toString(),
              Icons.hourglass_empty_outlined,
              Colors.orange,
            ),
            _buildStatItem(
              'Vencidas',
              provider.cuentasVencidas.toString(),
              Icons.error_outline,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCuentasListSliver(CuentasPorCobrarProvider provider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cuenta = provider.cuentas[index];
        return _buildCuentaCard(cuenta);
      }, childCount: provider.cuentas.length),
    );
  }

  Widget _buildCuentaCard(CuentaPorCobrar cuenta) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final montoOriginal = cuenta.montoOriginal;
    final montoPagado = cuenta.montoPagado;
    final saldo = cuenta.saldoPendiente;
    final porcentaje = cuenta.porcentajePagado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/cuenta-por-cobrar-detalle',
            arguments: cuenta.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Referencia y Monto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Folio CxC: ${cuenta.id}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _getColorForCxCEstado(cuenta.estado),
                          ),
                        ),
                        if (cuenta.referenciaDocumento != null)
                          Text(
                            cuenta.referenciaDocumento ?? 'Sin referencia',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        if (cuenta.venta != null)
                          Text(
                            'Venta Folio #${cuenta.venta!.id}',
                            style: TextStyle(
                              color: _getColorForCxCEstado(cuenta.estado),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: 'Monto original',
                        child: Text(
                          'Bs. ${montoOriginal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _getColorForCxCEstado(cuenta.estado),
                          ),
                        ),
                      ),
                      // Fecha de Creación
                      if (cuenta.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Creado: ${DateFormat('dd/MM/yyyy HH:mm').format(cuenta.createdAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      _buildEstadoBadge(cuenta),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cliente
              if (cuenta.cliente != null)
                Text(
                  cuenta.cliente!.nombre,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _getColorForCxCEstado(cuenta.estado),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              if (cuenta.estado.toUpperCase() != 'ANULADO') ...[
                // Montos y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagado: Bs. ${montoPagado.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Saldo: Bs. ${saldo.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: saldo > 0 ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      porcentaje >= 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Vencimiento
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (cuenta.fechaVencimiento != null)
                      Text(
                        'Vence: ${DateFormat('dd/MMM').format(cuenta.fechaVencimiento!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cuenta.estaVencida
                              ? Colors.red
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (cuenta.diasVencido != null && cuenta.diasVencido! > 0)
                      Text(
                        'Vencida hace ${cuenta.diasVencido} días',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(CuentaPorCobrar cuenta) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (cuenta.estado.toUpperCase()) {
      case 'PAGADO':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        badgeText = 'Pagado';
        break;
      case 'ANULADO':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        badgeText = 'Anulado';
        break;
      case 'PARCIAL':
        badgeColor = Colors.orange;
        badgeIcon = Icons.schedule;
        badgeText = 'Parcial';
        break;
      case 'PENDIENTE':
      default:
        badgeColor = Colors.amber;
        badgeIcon = Icons.pending_actions;
        badgeText = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CuentasPorCobrarProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error al cargar', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Ocurrió un error inesperado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              provider.loadCuentas();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<CuentasPorCobrarProvider>(
      builder: (context, provider, _) {
        final hasFilters =
            _searchController.text.isNotEmpty ||
            provider.filtroEstado != null ||
            provider.filtroFechaDesde != null ||
            provider.filtroFechaHasta != null ||
            provider.filtroSoloVencidas;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin cuentas por cobrar',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters
                    ? 'No hay registros que coincidan con los filtros aplicados'
                    : 'No hay cuentas por cobrar registradas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
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
      },
    );
  }

  Widget _buildFiltrosModal() {
    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Text(
                      'Filtros Avanzados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Filtro por Estado
                    Text(
                      'Estado',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String?>(
                      segments: const [
                        ButtonSegment(label: Text('Todos'), value: null),
                        ButtonSegment(
                          label: Text('Pendiente'),
                          value: 'PENDIENTE',
                        ),
                        ButtonSegment(label: Text('Parcial'), value: 'PARCIAL'),
                        ButtonSegment(label: Text('Pagado'), value: 'PAGADO'),
                      ],
                      selected: {_provider.filtroEstado},
                      onSelectionChanged: (Set<String?> newSelection) {
                        setState(() {
                          _provider.aplicarFiltroEstado(newSelection.first);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro por Vencidas
                    CheckboxListTile(
                      title: const Text('Solo cuentas vencidas'),
                      value: _provider.filtroSoloVencidas,
                      onChanged: (value) {
                        setState(() {
                          _provider.aplicarFiltroVencidas(value ?? false);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro por Fechas
                    Text(
                      'Rango de Vencimiento',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date =
                                  await DatePickerUtils.showThemedDatePicker(
                                    context: context,
                                    initialDate:
                                        _provider.filtroFechaDesde ??
                                        DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                              if (date != null) {
                                setState(() {
                                  _provider.aplicarFiltroFechas(
                                    date,
                                    _provider.filtroFechaHasta,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _provider.filtroFechaDesde != null
                                  ? DateFormat(
                                      'dd/MM',
                                    ).format(_provider.filtroFechaDesde!)
                                  : 'Desde',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    _provider.filtroFechaHasta ??
                                    DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  _provider.aplicarFiltroFechas(
                                    _provider.filtroFechaDesde,
                                    date,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _provider.filtroFechaHasta != null
                                  ? DateFormat(
                                      'dd/MM',
                                    ).format(_provider.filtroFechaHasta!)
                                  : 'Hasta',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón Limpiar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _provider.limpiarFiltros();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar Filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
