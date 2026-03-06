import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

/// Widget para mostrar badges de estado de entrega (COMPLETA, NOVEDAD, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  }) : super(key: key);

  /// Factory constructor para COMPLETA (verde)
  factory StatusBadge.completa({Key? key}) {
    return StatusBadge(
      key: key,
      label: '✅ Completa',
      icon: Icons.check_circle,
      backgroundColor: Colors.green[100]!,
      textColor: Colors.green[700]!,
      iconColor: Colors.green[700]!,
    );
  }

  /// Factory constructor para NOVEDAD (naranja)
  factory StatusBadge.novedad({Key? key}) {
    return StatusBadge(
      key: key,
      label: '⚠️ Con Novedad',
      icon: Icons.warning,
      backgroundColor: Colors.orange[100]!,
      textColor: Colors.orange[700]!,
      iconColor: Colors.orange[700]!,
    );
  }

  /// Factory constructor para tipo de novedad (rojo)
  factory StatusBadge.tipoNovedad({
    Key? key,
    required String tipoNovedad,
  }) {
    return StatusBadge(
      key: key,
      label: '📋 $tipoNovedad',
      icon: Icons.description_outlined,
      backgroundColor: Colors.red[100]!,
      textColor: Colors.red[700]!,
      iconColor: Colors.red[700]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTextStyles.labelSmall(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
