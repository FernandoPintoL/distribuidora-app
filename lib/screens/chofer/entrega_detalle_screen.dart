import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
// ✅ NUEVO: Widgets de pantallas
import 'entrega_detalle/widgets/tab_general_widget.dart';
import 'entrega_detalle/widgets/tab_productos_widget.dart';
import 'entrega_detalle/widgets/tab_ventas_widget.dart';
import 'entrega_detalle/widgets/botones_accion.dart';
import 'entrega_detalle/dialogs/marcar_llegada_dialog.dart';
import 'entrega_detalle/dialogs/iniciar_entrega_dialog.dart';
import 'entrega_detalle/dialogs/marcar_entregada_dialog.dart';
import 'entrega_detalle/dialogs/reportar_novedad_dialog.dart';
import 'entrega_detalle/dialogs/confirmar_carga_lista_dialog.dart';
import 'entrega_detalle/dialogs/entregas_terminadas_dialog.dart';

class EntregaDetalleScreen extends StatefulWidget {
  final int entregaId;

  const EntregaDetalleScreen({Key? key, required this.entregaId})
    : super(key: key);

  @override
  State<EntregaDetalleScreen> createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late TabController _tabController;
  bool _hasInitialized = false;

  final GlobalKey _generalKey = GlobalKey();
  final GlobalKey _productosKey = GlobalKey();
  final GlobalKey _ventasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        debugPrint('🔄 [initState] Cargando entrega #${widget.entregaId}');
        context.read<EntregaProvider>().obtenerEntrega(widget.entregaId);
      }
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      debugPrint('📑 Tab cambió a índice: $index');

      if (index == 0) {
        // General - recargar entrega completa
        debugPrint('📑 Recargando General...');
        (_generalKey.currentState as dynamic)?.recargar();
      } else if (index == 1) {
        // Productos - hacer petición propia
        debugPrint('📑 Recargando Productos...');
        (_productosKey.currentState as dynamic)?.recargar();
      } else if (index == 2) {
        // Ventas - hacer petición propia
        debugPrint('📑 Recargando Ventas...');
        (_ventasKey.currentState as dynamic)?.recargar();
      }
    }
  }

  @override
  void didUpdateWidget(EntregaDetalleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entregaId != widget.entregaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint(
            '🔄 [didUpdateWidget] Entrega cambió de ${oldWidget.entregaId} a ${widget.entregaId}',
          );
          context.read<EntregaProvider>().obtenerEntrega(widget.entregaId);
        }
      });
    }
  }

  @override
  void dispose() {
    // ✅ NUEVO: Dispose del TabController
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    // NOTA: NO desconectamos el WebSocket aquí porque es una conexión global
    // Se mantiene activa para otras pantallas
    super.dispose();
  }

  Future<void> _cargarDetalle(EntregaProvider provider) async {
    // No ejecutar si ya está recargando
    if (_isRefreshing) {
      return;
    }

    if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final success = await provider.obtenerEntrega(widget.entregaId);

      if (mounted) {
        setState(() => _isRefreshing = false);

        if (success) {
          debugPrint('✅ Entrega recargada exitosamente');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Información recargada'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('❌ Error al recargar entrega');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Error al recargar la información',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción al recargar: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EntregaProvider>();
    final entrega = provider.entregaActual;

    // ✅ NUEVO 2026-06-15: Convertir color hex del estado de entrega a Color
    Color appBarColor = Colors.deepOrange; // fallback
    if (entrega?.estadoEntregaObj?.color != null) {
      try {
        final colorHex = entrega!.estadoEntregaObj?.color!.replaceFirst(
          '#',
          '',
        );
        appBarColor = Color(int.parse('FF$colorHex', radix: 16));
      } catch (e) {
        debugPrint(
          '⚠️ Error al parsear color: ${entrega!.estadoEntregaObj?.color} - $e',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega #${widget.entregaId}'),
        backgroundColor: appBarColor,
        actions: [
          // ✅ Botón para actualizar/recargar la pantalla
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: AnimatedRotation(
                turns: _isRefreshing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Icon(Icons.refresh),
              ),
              tooltip: _isRefreshing
                  ? 'Recargando...'
                  : 'Actualizar información',
              onPressed: _isRefreshing ? null : () => _cargarDetalle(provider),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber[300],
            labelColor: Colors.amber[300],
            unselectedLabelColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              const Tab(icon: Icon(Icons.info), text: 'General'),
              const Tab(icon: Icon(Icons.inventory), text: 'Productos'),
              // ✅ NUEVO: Mostrar cantidad de ventas (centralizamos pagos aquí)
              Tab(
                icon: const Icon(Icons.receipt),
                text:
                    'Ventas${provider.entregaActual != null ? ' (${provider.entregaActual!.ventas.length})' : ''}',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: () {
        final entregaActual = provider.entregaActual;
        if (entregaActual == null ||
            entregaActual.id != widget.entregaId ||
            provider.isLoading) {
          return const SizedBox.shrink();
        }
        return Material(
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: SingleChildScrollView(
              child: BotonesAccion(
                colorButton: appBarColor,
                key: ValueKey(
                  'botones_${entregaActual.id}_${entregaActual.estado}',
                ),
                entrega: entregaActual,
                provider: provider,
                onIniciarEntrega: (ctx, ent, prov) =>
                    IniciarEntregaDialog.show(ctx, ent, prov),
                onMarcarLlegada: (ctx, ent, prov) =>
                    MarcarLlegadaDialog.show(ctx, ent, prov),
                onMarcarEntregada: (ctx, ent, prov) =>
                    MarcarEntregadaDialog.show(ctx, ent, prov),
                onReportarNovedad: (ctx, ent, prov) =>
                    ReportarNovedadDialog.show(ctx, ent, prov),
                onConfirmarCargaLista: (ctx, ent, prov, {onReload}) =>
                    ConfirmarCargaListaDialog.show(
                      ctx,
                      ent,
                      prov,
                      onReload: onReload,
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                    ),
                onEntregasTerminadas: (ctx, ent, prov) =>
                    EntregasTerminadasDialog.show(ctx, ent, prov),
                onReintentarGps: () => _cargarDetalle(provider),
                onReload: () => _cargarDetalle(provider),
              ),
            ),
          ),
        );
      }(),
      body: provider.entregaActual == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Cargando detalles de entrega...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                TabGeneralWidget(key: _generalKey, provider: provider),
                TabProductosWidget(
                  key: _productosKey,
                  entrega: provider.entregaActual!,
                  provider: provider,
                ),
                TabVentasWidget(
                  key: _ventasKey,
                  entrega: provider.entregaActual!,
                  provider: provider,
                  context: context,
                ),
              ],
            ),
    );
  }
}
