import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_home_screen.dart';
import '../../models/navigation_item.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../screens.dart';
import '../perfil/perfil_screen.dart';

/// Pantalla principal para usuarios con rol CLIENTE
///
/// Muestra:
/// - Dashboard con acceso rápido
/// - Productos destacados
/// - Mis pedidos recientes
/// - Estado de envíos activos
class HomeClienteScreen extends BaseHomeScreen {
  const HomeClienteScreen({super.key});

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends BaseHomeScreenState<HomeClienteScreen> {
  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      icon: Icons.home,
      label: 'Inicio',
    ),
    NavigationItem(
      icon: Icons.inventory_2,
      label: 'Productos',
    ),
    NavigationItem(
      icon: Icons.receipt_long,
      label: 'Mis Pedidos',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  List<Widget> get screens => [
    const _DashboardTab(),
    const ProductListScreen(),
    const PedidosHistorialScreen(),
    const PerfilScreen(),
  ];

  @override
  PreferredSizeWidget get appBar => AppBar(
    title: const Text('Distribuidora Paucara'),
    actions: [
      // Carrito
      IconButton(
        icon: const Badge(
          label: Text('0'), // TODO: Actualizar con cantidad real
          child: Icon(Icons.shopping_cart),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/carrito');
        },
      ),
      // Notificaciones
      Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final unreadCount = notificationProvider.unreadCount;

          return IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          );
        },
      ),
    ],
  );

  @override
  Future<void> loadInitialData() async {
    if (!mounted) return;

    try {
      final pedidoProvider = context.read<PedidoProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      // ✅ Solo cargar estadísticas de notificaciones (contador), no las notificaciones completas
      await notificationProvider.loadStats();

      // ✅ Solo cargar estadísticas de pedidos al iniciar (ligero y rápido)
      // Las proformas completas se cargarán cuando el usuario navegue al tab
      await pedidoProvider.loadStats();

      // Los productos se cargarán cuando el usuario navegue a la pestaña de Productos

      // Las notificaciones completas se cargarán solo cuando el usuario abra la pantalla de notificaciones
    } catch (e) {
      debugPrint('❌ Error cargando datos iniciales: $e');
    }
  }
}
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pedidoProvider = context.watch<PedidoProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await pedidoProvider.loadPedidos(refresh: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            _buildWelcomeBanner(context, authProvider.user?.name ?? 'Cliente'),

            const SizedBox(height: 24),

            // Acciones rápidas
            _buildQuickActions(context),

            const SizedBox(height: 24),

            // Estadísticas de mis pedidos
            _buildProformasStats(context, pedidoProvider),

            const SizedBox(height: 24),

            // Enlace a ver todos los pedidos
            _buildViewAllPedidosButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, String userName) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, $userName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bienvenido a tu tienda de distribución',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.inventory_2,
                title: 'Ver Productos',
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/products');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.shopping_cart,
                title: 'Mi Carrito',
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, '/carrito');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long,
                title: 'Mis Pedidos',
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/mis-pedidos');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.local_shipping,
                title: 'Seguimiento',
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(context, '/mis-pedidos');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProformasStats(BuildContext context, PedidoProvider provider) {
    final stats = provider.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Pedidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.isLoadingStats)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (stats == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar estadísticas',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (stats.total == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes pedidos aún',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              // Cards de estadísticas
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      label: 'Pendientes',
                      value: '${stats.porEstado.pendiente}',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      label: 'Aprobados',
                      value: '${stats.porEstado.aprobada}',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_bag,
                      label: 'Total',
                      value: '${stats.total}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      label: 'Monto',
                      value: 'Bs. ${stats.montoTotal.toStringAsFixed(0)}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              // Alerta si hay vencidas o por vencer
              if (stats.alertas.tieneAlertas) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stats.alertas.vencidas > 0
                              ? '${stats.alertas.vencidas} pedido(s) vencido(s)'
                              : '${stats.alertas.porVencer} pedido(s) por vencer',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
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
      ],
    );
  }

  Widget _buildViewAllPedidosButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/mis-pedidos');
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Ver Todos Mis Pedidos'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Tarjeta de acción rápida
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de estadística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
