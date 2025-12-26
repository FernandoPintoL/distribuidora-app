import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import 'package:intl/intl.dart';

class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  EstadoPedido? _filtroEstadoSeleccionado;
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sincronizar el filtro local con el filtro del provider
      final pedidoProvider = context.read<PedidoProvider>();
      if (pedidoProvider.filtroEstado != null) {
        setState(() {
          _filtroEstadoSeleccionado = pedidoProvider.filtroEstado;
        });
      }
      _cargarPedidos();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
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
      busqueda: _searchController.text.isEmpty ? null : _searchController.text,
      refresh: true,
    );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final pedidoProvider = context.read<PedidoProvider>();
      pedidoProvider.aplicarBusqueda(query.isEmpty ? null : query);
    });
  }

  void _aplicarFiltroEstado(EstadoPedido? estado) {
    setState(() {
      _filtroEstadoSeleccionado = estado;
    });
    context.read<PedidoProvider>().aplicarFiltroEstado(estado);
  }

  void _limpiarBusquedaYFiltros() {
    _searchController.clear();
    setState(() {
      _filtroEstadoSeleccionado = null;
      _isSearchExpanded = false;
    });
    context.read<PedidoProvider>().limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mis Pedidos',
        customGradient: AppGradients.getRoleGradient('cliente'),
        actions: [
          // Icono de búsqueda que expande el campo
          IconButton(
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  context.read<PedidoProvider>().aplicarBusqueda(null);
                }
              });
            },
            tooltip: _isSearchExpanded ? 'Cerrar búsqueda' : 'Buscar',
          ),
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, _) {
          // Estado de carga inicial
          if (pedidoProvider.isLoading && pedidoProvider.pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando pedidos...',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
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

          // Lista de pedidos con filtros
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: colorScheme.primary,
            child: Column(
              children: [
                // Barra de búsqueda expandible
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isSearchExpanded ? 60 : 0,
                  child: _isSearchExpanded
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surface
                                : colorScheme.primary.withOpacity(0.05),
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Buscar por número de proforma...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? colorScheme.surfaceContainerHighest
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Chips de filtro rápido
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Todos',
                          isSelected: _filtroEstadoSeleccionado == null,
                          onTap: () => _aplicarFiltroEstado(null),
                          icon: Icons.list_alt,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Pendientes',
                          isSelected:
                              _filtroEstadoSeleccionado ==
                              EstadoPedido.PENDIENTE,
                          onTap: () =>
                              _aplicarFiltroEstado(EstadoPedido.PENDIENTE),
                          icon: Icons.hourglass_empty,
                          color: EstadoInfo.getInfo(
                            EstadoPedido.PENDIENTE,
                          ).color,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Aprobadas',
                          isSelected:
                              _filtroEstadoSeleccionado ==
                              EstadoPedido.APROBADA,
                          onTap: () =>
                              _aplicarFiltroEstado(EstadoPedido.APROBADA),
                          icon: Icons.check_circle_outline,
                          color: EstadoInfo.getInfo(
                            EstadoPedido.APROBADA,
                          ).color,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'En Ruta',
                          isSelected:
                              _filtroEstadoSeleccionado == EstadoPedido.EN_RUTA,
                          onTap: () =>
                              _aplicarFiltroEstado(EstadoPedido.EN_RUTA),
                          icon: Icons.local_shipping,
                          color: EstadoInfo.getInfo(EstadoPedido.EN_RUTA).color,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Entregados',
                          isSelected:
                              _filtroEstadoSeleccionado ==
                              EstadoPedido.ENTREGADO,
                          onTap: () =>
                              _aplicarFiltroEstado(EstadoPedido.ENTREGADO),
                          icon: Icons.check_circle,
                          color: EstadoInfo.getInfo(
                            EstadoPedido.ENTREGADO,
                          ).color,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Rechazadas',
                          isSelected:
                              _filtroEstadoSeleccionado ==
                              EstadoPedido.RECHAZADA,
                          onTap: () =>
                              _aplicarFiltroEstado(EstadoPedido.RECHAZADA),
                          icon: Icons.cancel,
                          color: EstadoInfo.getInfo(
                            EstadoPedido.RECHAZADA,
                          ).color,
                        ),
                      ],
                    ),
                  ),
                ),

                // Banner de filtro activo
                if (_filtroEstadoSeleccionado != null ||
                    (_searchController.text.isNotEmpty))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFiltroActivoText(),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _limpiarBusquedaYFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
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
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final chipColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor
                : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : colorScheme.onSurface),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFiltroActivoText() {
    final List<String> filtros = [];

    if (_searchController.text.isNotEmpty) {
      filtros.add('Búsqueda: "${_searchController.text}"');
    }

    if (_filtroEstadoSeleccionado != null) {
      filtros.add(
        'Estado: ${EstadoInfo.getInfo(_filtroEstadoSeleccionado!).nombre}',
      );
    }

    return filtros.join(' • ');
  }

  Widget _buildEmptyState() {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 120,
            color: isDark
                ? colorScheme.onSurface.withOpacity(0.3)
                : colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            _filtroEstadoSeleccionado != null ||
                    _searchController.text.isNotEmpty
                ? 'No se encontraron pedidos'
                : 'No tienes pedidos aún',
            style: context.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _filtroEstadoSeleccionado != null ||
                    _searchController.text.isNotEmpty
                ? 'Intenta con otros filtros de búsqueda'
                : 'Crea tu primer pedido desde el catálogo',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (_filtroEstadoSeleccionado == null &&
              _searchController.text.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/products'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Ver Productos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: colorScheme.error),
          const SizedBox(height: 24),
          Text(
            'Error al cargar pedidos',
            style: context.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _cargarPedidos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
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
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final estadoInfo = pedido.estadoInfo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 2 : 1,
      color: isDark ? colorScheme.surface : Colors.white,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.1),
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
                        Text(
                          'Proforma',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pedido.numero,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
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
                      color: estadoInfo.color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: estadoInfo.color.withOpacity(isDark ? 0.5 : 0.3),
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

              Divider(height: 24, color: colorScheme.outline.withOpacity(0.2)),

              // Información del pedido
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: context.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatearFecha(pedido.fechaCreacion),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
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
                    color: context.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pedido.cantidadItems} ${pedido.cantidadItems == 1 ? 'producto' : 'productos'}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
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
                      color: context.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pedido.direccionEntrega!.direccion,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
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
                  Text(
                    'Total',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Bs. ${pedido.total.toStringAsFixed(2)}',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A),
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
                    color: isDark
                        ? const Color(0xFFFB923C).withOpacity(0.15)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFFB923C).withOpacity(0.3)
                          : const Color(0xFFFED7AA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFFB923C)
                            : const Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reserva expira en ${pedido.reservaMasProximaAVencer?.tiempoRestanteFormateado ?? ''}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? const Color(0xFFFB923C)
                                : const Color(0xFFC2410C),
                            fontWeight: FontWeight.w500,
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
