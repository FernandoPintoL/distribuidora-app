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
import 'widgets/pedido_card.dart';
import 'widgets/filtros_avanzados_modal.dart';
import 'widgets/filtros_container.dart';
import 'helpers/dialogs_pedidos.dart';
import 'helpers/formatters.dart';
import 'helpers/filtro_logic.dart';

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

      // ✅ NUEVO: Cargar proformas PENDIENTES de ayer y hoy por defecto
      final hoy = DateTime.now();
      final ayer = hoy.subtract(const Duration(days: 1));

      setState(() {
        _filtroEstadoSeleccionado = 'PENDIENTE';
        _filtroFechaDesde = ayer;
        _filtroFechaHasta = hoy;
      });

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
      search: _searchController.text.isEmpty ? null : _searchController.text,
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
      search: _searchController.text.isEmpty ? null : _searchController.text,
      refresh: true,
    );
  }

  /// ✅ NUEVO: Descargar PDF de proformas con filtros
  /// Envía los filtros actuales al backend para obtener TODOS los resultados
  Future<void> _descargarPdfProformas() async {
    try {
      final apiService = ApiService();
      final printService = PrintService();

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando PDF con todos los resultados filtrados...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Enviar filtros al backend (no IDs, sino los filtros aplicados)
      final pdfBytes = await apiService.descargarPdfProformasConFiltros(
        busqueda: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        estado: _filtroEstadoSeleccionado,
        fechaDesde: _filtroFechaDesde,
        fechaHasta: _filtroFechaHasta,
        fechaVencimientoDesde: _filtroFechaVencimientoDesde,
        fechaVencimientoHasta: _filtroFechaVencimientoHasta,
        fechaEntregaSolicitadaDesde: _filtroFechaEntregaSolicitadaDesde,
        fechaEntregaSolicitadaHasta: _filtroFechaEntregaSolicitadaHasta,
        formato: 'A4',
      );

      // Abrir PDF con PrintService
      await printService.abrirPdfDesdeBytes(
        pdfBytes: pdfBytes,
        nombreArchivo: 'proformas_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

  void _aplicarFiltroEstado(String? estado) {
    // ✅ ACTUALIZADO: Ahora acepta código String en lugar de enum EstadoPedido
    setState(() {
      _filtroEstadoSeleccionado = estado;
    });
    // ✅ NUEVO: Limpiar datos anteriores y recargar con nuevo estado
    context.read<PedidoProvider>().aplicarFiltroEstado(estado);
    _cargarPedidos();
  }

  /// ✅ NUEVO: Mostrar modal de filtros avanzados (fechas)
  void _mostrarModalFiltrosAvanzados() {
    mostrarFiltrosAvanzadosModal(
      context,
      filtroFechaDesde: _filtroFechaDesde,
      filtroFechaHasta: _filtroFechaHasta,
      filtroFechaVencimientoDesde: _filtroFechaVencimientoDesde,
      filtroFechaVencimientoHasta: _filtroFechaVencimientoHasta,
      filtroFechaEntregaSolicitadaDesde: _filtroFechaEntregaSolicitadaDesde,
      filtroFechaEntregaSolicitadaHasta: _filtroFechaEntregaSolicitadaHasta,
      onFechaDesdeChanged: (fecha) => setState(() => _filtroFechaDesde = fecha),
      onFechaHastaChanged: (fecha) => setState(() => _filtroFechaHasta = fecha),
      onFechaVencDesdeChanged: (fecha) =>
          setState(() => _filtroFechaVencimientoDesde = fecha),
      onFechaVencHastaChanged: (fecha) =>
          setState(() => _filtroFechaVencimientoHasta = fecha),
      onFechaEntregaDesdeChanged: (fecha) =>
          setState(() => _filtroFechaEntregaSolicitadaDesde = fecha),
      onFechaEntregaHastaChanged: (fecha) =>
          setState(() => _filtroFechaEntregaSolicitadaHasta = fecha),
      onLimpiar: () {
        setState(() {
          _filtroFechaDesde = null;
          _filtroFechaHasta = null;
          _filtroFechaVencimientoDesde = null;
          _filtroFechaVencimientoHasta = null;
          _filtroFechaEntregaSolicitadaDesde = null;
          _filtroFechaEntregaSolicitadaHasta = null;
        });
      },
      onAplicar: () {
        // ✅ NUEVO: Cargar pedidos mostrando indicador de carga
        _cargarPedidos();
      },
      buildDateFilterGroup: FilterContainers.buildDateFilterGroupWithReset,
    );
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
      resizeToAvoidBottomInset:
          false, // ✅ NUEVO: Prevenir overflow cuando el teclado se abre
      appBar: CustomGradientAppBar(
        title: 'Mi Historial de Pedidos',
        customGradient: AppGradients.getRoleGradient('cliente'),
        actions: [
          // ✅ NUEVO: Botón de impresión/descarga de PDF
          /*Consumer<PedidoProvider>(
            builder: (context, pedidoProvider, _) {
              return IconButton(
                icon: const Icon(Icons.print),
                onPressed: pedidoProvider.pedidos.isEmpty
                    ? null
                    : _descargarPdfProformas,
                tooltip: 'Descargar PDF',
              );
            },
          ),*/
          // ✅ NUEVO: Botón para filtros avanzados (fechas)
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _mostrarModalFiltrosAvanzados,
            tooltip: 'Filtros avanzados (fechas)',
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
                                    final pedidoProvider = context
                                        .read<PedidoProvider>();
                                    pedidoProvider.aplicarBusquedaCliente(
                                      query.isEmpty ? null : query,
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar ID, número, nombre o código cliente...',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: colorScheme.primary,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                              });
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
                              ),
                              const SizedBox(width: 8),
                              // ✅ NUEVO: Botón para ejecutar búsqueda
                              ElevatedButton.icon(
                                onPressed: () {
                                  final pedidoProvider = context
                                      .read<PedidoProvider>();
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
                // 2️⃣ FILTROS DINÁMICOS - Independiente del listado
                // ============================================================
                FilterContainers.buildDynamicFilterContainer(
                  context,
                  colorScheme,
                  isDark,
                  _filtroEstadoSeleccionado,
                  (estado) => _aplicarFiltroEstado(estado),
                ),

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
                // ✅ NUEVO: Estado de carga (muestra incluso si hay datos anteriores)
                if (pedidoProvider.isLoading) {
                  // Detectar si hay filtros activos
                  final tieneFilTros =
                      _filtroEstadoSeleccionado != null ||
                      _searchController.text.isNotEmpty ||
                      _filtroFechaDesde != null ||
                      _filtroFechaHasta != null ||
                      _filtroFechaVencimientoDesde != null ||
                      _filtroFechaVencimientoHasta != null ||
                      _filtroFechaEntregaSolicitadaDesde != null ||
                      _filtroFechaEntregaSolicitadaHasta != null;

                  // Si hay datos anteriores, mostrar overlay de carga
                  if (pedidoProvider.pedidos.isNotEmpty) {
                    return Stack(
                      children: [
                        // Listado anterior deshabilitado
                        Opacity(
                          opacity: 0.5,
                          child: IgnorePointer(
                            child: RefreshIndicator(
                              onRefresh: _onRefresh,
                              color: colorScheme.primary,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                children: [
                                  // Resumen de resultados
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${pedidoProvider.pedidos.length} resultado${pedidoProvider.pedidos.length != 1 ? 's' : ''} encontrado${pedidoProvider.pedidos.length != 1 ? 's' : ''}',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  // Lista
                                  ...pedidoProvider.pedidos
                                      .take(3)
                                      .map(
                                        (pedido) => _PedidoCard(
                                          pedido: pedido,
                                          onTap: () {},
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Overlay de carga
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    tieneFilTros
                                        ? '🔍 Cargando con filtros...'
                                        : '📋 Cargando estado...',
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Por favor espera...',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(color: colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Si no hay datos, mostrar pantalla completa de carga
                  final mensajeCarga = tieneFilTros
                      ? '🔍 Buscando pedidos con filtros...'
                      : '📋 Cargando pedidos...';

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Indicador de carga animado
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            mensajeCarga,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor espera...',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
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
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // ✅ NUEVO: Resumen de resultados
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${pedidoProvider.pedidos.length} de ${pedidoProvider.totalItems} resultado${pedidoProvider.totalItems != 1 ? 's' : ''}',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Mostrar indicador si hay más páginas
                            if (pedidoProvider.hasMorePages)
                              Chip(
                                label: const Text('Hay más'),
                                backgroundColor: colorScheme.primaryContainer,
                                labelStyle: AppTextStyles.labelSmall(context).copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Lista de pedidos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            pedidoProvider.pedidos.length +
                            (pedidoProvider.isLoadingMore || !pedidoProvider.hasMorePages ? 1 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        itemBuilder: (context, index) {
                          // Elemento final: carga o fin de lista
                          if (index == pedidoProvider.pedidos.length) {
                            // Indicador de carga
                            if (pedidoProvider.isLoadingMore) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Cargando más pedidos...',
                                        style: context.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Mensaje de fin de lista
                            else {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.done_all,
                                        color: colorScheme.outline.withOpacity(0.5),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No hay más proformas',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.outline.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
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
                    ],
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
  Future<void> _handlePrintProforma(
    String action,
    String url,
    String numero,
  ) async {
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
      final esProforma = [
        'PENDIENTE',
        'APROBADA',
        'CONVERTIDA',
        'RECHAZADA',
        'VENCIDA',
      ].contains(_filtroEstadoSeleccionado?.toUpperCase());

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

    // Detectar si hay filtros activos
    final tieneFilTros =
        _filtroEstadoSeleccionado != null ||
        _searchController.text.isNotEmpty ||
        _filtroFechaDesde != null ||
        _filtroFechaHasta != null ||
        _filtroFechaVencimientoDesde != null ||
        _filtroFechaVencimientoHasta != null ||
        _filtroFechaEntregaSolicitadaDesde != null ||
        _filtroFechaEntregaSolicitadaHasta != null;

    // Construir descripción de filtros activos
    final filtrosActivos = <String>[];
    if (_searchController.text.isNotEmpty) {
      filtrosActivos.add('búsqueda: "${_searchController.text}"');
    }
    if (_filtroEstadoSeleccionado != null) {
      filtrosActivos.add('estado: $_filtroEstadoSeleccionado');
    }
    if (_filtroFechaDesde != null || _filtroFechaHasta != null) {
      final desde = _filtroFechaDesde?.toString().split(' ')[0] ?? '...';
      final hasta = _filtroFechaHasta?.toString().split(' ')[0] ?? '...';
      filtrosActivos.add('fechas: $desde a $hasta');
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tieneFilTros ? Icons.search_off : Icons.receipt_long_outlined,
                size: 80,
                color: isDark
                    ? colorScheme.onSurface.withOpacity(0.3)
                    : colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                tieneFilTros
                    ? '😔 No se encontraron pedidos'
                    : '📭 No tienes pedidos aún',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      tieneFilTros
                          ? 'Intenta ajustar tus filtros de búsqueda'
                          : 'Crea tu primer pedido desde el catálogo',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Mostrar filtros activos
                    if (tieneFilTros && filtrosActivos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros activos:',
                              style: context.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...filtrosActivos.map(
                              (filtro) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $filtro',
                                  style: context.textTheme.bodySmall,
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
              if (_filtroEstadoSeleccionado == null &&
                  _searchController.text.isEmpty) ...[
                const SizedBox(height: 24), // Reducido de 32
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/products'),
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
}

/// ✅ NUEVO: Helper para mostrar diálogo de anulación de proforma
void _mostrarDialogoAnularProforma(BuildContext context, Pedido proforma) {
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

            // ✅ No mostrar snackbar en caso de éxito
            // La notificación nativa será mostrada por el listener de WebSocket
            if (!result) {
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

  const _PedidoCard({required this.pedido, required this.onTap, this.onPrint});

  String _formatearFecha(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy', 'es_ES');
    return formatter.format(fecha);
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
                        // ✅ ID de la proforma (pequeño, arriba)
                        Text(
                          'Folio: ${pedido.id}',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // ✅ CLIENTE - Resaltado en negrita (principal)
                        Text(
                          pedido.cliente?.nombre ?? 'Cliente desconocido',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Número de pedido (secundario)
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '#${pedido.numero}',
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
                      final baseUrl = apiService
                          .getBaseUrl(); // http://localhost:8000/api
                      final impresionUrl =
                          '$baseUrl/proformas/${pedido.id}/imprimir?formato=TICKET_80&accion=$value';

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
                            Icon(
                              Icons.download,
                              size: 18,
                              color: colorScheme.primary,
                            ),
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
                            Icon(
                              Icons.preview,
                              size: 18,
                              color: colorScheme.primary,
                            ),
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
                            Icon(
                              Icons.share,
                              size: 18,
                              color: colorScheme.primary,
                            ),
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
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
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

              // ✅ NUEVO 2026-02-27: Estados de la venta convertida
              if (pedido.venta != null) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  '📋 Estados de Venta Convertida',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Estado del Documento
                if (pedido.venta!.estadoDocumento != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _hexToColor(pedido.venta!.estadoDocumento!.color)
                          .withOpacity(0.15),
                      border: Border.all(
                        color: _hexToColor(pedido.venta!.estadoDocumento!.color),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '📄',
                          style: context.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Documento',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                pedido.venta!.estadoDocumento!.nombre,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: _hexToColor(
                                      pedido.venta!.estadoDocumento!.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Estado Logístico
                if (pedido.venta!.estadoLogistica != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _hexToColor(pedido.venta!.estadoLogistica!.color)
                          .withOpacity(0.15),
                      border: Border.all(
                        color: _hexToColor(pedido.venta!.estadoLogistica!.color),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🚚',
                          style: context.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logística',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                pedido.venta!.estadoLogistica!.nombre,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: _hexToColor(
                                      pedido.venta!.estadoLogistica!.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // ✅ NUEVO 2026-02-27: Motivo de anulación si está anulada
                if (pedido.venta!.estadoDocumento?.codigo == 'ANULADA' &&
                    pedido.venta!.observaciones != null &&
                    pedido.venta!.observaciones!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
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
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de Anulación',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pedido.venta!.observaciones!,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                // Confirmaciones de Entrega
                if (pedido.venta!.confirmacionesEntrega.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Confirmaciones de Entrega',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pedido.venta!.confirmacionesEntrega.map((confirmacion) {
                    final isConfirmado = confirmacion.estado == 'CONFIRMADO' ||
                        confirmacion.estado == 'ENTREGADO';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isConfirmado
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: isConfirmado
                              ? Colors.green.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isConfirmado ? '✅' : '⏳',
                            style: context.textTheme.labelMedium,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${confirmacion.chofer ?? 'Chofer'} → ${confirmacion.cliente ?? 'Cliente'}',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (confirmacion.fecha != null)
                                  Text(
                                    DateFormat('dd/MM/yy HH:mm')
                                        .format(confirmacion.fecha!),
                                    style: AppTextStyles.labelSmall(context).copyWith(
                                      color:
                                          colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],

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
                                  style: context.textTheme.labelSmall?.copyWith(
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
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
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

                            final carritoProvider = context
                                .read<CarritoProvider>();
                            final success = await carritoProvider
                                .cargarProformaEnCarrito(pedido);

                            // Cerrar diálogo de loading
                            if (context.mounted) {
                              Navigator.pop(context);

                              if (success) {
                                // ✅ ACTUALIZADO: Navegar a /products con carrito cargado para editar
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/products',
                                  (route) => route.isFirst,
                                );
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
