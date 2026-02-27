import 'package:flutter/material.dart';

/// Estilos de texto centralizados que respetan la escala de fuente del dispositivo
/// Uso: AppTextStyles.titleLarge(context)
class AppTextStyles {
  // ============================================================================
  // DISPLAY STYLES (Títulos grandes)
  // ============================================================================

  static TextStyle displayLarge(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.displayLarge!);

  static TextStyle displayMedium(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.displayMedium!);

  static TextStyle displaySmall(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.displaySmall!);

  // ============================================================================
  // HEADLINE STYLES (Subtítulos importantes)
  // ============================================================================

  static TextStyle headlineMedium(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.headlineMedium!);

  static TextStyle headlineSmall(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.headlineSmall!);

  // ============================================================================
  // TITLE STYLES (Títulos de secciones)
  // ============================================================================

  static TextStyle titleLarge(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.titleLarge!);

  static TextStyle titleMedium(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.titleMedium!);

  static TextStyle titleSmall(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.titleSmall!);

  // ============================================================================
  // BODY STYLES (Texto de cuerpo)
  // ============================================================================

  static TextStyle bodyLarge(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.bodyLarge!);

  static TextStyle bodyMedium(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.bodyMedium!);

  static TextStyle bodySmall(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.bodySmall!);

  // ============================================================================
  // LABEL STYLES (Etiquetas y botones)
  // ============================================================================

  static TextStyle labelLarge(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.labelLarge!);

  static TextStyle labelSmall(BuildContext context) =>
      _applyTextScale(context, Theme.of(context).textTheme.labelSmall!);

  // ============================================================================
  // CUSTOM STYLES (Estilos personalizados comunes)
  // ============================================================================

  /// Estilo para moneda/números importantes
  static TextStyle currency(BuildContext context) =>
      bodyLarge(context).copyWith(fontWeight: FontWeight.bold);

  /// Estilo para fechas
  static TextStyle date(BuildContext context) => bodySmall(context);

  /// Estilo para estados/badges
  static TextStyle badge(BuildContext context) =>
      labelSmall(context).copyWith(fontWeight: FontWeight.w600);

  /// Estilo para errores
  static TextStyle error(BuildContext context) =>
      bodyMedium(context).copyWith(color: Colors.red);

  /// Estilo para éxito
  static TextStyle success(BuildContext context) =>
      bodyMedium(context).copyWith(color: Colors.green);

  /// Estilo para texto deshabilitado
  static TextStyle disabled(BuildContext context) =>
      bodyMedium(context).copyWith(color: Colors.grey[500]);

  /// Estilo para texto de ayuda/hint
  static TextStyle hint(BuildContext context) =>
      bodySmall(context).copyWith(color: Colors.grey[600]);

  // ============================================================================
  // HELPER PRIVADO - Aplica textScaleFactor automáticamente
  // ============================================================================

  /// Aplica el factor de escala del dispositivo al estilo
  static TextStyle _applyTextScale(BuildContext context, TextStyle baseStyle) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Si el fontSize es null, retorna el estilo sin cambios
    if (baseStyle.fontSize == null) return baseStyle;

    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * textScaleFactor,
    );
  }
}
