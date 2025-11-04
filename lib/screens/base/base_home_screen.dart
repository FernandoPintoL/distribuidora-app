import 'package:flutter/material.dart';
import '../../models/navigation_item.dart';

/// Clase base abstracta para todas las pantallas de home por rol
///
/// Proporciona:
/// - Estructura común Scaffold
/// - Gestión de navegación por índice
/// - Métodos abstractos para customización por rol
/// - Métodos helper comunes
abstract class BaseHomeScreen extends StatefulWidget {
  const BaseHomeScreen({super.key});
}

abstract class BaseHomeScreenState<T extends BaseHomeScreen>
    extends State<T> {
  late int _currentIndex;

  /// Lista de items de navegación (definida por subclases)
  List<NavigationItem> get navigationItems;

  /// Lista de pantallas/widgets (definida por subclases)
  List<Widget> get screens;

  /// AppBar personalizado (definido por subclases)
  PreferredSizeWidget? get appBar;

  /// FloatingActionButton opcional (null por defecto)
  FloatingActionButton? get floatingActionButton => null;

  /// Drawer opcional (null por defecto)
  Widget? get drawer => null;

  /// EndDrawer opcional (null por defecto)
  Widget? get endDrawer => null;

  /// Bottom sheet adicional (null por defecto)
  Widget? get bottomSheet => null;

  /// Color de fondo (null por defecto, usa el del tema)
  Color? get backgroundColor => null;

  /// Callback cuando se cambia el índice de navegación
  void onNavigationItemTapped(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
      navigationItems[index].onTap?.call();
    }
  }

  /// Navega a un índice específico
  void navigateToIndex(int index) {
    if (index >= 0 && index < navigationItems.length) {
      onNavigationItemTapped(index);
    }
  }

  /// Obtiene el item de navegación actual
  NavigationItem get currentNavigationItem => navigationItems[_currentIndex];

  /// Obtiene la pantalla actual
  Widget get currentScreen => screens[_currentIndex];

  /// Construye el BottomNavigationBar
  BottomNavigationBar buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: onNavigationItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: navigationItems.map((item) => item.toBottomNavItem()).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    // Cargar datos iniciales (puede ser sobrescrito por subclases)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialData();
    });
  }

  /// Cargar datos iniciales (puede ser sobrescrito por subclases)
  Future<void> loadInitialData() async {
    // Por defecto no hace nada
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      body: screens[_currentIndex],
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      bottomSheet: bottomSheet,
    );
  }
}
