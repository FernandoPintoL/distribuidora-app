import 'package:flutter/material.dart';
import '../../config/config.dart';

/// AppBar moderno con gradientes automáticos basados en roles o personalizables
///
/// Características:
/// - Gradientes automáticos por rol (admin, preventista, cliente, chofer)
/// - Gradientes personalizados
/// - Support para acciones (actions)
/// - Totalmente reutilizable
///
/// Ejemplo básico con rol:
/// ```dart
/// CustomGradientAppBar(
///   title: 'Mi Pantalla',
///   userRole: 'cliente',
/// )
/// ```
///
/// Ejemplo con gradiente personalizado:
/// ```dart
/// CustomGradientAppBar(
///   title: 'Editar',
///   customGradient: AppGradients.orange,
///   actions: [RefreshAction(...)],
/// )
/// ```
class CustomGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título de texto (alternativa a titleWidget)
  final String? title;

  /// Widget personalizado para el título (alternativa a title)
  final Widget? titleWidget;

  /// Rol del usuario para obtener gradiente automático
  /// Soporta: 'admin', 'preventista', 'cliente', 'chofer'
  final String? userRole;

  /// Gradiente personalizado (sobrescribe el gradiente por rol)
  final Gradient? customGradient;

  /// Lista de acciones (botones) en el AppBar
  final List<Widget>? actions;

  /// Widget personalizado en el lado izquierdo (antes del título)
  final Widget? leading;

  /// Elevación del AppBar (sombra)
  final double elevation;

  /// Color del texto del título
  final Color titleColor;

  /// Color de los iconos
  final Color iconColor;

  /// Si el título está centrado
  final bool centerTitle;

  /// Widget personalizado en la parte inferior del AppBar (ej: TabBar)
  final PreferredSizeWidget? bottom;

  const CustomGradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.userRole,
    this.customGradient,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.titleColor = Colors.white,
    this.iconColor = Colors.white,
    this.centerTitle = false,
    this.bottom,
  })  : assert(
          title != null || titleWidget != null,
          'Either title or titleWidget must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();

    return AppBar(
      title: titleWidget ??
          Text(
            title!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
      elevation: elevation,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(color: iconColor),
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: gradient),
      ),
      bottom: bottom,
    );
  }

  /// Obtiene el gradiente a usar
  /// Prioridad: customGradient > userRole > default (azul)
  Gradient _getGradient() {
    if (customGradient != null) return customGradient!;
    if (userRole != null && userRole!.isNotEmpty) {
      return AppGradients.getRoleGradient(userRole!);
    }
    return AppGradients.blue;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
