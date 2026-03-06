import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

/// Widget para mostrar un par etiqueta + cantidad de dinero
/// Usado para mostrar totales, montos devueltos, etc.
class MoneyRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? labelColor;
  final Color? amountColor;
  final bool isDarkMode;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;
  final Widget? rightWidget; // Alternativa a amount para mostrar widget personalizado
  final String prefix; // Prefijo de moneda (default: "Bs. ")

  const MoneyRow({
    Key? key,
    required this.label,
    required this.amount,
    this.labelColor,
    this.amountColor,
    required this.isDarkMode,
    this.labelStyle,
    this.amountStyle,
    this.rightWidget,
    this.prefix = 'Bs. ',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Etiqueta a la izquierda
        Expanded(
          child: Text(
            label,
            style: labelStyle ??
                TextStyle(
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? (isDarkMode ? Colors.grey[100] : Colors.grey[900]),
                ),
          ),
        ),
        // Monto o widget personalizado a la derecha
        if (rightWidget != null)
          rightWidget!
        else
          Text(
            '$prefix${amount.toStringAsFixed(2)}',
            style: amountStyle ??
                TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w900,
                  color: amountColor ?? (isDarkMode ? Colors.grey[50] : Colors.grey[950]),
                ),
          ),
      ],
    );
  }
}
