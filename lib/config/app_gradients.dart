import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clase que define todos los gradientes de la aplicación
/// Esquema unificado Verde-Teal para coherencia visual
///
/// NUEVO: AppGradients.blue ahora es Verde-Teal para clientes
class AppGradients {
  AppGradients._(); // Constructor privado

  // Alignments por defecto
  static const Alignment _defaultBegin = Alignment.topLeft;
  static const Alignment _defaultEnd = Alignment.bottomRight;

  // ==================== GRADIENTES PRINCIPALES ====================

  /// Gradiente principal Verde-Teal (reemplaza el azul anterior)
  /// Usado como gradiente por defecto para clientes
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],  // Verde a Teal
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente verde puro (para acciones principales)
  static const LinearGradient green = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryDark],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente teal puro (para información, estados secundarios)
  static const LinearGradient teal = LinearGradient(
    colors: [AppColors.secondaryLight, AppColors.secondaryDark],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  // ==================== GRADIENTES POR ROL ====================

  /// Gradiente para Cliente: Verde-Teal (ACTUALIZADO)
  /// Anteriormente era azul, ahora es verde-teal para coherencia
  static const LinearGradient blue = LinearGradient(
    colors: [AppColors.clientePrimary, AppColors.clienteSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente para Chofer: Verde oscuro (ACTUALIZADO)
  static const LinearGradient greenDark = LinearGradient(
    colors: [AppColors.choferPrimary, AppColors.choferSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente para Preventista: Naranja
  static const LinearGradient orange = LinearGradient(
    colors: [AppColors.preventistaPrimary, AppColors.preventistaSecondary],
    begin: _defaultBegin,
    end: _defaultEnd,
  );

  /// Gradiente para Admin: Rojo
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

  // ==================== MÉTODOS ====================

  /// Obtiene el gradiente automáticamente según el rol del usuario
  ///
  /// Ejemplo:
  /// ```dart
  /// final gradient = AppGradients.getRoleGradient('cliente');
  /// // Retorna gradiente Verde-Teal
  /// ```
  static LinearGradient getRoleGradient(String role) {
    return AppColors.getRoleGradient(role);
  }

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
