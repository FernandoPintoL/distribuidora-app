import 'package:flutter/material.dart';
import '../../../../models/entrega_info.dart';
import '../../../../config/app_colors.dart';
import '../../../../extensions/theme_extension.dart';

class EntregaInfoWidget extends StatelessWidget {
  final EntregaInfo entrega;

  const EntregaInfoWidget({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      color: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withAlpha(20), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    Text(
                      ' Información de Entrega',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                // Estado de Entrega
                if (entrega.estadoEntrega != null)
                  _buildInfoSection(
                    context,
                    icon: Icons.info_outline,
                    label: 'Estado',
                    value: entrega.estadoEntrega!.nombre,
                    color: entrega.estadoEntrega!.color,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Chofer
                if (entrega.chofer != null)
                  Expanded(
                    child: _buildInfoSection(
                      context,
                      icon: Icons.person_outline,
                      label: 'Chofer',
                      value: entrega.chofer!.nombre,
                      subValue: entrega.chofer!.telefono,
                    ),
                  ),
                if (entrega.chofer != null && entrega.vehiculo != null)
                  const SizedBox(width: 16),

                // Vehículo
                if (entrega.vehiculo != null)
                  Expanded(
                    child: _buildInfoSection(
                      context,
                      icon: Icons.directions_car_outlined,
                      label: 'Vehículo',
                      value: entrega.vehiculo!.placa,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    String? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
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
