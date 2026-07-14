import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../extensions/theme_extension.dart';
import '../helpers/perfil_helpers.dart';

class PerfilRolesCardWidget extends StatelessWidget {
  final dynamic user;

  const PerfilRolesCardWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final roles = user?.roles ?? [];
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    if (roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Sin roles asignados',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withAlpha(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: (roles as List<dynamic>).map((role) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  getRoleColor(role.toString()),
                  getRoleColor(role.toString()).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: getRoleColor(role.toString()).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getRolePrimaryIcon(role.toString()),
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  getRoleLabel(role.toString()),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
