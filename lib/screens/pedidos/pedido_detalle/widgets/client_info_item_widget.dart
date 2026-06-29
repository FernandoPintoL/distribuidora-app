import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';

class ClientInfoItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final BuildContext parentContext;

  const ClientInfoItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(parentContext).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTextStyles.labelSmall(parentContext).fontSize!,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTextStyles.bodyMedium(parentContext).fontSize!,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
