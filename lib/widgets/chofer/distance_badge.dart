import 'package:flutter/material.dart';
import 'dart:math' as Math;

/// Widget que muestra la distancia y tiempo estimado hacia una entrega
/// Calcula usando fórmula de Haversine basada en coordenadas
class DistanceBadge extends StatelessWidget {
  final double distanceKm;
  final int estimatedMinutes;

  const DistanceBadge({
    Key? key,
    required this.distanceKm,
    required this.estimatedMinutes,
  }) : super(key: key);

  /// Crear badge desde coordenadas (calcular distancia internamente)
  /// Usa fórmula de Haversine para calcular distancia entre dos puntos
  static DistanceBadge fromCoordinates({
    required double currentLat,
    required double currentLng,
    required double deliveryLat,
    required double deliveryLng,
  }) {
    final distanceKm = _calculateDistance(
      currentLat,
      currentLng,
      deliveryLat,
      deliveryLng,
    );

    // Estimar tiempo: 40 km/h promedio en ciudad
    final estimatedMinutes = ((distanceKm / 40) * 60).ceil();

    return DistanceBadge(
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Calcular distancia entre dos coordenadas usando Haversine
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_degreesToRadians(lat1)) *
            Math.cos(_degreesToRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de distancia
          const Icon(
            Icons.location_on,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 6),

          // Distancia
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(width: 12),

          // Separador visual
          Container(
            width: 1,
            height: 16,
            color: Colors.grey[300],
          ),

          const SizedBox(width: 12),

          // Icono de tiempo
          const Icon(
            Icons.schedule,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 6),

          // Tiempo estimado
          Text(
            '$estimatedMinutes min',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
