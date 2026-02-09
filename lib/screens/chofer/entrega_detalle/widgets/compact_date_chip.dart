import 'package:flutter/material.dart';
import '../../../../utils/date_formatters.dart';

class CompactDateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final bool isDarkMode;
  final ColorScheme colorScheme;
  final bool isSuccess;

  const CompactDateChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.date,
    required this.isDarkMode,
    required this.colorScheme,
    this.isSuccess = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isSuccess
        ? (isDarkMode ? Colors.green[900] : Colors.green[100])
        : (isDarkMode
              ? colorScheme.surface.withValues(alpha: 0.5)
              : colorScheme.primaryContainer.withValues(alpha: 0.08));

    final borderColor = isSuccess
        ? (isDarkMode ? Colors.green[600]! : Colors.green[300]!)
        : (isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.15)
              : colorScheme.outline.withValues(alpha: 0.1));

    final accentColor = isSuccess
        ? (isDarkMode ? Colors.green[400] : Colors.green[700])
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatters.formatCompactDate(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
