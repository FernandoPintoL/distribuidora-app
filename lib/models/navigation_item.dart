import 'package:flutter/material.dart';

/// Modelo que representa un item de navegación
/// Utilizado para definir la estructura de navegación de forma reutilizable
class NavigationItem {
  /// Icono del item
  final IconData icon;

  /// Etiqueta/nombre del item
  final String label;

  /// Nombre de la ruta (opcional)
  final String? route;

  /// Widget a mostrar cuando se selecciona este item
  final Widget? screen;

  /// Permisos requeridos para ver este item (opcional)
  /// Si es null, el item siempre es visible
  final List<String>? requiredPermissions;

  /// Callback cuando se toca el item
  final VoidCallback? onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    this.route,
    this.screen,
    this.requiredPermissions,
    this.onTap,
  });

  /// Verifica si el usuario tiene permisos para ver este item
  bool hasPermission(List<String> userPermissions) {
    if (requiredPermissions == null || requiredPermissions!.isEmpty) {
      return true;
    }

    return requiredPermissions!.any(
      (permission) => userPermissions.contains(permission),
    );
  }

  /// Convierte el item a BottomNavigationBarItem
  BottomNavigationBarItem toBottomNavItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}
