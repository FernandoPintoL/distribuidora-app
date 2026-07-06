import 'package:flutter/material.dart';
import '../../../../extensions/theme_extension.dart';

class ObservacionesSection extends StatelessWidget {
  final String observaciones;
  final BuildContext parentContext;
  final bool isRechazo;
  final String? titulo;
  final String? estadoLogisticoColor;

  const ObservacionesSection({
    super.key,
    required this.observaciones,
    required this.parentContext,
    this.isRechazo = false,
    this.titulo,
    this.estadoLogisticoColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = parentContext.isDark;
    final colorScheme = parentContext.colorScheme;

    debugPrint("Color del estado logístico: $estadoLogisticoColor");

    Color _getCardColor() {
      if (isRechazo) return Colors.red.withOpacity(0.15);
      if (estadoLogisticoColor != null) {
        try {
          final hex = estadoLogisticoColor!.replaceFirst('#', '');
          return Color(int.parse('FF$hex', radix: 16)).withOpacity(0.15);
        } catch (e) {
          return colorScheme.surface;
        }
      } else {
        return colorScheme.surface;
      }
    }

    Color _getBorderColor() {
      if (isRechazo) return Colors.red.withOpacity(0.5);
      if (estadoLogisticoColor != null) {
        try {
          final hex = estadoLogisticoColor!.replaceFirst('#', '');
          return Color(int.parse('FF$hex', radix: 16)).withOpacity(0.3);
        } catch (e) {
          return colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15);
        }
      }
      return colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15);
    }

    return Card(
      elevation: 0,
      color: _getCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getBorderColor()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo ??
                  (isRechazo ? 'Observaciones de Rechazo' : 'Observaciones'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(
              height: 20,
              color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
            ),
            Text(observaciones, style: TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
