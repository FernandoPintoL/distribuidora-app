import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_gradients.dart';
import '../../models/orden_del_dia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visita_provider.dart';
import '../home_screen.dart';
import '../chofer/home_chofer_screen.dart';
import 'dashboard_preventista_widgets.dart';
import 'stock_download_service.dart';

/// Dashboard para Preventistas
class DashboardPreventista extends StatefulWidget {
  const DashboardPreventista({super.key});

  @override
  State<DashboardPreventista> createState() => _DashboardPreventistaState();
}

class _DashboardPreventistaState extends State<DashboardPreventista>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Future<OrdenDelDia?>? _ordenDelDiaFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();

    // ✅ OPTIMIZADO: Cargar orden del día una sola vez en initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrdenDelDia();
    });
  }

  /// Cargar orden del día (solo una vez)
  void _loadOrdenDelDia() {
    if (mounted) {
      final visitaProvider = context.read<VisitaProvider>();
      setState(() {
        _ordenDelDiaFuture = visitaProvider.obtenerOrdenDelDia();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  /// ✅ NUEVO: Construir lista de cards dinámicamente según permisos
  List<Widget> _buildDashboardCards(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final List<Widget> cards = [];

    // Card: Crear Pedido (siempre visible)
    cards.add(
      DashboardPreventistaWidgets.buildGradientCard(
        context,
        title: 'Crear Pedido',
        subtitle: 'Crear Proformas',
        icon: Icons.shopping_cart_outlined,
        gradient: AppGradients.orange,
        onTap: () {
          Navigator.pushNamed(context, '/products');
        },
      ),
    );

    // Card: Clientes (siempre visible)
    final stats = authProvider.preventistaStats;
    cards.add(
      DashboardPreventistaWidgets.buildClientesCard(
        context,
        totalBd: stats?.totalClientesBd ?? 0,
        asignados: stats?.totalClientesAsignados ?? 0,
        sinAsignar: stats?.clientesSinAsignar ?? 0,
        activos: stats?.clientesActivos ?? 0,
        inactivos: stats?.clientesInactivos ?? 0,
        gradient: AppGradients.blue,
        onTap: () {
          final homeState = context.findAncestorStateOfType<HomeScreenState>();
          homeState?.navigateToIndex(1);
        },
      ),
    );

    // Card: Pedidos (siempre visible)
    cards.add(
      DashboardPreventistaWidgets.buildPedidosCard(
        context,
        proformasPendientes: stats?.proformasCredasHoy.pendientes ?? 0,
        proformasConvertidas: stats?.proformasCredasHoy.convertidas ?? 0,
        proformasRechazadas: stats?.proformasCredasHoy.rechazadas ?? 0,
        entregaPendientes: stats?.proformasEntregaSolicitadaHoy.pendientes ?? 0,
        entregaConvertidas:
            stats?.proformasEntregaSolicitadaHoy.convertidas ?? 0,
        entregaRechazadas: stats?.proformasEntregaSolicitadaHoy.rechazadas ?? 0,
        ventasAprobadas: stats?.ventasAprobadas ?? 0,
        ventasAnuladas: stats?.ventasAnuladas ?? 0,
        totalVentas: stats?.totalVentas ?? 0,
        gradient: AppGradients.greenDark,
        onTap: () {
          Navigator.pushNamed(context, '/mis-pedidos');
        },
      ),
    );

    // Card: Ventas (solo si tiene permiso)
    if (authProvider.hasPermission('ventas.index.app')) {
      cards.add(
        DashboardPreventistaWidgets.buildGradientCard(
          context,
          title: 'Ventas',
          subtitle: 'Listado Completo',
          icon: Icons.receipt_long_outlined,
          gradient: AppGradients.teal,
          onTap: () {
            Navigator.pushNamed(context, '/ventas-list');
          },
        ),
      );
    }

    // Card: Cuentas por Cobrar (solo si tiene permiso)
    if (authProvider.hasPermission('cuentas_por_cobrar.index.app')) {
      cards.add(
        DashboardPreventistaWidgets.buildGradientCard(
          context,
          title: 'Cuentas por Cobrar',
          subtitle: 'Seguimiento',
          icon: Icons.account_balance_wallet_outlined,
          gradient: AppGradients.red,
          onTap: () {
            Navigator.pushNamed(context, '/cuentas-por-cobrar-list');
          },
        ),
      );
    }

    // Card: Entregas (solo si tiene permiso o es chofer)
    if (authProvider.hasPermission('entregas.index.app') ||
        (authProvider.user?.roles?.contains('chofer') ?? false) ||
        (authProvider.user?.roles?.contains('Chofer') ?? false)) {
      cards.add(
        DashboardPreventistaWidgets.buildGradientCard(
          context,
          title: 'Entregas',
          subtitle: 'Ver todas',
          icon: Icons.local_shipping_outlined,
          gradient: AppGradients.blue,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const HomeChoferScreen(showBackButton: true),
              ),
            );
          },
        ),
      );
    }

    // Card: Reporte de Ventas (siempre visible)
    cards.add(
      DashboardPreventistaWidgets.buildReportVentasCard(
        context,
        cantidadProductos: stats?.cantidadProductosVendidos ?? 0,
        sumaProductos: stats?.sumatiorProductosVendidos ?? 0,
        cantidadItems: stats?.cantidadTotalItemsVendidos ?? 0,
        gradient: AppGradients.teal,
        onTap: () {
          Navigator.pushNamed(context, '/reporte-productos-vendidos');
        },
      ),
    );

    cards.add(
      DashboardPreventistaWidgets.buildGradientCard(
        context,
        title: 'Orden del Día',
        subtitle: 'Clientes Hoy',
        icon: Icons.checklist_rtl,
        gradient: AppGradients.teal,
        onTap: () {
          Navigator.pushNamed(context, '/orden-del-dia');
        },
      ),
    );

    cards.add(
      DashboardPreventistaWidgets.buildGradientCard(
        context,
        title: 'Stock Disponible',
        subtitle: 'Descargar',
        icon: Icons.file_download_outlined,
        gradient: AppGradients.red,
        onTap: () => _mostrarOpcionesDescargarStock(),
      ),
    );

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // ✅ OPTIMIZADO: Refrescar orden del día + animación
          _loadOrdenDelDia();
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _animationController.reset();
              _animationController.forward();
            });
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final cards = _buildDashboardCards(
                          context,
                          authProvider,
                        );
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.7,
                          children: cards,
                        );
                      },
                    ),
                    // ✅ Reporte de Ventas detallado (sección separada)
                    /* Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final stats = authProvider.preventistaStats;
                          return DashboardPreventistaWidgets.buildReportVentasCard(
                            context,
                            cantidadProductos: stats?.cantidadProductosVendidos ?? 0,
                            sumaProductos: stats?.sumatiorProductosVendidos ?? 0,
                            cantidadItems: stats?.cantidadTotalItemsVendidos ?? 0,
                            gradient: AppGradients.teal,
                            onTap: () {
                              Navigator.pushNamed(context, '/reporte-productos-vendidos');
                            },
                          );
                        },
                      ),
                    ), */
                    const SizedBox(height: 16),
                    // ✅ NUEVO: Grid con Orden del Día y Stock Disponible
                    /* Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                        children: [
                          DashboardPreventistaWidgets.buildGradientCard(
                            context,
                            title: 'Orden del Día',
                            subtitle: 'Clientes Hoy',
                            icon: Icons.checklist_rtl,
                            gradient: AppGradients.teal,
                            onTap: () {
                              Navigator.pushNamed(context, '/orden-del-dia');
                            },
                          ),
                          DashboardPreventistaWidgets.buildGradientCard(
                            context,
                            title: 'Stock Disponible',
                            subtitle: 'Descargar',
                            icon: Icons.file_download_outlined,
                            gradient: AppGradients.red,
                            onTap: () => _mostrarOpcionesDescargarStock(),
                          ),
                        ],
                      ),
                    ), */
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcionesDescargarStock() {
    StockDownloadService(context).mostrarOpcionesDescargar();
  }
}
