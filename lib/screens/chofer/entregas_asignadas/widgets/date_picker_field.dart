import 'package:flutter/material.dart';

import '../../../../config/app_text_styles.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onDateSelected;
  final bool isDarkMode;

  const DatePickerField({
    Key? key,
    required this.label,
    required this.date,
    required this.onDateSelected,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextStyles.labelSmall(context).fontSize!,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Seleccionar',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? (date != null ? Colors.white : Colors.grey[400])
                        : (date != null ? Colors.black87 : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
