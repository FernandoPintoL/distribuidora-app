import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Solicita permisos de ubicación al usuario
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
               result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        // Abrir configuración de la app
        await Geolocator.openLocationSettings();
        return false;
      } else {
        return true;
      }
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  /// Verifica si el servicio de ubicación está habilitado
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtiene la ubicación actual del dispositivo
  /// Retorna null si hay error o no se puede obtener
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Verificar que el servicio esté habilitado
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicio de ubicación deshabilitado');
        return null;
      }

      // Solicitar permisos si es necesario
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Permiso de ubicación denegado');
        return null;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: true,
      );

      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Obtiene la ubicación actual de forma simple
  /// Retorna un Map con 'latitude' y 'longitude', o null si hay error
  Future<Map<String, double>?> getCoordinates() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    return null;
  }

  /// Stream continuo de cambios de ubicación
  /// Útil para tracking en tiempo real
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10, // metros
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calcula la distancia entre dos puntos en metros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Obtiene información de ubicación con reintentos
  Future<Position?> getCurrentLocationWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final position = await getCurrentLocation();
        if (position != null) {
          return position;
        }
      } catch (e) {
        print('Intento $i falló: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return null;
  }
}
