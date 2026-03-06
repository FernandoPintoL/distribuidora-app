import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

/// Widget para mostrar una columna con etiqueta y valor
class InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final bool isDarkMode;
  final TextAlign valueAlign;
  final MainAxisAlignment mainAxisAlignment;

  const InfoColumn({
    Key? key,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    required this.isDarkMode,
    this.valueAlign = TextAlign.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextStyles.bodySmall(context).fontSize!,
            color: labelColor ?? (isDarkMode ? Colors.blue[200] : Colors.blue[800]),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTextStyles.headlineMedium(context).fontSize!,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
          textAlign: valueAlign,
        ),
      ],
    );
  }
}
