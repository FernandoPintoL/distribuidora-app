import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../extensions/theme_extension.dart';
import '../../services/print_service.dart';
import 'widgets/filtros_avanzados_modal.dart';
import 'widgets/filtros_container.dart';
import 'widgets/pedido_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_state.dart';

/// âœ… REFACTORIZADO: Antes era solo "Proformas", ahora es "Mis Pedidos" unificado
/// Muestra todo el ciclo: Proforma â†’ Venta â†’ LogÃ­stica
class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _filtroEstadoSeleccionado;
  Timer? _debounceTimer;
  bool _isSearchExpanded = false;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;

  // âœ… NUEVO: Filtros especÃ­ficos para fechas de vencimiento y entrega
  DateTime? _filtroFechaVencimientoDesde;
  DateTime? _filtroFechaVencimientoHasta;
  DateTime? _filtroFechaEntregaSolicitadaDesde;
  DateTime? _filtroFechaEntregaSolicitadaHasta;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // âœ… NUEVO: Registrar observer para detectar cambios de ciclo de vida
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar estados y estadÃ­sticas dinÃ¡micamente
      final estadosProvider = context.read<EstadosProvider>();
      estadosProvider.loadEstadosYEstadisticas();

      // âœ… ACTUALIZADO: Cargar pedidos con fecha_entrega_solicitada=hoy SIN filtro de estado
      // Esto muestra todos los estados para hoy
      _inicializarFiltrosYCargar();
    });
  }

  /// âœ… NUEVO: MÃ©todo para inicializar filtros y cargar datos
  void _inicializarFiltrosYCargar() {
    final hoy = DateTime.now();

    setState(() {
      // NO filtrar por estado - dejar null para mostrar todos
      _filtroEstadoSeleccionado = null;
      // âœ… CAMBIO: Usar fecha de entrega solicitada en lugar de fecha de creaciÃ³n
      _filtroFechaEntregaSolicitadaDesde = hoy;
      _filtroFechaEntregaSolicitadaHasta = hoy;
    });

    // Sincronizar el filtro local con el filtro del provider
    final pedidoProvider = context.read<PedidoProvider>();
    if (pedidoProvider.filtroEstado != null) {
      setState(() {
        _filtroEstadoSeleccionado = pedidoProvider.filtroEstado;
      });
    }
    _cargarPedidos();
  }

  /// âœ… NUEVO: Detectar cuando la app vuelve a foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App volviÃ³ a foreground - recargar datos
      debugPrint('âœ… [PEDIDOS] App reanudada, recargando pedidos...');
      _inicializarFiltrosYCargar();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    // âœ… NUEVO: Remover observer
    WidgetsBinding.instance.removeObserver(this);
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
      // âœ… CAMBIADO: De 'busqueda' a 'cliente' para buscar por nombre, telÃ©fono o NIT
      search: _searchController.text.isEmpty ? null : _searchController.text,
      refresh: true,
    );
  }

  void _aplicarFiltroEstado(String? estado) {
    // âœ… ACTUALIZADO: Ahora acepta cÃ³digo String en lugar de enum EstadoPedido
    setState(() {
      _filtroEstadoSeleccionado = estado;
    });
    // âœ… NUEVO: Limpiar datos anteriores y recargar con nuevo estado
    context.read<PedidoProvider>().aplicarFiltroEstado(estado);
    _cargarPedidos();
  }

  /// âœ… NUEVO: Mostrar modal de filtros avanzados (fechas)
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
        // âœ… NUEVO: Cargar pedidos mostrando indicador de carga
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
          false, // âœ… NUEVO: Prevenir overflow cuando el teclado se abre
      appBar: CustomGradientAppBar(
        title: 'Mi Historial de Pedidos Cliente',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _mostrarModalFiltrosAvanzados,
            tooltip: 'Filtros avanzados (fechas)',
          ),
          // âœ… NUEVO: BotÃ³n de recarga
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
            tooltip: 'Recargar pedidos',
          ),
          // Icono de bÃºsqueda que expande el campo
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
            tooltip: _isSearchExpanded ? 'Cerrar bÃºsqueda' : 'Buscar',
          ),
        ],
      ),
      body: Column(
        children: [
          // NUEVO: Envolver filtros en SingleChildScrollView para que sean scrollables cuando el teclado se abre
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ============================================================
                // 1ï¸âƒ£ BÃšSQUEDA - Independiente
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
                                  // âœ… CAMBIO: De onChanged a onSubmitted (Enter key o botÃ³n)
                                  onSubmitted: (query) {
                                    final pedidoProvider = context
                                        .read<PedidoProvider>();
                                    pedidoProvider.aplicarBusquedaCliente(
                                      query.isEmpty ? null : query,
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar ID, número, nombre o codigo cliente...',
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
                              // âœ… NUEVO: BotÃ³n para ejecutar bÃºsqueda
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
                // Filtros de estados de proformas - Independiente del listado
                // ============================================================
                FilterContainers.buildDynamicFilterContainer(
                  context,
                  colorScheme,
                  isDark,
                  _filtroEstadoSeleccionado,
                  (estado) => _aplicarFiltroEstado(estado),
                  _limpiarBusquedaYFiltros,
                ),
              ],
            ),
          ),

          // ============================================================
          // 4 LISTADO DE PEDIDOS - Dentro del Consumer
          // ============================================================
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, pedidoProvider, _) {
                // âœ… NUEVO: Estado de carga (muestra incluso si hay datos anteriores)
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
                                children: [
                                  // Resumen de resultados
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.secondary
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${pedidoProvider.pedidos.length} resultado${pedidoProvider.pedidos.length != 1 ? 's' : ''} encontrado${pedidoProvider.pedidos.length != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Lista
                                  ...pedidoProvider.pedidos
                                      .take(3)
                                      .map(
                                        (pedido) => PedidoCard(
                                          pedido: pedido,
                                          onTap: () {
                                            // Si la proforma ya fue convertida a venta, ir a venta-detalle
                                            if (pedido.esVenta &&
                                                pedido.ventaId != null) {
                                              Navigator.pushNamed(
                                                context,
                                                '/venta-detalle',
                                                arguments: pedido.ventaId,
                                              );
                                            } else {
                                              // Si no está convertida, ir a pedido-detalle
                                              Navigator.pushNamed(
                                                context,
                                                '/pedido-detalle',
                                                arguments: pedido.id,
                                              );
                                            }
                                          },
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
                                      color: colorScheme.secondary,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    tieneFilTros
                                        ? 'Cargando con filtros...'
                                        : 'Cargando estado...',
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Por favor espera...',
                                    style: TextStyle(
                                      color: colorScheme.outline,
                                    ),
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
                      ? 'Buscando pedidos con filtros...'
                      : 'Cargando pedidos...';

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
                              color: colorScheme.secondary,
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            mensajeCarga,
                            style: TextStyle(color: colorScheme.secondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor espera...',
                            style: TextStyle(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Estado de error
                if (pedidoProvider.errorMessage != null &&
                    pedidoProvider.pedidos.isEmpty) {
                  return ErrorState(
                    error: pedidoProvider.errorMessage!,
                    onReintentar: _cargarPedidos,
                  );
                }

                // Estado vacío
                if (pedidoProvider.pedidos.isEmpty) {
                  final tieneFilTros =
                      _filtroEstadoSeleccionado != null ||
                      _searchController.text.isNotEmpty ||
                      _filtroFechaDesde != null ||
                      _filtroFechaHasta != null ||
                      _filtroFechaVencimientoDesde != null ||
                      _filtroFechaVencimientoHasta != null ||
                      _filtroFechaEntregaSolicitadaDesde != null ||
                      _filtroFechaEntregaSolicitadaHasta != null;

                  final filtrosActivos = <String>[];
                  if (_searchController.text.isNotEmpty) {
                    filtrosActivos.add('búsqueda: "${_searchController.text}"');
                  }
                  if (_filtroEstadoSeleccionado != null) {
                    filtrosActivos.add('estado: $_filtroEstadoSeleccionado');
                  }
                  if (_filtroFechaDesde != null || _filtroFechaHasta != null) {
                    final desde =
                        _filtroFechaDesde?.toString().split(' ')[0] ?? '...';
                    final hasta =
                        _filtroFechaHasta?.toString().split(' ')[0] ?? '...';
                    filtrosActivos.add('fechas: $desde a $hasta');
                  }

                  return EmptyState(
                    tieneFilTros: tieneFilTros,
                    filtrosActivos: filtrosActivos,
                    onVerProductos: () =>
                        Navigator.pushNamed(context, '/products'),
                  );
                }

                // Lista de pedidos
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        pedidoProvider.pedidos.length +
                        (pedidoProvider.isLoadingMore ||
                                !pedidoProvider.hasMorePages
                            ? 1
                            : 0),
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
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                    ),
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
                                    'No hay más pedidos',
                                    style: TextStyle(
                                      color: colorScheme.outline.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }

                      final pedido = pedidoProvider.pedidos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: PedidoCard(
                          pedido: pedido,
                          onTap: () {
                            // Si la proforma ya fue convertida a venta, ir a venta-detalle
                            if (pedido.esVenta && pedido.ventaId != null) {
                              Navigator.pushNamed(
                                context,
                                '/venta-detalle',
                                arguments: pedido.ventaId,
                              );
                            } else {
                              // Si no está convertida, ir a pedido-detalle
                              Navigator.pushNamed(
                                context,
                                '/pedido-detalle',
                                arguments: pedido.id,
                              );
                            }
                          },
                          onPrint: _handlePrintProforma,
                        ),
                      );
                      // return Text("no se que esta pasando");
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

  /// Manejar acciones de impresiÃ³n de proforma con PrintService
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
          // Descargar PDF - usa PrintService para manejo completo con autenticaciÃ³n
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

        case 'imagen':
          // ðŸ–¼ï¸ NUEVO: Descargar como imagen y mostrar diÃ¡logo de compartir
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Descargando imagen de proforma...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }

          final nombreArchivo =
              'proforma_${numero}_${DateTime.now().millisecondsSinceEpoch}.jpeg';
          final filePath = await printService.downloadImage(
            imageUrl: url,
            nombreArchivo: nombreArchivo,
            showShareDialog: true, // Mostrar diÃ¡logo de compartir
          );

          if (filePath == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo descargar la imagen'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (filePath != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âœ… Imagen lista para compartir'),
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
            'ImpresiÃ³n de proforma $numero: $url',
            subject: 'Proforma $numero',
          );
          break;
      }
    } catch (e) {
      debugPrint('Error en operaciÃ³n de impresiÃ³n: $e');
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
}
