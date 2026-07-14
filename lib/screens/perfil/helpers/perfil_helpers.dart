import 'package:flutter/material.dart';

/// Helpers para la pantalla de perfil
/// Contiene métodos de utilidad compartidos entre widgets

String getPrimaryRole(dynamic user) {
  final roles = user?.roles ?? [];
  if (roles.isEmpty) return 'Usuario';

  // Prioridad: Admin > Preventista > Chofer > Cliente
  if (roles.contains('Admin')) return 'Admin';
  if (roles.contains('Preventista')) return 'Preventista';
  if (roles.contains('Chofer')) return 'Chofer';
  if (roles.contains('Cliente')) return 'Cliente';

  return roles.first.toString();
}

LinearGradient getRoleGradient(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.red.shade700, Colors.red.shade900],
      );
    case 'preventista':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.orange.shade600, Colors.deepOrange.shade800],
      );
    case 'cliente':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.teal.shade600, Colors.teal.shade900],
      );
    case 'chofer':
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.green.shade600, Colors.green.shade900],
      );
    default:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade700, Colors.grey.shade900],
      );
  }
}

Color getRoleColor(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return Colors.red;
    case 'preventista':
      return Colors.orange;
    case 'cliente':
      return Colors.teal;
    case 'chofer':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

IconData getRolePrimaryIcon(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return Icons.security;
    case 'preventista':
      return Icons.business_center;
    case 'cliente':
      return Icons.shopping_bag;
    case 'chofer':
      return Icons.local_shipping;
    default:
      return Icons.person;
  }
}

String getRoleLabel(String role) {
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
}
