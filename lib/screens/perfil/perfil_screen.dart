import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/role_based_router.dart';

/// Pantalla de perfil compartida para todos los roles
/// - Cliente
/// - Chofer
/// - Preventista
/// - Admin
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del perfil
              _buildProfileHeader(context, user),
              const SizedBox(height: 32),

              // Información personal
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.person,
                title: 'Nombre',
                value: user?.name ?? 'No disponible',
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.email,
                title: 'Correo Electrónico',
                value: user?.email ?? 'No disponible',
              ),
              const SizedBox(height: 8),
              if (user?.usernick != null)
                Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.account_circle,
                      title: 'Usuario',
                      value: '@${user?.usernick}',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),

              // Roles y permisos
              _buildSectionTitle('Roles y Permisos'),
              const SizedBox(height: 12),
              _buildRolesCard(user),
              const SizedBox(height: 24),

              // Estado del usuario
              _buildSectionTitle('Estado'),
              const SizedBox(height: 12),
              _buildStatusCard(user),
              const SizedBox(height: 32),

              // Botón de cerrar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              (user?.name ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Usuario',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RoleBasedRouter.getRoleDescription(user),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesCard(dynamic user) {
    final roles = user?.roles ?? [];

    if (roles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Sin roles asignados',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (roles as List<dynamic>).map((role) {
            return Chip(
              label: Text(
                _getRoleLabel(role.toString()),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: _getRoleColor(role.toString()),
              avatar: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: _getRoleIcon(role.toString()),
              ),
            );
          }).toList() as List<Widget>,
        ),
      ),
    );
  }

  Widget _buildStatusCard(dynamic user) {
    final isActive = user?.activo ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 8,
              backgroundColor: isActive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado de Cuenta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'preventista':
        return 'Preventista';
      case 'cliente':
        return 'Cliente';
      case 'chofer':
        return 'Chofer';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'preventista':
        return Colors.orange;
      case 'cliente':
        return Colors.blue;
      case 'chofer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getRoleIcon(String role) {
    IconData icon;
    switch (role.toLowerCase()) {
      case 'admin':
        icon = Icons.security;
        break;
      case 'preventista':
        icon = Icons.business_center;
        break;
      case 'cliente':
        icon = Icons.shopping_bag;
        break;
      case 'chofer':
        icon = Icons.local_shipping;
        break;
      default:
        icon = Icons.person;
    }
    return Icon(icon, size: 12, color: Colors.white);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
