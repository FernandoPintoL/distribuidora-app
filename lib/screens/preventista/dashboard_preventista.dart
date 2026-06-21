import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_gradients.dart';
import '../../config/app_text_styles.dart';
import '../../models/orden_del_dia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/pedido_provider.dart';
import '../../providers/visita_provider.dart';
import '../home_screen.dart';
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
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.95,
                      children: [
                        DashboardPreventistaWidgets.buildGradientCard(
                          context,
                          title: 'Crear Pedido',
                          subtitle: 'Proformas',
                          icon: Icons.shopping_cart_outlined,
                          gradient: AppGradients.orange,
                          onTap: () {
                            // ✅ NUEVO: Navegar a la lista de productos para crear pedido
                            Navigator.pushNamed(context, '/products');
                          },
                        ),
                        DashboardPreventistaWidgets.buildGradientCard(
                          context,
                          title: 'Clientes',
                          subtitle: 'Gestionar',
                          icon: Icons.people_outline,
                          gradient: AppGradients.blue,
                          onTap: () {
                            // Cambiar a pestaña de Clientes sin abrir nueva ventana
                            final homeState = context
                                .findAncestorStateOfType<HomeScreenState>();
                            homeState?.navigateToIndex(1); // Index 1 = Clientes
                          },
                        ),
                        // dirigir a la pantalla de pedidos
                        DashboardPreventistaWidgets.buildGradientCard(
                          context,
                          title: 'Mis Pedidos',
                          subtitle: 'Ver Todos',
                          icon: Icons.receipt_long_outlined,
                          gradient: AppGradients.greenDark,
                          onTap: () {
                            Navigator.pushNamed(context, '/mis-pedidos');
                          },
                        ),
                        // ✅ NUEVO: Orden del día
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
                        // ✅ ACTUALIZADO: Stock Disponible (PDF/Imagen)
                        DashboardPreventistaWidgets.buildGradientCard(
                          context,
                          title: 'Stock Disponible',
                          subtitle: 'Descargar',
                          icon: Icons.file_download_outlined,
                          gradient: AppGradients.red,
                          onTap: () => _mostrarOpcionesDescargarStock(),
                        ),
                        // ✅ NUEVO: Reporte Productos Vendidos
                        DashboardPreventistaWidgets.buildGradientCard(
                          context,
                          title: 'Reporte de Ventas',
                          subtitle: 'Productos Vendidos',
                          icon: Icons.bar_chart_outlined,
                          gradient: AppGradients.teal,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/reporte-productos-vendidos',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Estadísticas con KPIs
                    Text(
                      'Tu Desempeño',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Consumer<ClientProvider>(
                      builder: (context, clientProvider, child) {
                        // ✅ OPTIMIZADO: Usar dashboard stats en lugar de cargar clientes completos
                        final totalClientes =
                            clientProvider.dashboardTotalClientes ?? 0;
                        final clientesActivos =
                            clientProvider.dashboardClientesActivos ?? 0;
                        final clientesInactivos =
                            clientProvider.dashboardClientesInactivos ?? 0;
                        final porcentajeActivos = totalClientes > 0
                            ? ((clientesActivos / totalClientes) * 100)
                                  .toStringAsFixed(1)
                            : '0';

                        return Column(
                          children: [
                            // KPI Principal
                            DashboardPreventistaWidgets.buildKPICard(
                              context,
                              title: 'Total de Clientes',
                              value: totalClientes.toString(),
                              subtitle: 'Bajo tu gestión',
                              icon: Icons.people,
                              color: Colors.blue,
                              progress: 1.0,
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta de Progreso
                            DashboardPreventistaWidgets.buildProgressCard(
                              context,
                              title: 'Clientes Activos',
                              current: clientesActivos,
                              total: totalClientes,
                              percentage:
                                  double.tryParse(porcentajeActivos) ?? 0,
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta de Inactivos
                            DashboardPreventistaWidgets.buildProgressCard(
                              context,
                              title: 'Clientes para Reactivar',
                              current: clientesInactivos,
                              total: totalClientes,
                              percentage:
                                  100 -
                                  (double.tryParse(porcentajeActivos) ?? 0),
                              icon: Icons.warning_rounded,
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Clientes Pendientes de Visitas
                    Text(
                      'Clientes Pendientes de Visitas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<OrdenDelDia?>(
                      future: _ordenDelDiaFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final ordenDelDia = snapshot.data;
                        if (ordenDelDia == null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Colors.blue.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Sin orden del día',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No hay clientes programados para hoy',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Resumen de la orden del día
                        final resumen = ordenDelDia.resumen;
                        final porcentajeDecimal =
                            resumen.porcentajeCompletado / 100;
                        Color progressColor = Colors.red;
                        if (porcentajeDecimal >= 0.75) {
                          progressColor = Colors.green;
                        } else if (porcentajeDecimal >= 0.5) {
                          progressColor = Colors.orange;
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título y porcentaje
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso del Día',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: progressColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${resumen.porcentajeCompletado.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: progressColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    value: porcentajeDecimal,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Estadísticas en fila
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    DashboardPreventistaWidgets.buildStatItem(
                                      context,
                                      count: resumen.totalClientes,
                                      label: 'Total',
                                      color: Colors.blue,
                                    ),
                                    DashboardPreventistaWidgets.buildStatItem(
                                      context,
                                      count: resumen.visitados,
                                      label: 'Visitados',
                                      color: Colors.green,
                                    ),
                                    DashboardPreventistaWidgets.buildStatItem(
                                      context,
                                      count: resumen.pendientes,
                                      label: 'Pendientes',
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Botón para ver más detalles
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/orden-del-dia',
                                      );
                                    },
                                    child: const Text(
                                      'Ver Orden del Día',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // ✅ NUEVO: Sección de Mis Pedidos
                    Text(
                      'Pedidos de mis clientes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Consumer<PedidoProvider>(
                      builder: (context, pedidoProvider, child) {
                        final stats = pedidoProvider.stats;

                        // Si no hay stats, mostrar loading
                        if (stats == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          children: [
                            // Fila 1: Pendientes y Aprobados
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      DashboardPreventistaWidgets.buildStatCard(
                                        context,
                                        title: 'Pendientes',
                                        value: stats.porEstado.pendiente
                                            .toString(),
                                        icon: Icons.pending_outlined,
                                        color: Colors.orange,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      DashboardPreventistaWidgets.buildStatCard(
                                        context,
                                        title: 'Aprobados',
                                        value: stats.porEstado.aprobada
                                            .toString(),
                                        icon: Icons.check_circle_outlined,
                                        color: Colors.green,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Fila 2: Convertidos y Total
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      DashboardPreventistaWidgets.buildStatCard(
                                        context,
                                        title: 'Convertidos',
                                        value: stats.porEstado.convertida
                                            .toString(),
                                        icon: Icons.shopping_bag_outlined,
                                        color: Colors.teal,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      DashboardPreventistaWidgets.buildStatCard(
                                        context,
                                        title: 'Total',
                                        value: stats.total.toString(),
                                        icon: Icons.receipt_long_outlined,
                                        color: Colors.blue,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botón para ver todos los pedidos
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/mis-pedidos');
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Ver Todos los Pedidos'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            // ✅ NUEVO: Alertas si hay pedidos vencidos o por vencer
                            if (stats.alertas.vencidas > 0 ||
                                stats.alertas.porVencer > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stats.alertas.vencidas > 0
                                              ? '${stats.alertas.vencidas} pedido(s) vencido(s)'
                                              : '${stats.alertas.porVencer} pedido(s) por vencer',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
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
