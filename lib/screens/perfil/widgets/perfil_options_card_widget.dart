import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../extensions/theme_extension.dart';

class PerfilRoleSpecificOptionsWidget extends StatelessWidget {
  final dynamic user;
  final String primaryRole;

  const PerfilRoleSpecificOptionsWidget({
    super.key,
    required this.user,
    required this.primaryRole,
  });

  @override
  Widget build(BuildContext context) {
    switch (primaryRole.toLowerCase()) {
      case 'cliente':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Importar el widget de sección de título desde donde esté disponible
            _buildSectionTitle(context, 'Mis Opciones', Icons.tune),
            const SizedBox(height: 12),
            _buildClientOptionsCard(context),
            const SizedBox(height: 24),
          ],
        );
      case 'preventista':
      case 'chofer':
      case 'admin':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.secondary.withOpacity(0.2)
                : colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildClientOptionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _buildModernOptionTile(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Mis Direcciones',
              subtitle: 'Gestionar direcciones de entrega',
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              onTap: () => Navigator.pushNamed(context, '/mis-direcciones'),
            ),
            // const Divider(height: 1, indent: 72),
            /*_buildModernOptionTile(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: 'Mis Pedidos',
              subtitle: 'Ver historial de pedidos',
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad en desarrollo'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildModernOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: context.textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
