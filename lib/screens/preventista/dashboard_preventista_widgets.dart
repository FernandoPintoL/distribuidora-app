import 'package:flutter/material.dart';

import '../../config/app_text_styles.dart';

/// Widget builders para el Dashboard Preventista
class DashboardPreventistaWidgets {
  static Widget buildGradientCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 28, color: color)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildProgressCard(
    BuildContext context, {
    required String title,
    required int current,
    required int total,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, size: 22, color: color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$current de $total',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTextStyles.displaySmall(context).fontSize!,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildStatItem(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: AppTextStyles.displaySmall(context).fontSize!,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Card de Clientes con estadísticas dentro del componente
  static Widget buildClientesCard(
    BuildContext context, {
    required int totalBd,
    required int asignados,
    required int sinAsignar,
    required int activos,
    required int inactivos,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 28, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                'Clientes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              _buildStatLine('Total', totalBd.toString()),
              _buildStatLine('Mis clientes', asignados.toString()),
              // _buildStatLine('Sin Asignar', sinAsignar.toString()),
              // _buildStatLine('Activos', activos.toString()),
              // _buildStatLine('Inactivos', inactivos.toString()),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de Pedidos con estadísticas dentro del componente
  static Widget buildPedidosCard(
    BuildContext context, {
    required int proformasPendientes,
    required int proformasConvertidas,
    required int proformasRechazadas,
    required int entregaPendientes,
    required int entregaConvertidas,
    required int entregaRechazadas,
    required int ventasAprobadas,
    required int ventasAnuladas,
    required int totalVentas,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(height: 2),
                Text(
                  'Mis Pedidos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildMiniSection('Creadas Hoy', Colors.amber),
                _buildCompactStatLine(
                  'Pendientes',
                  proformasPendientes.toString(),
                ),
                _buildCompactStatLine(
                  'Convertidas',
                  proformasConvertidas.toString(),
                ),
                _buildCompactStatLine(
                  'Rechazadas',
                  proformasRechazadas.toString(),
                ),
                const SizedBox(height: 4),
                _buildMiniSection('Solicitadas Hoy', Colors.cyan),
                _buildCompactStatLine(
                  'Pendientes',
                  entregaPendientes.toString(),
                ),
                _buildCompactStatLine(
                  'Convertidas',
                  entregaConvertidas.toString(),
                ),
                _buildCompactStatLine(
                  'Rechazadas',
                  entregaRechazadas.toString(),
                ),
                const SizedBox(height: 4),
                _buildMiniSection('Ventas Hoy', Colors.lightGreen),
                _buildCompactStatLine('Aprobadas', ventasAprobadas.toString()),
                _buildCompactStatLine('Anuladas', ventasAnuladas.toString()),
                _buildCompactStatLine('Total', totalVentas.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCompactStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMiniSection(String title, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Card de Reporte de Ventas con estadísticas dentro del componente
  static Widget buildReportVentasCard(
    BuildContext context, {
    required int cantidadProductos,
    required int sumaProductos,
    required int cantidadItems,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_outlined, size: 24, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                'Reporte de Ventas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildCompactStatLine(
                'Total Productos',
                cantidadItems.toString(),
              ),
              const SizedBox(height: 6),
              _buildCompactStatLine('Productos', cantidadProductos.toString()),
              _buildCompactStatLine(
                'Monto Total',
                "${_formatMoney(sumaProductos)} Bs",
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMoney(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
