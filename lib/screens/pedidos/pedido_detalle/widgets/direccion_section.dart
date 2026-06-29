import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../extensions/theme_extension.dart';

class DireccionSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const DireccionSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final direccion = pedido.direccionEntrega!;
    final colorScheme = Theme.of(parentContext).colorScheme;
    final isDark = parentContext.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dirección de Entrega',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(parentContext).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direccion.direccion ?? '',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodyLarge(
                              parentContext,
                            ).fontSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (direccion.ciudad != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ciudad: ${direccion.ciudad}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (direccion.departamento != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            direccion.departamento!,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        if (direccion.observaciones != null &&
                            direccion.observaciones!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary
                                  .withOpacity(isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Obs: ${direccion.observaciones}',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  parentContext,
                                ).fontSize!,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
