import 'package:flutter/material.dart';

import '../../../../config/app_text_styles.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextStyles.bodySmall(context).fontSize!,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTextStyles.bodyMedium(context).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
