import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../services/gps_service.dart';
import '../services/entrega_tracking_service.dart';
import '../services/entrega_service.dart';

/// ✅ FASE 4: Mixin para agregar tracking a EntregaProvider
///
/// REQUISITO: La clase que use este mixin DEBE extender ChangeNotifier
///
/// USO:
/// class EntregaProvider extends ChangeNotifier with EntregaTrackingMixin {
///   final EntregaService _entregaService = EntregaService();
///   // ... código existente ...
/// }
///
/// ENTONCES EN EL PROVIDER PUEDES HACER:
/// await iniciarTracking(entregaId);
/// await detenerTracking();
///
mixin EntregaTrackingMixin {
  late EntregaTrackingService _trackingService;
  bool _isTracking = false;
  Position? _ultimaUbicacion;
  double _distanciaRecorrida = 0.0;
  Position? _ultimaUbicacionCalculada; // Para calcular distancia incremental

  // Variables que debe proporcionar la clase que usa el mixin
  // (para acceder a _entregaService)
  final EntregaService _trackingEntregaService = EntregaService();

  // Getters
  bool get isTracking => _isTracking;
  Position? get ultimaUbicacion => _ultimaUbicacion;
  double get distanciaRecorrida => _distanciaRecorrida;

  /// Método abstracto que la clase usando este mixin debe implementar
  /// (Dart mixins no soportan métodos abstractos, pero asumimos que
  /// la clase que usa este mixin extiende ChangeNotifier)
  void notifyListeners() {
    // Este método será proporcionado por ChangeNotifier
    // Si se llama y falla, significa que no se está usando correctamente el mixin
  }

  /// Iniciar tracking de entrega
  /// Llamar cuando chofer presiona "Iniciar Entrega"
  Future<void> iniciarTracking({
    required int entregaId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      if (_isTracking) {
        onError('Tracking ya está activo');
        return;
      }

      _isTracking = true;
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ [MIXIN] notifyListeners falló: $e');
      }

      debugPrint('📍 [TRACKING_MIXIN] Inicializando servicio de tracking...');

      // Inicializar servicio de tracking con el servicio de API real
      _trackingService = EntregaTrackingService(
        gpsService: GpsService(),
        apiService: _trackingEntregaService,
      );

      debugPrint('▶️ [TRACKING_MIXIN] Iniciando tracking de entrega #$entregaId');

      // Resetear distancia recorrida
      _resetearDistancia();

      // Iniciar tracking
      await _trackingService.iniciarTracking(
        entregaId: entregaId,
        onLocationCallback: _onLocationUpdate,
        onErrorCallback: (error) {
          debugPrint('❌ [TRACKING_MIXIN] Error tracking: $error');
          onError(error);
        },
        onSuccessCallback: (message) {
          debugPrint('✅ [TRACKING_MIXIN] $message');
          onSuccess(message);
        },
      );
    } catch (e) {
      _isTracking = false;
      debugPrint('❌ [TRACKING_MIXIN] Excepción: $e');
      try {
        notifyListeners();
      } catch (_) {}
      onError('Error iniciando tracking: $e');
    }
  }

  /// Detener tracking
  /// Llamar cuando entrega se completa
  Future<void> detenerTracking() async {
    try {
      if (_isTracking) {
        _trackingService.detenerTracking();
      }
      _isTracking = false;
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ [MIXIN] notifyListeners falló al detener: $e');
      }
    } catch (e) {
      debugPrint('❌ [TRACKING_MIXIN] Error deteniendo tracking: $e');
    }
  }

  /// Callback cuando ubicación se actualiza
  void _onLocationUpdate(Position position) {
    _ultimaUbicacion = position;

    // Calcular distancia recorrida si hay una ubicación anterior
    if (_ultimaUbicacionCalculada != null) {
      final distanciaIncremental = _calcularDistancia(
        _ultimaUbicacionCalculada!.latitude,
        _ultimaUbicacionCalculada!.longitude,
        position.latitude,
        position.longitude,
      );
      // Solo acumular si la distancia es significativa (> 5 metros para evitar ruido GPS)
      if (distanciaIncremental > 0.005) {
        _distanciaRecorrida += distanciaIncremental;
        debugPrint(
          '📏 [TRACKING_MIXIN] Distancia acumulada: ${_distanciaRecorrida.toStringAsFixed(3)}km',
        );
      }
    }

    // Actualizar última ubicación calculada
    _ultimaUbicacionCalculada = position;

    // Aquí podrías actualizar estado de la entrega en el provider
    // Por ejemplo: entregaActual?.latitud = position.latitude;
    try {
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [MIXIN] notifyListeners falló en ubicación: $e');
    }
  }

  /// Resetear distancia recorrida (cuando inicia nueva entrega)
  void _resetearDistancia() {
    _distanciaRecorrida = 0.0;
    _ultimaUbicacionCalculada = null;
    debugPrint('🔄 [TRACKING_MIXIN] Distancia recorrida reseteada');
  }

  /// Calcular distancia entre dos puntos usando fórmula Haversine
  /// Retorna distancia en kilómetros
  double _calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) *
              cos(_degreesToRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  /// Limpiar recursos
  Future<void> limpiarTracking() async {
    try {
      if (_isTracking) {
        await _trackingService.dispose();
      }
      _isTracking = false;
    } catch (e) {
      debugPrint('❌ [TRACKING_MIXIN] Error limpiando: $e');
    }
  }
}
