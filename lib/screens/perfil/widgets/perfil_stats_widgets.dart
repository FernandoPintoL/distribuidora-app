import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_text_styles.dart';
import '../../../providers/providers.dart';

class PerfilRoleSpecificStatsWidget extends StatelessWidget {
  final dynamic user;
  final String primaryRole;

  const PerfilRoleSpecificStatsWidget({
    super.key,
    required this.user,
    required this.primaryRole,
  });

  @override
  Widget build(BuildContext context) {
    switch (primaryRole.toLowerCase()) {
      case 'cliente':
        return _buildClientStats(context);
      case 'preventista':
        return _buildPreventistaStats(context);
      case 'chofer':
        return _buildChoferStats(context);
      case 'admin':
        return _buildAdminStats(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade600.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Resumen de Compras',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Pedidos',
                  '0',
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Direcciones',
                  '0',
                  Icons.location_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreventistaStats(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final stats = authProvider.preventistaStats;
        final totalClientesBd = stats?.totalClientesBd ?? 0;
        final clientesActivos = stats?.clientesActivos ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Panel de Ventas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Total Clientes',
                      totalClientesBd.toString(),
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Clientes Activos',
                      clientesActivos.toString(),
                      Icons.person_add,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoferStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Panel de Entregas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Entregas',
                  '0',
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem(context, 'Rutas', '0', Icons.map)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Panel de Administración',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextStyles.headlineSmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(context, 'Usuarios', '0', Icons.people),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(context, 'Sistema', 'OK', Icons.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
