import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'base/base_home_screen.dart';
import '../models/navigation_item.dart';
import '../providers/providers.dart';
import 'clients/client_list_screen.dart';
import 'perfil/perfil_screen.dart';
import '../widgets/widgets.dart';
import '../config/config.dart';

/// Pantalla principal para usuarios con rol ADMIN/PREVENTISTA
class HomeScreen extends BaseHomeScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseHomeScreenState<HomeScreen> {
  late List<Widget> _dynamicScreens;
  late List<NavigationItem> _dynamicNavigationItems;

  @override
  List<NavigationItem> get navigationItems => _dynamicNavigationItems;

  @override
  List<Widget> get screens => _dynamicScreens;

  @override
  PreferredSizeWidget get appBar => CustomGradientAppBar(
    title: 'Distribuidora Paucara',
    userRole: _getDynamicRole(),
    actions: [LogoutAction(onLogout: () => _showLogoutDialog(context))],
  );

  String _getDynamicRole() {
    try {
      final authProvider = context.read<AuthProvider>();
      return authProvider.user?.roles?.first ?? 'admin';
    } catch (e) {
      return 'admin';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildDynamicNavigation();
  }

  @override
  Future<void> loadInitialData() async {
    // ✅ NUEVO: Cargar datos del preventista desde el login
    try {
      final authProvider = context.read<AuthProvider>();
      final clientProvider = context.read<ClientProvider>();
      final pedidoProvider = context.read<PedidoProvider>();

      // ✅ NUEVO: Cargar estadísticas de pedidos (ligero ~100ms)
      debugPrint('📊 Cargando estadísticas de pedidos...');
      await pedidoProvider.loadStats();

      // ✅ IMPORTANTE: Cargar clientes desde /clientes en lugar del login
      // El endpoint /login devuelve datos básicos sin campos de crédito
      // El endpoint /clientes retorna los datos COMPLETOS incluyendo puede_tener_credito
      debugPrint('📊 Cargando lista completa de clientes desde API...');
      clientProvider
          .loadClients(perPage: 100)
          .then((_) {
            debugPrint(
              '✅ Clientes cargados desde /clientes (con datos de crédito)',
            );
          })
          .catchError((e) {
            debugPrint('❌ Error cargando clientes: $e');
            // Si falla, usar los datos del login como fallback
            if (authProvider.preventistaStats != null) {
              debugPrint(
                '📊 Usando datos del preventista del login como fallback...',
              );
              clientProvider.loadClientsFromPreventistaStats(
                authProvider.preventistaStats!,
              );
            }
          });
    } catch (e) {
      debugPrint('❌ Error cargando datos iniciales: $e');
    }
  }

  void _buildDynamicNavigation() {
    final screens = <Widget>[
      const DashboardPreventista(),
      const ClientListScreen(),
      const PerfilScreen(),
    ];
    final navItems = <NavigationItem>[
      NavigationItem(icon: Icons.dashboard, label: 'Dashboard'),
      NavigationItem(icon: Icons.people, label: 'Clientes'),
      NavigationItem(icon: Icons.person, label: 'Perfil'),
    ];

    setState(() {
      _dynamicScreens = screens;
      _dynamicNavigationItems = navItems;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}

/// Dashboard para Preventistas
class DashboardPreventista extends StatefulWidget {
  const DashboardPreventista({super.key});

  @override
  State<DashboardPreventista> createState() => _DashboardPreventistaState();
}

class _DashboardPreventistaState extends State<DashboardPreventista>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
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
              // Header mejorado con gradiente
              Container(
                decoration: BoxDecoration(gradient: AppGradients.orange),
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userName = authProvider.user?.name ?? 'Preventista';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()}, $userName',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tu panel de ventas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accesos Rápidos - Mejorado con gradientes
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _buildGradientCard(
                          context,
                          title: 'Crear Pedido',
                          subtitle: 'Productos',
                          icon: Icons.shopping_cart_outlined,
                          gradient: AppGradients.orange,
                          onTap: () {
                            // ✅ NUEVO: Navegar a la lista de productos para crear pedido
                            Navigator.pushNamed(context, '/products');
                          },
                        ),
                        _buildGradientCard(
                          context,
                          title: 'Clientes',
                          subtitle: 'Gestionar',
                          icon: Icons.people_outline,
                          gradient: AppGradients.blue,
                          onTap: () {
                            // Cambiar a pestaña de Clientes sin abrir nueva ventana
                            final homeState = context
                                .findAncestorStateOfType<_HomeScreenState>();
                            homeState?.navigateToIndex(1); // Index 1 = Clientes
                          },
                        ),
                        _buildGradientCard(
                          context,
                          title: 'Nuevo Cliente',
                          subtitle: 'Registrar',
                          icon: Icons.person_add_outlined,
                          gradient: AppGradients.green,
                          onTap: () {
                            Navigator.pushNamed(context, '/client-form');
                          },
                        ),
                        // dirigir a la pantalla de pedidos
                        _buildGradientCard(
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
                        _buildGradientCard(
                          context,
                          title: 'Orden del Día',
                          subtitle: 'Clientes Hoy',
                          icon: Icons.checklist_rtl,
                          gradient: AppGradients.teal,
                          onTap: () {
                            Navigator.pushNamed(context, '/orden-del-dia');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Estadísticas con KPIs
                    const Text(
                      'Tu Desempeño',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Consumer<ClientProvider>(
                      builder: (context, clientProvider, child) {
                        final totalClientes = clientProvider.clients.length;
                        final clientesActivos = clientProvider.clients
                            .where((c) => c.activo)
                            .length;
                        final porcentajeActivos = totalClientes > 0
                            ? ((clientesActivos / totalClientes) * 100)
                                  .toStringAsFixed(1)
                            : '0';

                        return Column(
                          children: [
                            // KPI Principal
                            _buildKPICard(
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
                            _buildProgressCard(
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
                            _buildProgressCard(
                              context,
                              title: 'Clientes para Reactivar',
                              current: totalClientes - clientesActivos,
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

                    // Clientes Pendientes
                    const Text(
                      'Clientes Pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Consumer<ClientProvider>(
                      builder: (context, clientProvider, child) {
                        final clientesPendientes = clientProvider.clients
                            .where((c) => !c.activo)
                            .toList();

                        if (clientesPendientes.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 48,
                                    color: Colors.green.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Excelente trabajo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Todos tus clientes están activos',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            ...clientesPendientes.take(3).map((cliente) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildClientPendingCard(
                                  context,
                                  nombre: cliente.nombre,
                                  telefono: cliente.telefono ?? 'Sin teléfono',
                                  localidad:
                                      cliente.localidad?.nombre ??
                                      'Sin localidad',
                                ),
                              );
                            }),
                            if (clientesPendientes.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ClientListScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Ver ${clientesPendientes.length - 3} más',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // ✅ NUEVO: Sección de Mis Pedidos
                    const Text(
                      'Pedidos de mis clientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  child: _buildStatCard(
                                    context,
                                    title: 'Pendientes',
                                    value: stats.porEstado.pendiente.toString(),
                                    icon: Icons.pending_outlined,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    title: 'Aprobados',
                                    value: stats.porEstado.aprobada.toString(),
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
                                  child: _buildStatCard(
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
                                  child: _buildStatCard(
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
                                            fontSize: 13,
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

  Widget _buildGradientCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 28, color: color)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required String title,
    required int current,
    required int total,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, size: 22, color: color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$current de $total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientPendingCard(
    BuildContext context, {
    required String nombre,
    required String telefono,
    required String localidad,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 20, color: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          telefono,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          localidad,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
