import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// ✅ FASE 4: Servicio de GPS en tiempo real para entregas
///
/// Responsabilidades:
/// ✓ Obtener ubicación GPS cada X segundos
/// ✓ Validar permisos de localización
/// ✓ Manejar errores de GPS
/// ✓ Proporcionar stream de ubicaciones
/// ✓ Enviar ubicaciones al backend
///
/// FLUJO:
/// 1. initGPS() - Solicitar permisos
/// 2. startTracking(entregaId) - Comenzar a enviar ubicaciones
/// 3. onLocationUpdate (stream) - Escuchar cambios
/// 4. stopTracking() - Detener cuando entrega se completa
///
class GpsService {
  static final GpsService _instance = GpsService._internal();

  factory GpsService() {
    return _instance;
  }

  GpsService._internal();

  /// Stream de ubicaciones
  late StreamController<Position> _locationStreamController;
  Stream<Position> get locationStream => _locationStreamController.stream;

  /// Timer para tracking continuo
  Timer? _trackingTimer;
  bool _isTracking = false;

  /// Última ubicación registrada
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  /// Configuración
  static const int TRACKING_INTERVAL_SECONDS = 10; // Enviar ubicación cada 10 segundos
  static const int LOCATION_TIMEOUT_SECONDS = 10;
  static const double LOCATION_ACCURACY_THRESHOLD = 50; // metros

  /// Inicializar servicio
  Future<void> initialize() async {
    _locationStreamController = StreamController<Position>.broadcast();

    // Verificar y solicitar permisos
    final status = await _checkPermissions();
    if (!status) {
      throw Exception('Permisos de localización denegados');
    }

    // Escuchar cambios de ubicación (background)
    _initializeLocationListener();
  }

  /// Verificar permisos de localización
  Future<bool> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      // Abre settings
      await Geolocator.openLocationSettings();
      return false;
    }

    return true;
  }

  /// Inicializar listener de ubicación en background
  void _initializeLocationListener() {
    try {
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5, // Actualizar si se mueve 5 metros
          timeLimit: Duration(seconds: LOCATION_TIMEOUT_SECONDS),
        ),
      ).listen(
        (Position position) {
          _lastPosition = position;
          // Emitir en stream para UI
          if (!_locationStreamController.isClosed) {
            _locationStreamController.add(position);
          }
          debugPrint(
            '📍 Ubicación actual: '
            '${position.latitude}, ${position.longitude} '
            '(Precisión: ${position.accuracy}m, Velocidad: ${position.speed}m/s)',
          );
        },
        onError: (e) {
          debugPrint('❌ Error en stream de ubicación: $e');
          _handleLocationError(e);
        },
      );
    } catch (e) {
      debugPrint('❌ Error inicializando listener: $e');
    }
  }

  /// Iniciar tracking continuo de entrega
  ///
  /// Enviará ubicación al servidor cada TRACKING_INTERVAL_SECONDS
  Future<void> startTracking({
    required int entregaId,
    required Function(Position) onLocationUpdate,
    required Function(String) onError,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Tracking ya está activo');
      return;
    }

    try {
      debugPrint('▶️ Iniciando tracking para entrega #$entregaId');
      _isTracking = true;

      // Obtener ubicación inicial
      final initialPosition = await _getUbicacionActual();
      if (initialPosition != null) {
        onLocationUpdate(initialPosition);
      }

      // Crear timer para enviar ubicaciones periódicamente
      _trackingTimer = Timer.periodic(
        Duration(seconds: TRACKING_INTERVAL_SECONDS),
        (_) async {
          try {
            final position = await _getUbicacionActual();
            if (position != null) {
              _lastPosition = position;
              onLocationUpdate(position);
            }
          } catch (e) {
            debugPrint('❌ Error obteniendo ubicación: $e');
            onError(e.toString());
          }
        },
      );
    } catch (e) {
      _isTracking = false;
      onError(e.toString());
      rethrow;
    }
  }

  /// Detener tracking
  void stopTracking() {
    if (_trackingTimer != null) {
      _trackingTimer!.cancel();
      _trackingTimer = null;
    }
    _isTracking = false;
    debugPrint('⏹️ Tracking detenido');
  }

  /// Obtener ubicación actual
  Future<Position?> _getUbicacionActual() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: Duration(seconds: LOCATION_TIMEOUT_SECONDS),
        forceAndroidLocationManager: false,
      );

      // Validar precisión
      if (position.accuracy > LOCATION_ACCURACY_THRESHOLD) {
        debugPrint(
          '⚠️ Ubicación con precisión baja: ${position.accuracy}m',
        );
      }

      return position;
    } on TimeoutException {
      debugPrint('⏱️ Timeout obteniendo ubicación');
      return _lastPosition; // Usar última ubicación conocida
    } catch (e) {
      debugPrint('❌ Error: $e');
      _handleLocationError(e);
      return null;
    }
  }

  /// Manejar errores de ubicación
  void _handleLocationError(dynamic error) {
    if (error is LocationServiceDisabledException) {
      debugPrint('❌ Servicios de localización deshabilitados');
    } else if (error is PermissionDeniedException) {
      debugPrint('❌ Permisos de localización denegados');
    } else if (error is TimeoutException) {
      debugPrint('❌ Timeout obteniendo ubicación');
    } else {
      debugPrint('❌ Error desconocido: $error');
    }
  }

  /// Calcular distancia entre dos puntos (Haversine)
  static double calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadiusKm * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    stopTracking();
    if (!_locationStreamController.isClosed) {
      await _locationStreamController.close();
    }
  }
}

// Alias para math (sin necesidad de import adicional)
class math {
  static const pi = 3.141592653589793;

  static double sin(double x) {
    return sin_impl(x);
  }

  static double cos(double x) {
    return cos_impl(x);
  }

  static double atan2(double y, double x) {
    return atan2_impl(y, x);
  }

  static double sqrt(double x) {
    return sqrt_impl(x);
  }

  static double sin_impl(double x) {
    // Taylor series approximation
    double result = 0;
    double term = x;
    for (int i = 1; i < 10; i++) {
      result += term;
      term *= -x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }

  static double cos_impl(double x) {
    return sin_impl(pi / 2 - x);
  }

  static double atan2_impl(double y, double x) {
    return 2 * atan_impl(y / (sqrt_impl(x * x + y * y) + x));
  }

  static double atan_impl(double x) {
    double result = 0;
    double term = x;
    for (int i = 0; i < 10; i++) {
      result += term;
      term *= -x * x * (2 * i + 1) / (2 * i + 3);
    }
    return result;
  }

  static double sqrt_impl(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double guess = x;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
