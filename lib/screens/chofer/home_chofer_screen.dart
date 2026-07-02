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
///
/// Parámetros opcionales:
/// - showBackButton: si true, muestra botón de regreso en lugar de menú de usuario
/// - showOnlyDeliveries: si true, solo muestra entregas (oculta préstamos) y agrega AppBar
class HomeChoferScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showOnlyDeliveries;

  const HomeChoferScreen({
    super.key,
    this.showBackButton = false,
    this.showOnlyDeliveries = false,
  });

  @override
  State<HomeChoferScreen> createState() => _HomeChoferScreenState();
}

class _HomeChoferScreenState extends State<HomeChoferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showOnlyDeliveries ? 1 : 2,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    // Cargar estados logísticos y préstamos DESPUÉS de que termine la construcción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadosLogisticos();
      _cargarPrestamos();
    });
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ NUEVO: Cargar estados logísticos (entrega, venta_logistica, proforma)
  /// Estos se cachean en el provider para uso en toda la app
  void _cargarEstadosLogisticos() {
    context.read<EstadoLogisticoProvider>().obtenerTodosLosEstados().then((ok) {
      if (ok) {
        debugPrint('✅ [HOME_CHOFER] Todos los estados logísticos cacheados');
      } else {
        debugPrint('⚠️ [HOME_CHOFER] Error cacheando estados logísticos');
      }
    });
  }

  void _cargarPrestamos() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<PrestamosProvider>().cargarPrestamosDelChofer(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showOnlyDeliveries ? null : _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: widget.showOnlyDeliveries
            ? [EntregasAsignadasScreen(showAppBar: widget.showBackButton)]
            : const [EntregasAsignadasScreen(), PrestamosAsignadosScreen()],
      ),
      bottomNavigationBar:
          widget.showOnlyDeliveries ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: _tabController.index,
      onTap: (index) => _tabController.animateTo(index),
      type: BottomNavigationBarType.fixed,
      /*selectedItemColor: colorScheme.primary,
      unselectedItemColor: isDarkMode
          ? Colors.grey.shade600
          : Colors.grey.shade500,*/
      backgroundColor: colorScheme.surface,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Entregas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Préstamos',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Bienvenido!'),
      elevation: 0,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
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
        // Menú de usuario (solo si NO muestra botón de regreso)
        if (!widget.showBackButton)
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
