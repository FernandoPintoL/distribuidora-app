import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/home_screen.dart';
import '../screens/cliente/home_cliente_screen.dart';
import '../screens/chofer/home_chofer_screen.dart';
import '../screens/clients/client_list_screen.dart';

/// Servicio para determinar qué home screen mostrar basado en el rol del usuario
/// Centraliza toda la lógica de routing por rol
class RoleBasedRouter {
  /// Obtiene el home screen apropiado según los roles del usuario
  ///
  /// Orden de prioridad:
  /// 1. Cliente - muestra HomeClienteScreen
  /// 2. Chofer - muestra HomeChoferScreen
  /// 3. Preventista o Admin - muestra HomeScreen (con dinámicas)
  /// 4. Por defecto - muestra ClientListScreen
  static Widget getHomeScreen(User? user) {
    if (user == null || (user.roles?.isEmpty ?? true)) {
      return const ClientListScreen();
    }

    final roles = user.roles?.map((role) => role.toLowerCase()).toList() ?? [];

    // Orden de precedencia
    if (roles.contains('cliente')) {
      return const HomeClienteScreen();
    } else if (roles.contains('chofer')) {
      return const HomeChoferScreen();
    } else if (roles.contains('preventista') || roles.contains('admin')) {
      return const HomeScreen();
    } else {
      return const ClientListScreen();
    }
  }

  /// Verifica si el usuario tiene un rol específico
  static bool hasRole(User? user, String role) {
    if (user == null || user.roles == null) return false;
    return user.roles!.any((r) => r.toLowerCase() == role.toLowerCase());
  }

  /// Verifica si el usuario tiene alguno de los roles especificados
  static bool hasAnyRole(User? user, List<String> roles) {
    if (user == null || user.roles == null) return false;
    return user.roles!.any(
      (userRole) => roles.any((role) => role.toLowerCase() == userRole.toLowerCase()),
    );
  }

  /// Obtiene una descripción del rol del usuario
  static String getRoleDescription(User? user) {
    if (user == null || user.roles == null || user.roles!.isEmpty) {
      return 'No autenticado';
    }

    final roleNames = user.roles!.map((role) {
      switch (role.toLowerCase()) {
        case 'admin':
          return 'Administrador';
        case 'preventista':
          return 'Preventista';
        case 'cliente':
          return 'Cliente';
        case 'chofer':
          return 'Chofer';
        default:
          return role;
      }
    }).toList();

    return roleNames.join(', ');
  }

  /// Obtiene todos los permisos asociados a los roles del usuario
  /// Útil para validar acceso a características
  static List<String> getPermissionsForRoles(List<String> roles) {
    final permissions = <String>[];

    for (final role in roles) {
      switch (role.toLowerCase()) {
        case 'admin':
          permissions.addAll([
            'view_dashboard',
            'manage_users',
            'manage_products',
            'manage_orders',
            'manage_deliveries',
            'view_analytics',
            'manage_roles',
          ]);
          break;
        case 'preventista':
          permissions.addAll([
            'view_dashboard',
            'manage_products',
            'manage_orders',
            'manage_clients',
            'view_analytics',
          ]);
          break;
        case 'cliente':
          permissions.addAll([
            'view_orders',
            'create_orders',
            'view_products',
            'manage_addresses',
            'manage_profile',
          ]);
          break;
        case 'chofer':
          permissions.addAll([
            'view_deliveries',
            'manage_deliveries',
            'view_routes',
            'update_status',
          ]);
          break;
      }
    }

    // Remover duplicados
    return permissions.toSet().toList();
  }
}
