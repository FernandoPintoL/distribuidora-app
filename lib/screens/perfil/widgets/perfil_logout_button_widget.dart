import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import 'dialogs/logout_dialog.dart';

class PerfilLogoutButtonWidget extends StatelessWidget {
  const PerfilLogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => LogoutDialog.show(context),
        icon: const Icon(Icons.logout, size: 22),
        label: Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: AppTextStyles.bodyLarge(context).fontSize!,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

