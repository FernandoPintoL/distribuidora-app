import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'base/base_home_screen.dart';
import '../models/navigation_item.dart';
import '../providers/providers.dart';
import 'products/product_list_screen.dart';
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
  late int _currentIndex = 0;

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
    final authProvider = context.read<AuthProvider>();
    final screens = <Widget>[
      const SizedBox(),
      const PerfilScreen(),
    ];
    final navItems = <NavigationItem>[
      NavigationItem(icon: Icons.dashboard, label: 'Dashboard'),
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
