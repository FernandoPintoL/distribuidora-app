import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'gps_service.dart';
import 'entrega_service.dart';

/// ✅ FASE 4: Servicio de Tracking de Entregas
///
/// Coordina:
/// ✓ Obtención de GPS (GpsService)
/// ✓ Envío al backend (EntregaService)
/// ✓ Manejo de errores
/// ✓ Logging de eventos
///
/// FLUJO:
/// 1. iniciarTracking(entregaId) - Comienza a trackear
/// 2. GpsService obtiene ubicación cada 10s
/// 3. Envía vía POST /api/chofer/entregas/{id}/ubicacion
/// 4. detenerTracking() - Finaliza tracking
///
class EntregaTrackingService {
  final GpsService gpsService;
  final EntregaService apiService;

  /// Callback para actualizar UI
  late Function(Position) onLocationUpdate;
  late Function(String) onError;
  late Function(String) onSuccess;

  EntregaTrackingService({
    required this.gpsService,
    required this.apiService,
  });

  /// Iniciar tracking de una entrega
  Future<void> iniciarTracking({
    required int entregaId,
    required Function(Position) onLocationCallback,
    required Function(String) onErrorCallback,
    required Function(String) onSuccessCallback,
  }) async {
    try {
      onLocationUpdate = onLocationCallback;
      onError = onErrorCallback;
      onSuccess = onSuccessCallback;

      debugPrint('▶️ Iniciando tracking de entrega #$entregaId');

      // Inicializar GPS si no está listo
      try {
        await gpsService.initialize();
      } catch (e) {
        debugPrint('⚠️ GPS ya inicializado: $e');
      }

      // Comenzar tracking y envío de ubicaciones
      await gpsService.startTracking(
        entregaId: entregaId,
        onLocationUpdate: (Position position) async {
          onLocationUpdate(position);

          // Enviar al servidor
          await _enviarUbicacion(
            entregaId: entregaId,
            latitud: position.latitude,
            longitud: position.longitude,
            velocidad: position.speed, // m/s → km/h
            rumbo: position.heading,
            altitud: position.altitude,
            precision: position.accuracy,
            evento: null, // No enviar evento para tracking continuo
          );
        },
        onError: (String error) {
          debugPrint('❌ Error en GPS: $error');
          onError(error);
        },
      );

      onSuccess('Tracking iniciado para entrega #$entregaId');
    } catch (e) {
      debugPrint('❌ Error iniciando tracking: $e');
      onError(e.toString());
      rethrow;
    }
  }

  /// Enviar ubicación al servidor
  Future<void> _enviarUbicacion({
    required int entregaId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double rumbo,
    required double altitud,
    required double precision,
    String? evento,
  }) async {
    try {
      // Convertir velocidad de m/s a km/h
      final velocidadKmh = (velocidad * 3.6).toStringAsFixed(1);

      // Enviar al servidor
      await apiService.registrarUbicacion(
        entregaId,
        latitud: latitud,
        longitud: longitud,
        velocidad: double.parse(velocidadKmh),
        rumbo: rumbo,
        altitud: altitud,
        precision: precision,
        evento: evento, // No enviar evento para tracking continuo si es null
      );

      debugPrint(
        '✅ Ubicación enviada: '
        'lat=$latitud, lng=$longitud, vel=${velocidadKmh}km/h',
      );
    } catch (e) {
      debugPrint('❌ Error enviando ubicación: $e');
      // NO fallar si hay error de envío
      // El GPS seguirá funcionando
    }
  }

  /// Detener tracking
  void detenerTracking() {
    gpsService.stopTracking();
    debugPrint('⏹️ Tracking detenido');
    onSuccess('Tracking detenido');
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    detenerTracking();
    await gpsService.dispose();
  }
}
