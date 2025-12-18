import 'package:flutter/material.dart';

/// Clase que centraliza todos los colores de la aplicación
/// Organizados por rol y estado
class AppColors {
  AppColors._(); // Constructor privado

  // ==================== COLORES POR ROL ====================

  /// Colores para rol ADMIN
  static const Color adminPrimary = Color(0xFFD32F2F);      // Red 700
  static const Color adminSecondary = Color(0xFFB71C1C);    // Red 900

  /// Colores para rol PREVENTISTA
  static const Color preventistaPrimary = Color(0xFFFB8C00);   // Orange 600
  static const Color preventistaSecondary = Color(0xFFBF360C); // Deep Orange 800

  /// Colores para rol CLIENTE
  static const Color clientePrimary = Color(0xFF1976D2);    // Blue 700
  static const Color clienteSecondary = Color(0xFF0D47A1);  // Blue 900

  /// Colores para rol CHOFER
  static const Color choferPrimary = Color(0xFF43A047);     // Green 600
  static const Color choferSecondary = Color(0xFF1B5E20);   // Green 900

  /// Colores por defecto (para usuarios sin rol específico)
  static const Color defaultPrimary = Color(0xFF616161);    // Grey 700
  static const Color defaultSecondary = Color(0xFF212121);  // Grey 900

  // ==================== COLORES DE ESTADO ====================

  /// Color para estado exitoso
  static const Color success = Color(0xFF4CAF50);

  /// Color para estado de error
  static const Color error = Color(0xFFF44336);

  /// Color para advertencias
  static const Color warning = Color(0xFFFF9800);

  /// Color para información
  static const Color info = Color(0xFF2196F3);

  // ==================== COLORES PARA BADGES ====================

  /// Fondo de badge (notificaciones, carrito)
  static const Color badgeBackground = Color(0xFFE53935);

  /// Texto de badge
  static const Color badgeText = Colors.white;

  // ==================== MÉTODOS ====================

  /// Obtiene el par de colores (primario y secundario) para un rol específico
  ///
  /// Ejemplo:
  /// ```dart
  /// final colors = AppColors.getRoleColors('cliente');
  /// // Retorna [Color(0xFF1976D2), Color(0xFF0D47A1)]
  /// ```
  static List<Color> getRoleColors(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [adminPrimary, adminSecondary];
      case 'preventista':
        return [preventistaPrimary, preventistaSecondary];
      case 'cliente':
      case 'client':
        return [clientePrimary, clienteSecondary];
      case 'chofer':
        return [choferPrimary, choferSecondary];
      default:
        return [defaultPrimary, defaultSecondary];
    }
  }

  /// Obtiene el color primario para un rol específico
  static Color getRolePrimaryColor(String role) {
    final colors = getRoleColors(role);
    return colors.first;
  }

  /// Obtiene el color secundario para un rol específico
  static Color getRoleSecondaryColor(String role) {
    final colors = getRoleColors(role);
    return colors.last;
  }
}
