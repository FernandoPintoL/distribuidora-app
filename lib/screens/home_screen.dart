import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'base/base_home_screen.dart';
import '../models/navigation_item.dart';
import '../providers/providers.dart';
import 'clients/client_list_screen.dart';
import 'perfil/perfil_screen.dart';

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
  PreferredSizeWidget get appBar => AppBar(
    title: const Text('Distribuidora Paucara'),
    elevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => _showLogoutDialog(context),
      ),
    ],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildDynamicNavigation();
  }

  @override
  Future<void> loadInitialData() async {}

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
class DashboardPreventista extends StatelessWidget {
  const DashboardPreventista({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Recargar datos
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final userName = authProvider.user?.name ?? 'Preventista';
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Hola, $userName!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bienvenido a tu panel de gestión',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Título de accesos rápidos
              const Text(
                'Accesos Rápidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Grid de accesos rápidos
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildQuickAccessCard(
                    context,
                    title: 'Clientes',
                    subtitle: 'Gestionar clientes',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAccessCard(
                    context,
                    title: 'Nuevo Cliente',
                    subtitle: 'Registrar cliente',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/client-form');
                    },
                  ),
                  /*_buildQuickAccessCard(
                    context,
                    title: 'Productos',
                    subtitle: 'Ver catálogo',
                    icon: Icons.inventory,
                    color: Colors.orange,
                    onTap: () {
                      // Navegar a productos si existe
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función en desarrollo'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),*/
                  _buildQuickAccessCard(
                    context,
                    title: 'Pedidos',
                    subtitle: 'Ver pedidos',
                    icon: Icons.shopping_cart,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función en desarrollo'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Resumen de estadísticas
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Consumer<ClientProvider>(
                builder: (context, clientProvider, child) {
                  return Column(
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Total Clientes',
                        value: clientProvider.clients.length.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        context,
                        title: 'Clientes Activos',
                        value: clientProvider.clients
                            .where((c) => c.activo)
                            .length
                            .toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        context,
                        title: 'Clientes Inactivos',
                        value: clientProvider.clients
                            .where((c) => !c.activo)
                            .length
                            .toString(),
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Información adicional
              /*Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Gestión de Clientes',
                        'Accede a la lista completa de clientes desde la pestaña "Clientes"',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        'Direcciones',
                        'Cada cliente puede tener múltiples direcciones de entrega con GPS',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        'Búsqueda',
                        'Busca clientes por nombre, teléfono, NIT, código o localidad',
                      ),
                    ],
                  ),
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          size: 20,
          color: Colors.green.shade600,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
