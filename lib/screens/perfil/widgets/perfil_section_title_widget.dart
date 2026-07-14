import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../extensions/theme_extension.dart';

class PerfilSectionTitleWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const PerfilSectionTitleWidget({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.secondary.withOpacity(0.2)
                : colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }
}
