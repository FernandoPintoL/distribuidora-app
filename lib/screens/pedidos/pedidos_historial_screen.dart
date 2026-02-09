import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../services/estados_helpers.dart';
import 'package:intl/intl.dart';

/// ✅ REFACTORIZADO: Antes era solo "Proformas", ahora es "Mis Pedidos" unificado
/// Muestra todo el ciclo: Proforma → Venta → Logística
class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _filtroEstadoSeleccionado;
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;
  bool _isFilterDateExpanded = false;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;

  // ✅ NUEVO: Filtros específicos para fechas de vencimiento y entrega
  DateTime? _filtroFechaVencimientoDesde;
  DateTime? _filtroFechaVencimientoHasta;
  DateTime? _filtroFechaEntregaSolicitadaDesde;
  DateTime? _filtroFechaEntregaSolicitadaHasta;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar estados y estadísticas dinámicamente
      final estadosProvider = context.read<EstadosProvider>();
      estadosProvider.loadEstadosYEstadisticas();

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
      // ✅ CAMBIADO: De 'busqueda' a 'cliente' para buscar por nombre, teléfono o NIT
      cliente: _searchController.text.isEmpty ? null : _searchController.text,
      refresh: true,
    );
  }

  /// ✅ MEJORADO: Helper para construir un grupo de filtro de fecha
  Widget _buildDateFilterGroup(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? desde,
    DateTime? hasta,
    Function(DateTime?) onDesdeChanged,
    Function(DateTime?) onHastaChanged,
    DateTime? minDate,
    DateTime? maxDate,
  ) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (desde != null || hasta != null)
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label del grupo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botones desde/hasta
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Desde
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: desde ?? DateTime.now(),
                    firstDate: minDate ?? DateTime(2020),
                    lastDate: maxDate ?? DateTime(2100),
                  );
                  if (fecha != null) {
                    onDesdeChanged(fecha);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: desde != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Desde',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desde != null
                            ? DateFormat('dd/MM').format(desde)
                            : '--',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: desde != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurface
                                          .withOpacity(0.6),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Separador
              Text(
                '→',
                style: TextStyle(
                  color: colorScheme.outline.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              // Botón Hasta
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: hasta ?? DateTime.now(),
                    firstDate: desde ?? minDate ?? DateTime(2020),
                    lastDate: maxDate ?? DateTime(2100),
                  );
                  if (fecha != null) {
                    onHastaChanged(fecha);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasta != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hasta',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasta != null ? DateFormat('dd/MM').format(hasta) : '--',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hasta != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurface
                                          .withOpacity(0.6),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir contenedor de filtro de fechas
  Widget _buildDateFilterContainer(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // ✅ MEJORADO: Grid de 3 columnas para los filtros
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // 1️⃣ FILTRO DE CREACIÓN
                _buildDateFilterGroup(
                  context,
                  'Fecha Creación',
                  Icons.calendar_today,
                  _filtroFechaDesde,
                  _filtroFechaHasta,
                  (fecha) =>
                      setState(() => _filtroFechaDesde = fecha),
                  (fecha) =>
                      setState(() => _filtroFechaHasta = fecha),
                  DateTime(2020),
                  DateTime.now(),
                ),

                // 2️⃣ FILTRO DE VENCIMIENTO
                _buildDateFilterGroup(
                  context,
                  'Fecha Vencimiento',
                  Icons.event_note,
                  _filtroFechaVencimientoDesde,
                  _filtroFechaVencimientoHasta,
                  (fecha) =>
                      setState(() => _filtroFechaVencimientoDesde = fecha),
                  (fecha) =>
                      setState(() => _filtroFechaVencimientoHasta = fecha),
                  DateTime(2020),
                  DateTime(2100),
                ),

                // 3️⃣ FILTRO DE ENTREGA SOLICITADA
                _buildDateFilterGroup(
                  context,
                  'Entrega Solicitada',
                  Icons.local_shipping,
                  _filtroFechaEntregaSolicitadaDesde,
                  _filtroFechaEntregaSolicitadaHasta,
                  (fecha) =>
                      setState(() => _filtroFechaEntregaSolicitadaDesde = fecha),
                  (fecha) =>
                      setState(() => _filtroFechaEntregaSolicitadaHasta = fecha),
                  DateTime(2020),
                  DateTime(2100),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botones de acción
            Row(
              children: [
                // Botón "Buscar"
                if (_filtroFechaDesde != null ||
                    _filtroFechaHasta != null ||
                    _filtroFechaVencimientoDesde != null ||
                    _filtroFechaVencimientoHasta != null ||
                    _filtroFechaEntregaSolicitadaDesde != null ||
                    _filtroFechaEntregaSolicitadaHasta != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PedidoProvider>().loadPedidos(
                              estado: context
                                  .read<PedidoProvider>()
                                  .filtroEstado,
                              fechaDesde: _filtroFechaDesde,
                              fechaHasta: _filtroFechaHasta,
                              cliente: context
                                  .read<PedidoProvider>()
                                  .filtroBusqueda,
                              fechaVencimientoDesde:
                                  _filtroFechaVencimientoDesde,
                              fechaVencimientoHasta:
                                  _filtroFechaVencimientoHasta,
                              fechaEntregaSolicitadaDesde:
                                  _filtroFechaEntregaSolicitadaDesde,
                              fechaEntregaSolicitadaHasta:
                                  _filtroFechaEntregaSolicitadaHasta,
                            );
                      },
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Botón "Limpiar"
                if (_filtroFechaDesde != null ||
                    _filtroFechaHasta != null ||
                    _filtroFechaVencimientoDesde != null ||
                    _filtroFechaVencimientoHasta != null ||
                    _filtroFechaEntregaSolicitadaDesde != null ||
                    _filtroFechaEntregaSolicitadaHasta != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filtroFechaDesde = null;
                        _filtroFechaHasta = null;
                        _filtroFechaVencimientoDesde = null;
                        _filtroFechaVencimientoHasta = null;
                        _filtroFechaEntregaSolicitadaDesde = null;
                        _filtroFechaEntregaSolicitadaHasta = null;
                      });
                      context.read<PedidoProvider>().loadPedidos();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construir contenedor de filtros dinámicos cargados desde EstadosProvider
  Widget _buildDynamicFilterContainer(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Consumer<EstadosProvider>(
      builder: (context, estadosProvider, _) {
        if (estadosProvider.isLoading && estadosProvider.estados.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        final states = estadosProvider.estados;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                _buildDynamicFilterChip(
                  context: context,
                  label: 'Todos',
                  codigo: null,
                  contador: estadosProvider.stats?.total ?? 0,
                  isSelected: _filtroEstadoSeleccionado == null,
                  onTap: () => _aplicarFiltroEstado(null),
                  icon: Icons.list_alt,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                ...states.map((estado) {
                  final contador = estadosProvider.getContadorEstado(estado.codigo);
                  final color = _hexToColor(estado.color);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDynamicFilterChip(
                      context: context,
                      label: estado.nombre,
                      codigo: estado.codigo,
                      contador: contador,
                      isSelected: _filtroEstadoSeleccionado == estado.codigo,
                      onTap: () => _aplicarFiltroEstado(estado.codigo),
                      icon: _getIconoParaEstado(estado.codigo),
                      color: color,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Obtener ícono según código de estado
  IconData _getIconoParaEstado(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'PENDIENTE':
        return Icons.hourglass_empty;
      case 'APROBADA':
        return Icons.check_circle_outline;
      case 'CONVERTIDA':
        return Icons.loop;
      case 'VENCIDA':
        return Icons.schedule;
      case 'RECHAZADA':
        return Icons.cancel;
      case 'PENDIENTE_ENVIO':
      case 'PENDIENTE_RETIRO':
        return Icons.inventory_2_outlined;
      case 'EN_TRANSITO':
        return Icons.local_shipping;
      case 'ENTREGADO':
      case 'ENTREGADA':
        return Icons.done_all;
      case 'PAGADO':
        return Icons.paid_outlined;
      default:
        return Icons.circle;
    }
  }

  /// Construir chip de filtro dinámico con contador
  Widget _buildDynamicFilterChip({
    required BuildContext context,
    required String label,
    required String? codigo,
    required int contador,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final chipColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : colorScheme.onSurface),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$contador',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _aplicarFiltroEstado(String? estado) {
    // ✅ ACTUALIZADO: Ahora acepta código String en lugar de enum EstadoPedido
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
      _isFilterDateExpanded = false;
      _filtroFechaDesde = null;
      _filtroFechaHasta = null;
      _filtroFechaVencimientoDesde = null;
      _filtroFechaVencimientoHasta = null;
      _filtroFechaEntregaSolicitadaDesde = null;
      _filtroFechaEntregaSolicitadaHasta = null;
    });
    context.read<PedidoProvider>().limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mi Historial de Pedidos',
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
      body: Column(
        children: [
          // ============================================================
          // 1️⃣ BÚSQUEDA - Independiente
          // ============================================================
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            // ✅ CAMBIO: De onChanged a onSubmitted (Enter key o botón)
                            onSubmitted: (query) {
                              final pedidoProvider =
                                  context.read<PedidoProvider>();
                              pedidoProvider.aplicarBusquedaCliente(
                                query.isEmpty ? null : query,
                              );
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por nombre, teléfono o NIT...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.primary,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                              filled: true,
                              fillColor: isDark
                                  ? colorScheme
                                      .surfaceContainerHighest
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ✅ NUEVO: Botón para ejecutar búsqueda
                        ElevatedButton.icon(
                          onPressed: () {
                            final pedidoProvider =
                                context.read<PedidoProvider>();
                            pedidoProvider.aplicarBusquedaCliente(
                              _searchController.text.isEmpty
                                  ? null
                                  : _searchController.text,
                            );
                          },
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Buscar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ============================================================
          // 2️⃣ FILTRO DE FECHAS - Independiente
          // ============================================================
          _buildDateFilterContainer(context, colorScheme, isDark),

          // ============================================================
          // 3️⃣ FILTROS DINÁMICOS - Independiente del listado
          // ============================================================
          _buildDynamicFilterContainer(context, colorScheme, isDark),

          // ============================================================
          // 3️⃣ BANNER DE FILTRO ACTIVO - Independiente
          // ============================================================
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

          // ============================================================
          // 4️⃣ LISTADO DE PEDIDOS - Dentro del Consumer
          // ============================================================
          Expanded(
            child: Consumer<PedidoProvider>(
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

                // Lista de pedidos
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: pedidoProvider.pedidos.length +
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  String _getFiltroActivoText() {
    final List<String> filtros = [];

    if (_searchController.text.isNotEmpty) {
      filtros.add('🔍 "${_searchController.text}"');
    }

    if (_filtroEstadoSeleccionado != null) {
      // Detectar si es estado de proforma o de venta/logística
      final esProforma = ['PENDIENTE', 'APROBADA', 'CONVERTIDA', 'RECHAZADA', 'VENCIDA']
          .contains(_filtroEstadoSeleccionado?.toUpperCase());

      final categoria = esProforma ? 'proforma' : 'venta_logistica';
      final icono = esProforma ? '📋' : '🚚';

      filtros.add(
        '$icono ${EstadosHelper.getEstadoLabel(categoria, _filtroEstadoSeleccionado!)}',
      );
    }

    if (_filtroFechaDesde != null || _filtroFechaHasta != null) {
      final desdeText = _filtroFechaDesde != null
          ? DateFormat('dd/MM').format(_filtroFechaDesde!)
          : '';
      final hastaText = _filtroFechaHasta != null
          ? DateFormat('dd/MM').format(_filtroFechaHasta!)
          : '';

      if (_filtroFechaDesde != null && _filtroFechaHasta != null) {
        filtros.add('📅 $desdeText - $hastaText');
      } else if (_filtroFechaDesde != null) {
        filtros.add('📅 Desde: $desdeText');
      } else if (_filtroFechaHasta != null) {
        filtros.add('📅 Hasta: $hastaText');
      }
    }

    return filtros.isEmpty ? 'Sin filtros aplicados' : filtros.join(' • ');
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

  /// ✅ HELPER: Convertir hex string (#RRGGBB) a Color
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

/// ✅ NUEVO: Helper para mostrar diálogo de anulación de proforma
void _mostrarDialogoAnularProforma(
  BuildContext context,
  Pedido proforma,
) {
  final TextEditingController motivoController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Anular Proforma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Estás seguro que deseas anular la proforma #${proforma.numero}?',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: motivoController,
            decoration: InputDecoration(
              hintText: 'Motivo de anulación (requerido)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.info_outlined),
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final motivo = motivoController.text.trim();

            if (motivo.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El motivo de anulación es requerido'),
                ),
              );
              return;
            }

            Navigator.pop(dialogContext);

            // ✅ NUEVO: Anular proforma
            final pedidoProvider = context.read<PedidoProvider>();
            final result = await pedidoProvider.anularProforma(
              proforma.id,
              motivo,
            );

            if (result) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Proforma #${proforma.numero} anulada exitosamente',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: ${pedidoProvider.errorMessage ?? "No se pudo anular la proforma"}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Anular'),
        ),
      ],
    ),
  );
}

/// ✅ REFACTORIZADA: Nueva card con Timeline unificado
/// Muestra: Proforma → Venta → Logística en paralelo
class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  String _formatearFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy', 'es_ES');
    return formatter.format(fecha);
  }

  String _formatearHora(DateTime fecha) {
    final formatter = DateFormat('HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  /// ✅ HELPER: Convertir hex string (#RRGGBB) a Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey;
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Widget para mostrar una línea de timeline con 3 estados posibles
  Widget _buildTimelineLine(
    BuildContext context,
    String titulo,
    String estado,
    String icono,
    Color color, {
    bool esUltimo = false,
  }) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono + línea vertical
        Column(
          children: [
            // Ícono del estado
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(icono, style: const TextStyle(fontSize: 18)),
              ),
            ),
            // Línea vertical (si no es el último)
            if (!esUltimo)
              Container(
                width: 2,
                height: 24,
                color: colorScheme.outline.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Información del estado
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la línea
                Text(
                  titulo,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                // Estado actual
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    estado,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

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
              // ═══════════════════════════════════════════════════════════════
              // 1️⃣ HEADER: Número, Cliente, Fecha
              // ═══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Número de pedido
                        Text(
                          pedido.numero,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Cliente
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pedido.cliente?.nombre ?? 'Cliente desconocido',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Monto total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bs. ${pedido.total.toStringAsFixed(2)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(pedido.fechaCreacion),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
              ),
              const SizedBox(height: 16),

              // ═══════════════════════════════════════════════════════════════
              // 2️⃣ TIMELINE: Proforma → Venta → Logística
              // ═══════════════════════════════════════════════════════════════
              Column(
                children: [
                  // 📋 PROFORMA
                  _buildTimelineLine(
                    context,
                    'Proforma',
                    pedido.estadoCodigo,
                    '📋',
                    _hexToColor(EstadosHelper.getEstadoColor(
                      'proforma',
                      pedido.estadoCodigo,
                    )),
                  ),
                  const SizedBox(height: 12),

                  // 💳 VENTA (Si ya se convirtió)
                  if (pedido.esVenta) ...[
                    _buildTimelineLine(
                      context,
                      'Venta',
                      'Convertida ✅',
                      '💳',
                      colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 🚚 LOGÍSTICA (Si tiene estado de envío)
                  if (pedido.tieneEstadoLogistico)
                    _buildTimelineLine(
                      context,
                      'Envío',
                      pedido.estadoNombre,
                      '🚚',
                      _hexToColor(EstadosHelper.getEstadoColor(
                        pedido.estadoCategoria,
                        pedido.estadoCodigo,
                      )),
                      esUltimo: true,
                    )
                  else
                    _buildTimelineLine(
                      context,
                      'Envío',
                      'Pendiente',
                      '📦',
                      colorScheme.outline.withOpacity(0.5),
                      esUltimo: true,
                    ),
                ],
              ),

              // ═══════════════════════════════════════════════════════════════
              // 3️⃣ INFORMACIÓN ADICIONAL
              // ═══════════════════════════════════════════════════════════════
              if (pedido.cantidadItems > 0 ||
                  pedido.direccionEntrega != null ||
                  pedido.tieneReservasProximasAVencer ||
                  pedido.fechaVencimiento != null ||
                  pedido.fechaEntregaSolicitada != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cantidad de productos
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pedido.cantidadItems} productos',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),

                      // Dirección de entrega
                      if (pedido.direccionEntrega != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pedido.direccionEntrega!.direccion,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ✅ NUEVO: Fecha de vencimiento
                      if (pedido.fechaVencimiento != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '📅 Vencimiento: ${_formatearFecha(pedido.fechaVencimiento!)}',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ✅ NUEVO: Fecha de entrega solicitada
                      if (pedido.fechaEntregaSolicitada != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '🚚 Entrega Solicitada: ${_formatearFecha(pedido.fechaEntregaSolicitada!)}',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Alerta de reserva próxima a vencer
                      if (pedido.tieneReservasProximasAVencer) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFB923C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: const Color(0xFFC2410C),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '⏰ Reserva expira ${pedido.reservaMasProximaAVencer?.tiempoRestanteFormateado ?? 'pronto'}',
                                  style:
                                      context.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFC2410C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ✅ NUEVO: Botones de acción (Editar y Anular)
              if ((pedido.estadoCodigo == 'PENDIENTE' ||
                      pedido.estadoCodigo == 'APROBADA') &&
                  pedido.estadoCategoria == 'proforma') ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Botón Editar (solo para PENDIENTE)
                    if (pedido.estadoCodigo == 'PENDIENTE')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // ✅ NUEVO: Mostrar loading mientras se cargan stocks
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (loadingContext) => const AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Cargando datos actualizados...'),
                                  ],
                                ),
                              ),
                            );

                            final carritoProvider = context.read<CarritoProvider>();
                            final success = await carritoProvider.cargarProformaEnCarrito(pedido);

                            // Cerrar diálogo de loading
                            if (context.mounted) {
                              Navigator.pop(context);

                              if (success) {
                                Navigator.pushNamed(context, '/carrito');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error: ${carritoProvider.errorMessage ?? "No se pudo cargar la proforma"}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    // Espaciador
                    if (pedido.estadoCodigo == 'PENDIENTE')
                      const SizedBox(width: 12),
                    // Botón Anular
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _mostrarDialogoAnularProforma(context, pedido);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Anular'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
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
}
