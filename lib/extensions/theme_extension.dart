import 'package:flutter/material.dart';

/// Extensión para acceder fácilmente a propiedades del tema desde BuildContext
extension ThemeExtension on BuildContext {
  /// Obtiene el ColorScheme del tema actual
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Obtiene el ThemeData completo
  ThemeData get theme => Theme.of(this);

  /// Verifica si el tema actual es oscuro
  bool get isDark => theme.brightness == Brightness.dark;

  /// Obtiene el TextTheme del tema actual
  TextTheme get textTheme => theme.textTheme;
}
