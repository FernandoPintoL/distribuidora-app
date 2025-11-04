import 'package:flutter/material.dart';
import '../../models/navigation_item.dart';

/// Widget reutilizable para BottomNavigationBar basado en rol
/// Facilita la creación de barras de navegación consistentes
class RoleBasedBottomNavBar extends StatelessWidget {
  /// Items de navegación a mostrar
  final List<NavigationItem> items;

  /// Índice actualmente seleccionado
  final int currentIndex;

  /// Callback cuando se toca un item
  final ValueChanged<int> onTap;

  /// Tipo de navegación (fixed, shifting, scrollable)
  final BottomNavigationBarType type;

  /// Color del item seleccionado
  final Color? selectedItemColor;

  /// Color del item no seleccionado
  final Color? unselectedItemColor;

  /// Tamaño de la fuente seleccionada
  final double selectedFontSize;

  /// Tamaño de la fuente no seleccionada
  final double unselectedFontSize;

  const RoleBasedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.type = BottomNavigationBarType.fixed,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize = 14,
    this.unselectedFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items.map((item) => item.toBottomNavItem()).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      type: type,
      selectedItemColor: selectedItemColor ?? Theme.of(context).primaryColor,
      unselectedItemColor: unselectedItemColor ?? Colors.grey,
      selectedFontSize: selectedFontSize,
      unselectedFontSize: unselectedFontSize,
    );
  }
}
