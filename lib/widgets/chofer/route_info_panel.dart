import 'package:flutter/material.dart';
import '../../models/entrega.dart';
import '../../services/route_optimizer_service.dart';

/// Panel que muestra información estadística de la ruta actual
/// Incluye distancia total, tiempo estimado, próxima entrega, etc.
class RouteInfoPanel extends StatelessWidget {
  final List<Entrega> entregas;
  final double? currentLatitude;
  final double? currentLongitude;

  const RouteInfoPanel({
    Key? key,
    required this.entregas,
    this.currentLatitude,
    this.currentLongitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener entregas pendientes
    final pendingEntregas = entregas
        .where((e) => e.estado != 'ENTREGADO' && e.estado != 'CANCELADA')
        .toList();

    // Calcular estadísticas de ruta (con ubicación actual)
    double totalDistance = 0;
    int estimatedMinutes = 0;

    if (currentLatitude != null && currentLongitude != null) {
      totalDistance = RouteOptimizerService.calculateTotalDistance(
        startLatitude: currentLatitude!,
        startLongitude: currentLongitude!,
        entregas: pendingEntregas,
      );

      estimatedMinutes = RouteOptimizerService.estimateRouteDurationMinutes(
        totalDistanceKm: totalDistance,
        averageSpeedKmPerHour: 40,
      );
    }

    // Próxima entrega
    final nextEntrega = pendingEntregas.isNotEmpty ? pendingEntregas.first : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              '🗺️ Información de Ruta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Grid de estadísticas
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                // Total entregas
                _StatisticBox(
                  icon: Icons.local_shipping,
                  label: 'Total',
                  value: pendingEntregas.length.toString(),
                  color: Colors.blue,
                ),

                // Distancia total
                _StatisticBox(
                  icon: Icons.directions,
                  label: 'Distancia',
                  value: '${totalDistance.toStringAsFixed(1)} km',
                  color: Colors.green,
                ),

                // Tiempo estimado
                _StatisticBox(
                  icon: Icons.schedule,
                  label: 'Tiempo',
                  value: _formatDuration(estimatedMinutes),
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Próxima entrega
            if (nextEntrega != null) ...[
              Text(
                'Próxima Entrega',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nextEntrega.tipoWorkIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${nextEntrega.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                nextEntrega.cliente ?? 'Cliente desconocido',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            nextEntrega.estadoLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (nextEntrega.direccion != null &&
                        nextEntrega.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              nextEntrega.direccion!,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '✅ ¡Todas las entregas completadas!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: entregas.isEmpty
                    ? 0
                    : (entregas.length - pendingEntregas.length) / entregas.length,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${entregas.length - pendingEntregas.length}/${entregas.length} completadas',
                style: TextStyle(
                  fontSize: 12,
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

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// Widget para mostrar una estadística individual
class _StatisticBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticBox({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
