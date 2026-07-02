import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';

class EstadoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic estadoData; // Acepta EstadoDocumento o EstadoLogistico
  final ColorScheme colorScheme;
  final BuildContext parentContext;

  const EstadoRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.estadoData,
    required this.colorScheme,
    required this.parentContext,
  });

  String get _nombre {
    if (estadoData is EstadoDocumento) {
      return (estadoData as EstadoDocumento).nombre;
    } else if (estadoData is EstadoLogistico) {
      return (estadoData as EstadoLogistico).nombre;
    }
    return 'Desconocido';
  }

  String? get _color {
    if (estadoData is EstadoDocumento) {
      return (estadoData as EstadoDocumento).color;
    } else if (estadoData is EstadoLogistico) {
      return (estadoData as EstadoLogistico).color;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color estadoColor = Colors.grey;
    try {
      if (_color != null && _color!.startsWith('#')) {
        estadoColor = Color(
          int.parse(_color!.replaceFirst('#', '0xff')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing color: $_color');
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: estadoColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: estadoColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _nombre,
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(parentContext).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
