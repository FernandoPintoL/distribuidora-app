import 'package:flutter/material.dart';

/// ✅ Widget reutilizable para contenedores con soporte Dark Mode
/// Maneja automáticamente colores claros/oscuros según el tema
class DarkModeContainer extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final Color? borderColor;
  final double borderRadius;
  final double? elevation;
  final EdgeInsets padding;

  const DarkModeContainer({
    Key? key,
    required this.child,
    required this.isDarkMode,
    this.borderColor,
    this.borderRadius = 12,
    this.elevation,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
