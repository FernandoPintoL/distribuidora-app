import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_item.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'base/base_home_screen.dart';
import 'clients/client_list_screen.dart';
import 'perfil/perfil_screen.dart';
import 'preventista/dashboard_preventista.dart';

/// Pantalla principal para usuarios con rol ADMIN/PREVENTISTA
class HomeScreen extends BaseHomeScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BaseHomeScreenState<HomeScreen> {
  late List<Widget> _dynamicScreens;
  late List<NavigationItem> _dynamicNavigationItems;
  final _clientListKey =
      GlobalKey<State>(); // ✅ Para acceder al state de ClientListScreen

  @override
  List<NavigationItem> get navigationItems => _dynamicNavigationItems;

  @override
  List<Widget> get screens => _dynamicScreens;

  @override
  PreferredSizeWidget get appBar => CustomGradientAppBar(
    title: 'Distribuidora Paucara',
    actions: [LogoutAction(onLogout: () => _showLogoutDialog(context))],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildDynamicNavigation();
  }

  @override
  Future<void> loadInitialData() async {
    // ✅ OPTIMIZADO: Cargar solo estadísticas ligeras para el dashboard
    try {
      final authProvider = context.read<AuthProvider>();
      final clientProvider = context.read<ClientProvider>();
      final pedidoProvider = context.read<PedidoProvider>();
      await pedidoProvider.loadStats();
      clientProvider
          .loadDashboardStats()
          .then((_) {
            debugPrint(
              '✅ Estadísticas del dashboard cargadas (sin cargar clientes completos)',
            );
          })
          .catchError((e) {
            debugPrint('❌ Error cargando estadísticas del dashboard: $e');
          });
    } catch (e) {
      debugPrint('❌ Error cargando datos iniciales: $e');
    }
  }

  void _buildDynamicNavigation() {
    final screens = <Widget>[
      const DashboardPreventista(),
      ClientListScreen(key: _clientListKey), // ✅ Pasar GlobalKey
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

  /// ✅ OPTIMIZADO: Cargar clientes SOLO cuando se selecciona la pestaña "Clientes"
  @override
  void onNavigationItemTapped(int index) {
    super.onNavigationItemTapped(index);

    // Si se selecciona la pestaña de Clientes (índice 1)
    if (index == 1) {
      // Cargar clientes de forma lazy (solo si no existen)
      final clientListState = _clientListKey.currentState;
      if (clientListState != null) {
        (clientListState as dynamic).loadClientsIfNeeded();
      }
    }
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
