import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_text_styles.dart';
import '../../providers/providers.dart';
import '../../providers/prestamos_provider.dart';
import 'entregas_asignadas_screen.dart';
import 'prestamos_asignados_screen.dart';
import '../perfil/perfil_screen.dart';
import '../notifications_screen.dart';

/// Pantalla principal para usuarios con rol CHOFER
///
/// Muestra:
/// - Listado de entregas asignadas
/// - Listado de préstamos asignados (clientes, eventos, proveedores)
/// - Acceso rápido a perfil
class HomeChoferScreen extends StatefulWidget {
  const HomeChoferScreen({super.key});

  @override
  State<HomeChoferScreen> createState() => _HomeChoferScreenState();
}

class _HomeChoferScreenState extends State<HomeChoferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Cargar préstamos cuando se abre la pantalla
    _cargarPrestamos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cargarPrestamos() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<PrestamosProvider>().cargarPrestamosDelChofer(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;  // ✅ Detectar modo oscuro

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // TabBar
          Container(
            color: isDark ? Colors.grey.shade800 : Colors.white,  // ✅ Modo oscuro
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,  // ✅ Color dinámico
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(
                  text: '🚚 Entregas',
                  icon: Icon(Icons.local_shipping),
                ),
                Tab(
                  text: '📦 Préstamos',
                  icon: Icon(Icons.inventory),
                ),
              ],
            ),
          ),
          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const EntregasAsignadasScreen(),
                const PrestamosAsignadosScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mis Entregas Asignadassss'),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        // Notificaciones
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unreadCount = notifProvider.unreadCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTextStyles.labelSmall(context).fontSize!,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Menú de usuario (Perfil y Logout)
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          onSelected: (value) async {
            if (value == 'perfil') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PerfilScreen()),
              );
            } else if (value == 'logout') {
              _mostrarDialogoConfirmarLogout();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'perfil',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Mi Perfil'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _mostrarDialogoConfirmarLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (!mounted) return;
                final authProvider = context.read<AuthProvider>();
                Navigator.of(context).pop();
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
