import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'animated_counter.dart';

/// Widget que muestra estadísticas visuales de entregas del chofer
/// Incluye gráfico circular con entregas completadas vs pendientes
class DashboardStatsCard extends StatelessWidget {
  final int totalEntregas;
  final int entregasCompletadas;
  final int entregasPendientes;

  const DashboardStatsCard({
    Key? key,
    required this.totalEntregas,
    required this.entregasCompletadas,
    required this.entregasPendientes,
  }) : super(key: key);

  /// Calcular el porcentaje de entregas completadas
  double get porcentajeCompletado {
    if (totalEntregas == 0) return 0;
    return (entregasCompletadas / totalEntregas) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cardColor,
      shadowColor: isDarkMode
          ? Colors.black.withAlpha((0.5 * 255).toInt())
          : Colors.grey.withAlpha((0.3 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con decoración
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Estadísticas de Hoy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenido: Gráfico y números
            Row(
              children: [
                // Gráfico Circular
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          // Entregas Completadas
                          PieChartSectionData(
                            value: entregasCompletadas.toDouble(),
                            title: '${entregasCompletadas.toString()}\n✅',
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            color: Colors.green,
                            radius: 55,
                          ),
                          // Entregas Pendientes
                          PieChartSectionData(
                            value: entregasPendientes.toDouble(),
                            title: '${entregasPendientes.toString()}\n⏳',
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            color: Colors.amber[600],
                            radius: 55,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Información Detallada
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total
                      _StatItem(
                        label: 'Total',
                        value: totalEntregas,
                        color: Colors.blue,
                        icon: Icons.inbox_rounded,
                        isAnimated: true,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      // Completadas
                      _StatItem(
                        label: 'Completadas',
                        value: entregasCompletadas,
                        color: Colors.green,
                        icon: Icons.check_circle,
                        isAnimated: true,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      // Pendientes
                      _StatItem(
                        label: 'Pendientes',
                        value: entregasPendientes,
                        color: Colors.amber,
                        icon: Icons.schedule,
                        isAnimated: true,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Barra de progreso mejorada
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso Diario',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalEntregas == 0 ? 0 : porcentajeCompletado / 100,
                    minHeight: 12,
                    backgroundColor: isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      porcentajeCompletado > 75
                          ? Colors.green
                          : porcentajeCompletado > 50
                              ? Colors.amber
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Porcentaje
            Center(
              child: Text(
                '${porcentajeCompletado.toStringAsFixed(1)}% Completado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para mostrar estadísticas individuales
class _StatItem extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  final IconData icon;
  final bool isAnimated;
  final bool isDarkMode;

  const _StatItem({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isAnimated = false,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((0.3 * 255).toInt()),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAnimated && value is int)
            AnimatedCounter(
              endValue: value as int,
              textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ) ?? const TextStyle(),
            )
          else
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
        ],
      ),
    );
  }
}
