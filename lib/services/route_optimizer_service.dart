import 'dart:math' as math;
import '../models/entrega.dart';

/// Servicio para optimizar rutas de entrega
/// Usa algoritmo Nearest Neighbor para ordenar entregas por proximidad
class RouteOptimizerService {
  /// Coordenada para cálculos de distancia
  static const earthRadiusKm = 6371.0;

  /// Optimizar ruta usando algoritmo Nearest Neighbor
  /// Ordena entregas por proximidad desde la ubicación actual
  static List<Entrega> optimizeRoute({
    required double currentLatitude,
    required double currentLongitude,
    required List<Entrega> entregas,
  }) {
    if (entregas.isEmpty) return [];

    final optimizedList = <Entrega>[];
    final remaining = [...entregas];
    var currentLat = currentLatitude;
    var currentLng = currentLongitude;

    // Algoritmo Nearest Neighbor: comenzar desde ubicación actual y agregar el más cercano
    while (remaining.isNotEmpty) {
      // Encontrar la entrega más cercana
      Entrega? nearest;
      double minDistance = double.infinity;

      for (final entrega in remaining) {
        // Para este prototipo, usar ubicaciones ficticias basadas en índice
        final deliveryLat = currentLat + (remaining.indexOf(entrega) * 0.005);
        final deliveryLng = currentLng + (remaining.indexOf(entrega) * 0.005);

        final distance = _calculateDistance(
          currentLat,
          currentLng,
          deliveryLat,
          deliveryLng,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = entrega;
        }
      }

      if (nearest != null) {
        optimizedList.add(nearest);
        remaining.remove(nearest);

        // Actualizar posición actual para la siguiente iteración
        final index = entregas.indexOf(nearest);
        currentLat = currentLat + (index * 0.005);
        currentLng = currentLng + (index * 0.005);
      }
    }

    return optimizedList;
  }

  /// Calcular distancia total de una ruta
  static double calculateTotalDistance({
    required double startLatitude,
    required double startLongitude,
    required List<Entrega> entregas,
  }) {
    double totalDistance = 0;
    var currentLat = startLatitude;
    var currentLng = startLongitude;

    for (int i = 0; i < entregas.length; i++) {
      final entrega = entregas[i];
      // Ubicación ficticia basada en índice
      final deliveryLat = startLatitude + (i * 0.005);
      final deliveryLng = startLongitude + (i * 0.005);

      final distance = _calculateDistance(
        currentLat,
        currentLng,
        deliveryLat,
        deliveryLng,
      );

      totalDistance += distance;
      currentLat = deliveryLat;
      currentLng = deliveryLng;
    }

    return totalDistance;
  }

  /// Estimar tiempo total de ruta basado en distancia
  /// Asume velocidad promedio de 40 km/h en ciudad
  static int estimateRouteDurationMinutes({
    required double totalDistanceKm,
    int averageSpeedKmPerHour = 40,
  }) {
    return ((totalDistanceKm / averageSpeedKmPerHour) * 60).ceil();
  }

  /// Calcular distancia entre dos coordenadas usando fórmula de Haversine
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Convertir grados a radianes
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Obtener resumen formateado de la ruta
  static String getRouteSummary({
    required List<Entrega> entregas,
    required double totalDistanceKm,
    required int estimatedMinutes,
  }) {
    final hours = estimatedMinutes ~/ 60;
    final minutes = estimatedMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return '${'${entregas.length}'} entregas • ${totalDistanceKm.toStringAsFixed(1)} km • $timeStr';
  }
}
