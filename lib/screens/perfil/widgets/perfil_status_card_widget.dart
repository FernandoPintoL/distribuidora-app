import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../extensions/theme_extension.dart';

class PerfilStatusCardWidget extends StatelessWidget {
  final dynamic user;

  const PerfilStatusCardWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user?.activo ?? false;
    final statusColor = isActive ? Colors.green : Colors.red;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? statusColor.withOpacity(0.1)
            : statusColor.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Cuenta',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: AppTextStyles.headlineSmall(
                          context,
                        ).fontSize!,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
