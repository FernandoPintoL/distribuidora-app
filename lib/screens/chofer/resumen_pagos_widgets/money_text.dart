import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

/// Widget para mostrar texto de dinero con estilo consistente
class MoneyText extends StatelessWidget {
  final double amount;
  final String prefix;
  final Color? color;
  final FontWeight fontWeight;
  final double? fontSize;
  final bool isDarkMode;
  final int decimalPlaces;
  final bool strikethrough;

  const MoneyText(
    this.amount, {
    Key? key,
    this.prefix = 'Bs. ',
    this.color,
    this.fontWeight = FontWeight.bold,
    this.fontSize,
    required this.isDarkMode,
    this.decimalPlaces = 2,
    this.strikethrough = false,
  }) : super(key: key);

  /// Factory para monto grande (títulos)
  factory MoneyText.large(
    double amount, {
    Key? key,
    required bool isDarkMode,
    Color? color,
  }) {
    return MoneyText(
      amount,
      key: key,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: color ?? (isDarkMode ? Colors.white : Colors.black),
      isDarkMode: isDarkMode,
    );
  }

  /// Factory para monto mediano
  factory MoneyText.medium(
    double amount, {
    Key? key,
    required bool isDarkMode,
    Color? color,
  }) {
    return MoneyText(
      amount,
      key: key,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color ?? (isDarkMode ? Colors.grey[100] : Colors.grey[900]),
      isDarkMode: isDarkMode,
    );
  }

  /// Factory para monto pequeño
  factory MoneyText.small(
    double amount, {
    Key? key,
    required bool isDarkMode,
    Color? color,
  }) {
    return MoneyText(
      amount,
      key: key,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color ?? (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
      isDarkMode: isDarkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$prefix${amount.toStringAsFixed(decimalPlaces)}',
      style: TextStyle(
        fontSize: fontSize ?? AppTextStyles.bodyMedium(context).fontSize,
        fontWeight: fontWeight,
        color: color ?? (isDarkMode ? Colors.blue[100] : Colors.blue[900]),
        decoration: strikethrough ? TextDecoration.lineThrough : null,
      ),
    );
  }
}
