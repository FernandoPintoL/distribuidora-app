import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../extensions/theme_extension.dart';

class ObservacionesSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const ObservacionesSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = parentContext.isDark;
    final colorScheme = parentContext.colorScheme;
    final textTheme = parentContext.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observaciones',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Divider(
                height: 20,
                color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.15),
              ),
              Text(
                pedido.observaciones!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
