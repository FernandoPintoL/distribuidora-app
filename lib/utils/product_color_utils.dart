import 'package:flutter/material.dart';

/// Utilidad para generar colores únicos e independientes para cada producto
/// con soporte completo para modo oscuro
class ProductColorUtils {
  /// Paleta de colores simples para modo claro
  static const List<Color> _lightColorPalette = [
    Color(0xFF2196F3), // Azul
    Color(0xFFFF6F00), // Naranja
    Color(0xFF4CAF50), // Verde
    Color(0xFF9C27B0), // Púrpura
    Color(0xFFE91E63), // Rosa/Magenta
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Rojo-Naranja
    Color(0xFF673AB7), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFFFFC107), // Ámbar
    Color(0xFF795548), // Café
    Color(0xFF3F51B5), // Azul Índigo
  ];

  /// Paleta de colores para modo oscuro (más saturados y claros)
  static const List<Color> _darkColorPalette = [
    Color(0xFF64B5F6), // Azul claro
    Color(0xFFFFB74D), // Naranja claro
    Color(0xFF81C784), // Verde claro
    Color(0xFFCE93D8), // Púrpura claro
    Color(0xFFF48FB1), // Rosa claro
    Color(0xFF4DD0E1), // Cyan claro
    Color(0xFFFFA726), // Rojo-Naranja claro
    Color(0xFF9FA8DA), // Indigo claro
    Color(0xFF4DB8AC), // Teal claro
    Color(0xFFFFD54F), // Ámbar claro
    Color(0xFFBCAAA4), // Café claro
    Color(0xFF7986CB), // Azul Índigo claro
  ];

  /// Obtiene un color único pero consistente para un producto basado en su ID
  /// Adaptado automáticamente al modo oscuro
  static Color getProductColor(int productId, {bool isDark = false}) {
    final palette = isDark ? _darkColorPalette : _lightColorPalette;
    final index = productId.abs() % palette.length;
    return palette[index];
  }

  /// Obtiene una variante más clara del color del producto (para backgrounds)
  static Color getProductColorLight(int productId, {bool isDark = false}) {
    final baseColor = getProductColor(productId, isDark: isDark);

    if (isDark) {
      // En modo oscuro, usar el color con menos transparencia
      return baseColor.withAlpha(100);
    } else {
      // En modo claro, usar el color con más transparencia
      return baseColor.withAlpha(40);
    }
  }

  /// Obtiene una variante para el badge/secundaria
  static Color getProductColorSecondary(int productId, {bool isDark = false}) {
    final baseColor = getProductColor(productId, isDark: isDark);
    return baseColor.withAlpha(100);
  }

  /// Obtiene el color del texto que contrasta bien con el color del producto
  static Color getProductTextColor(int productId, {bool isDark = false}) {
    return Colors.white;
  }

  /// Obtiene una variante para la sombra del color del producto
  static Color getProductShadowColor(int productId, {bool isDark = false}) {
    final baseColor = getProductColor(productId, isDark: isDark);
    if (isDark) {
      return baseColor.withAlpha(30);
    } else {
      return baseColor.withAlpha(15);
    }
  }

  /// Obtiene una variante para los bordes del color del producto
  static Color getProductBorderColor(int productId, {bool isDark = false}) {
    final baseColor = getProductColor(productId, isDark: isDark);
    return baseColor.withAlpha(120);
  }
}
