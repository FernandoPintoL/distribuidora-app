import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clase que define todos los gradientes de la aplicación
/// Utilizados principalmente en AppBars y componentes visuales
class AppGradients {
  AppGradients._(); // Constructor privado

  // Alignments por defecto
  static const Alignment _defaultBegin = Alignment.topLeft;
  static const Alignment _defaultEnd = Alignment.bottomRight;

  // ==================== GRADIENTES POR ROL ====================

  /// Obtiene el gradiente automáticamente según el rol del usuario
  ///
  /// Ejemplo:
  /// ```dart
  /// final gradient = AppGradients.getRoleGradient('cliente');
  /// ```
  static LinearGradient getRoleGradient(String role) {
    final colors = AppColors.getRoleColors(role);
    return LinearGradient(
      colors: colors,
      begin: _defaultBegin,
      end: _defaultEnd,
    );
  }

  // ==================== GRADIENTES PREDEFINIDOS ====================

  /// Gradiente azul (para Cliente)
  /// Utilizado como gradiente por defecto
  static const LinearGradient blue = LinearGradient(
    colors: [AppColors.clientePrimary, AppColors.clienteSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente verde (para Chofer)
  static const LinearGradient green = LinearGradient(
    colors: [AppColors.choferPrimary, AppColors.choferSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente naranja (para Preventista)
  static const LinearGradient orange = LinearGradient(
    colors: [AppColors.preventistaPrimary, AppColors.preventistaSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente rojo (para Admin)
  static const LinearGradient red = LinearGradient(
    colors: [AppColors.adminPrimary, AppColors.adminSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente gris (por defecto para usuarios sin rol)
  static const LinearGradient grey = LinearGradient(
    colors: [AppColors.defaultPrimary, AppColors.defaultSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  // ==================== GRADIENTES PERSONALIZADOS ====================

  /// Crea un gradiente personalizado con direcciones personalizadas
  ///
  /// Ejemplo:
  /// ```dart
  /// final custom = AppGradients.custom(
  ///   colors: [Colors.red, Colors.blue],
  ///   begin: Alignment.topLeft,
  ///   end: Alignment.bottomRight,
  /// );
  /// ```
  static LinearGradient custom({
    required List<Color> colors,
    Alignment begin = _defaultBegin,
    Alignment end = _defaultEnd,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }

  /// Crea un gradiente a partir de dos colores
  ///
  /// Ejemplo:
  /// ```dart
  /// final twoColor = AppGradients.twoColor(
  ///   primary: Colors.blue,
  ///   secondary: Colors.purple,
  /// );
  /// ```
  static LinearGradient twoColor({
    required Color primary,
    required Color secondary,
    Alignment begin = _defaultBegin,
    Alignment end = _defaultEnd,
  }) {
    return LinearGradient(
      colors: [primary, secondary],
      begin: begin,
      end: end,
    );
  }
}
