import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../services/estados_helpers.dart';
import '../../services/api_service.dart';
import '../../services/print_service.dart';
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
    await pedidoProvider.loadPedidos(
      estado: _filtroEstadoSeleccionado,
      cliente: _searchController.text.isEmpty ? null : _searchController.text,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      fechaVencimientoDesde: _filtroFechaVencimientoDesde,
      fechaVencimientoHasta: _filtroFechaVencimientoHasta,
      fechaEntregaSolicitadaDesde: _filtroFechaEntregaSolicitadaDesde,
      fechaEntregaSolicitadaHasta: _filtroFechaEntregaSolicitadaHasta,
    );
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

  /// ✅ NUEVO: Descargar PDF de proformas filtradas
  Future<void> _descargarPdfProformas() async {
    try {
      final pedidoProvider = context.read<PedidoProvider>();

      if (pedidoProvider.pedidos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay pedidos para descargar'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Obtener IDs de los pedidos actuales
      final proformaIds = pedidoProvider.pedidos
          .where((p) => p.proformaId != null)
          .map((p) => p.proformaId.toString())
          .toList();

      if (proformaIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay proformas para descargar'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Construir URL con IDs
      final idsParam = proformaIds.join(',');
      final apiService = ApiService();

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Descargar PDF
      await apiService.descargarPdfProformas(
        ids: idsParam,
        formato: 'A4',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF descargado exitosamente'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar PDF: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// ✅ MEJORADO: Construir contenedor de filtro de fechas con botones rápidos
  Widget _buildDateFilterContainer(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tieneFiltrosActivos = _filtroFechaDesde != null ||
        _filtroFechaHasta != null ||
        _filtroFechaVencimientoDesde != null ||
        _filtroFechaVencimientoHasta != null ||
        _filtroFechaEntregaSolicitadaDesde != null ||
        _filtroFechaEntregaSolicitadaHasta != null;

    return Container(
      width: double.infinity,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ HEADER: Toggle para mostrar/ocultar filtros
          InkWell(
            onTap: () => setState(() => _isFilterDateExpanded = !_isFilterDateExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isFilterDateExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.date_range,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrar por Fechas',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Badge de filtros activos
                  if (tieneFiltrosActivos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Activo',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO EXPANDIBLE
          if (_isFilterDateExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // ✅ BOTONES RÁPIDOS
                    _buildQuickDateButtons(context, colorScheme, isDark),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),

                    // ✅ FILTRO DE CREACIÓN
                    _buildDateFilterGroupWithReset(
                      context,
                      'Fecha Creación',
                      Icons.calendar_today,
                      _filtroFechaDesde,
                      _filtroFechaHasta,
                      (fecha) =>
                          setState(() => _filtroFechaDesde = fecha),
                      (fecha) =>
                          setState(() => _filtroFechaHasta = fecha),
                      () => setState(() {
                        _filtroFechaDesde = null;
                        _filtroFechaHasta = null;
                      }),
                      DateTime(2020),
                      DateTime.now(),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 12),

                    // ✅ FILTRO DE VENCIMIENTO
                    _buildDateFilterGroupWithReset(
                      context,
                      'Fecha Vencimiento',
                      Icons.event_note,
                      _filtroFechaVencimientoDesde,
                      _filtroFechaVencimientoHasta,
                      (fecha) =>
                          setState(() => _filtroFechaVencimientoDesde = fecha),
                      (fecha) =>
                          setState(() => _filtroFechaVencimientoHasta = fecha),
                      () => setState(() {
                        _filtroFechaVencimientoDesde = null;
                        _filtroFechaVencimientoHasta = null;
                      }),
                      DateTime(2020),
                      DateTime(2100),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 12),

                    // ✅ FILTRO DE ENTREGA SOLICITADA
                    _buildDateFilterGroupWithReset(
                      context,
                      'Entrega Solicitada',
                      Icons.local_shipping,
                      _filtroFechaEntregaSolicitadaDesde,
                      _filtroFechaEntregaSolicitadaHasta,
                      (fecha) =>
                          setState(() => _filtroFechaEntregaSolicitadaDesde = fecha),
                      (fecha) =>
                          setState(() => _filtroFechaEntregaSolicitadaHasta = fecha),
                      () => setState(() {
                        _filtroFechaEntregaSolicitadaDesde = null;
                        _filtroFechaEntregaSolicitadaHasta = null;
                      }),
                      DateTime(2020),
                      DateTime(2100),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 16),

                    // ✅ BOTONES DE ACCIÓN
                    Row(
                      children: [
                        if (tieneFiltrosActivos)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<PedidoProvider>().loadPedidos(
                                      estado: _filtroEstadoSeleccionado,
                                      fechaDesde: _filtroFechaDesde,
                                      fechaHasta: _filtroFechaHasta,
                                      cliente: _searchController.text.isEmpty ? null : _searchController.text,
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
                        if (tieneFiltrosActivos) const SizedBox(width: 8),
                        if (tieneFiltrosActivos)
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
                              context.read<PedidoProvider>().loadPedidos(
                                    estado: _filtroEstadoSeleccionado,
                                    cliente: _searchController.text.isEmpty ? null : _searchController.text,
                                  );
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Limpiar todo'),
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
            ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Botones rápidos para rangos comunes de fechas
  Widget _buildQuickDateButtons(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 7));
    final hace30Dias = hoy.subtract(const Duration(days: 30));
    final primerDiaDelMes =
        DateTime(hoy.year, hoy.month, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Accesos rápidos de fechas',
          style: context.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateButton(
              context,
              'Hoy',
              hoy,
              hoy,
              colorScheme,
              isDark,
            ),
            _buildQuickDateButton(
              context,
              'Últimos 7 días',
              hace7Dias,
              hoy,
              colorScheme,
              isDark,
            ),
            _buildQuickDateButton(
              context,
              'Últimos 30 días',
              hace30Dias,
              hoy,
              colorScheme,
              isDark,
            ),
            _buildQuickDateButton(
              context,
              'Este mes',
              primerDiaDelMes,
              hoy,
              colorScheme,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ NUEVO: Botón individual para rango rápido
  Widget _buildQuickDateButton(
    BuildContext context,
    String label,
    DateTime desde,
    DateTime hasta,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filtroFechaDesde = desde;
          _filtroFechaHasta = hasta;
          _filtroFechaVencimientoDesde = null;
          _filtroFechaVencimientoHasta = null;
          _filtroFechaEntregaSolicitadaDesde = null;
          _filtroFechaEntregaSolicitadaHasta = null;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        foregroundColor: colorScheme.primary,
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }

  /// ✅ MEJORADO: Grupo de filtro de fechas con botón de reset individual
  Widget _buildDateFilterGroupWithReset(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? desde,
    DateTime? hasta,
    Function(DateTime?) onDesdeChanged,
    Function(DateTime?) onHastaChanged,
    VoidCallback onReset,
    DateTime? minDate,
    DateTime? maxDate,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tieneFiltros = desde != null || hasta != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tieneFiltros
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label con reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  if (tieneFiltros) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Activo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              if (tieneFiltros)
                InkWell(
                  onTap: onReset,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colorScheme.error,
                    ),
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
              const SizedBox(width: 6),
              // Info de rango
              if (desde != null && hasta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${hasta!.difference(desde!).inDays + 1} días',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
      resizeToAvoidBottomInset: false, // ✅ NUEVO: Prevenir overflow cuando el teclado se abre
      appBar: CustomGradientAppBar(
        title: 'Mi Historial de Pedidos',
        customGradient: AppGradients.getRoleGradient('cliente'),
        actions: [
          // ✅ NUEVO: Botón de impresión/descarga de PDF
          Consumer<PedidoProvider>(
            builder: (context, pedidoProvider, _) {
              return IconButton(
                icon: const Icon(Icons.print),
                onPressed: pedidoProvider.pedidos.isEmpty
                    ? null
                    : _descargarPdfProformas,
                tooltip: 'Descargar PDF',
              );
            },
          ),
          // ✅ NUEVO: Botón de recarga
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
            tooltip: 'Recargar pedidos',
          ),
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
          // ✅ NUEVO: Envolver filtros en SingleChildScrollView para que sean scrollables cuando el teclado se abre
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando pedidos...',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
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
                        onPrint: _handlePrintProforma,
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

  /// Manejar acciones de impresión de proforma con PrintService
  Future<void> _handlePrintProforma(String action, String url, String numero) async {
    try {
      // Extraer ID de la proforma de la URL
      final regExp = RegExp(r'/proformas/(\d+)/');
      final match = regExp.firstMatch(url);
      if (match == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se pudo identificar la proforma'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }

      final proformaId = int.parse(match.group(1)!);
      final printService = PrintService();

      switch (action) {
        case 'download':
          // Descargar PDF - usa PrintService para manejo completo con autenticación
          final success = await printService.downloadDocument(
            documentoId: proformaId,
            documentType: PrintDocumentType.proforma,
            format: PrintFormat.ticket80,
          );

          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo descargar el PDF'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abriendo PDF...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case 'stream':
          // Ver en navegador - usar PrintService para preview
          final success = await printService.previewDocument(
            documentoId: proformaId,
            documentType: PrintDocumentType.proforma,
            format: PrintFormat.ticket80,
          );

          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir el navegador'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case 'compartir':
          // Compartir link
          await Share.share(
            'Impresión de proforma $numero: $url',
            subject: 'Proforma $numero',
          );
          break;
      }
    } catch (e) {
      debugPrint('Error en operación de impresión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
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

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80, // Reducido de 120
                color: isDark
                    ? colorScheme.onSurface.withOpacity(0.3)
                    : colorScheme.outline,
              ),
              const SizedBox(height: 16), // Reducido de 24
              Text(
                _filtroEstadoSeleccionado != null ||
                        _searchController.text.isNotEmpty
                    ? 'No se encontraron pedidos'
                    : 'No tienes pedidos aún',
                style: context.textTheme.titleMedium?.copyWith(
                  // Cambiado de headlineSmall
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // Reducido de 12
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _filtroEstadoSeleccionado != null ||
                          _searchController.text.isNotEmpty
                      ? 'Intenta con otros filtros de búsqueda'
                      : 'Crea tu primer pedido desde el catálogo',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_filtroEstadoSeleccionado == null &&
                  _searchController.text.isEmpty) ...[
                const SizedBox(height: 24), // Reducido de 32
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/products'),
                  icon: const Icon(Icons.shopping_bag, size: 18),
                  label: const Text('Ver Productos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70, // Reducido de 80
                color: colorScheme.error,
              ),
              const SizedBox(height: 16), // Reducido de 24
              Text(
                'Error al cargar pedidos',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(height: 24), // Reducido de 32
              ElevatedButton.icon(
                onPressed: _cargarPedidos,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  final Function(String action, String url, String numero)? onPrint;

  const _PedidoCard({
    required this.pedido,
    required this.onTap,
    this.onPrint,
  });

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
                  Expanded(
                    flex: 0,
                    child: Column(
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
                  ),
                  const SizedBox(width: 8),
                  // ✅ Botón de descargar/compartir impresión
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      // ✅ CORREGIDO: Usar ApiService para obtener baseUrl dinámicamente
                      final apiService = ApiService();
                      final baseUrl = apiService.getBaseUrl(); // http://localhost:8000/api
                      final impresionUrl = '$baseUrl/proformas/${pedido.id}/imprimir?formato=TICKET_80&accion=$value';

                      if (onPrint != null) {
                        onPrint!(value, impresionUrl, pedido.numero);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Descargar PDF'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'stream',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.preview, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Ver en navegador'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'compartir',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Compartir'),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    padding: EdgeInsets.zero,
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
              // 2️⃣ ESTADO ACTUAL (Simple)
              // ═══════════════════════════════════════════════════════════════
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Estado principal de la Proforma/Venta
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _hexToColor(
                        EstadosHelper.getEstadoColor(
                          pedido.estadoCategoria,
                          pedido.estadoCodigo,
                        ),
                      ).withOpacity(0.15),
                      border: Border.all(
                        color: _hexToColor(
                          EstadosHelper.getEstadoColor(
                            pedido.estadoCategoria,
                            pedido.estadoCodigo,
                          ),
                        ),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      pedido.esVenta ? '✅ Convertida' : pedido.estadoCodigo,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: _hexToColor(
                          EstadosHelper.getEstadoColor(
                            pedido.estadoCategoria,
                            pedido.estadoCodigo,
                          ),
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Número de venta si está convertida
                  if (pedido.esVenta && pedido.ventaNumero != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '🛍️ ${pedido.ventaNumero}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Estado logístico si existe
                  if (pedido.tieneEstadoLogistico)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _hexToColor(
                          EstadosHelper.getEstadoColor(
                            pedido.estadoCategoria,
                            pedido.estadoCodigo,
                          ),
                        ).withOpacity(0.15),
                        border: Border.all(
                          color: _hexToColor(
                            EstadosHelper.getEstadoColor(
                              pedido.estadoCategoria,
                              pedido.estadoCodigo,
                            ),
                          ),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '🚚 ${pedido.estadoNombre}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: _hexToColor(
                            EstadosHelper.getEstadoColor(
                              pedido.estadoCategoria,
                              pedido.estadoCodigo,
                            ),
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
