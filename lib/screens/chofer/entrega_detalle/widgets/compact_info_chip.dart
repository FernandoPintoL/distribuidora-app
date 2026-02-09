import 'package:flutter/material.dart';

class CompactInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;
  final ColorScheme colorScheme;

  const CompactInfoChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.08),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.15)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
