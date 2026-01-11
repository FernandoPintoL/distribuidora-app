import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

/// Widget que muestra el estado completo del tracking GPS en tiempo real
/// Incluye: ubicación, velocidad, precisión, rumbo, distancia al destino,
/// indicador de movimiento y distancia recorrida.
class GpsTrackingStatusWidget extends StatelessWidget {
  final bool isTracking;
  final Position? ultimaUbicacion;
  final double? destinoLatitud;
  final double? destinoLongitud;
  final double distanciaRecorrida;
  final bool compact; // false = expandido (por defecto)
  final VoidCallback? onRetry; // Callback para reintentar
  final bool isRetrying; // Indica si está intentando reconectar

  const GpsTrackingStatusWidget({
    Key? key,
    required this.isTracking,
    required this.ultimaUbicacion,
    this.destinoLatitud,
    this.destinoLongitud,
    this.distanciaRecorrida = 0.0,
    this.compact = false,
    this.onRetry,
    this.isRetrying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determinar el color basado en el estado del GPS
    final color = _getGpsColor();
    final bgColor = isDarkMode
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.15);
    final borderColor = isDarkMode
        ? color.withOpacity(0.6)
        : color.withOpacity(0.7);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado
            Row(
              children: [
                Icon(
                  isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  size: 24,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Tracking ${isTracking ? "Activo" : "Inactivo"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (isTracking && ultimaUbicacion != null)
                        Text(
                          _getGpsHealthStatus(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (isTracking && ultimaUbicacion != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Grid de métricas principales
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  // Velocidad
                  TrackingMetricBadge(
                    icon: Icons.speed,
                    label: 'Velocidad',
                    value: _getSpeedKmh(),
                    color: color,
                  ),

                  // Precisión
                  TrackingMetricBadge(
                    icon: Icons.my_location,
                    label: 'Precisión',
                    value: _getAccuracyLabel(),
                    color: _getAccuracyColor(),
                  ),

                  // Movimiento
                  TrackingMetricBadge(
                    icon: _getMovementIcon(),
                    label: 'Estado',
                    value: _getMovementStatus(),
                    color: _getMovementColor(),
                  ),

                  // Última actualización
                  TrackingMetricBadge(
                    icon: Icons.access_time,
                    label: 'Actualizado',
                    value: _getLastUpdateText(),
                    color: _getUpdateTimeColor(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Sección de ubicación
              _buildLocationSection(isDarkMode, color),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Sección de distancias
              _buildDistanceSection(isDarkMode, color),
            ] else if (!isTracking) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicia la entrega para activar el tracking de GPS',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón de reintentar
                    if (onRetry != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isRetrying ? null : onRetry,
                          icon: isRetrying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(isRetrying ? 'Reintentando...' : 'Reintentar Conexión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construir sección de ubicación (coordenadas, rumbo, altitud)
  Widget _buildLocationSection(bool isDarkMode, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación Actual',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Coordenadas
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ultimaUbicacion!.latitude.toStringAsFixed(6)}, ${ultimaUbicacion!.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Rumbo y Altitud
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.navigation, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Rumbo: ${_getCardinalDirection()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.height, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '${ultimaUbicacion!.altitude.toStringAsFixed(1)}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir sección de distancias (al destino y recorrida)
  Widget _buildDistanceSection(bool isDarkMode, Color color) {
    final distanciaDestino = destinoLatitud != null && destinoLongitud != null
        ? _calculateDistanceToDestination()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso de Entrega',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Distancia recorrida
        Row(
          children: [
            Icon(Icons.route, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recorrida: ${distanciaRecorrida.toStringAsFixed(2)} km',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),

        if (distanciaDestino != null) ...[
          const SizedBox(height: 8),

          // Distancia restante
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restante: ${distanciaDestino.toStringAsFixed(2)} km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tiempo estimado
          Row(
            children: [
              Icon(Icons.timer, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimado: ${_getEstimatedTimeText(distanciaDestino)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ======================== MÉTODOS HELPER ========================

  /// Obtener color basado en estado de salud GPS
  Color _getGpsColor() {
    if (!isTracking) return Colors.grey;
    if (ultimaUbicacion == null) return Colors.red;

    final timeDiff = DateTime.now().difference(ultimaUbicacion!.timestamp);
    if (timeDiff.inSeconds > 60) return Colors.red;

    if (ultimaUbicacion!.accuracy < 20) return Colors.green;
    if (ultimaUbicacion!.accuracy < 50) return Colors.amber;
    return Colors.red;
  }

  /// Obtener descripción de estado GPS
  String _getGpsHealthStatus() {
    if (ultimaUbicacion == null) return 'Sin señal GPS';

    final accuracy = ultimaUbicacion!.accuracy;
    if (accuracy < 20) return '✓ Señal excelente';
    if (accuracy < 50) return '⚠ Señal aceptable';
    return '✗ Señal pobre';
  }

  /// Convertir velocidad de m/s a km/h y formatear
  String _getSpeedKmh() {
    if (ultimaUbicacion == null) return '0 km/h';
    final speedKmh = ultimaUbicacion!.speed * 3.6;
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  /// Formatear precisión con clasificación
  String _getAccuracyLabel() {
    if (ultimaUbicacion == null) return 'N/A';
    final accuracy = ultimaUbicacion!.accuracy;
    return '${accuracy.toStringAsFixed(1)}m';
  }

  /// Obtener color de precisión
  Color _getAccuracyColor() {
    if (ultimaUbicacion == null) return Colors.grey;
    if (ultimaUbicacion!.accuracy < 20) return Colors.green;
    if (ultimaUbicacion!.accuracy < 50) return Colors.amber;
    return Colors.red;
  }

  /// Obtener texto de última actualización
  String _getLastUpdateText() {
    if (ultimaUbicacion == null) return 'N/A';
    final diff = DateTime.now().difference(ultimaUbicacion!.timestamp);

    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    return 'hace ${diff.inHours}h';
  }

  /// Obtener color de tiempo de actualización
  Color _getUpdateTimeColor() {
    if (ultimaUbicacion == null) return Colors.grey;
    final diff = DateTime.now().difference(ultimaUbicacion!.timestamp);

    if (diff.inSeconds < 15) return Colors.green;
    if (diff.inSeconds < 30) return Colors.amber;
    return Colors.red;
  }

  /// Convertir grados de rumbo a dirección cardinal
  String _getCardinalDirection() {
    if (ultimaUbicacion == null) return 'N/A';
    final heading = ultimaUbicacion!.heading % 360;

    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((heading + 11.25) / 22.5).toInt() % 16;

    return '${directions[index]} (${heading.toStringAsFixed(0)}°)';
  }

  /// Obtener estado de movimiento
  String _getMovementStatus() {
    if (ultimaUbicacion == null) return 'Desconocido';
    // 1 m/s = 3.6 km/h
    return ultimaUbicacion!.speed < 1.0 ? 'Detenido' : 'En movimiento';
  }

  /// Obtener ícono de movimiento
  IconData _getMovementIcon() {
    if (ultimaUbicacion == null) return Icons.help_outline;
    return ultimaUbicacion!.speed < 1.0 ? Icons.pause_circle : Icons.directions_run;
  }

  /// Obtener color de movimiento
  Color _getMovementColor() {
    if (ultimaUbicacion == null) return Colors.grey;
    return ultimaUbicacion!.speed < 1.0 ? Colors.amber : Colors.green;
  }

  /// Calcular distancia al destino usando fórmula Haversine
  double _calculateDistanceToDestination() {
    if (destinoLatitud == null || destinoLongitud == null || ultimaUbicacion == null) {
      return 0.0;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(destinoLatitud! - ultimaUbicacion!.latitude);
    final dLon = _degreesToRadians(destinoLongitud! - ultimaUbicacion!.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(ultimaUbicacion!.latitude)) *
              cos(_degreesToRadians(destinoLatitud!)) *
              sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Obtener texto de tiempo estimado
  String _getEstimatedTimeText(double distanciaKm) {
    // Asumiendo promedio de 40 km/h en ciudad
    const promedioKmh = 40.0;
    final minutosEstimados = (distanciaKm / promedioKmh * 60).toInt();

    if (minutosEstimados < 1) return '< 1 min';
    if (minutosEstimados < 60) return '${minutosEstimados}m';

    final horas = minutosEstimados ~/ 60;
    final minutos = minutosEstimados % 60;
    return '${horas}h ${minutos}m';
  }
}

/// Widget auxiliar para mostrar métricas individuales en badges
class TrackingMetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const TrackingMetricBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isDarkMode ? color.withOpacity(0.4) : color.withOpacity(0.3),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
