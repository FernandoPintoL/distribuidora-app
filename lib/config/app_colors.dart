import 'package:flutter/material.dart';

/// Clase que centraliza todos los colores de la aplicación
/// Esquema unificado: Verde-Teal para coherencia visual
///
/// Filosofía de color:
/// - Verde: Representa crecimiento, frescura, dinero (perfecto para e-commerce)
/// - Teal: Complemento natural del verde, profesional y moderno
class AppColors {
  AppColors._(); // Constructor privado

  // ==================== COLORES PRINCIPALES (VERDE-TEAL) ====================

  /// Verde principal (usado en botones, precios, acciones)
  static const Color primaryLight = Color(0xFF4ade80); // Green 400
  static const Color primary = Color(0xFF22c55e); // Green 500
  static const Color primaryDark = Color(0xFF16a34a); // Green 600
  static const Color primaryDarker = Color(0xFF15803d); // Green 700

  /// Teal como color secundario/acento (navegación, estados)
  static const Color secondaryLight = Color(0xFF2dd4bf); // Teal 400
  static const Color secondary = Color(0xFF14b8a6); // Teal 500
  static const Color secondaryDark = Color(0xFF0d9488); // Teal 600
  static const Color secondaryDarker = Color(0xFF0f766e); // Teal 700

  // ==================== COLORES POR ROL (ACTUALIZADOS) ====================

  /// Colores para rol ADMIN (Rojo - sin cambios)
  static const Color adminPrimary = Color(0xFFD32F2F); // Red 700
  static const Color adminSecondary = Color(0xFFB71C1C); // Red 900

  /// Colores para rol PREVENTISTA (Naranja - sin cambios)
  static const Color preventistaPrimary = Color(0xFFFB8C00); // Orange 600
  static const Color preventistaSecondary = Color(
    0xFFBF360C,
  ); // Deep Orange 800

  /// Colores para rol CLIENTE (Verde-Teal - ACTUALIZADO)
  static const Color clientePrimary = Color.fromARGB(
    255,
    30,
    92,
    89,
  ); // Green 500
  static const Color clienteSecondary = Color.fromARGB(
    255,
    18,
    100,
    91,
  ); // Teal 500

  /// Colores para rol CHOFER (Verde oscuro - ACTUALIZADO)
  static const Color choferPrimary = Color(0xFF16a34a); // Green 600
  static const Color choferSecondary = Color(0xFF15803d); // Green 700

  /// Colores por defecto (para usuarios sin rol específico)
  static const Color defaultPrimary = Color(0xFF616161); // Grey 700
  static const Color defaultSecondary = Color(0xFF212121); // Grey 900

  // ==================== COLORES DE ESTADO ====================

  /// Color para estado exitoso (verde)
  static const Color success = Color(0xFF22c55e); // Green 500
  static const Color successDark = Color(0xFF16a34a); // Green 600

  /// Color para estado de error (rojo)
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorDark = Color(0xFFDC2626); // Red 600

  /// Color para advertencias (amarillo/amber)
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningDark = Color(0xFFD97706); // Amber 600

  /// Color para información (teal)
  static const Color info = Color(0xFF14b8a6); // Teal 500
  static const Color infoDark = Color(0xFF0d9488); // Teal 600

  // ==================== COLORES PARA BADGES ====================

  /// Fondo de badge (notificaciones, carrito)
  static const Color badgeBackground = Color(0xFFEF4444); // Red 500

  /// Texto de badge
  static const Color badgeText = Colors.white;

  // ==================== GRADIENTES PRINCIPALES ====================

  /// Gradiente principal Verde-Teal (AppBar, elementos destacados)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary], // Verde a Teal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente verde puro (para botones de acción primaria)
  static const LinearGradient greenGradient = LinearGradient(
    colors: [primaryLight, primaryDark], // Verde claro a oscuro
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente teal puro (para información, estados secundarios)
  static const LinearGradient tealGradient = LinearGradient(
    colors: [secondaryLight, secondaryDark], // Teal claro a oscuro
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== MÉTODOS ====================

  /// Obtiene el par de colores (primario y secundario) para un rol específico
  ///
  /// Ejemplo:
  /// ```dart
  /// final colors = AppColors.getRoleColors('cliente');
  /// // Retorna [Color(0xFF22c55e), Color(0xFF14b8a6)] - Verde-Teal
  /// ```
  static List<Color> getRoleColors(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [adminPrimary, adminSecondary];
      case 'preventista':
        return [const Color.fromARGB(255, 216, 194, 167), preventistaSecondary];
      case 'cliente':
      case 'client':
        return [
          Colors.teal,
          Colors.teal,
          /* const Color.fromARGB(255, 29, 112, 60),
          const Color.fromARGB(255, 37, 148, 105), */
        ]; // Verde-Teal
      case 'chofer':
        return [choferPrimary, choferSecondary]; // Verde oscuro
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

  /// Obtiene el gradiente para un rol específico
  static LinearGradient getRoleGradient(String role) {
    final colors = getRoleColors(role);
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
