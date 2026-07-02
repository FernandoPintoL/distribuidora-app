import 'package:flutter/material.dart';

/// AppBar simple que respeta los temas claro/oscuro del dispositivo
///
/// Características:
/// - Usa colores del tema (no gradientes)
/// - Respeta preferencias light/dark del dispositivo
/// - Support para acciones (actions)
/// - Totalmente reutilizable
///
/// Ejemplo:
/// ```dart
/// CustomGradientAppBar(
///   title: 'Mi Pantalla',
/// )
/// ```
class CustomGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Título de texto (alternativa a titleWidget)
  final String? title;

  /// Widget personalizado para el título (alternativa a title)
  final Widget? titleWidget;

  /// Lista de acciones (botones) en el AppBar
  final List<Widget>? actions;

  /// Widget personalizado en el lado izquierdo (antes del título)
  final Widget? leading;

  /// Elevación del AppBar (sombra)
  final double elevation;

  /// Si el título está centrado
  final bool centerTitle;

  /// Widget personalizado en la parte inferior del AppBar (ej: TabBar)
  final PreferredSizeWidget? bottom;

  /// ✅ NUEVO 2026-06-15: Color de fondo personalizado (hex string o Color)
  final Color? backgroundColor;

  const CustomGradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.centerTitle = false,
    this.bottom,
    this.backgroundColor,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    // ✅ NUEVO 2026-06-15: Usar color personalizado o fallback a deepOrange
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;

    return AppBar(
      title:
          titleWidget ??
          Text(title!, style: const TextStyle(fontWeight: FontWeight.bold)),
      elevation: elevation,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
