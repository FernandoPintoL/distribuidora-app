import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_home_screen.dart';
import '../../models/navigation_item.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../screens.dart';
import '../perfil/perfil_screen.dart';
import '../../widgets/widgets.dart';

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
    NavigationItem(icon: Icons.home, label: 'Inicio'),
    NavigationItem(icon: Icons.inventory_2, label: 'Productos'),
    NavigationItem(icon: Icons.receipt_long, label: 'Mis Pedidos'),
    NavigationItem(icon: Icons.person, label: 'Perfil'),
  ];

  @override
  List<Widget> get screens => [
    const _DashboardTab(),
    const ProductListScreen(),
    const PedidosHistorialScreen(),
    const PerfilScreen(),
  ];

  @override
  PreferredSizeWidget get appBar => CustomGradientAppBar(
    title: 'Distribuidora Paucara',
    userRole: 'cliente',
    actions: [CartBadgeAction(), NotificationBadgeAction()],
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

            // ✅ NUEVO: Botón de Mis Ventas
            _buildMisVentasButton(context),

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.teal.shade700, Colors.teal.shade900]
              : [Colors.teal.shade600, Colors.teal.shade800],
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
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    // Obtener acceso al estado del BaseHomeScreen para navegar entre tabs
    final homeState = context
        .findAncestorStateOfType<_HomeClienteScreenState>();
    final pedidoProvider = context.watch<PedidoProvider>();

    // Calcular cantidad de pedidos en ruta (EN_RUTA + LLEGO)
    // ✅ ACTUALIZADO: Usar códigos de estado String en lugar de enum
    final pedidosEnRuta = pedidoProvider.pedidosEnProceso
        .where((p) => p.estadoCodigo == 'EN_RUTA' || p.estadoCodigo == 'LLEGO')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: Theme.of(context).textTheme.headlineSmall,
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
                  // Navegar al tab de Productos (índice 1)
                  homeState?.navigateToIndex(1);
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
                  // El carrito sí navega a otra página
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
                color: Colors.blue,
                onTap: () {
                  // Navegar al tab de Mis Pedidos (índice 2)
                  homeState?.navigateToIndex(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.local_shipping,
                title: 'Seguimiento',
                color: Colors.purple,
                badgeCount:
                    pedidosEnRuta, // Mostrar cantidad de pedidos en ruta
                onTap: () {
                  // ✅ ACTUALIZADO: Usar código de estado String en lugar de enum
                  // Aplicar filtro de pedidos EN_RUTA y navegar al tab
                  context.read<PedidoProvider>().aplicarFiltroEstado('EN_RUTA');

                  // Navegar al tab de Mis Pedidos (índice 2)
                  homeState?.navigateToIndex(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ NUEVO: Widget para mostrar botón de Mis Ventas
  Widget _buildMisVentasButton(BuildContext context) {
    final ventasProvider = context.watch<VentasProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis Ventas', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/mis-ventas');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade800],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ver mis compras confirmadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pagos, logística y más',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      icon: Icons.local_shipping,
                      label: 'Convertidos',
                      value: '${stats.porEstado.convertida}',
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_bag,
                      label: 'Total',
                      value: '${stats.total}',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      label: 'Monto Total',
                      value: 'Bs. ${stats.montoTotal.toStringAsFixed(0)}',
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      label: 'Convertidos',
                      value:
                          'Bs. ${stats.montosPorEstado.convertida.toStringAsFixed(0)}',
                      color: Colors.teal.shade600,
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
                      Icon(
                        Icons.warning,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
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
    // Obtener acceso al estado del BaseHomeScreen para navegar entre tabs
    final homeState = context
        .findAncestorStateOfType<_HomeClienteScreenState>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navegar al tab de Mis Pedidos (índice 2)
          homeState?.navigateToIndex(2);
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Ver Todos Mis Pedidos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
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
  final int? badgeCount; // Contador opcional para mostrar badge

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badgeCount,
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
              // Icono con badge opcional
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: color),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount! > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
