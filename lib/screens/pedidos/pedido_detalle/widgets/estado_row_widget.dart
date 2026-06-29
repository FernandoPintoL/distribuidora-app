import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';

class EstadoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final EstadoDocumento estadoData;
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

  @override
  Widget build(BuildContext context) {
    Color estadoColor = Colors.grey;
    try {
      if (estadoData.color != null && estadoData.color!.startsWith('#')) {
        estadoColor = Color(
          int.parse(estadoData.color!.replaceFirst('#', '0xff')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing color: ${estadoData.color}');
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
                      estadoData.nombre,
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
