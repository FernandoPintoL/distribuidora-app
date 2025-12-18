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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              '📊 Estadísticas de Hoy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Contenido: Gráfico y números
            Row(
              children: [
                // Gráfico Circular
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          // Entregas Completadas (Verde)
                          PieChartSectionData(
                            value: entregasCompletadas.toDouble(),
                            title: '${entregasCompletadas.toString()}\n✅',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            color: Colors.green,
                            radius: 80,
                          ),
                          // Entregas Pendientes (Gris)
                          PieChartSectionData(
                            value: entregasPendientes.toDouble(),
                            title: '${entregasPendientes.toString()}\n⏳',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            color: Colors.grey[400],
                            radius: 80,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
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
                        icon: '📦',
                        isAnimated: true,
                      ),
                      const SizedBox(height: 12),

                      // Completadas
                      _StatItem(
                        label: 'Completadas',
                        value: entregasCompletadas,
                        color: Colors.green,
                        icon: '✅',
                        isAnimated: true,
                      ),
                      const SizedBox(height: 12),

                      // Pendientes
                      _StatItem(
                        label: 'Pendientes',
                        value: entregasPendientes,
                        color: Colors.orange,
                        icon: '⏳',
                        isAnimated: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalEntregas == 0 ? 0 : porcentajeCompletado / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  porcentajeCompletado > 75
                      ? Colors.green
                      : porcentajeCompletado > 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Porcentaje
            Center(
              child: Text(
                '${porcentajeCompletado.toStringAsFixed(1)}% Completado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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
  final String icon;
  final bool isAnimated;

  const _StatItem({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isAnimated = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          if (isAnimated && value is int)
            AnimatedCounter(
              endValue: value as int,
              textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ) ?? const TextStyle(),
            )
          else
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
