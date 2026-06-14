import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

class EntregaInfoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final VoidCallback? onSecondaryTap;

  const EntregaInfoRowWidget({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
    this.onSecondaryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onSecondaryTap,
                  child: Text(
                    secondaryValue!,
                    style: TextStyle(
                      color: onSecondaryTap != null ? Colors.blue : Colors.grey,
                      decoration: onSecondaryTap != null
                          ? TextDecoration.underline
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
