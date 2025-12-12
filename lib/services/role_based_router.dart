import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/home_screen.dart';
import '../screens/cliente/home_cliente_screen.dart';
import '../screens/chofer/home_chofer_screen.dart';
import '../screens/clients/client_list_screen.dart';

/// Servicio para determinar qué home screen mostrar basado en el rol del usuario
/// Centraliza toda la lógica de routing por rol
///
/// ✅ NOTA: Los permisos son ahora dinámicos y se obtienen desde:
/// - user.permissions (lista de permisos específicos)
/// - AuthProvider.refreshPermissionsIfNeeded() (para mantener cache actualizado)
///
/// Para verificar si un usuario tiene un permiso específico, usa:
/// - authProvider.hasPermission('permission.name')
/// - RoleBasedRouter.hasPermission(user, 'permission.name')
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

  /// Verifica si el usuario tiene un permiso específico
  /// Los permisos provienen de la BD y se sincronizan dinámicamente
  static bool hasPermission(User? user, String permission) {
    if (user == null || user.permissions == null) return false;
    return user.permissions!.contains(permission);
  }

  /// Verifica si el usuario tiene alguno de los permisos especificados
  static bool hasAnyPermission(User? user, List<String> permissions) {
    if (user == null || user.permissions == null) return false;
    return user.permissions!.any((userPerm) => permissions.contains(userPerm));
  }

  /// Verifica si el usuario tiene todos los permisos especificados
  static bool hasAllPermissions(User? user, List<String> permissions) {
    if (user == null || user.permissions == null) return false;
    return permissions.every((perm) => user.permissions!.contains(perm));
  }
}
