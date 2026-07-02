import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';

class InfoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext parentContext;
  final Color colorIcon;
  final Color colorText;

  const InfoRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.parentContext,
    this.colorIcon = Colors.white,
    this.colorText = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorIcon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colorText)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500, color: colorText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
