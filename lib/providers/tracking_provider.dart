import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class TrackingProvider with ChangeNotifier {
  final TrackingService _trackingService = TrackingService();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _ubicacionSubscription;

  // Estado
  UbicacionTracking? _ubicacionActual;
  List<UbicacionTracking> _historialUbicaciones = [];
  DistanciaEstimada? _distanciaEstimada;
  int? _entregaIdActual;
  bool _isLoading = false;
  String? _errorMessage;

  // Polling
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  static const Duration _pollingInterval = Duration(seconds: 30);

  // Getters
  UbicacionTracking? get ubicacionActual => _ubicacionActual;
  List<UbicacionTracking> get historialUbicaciones => _historialUbicaciones;
  DistanciaEstimada? get distanciaEstimada => _distanciaEstimada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPollingActive => _isPollingActive;
  int? get entregaIdActual => _entregaIdActual;

  /// Suscribirse al tracking de una entrega
  ///
  /// Combina polling (fallback) con WebSocket (tiempo real)
  Future<void> suscribirseATracking(int entregaId) async {
    debugPrint('📍 Suscribiéndose al tracking de entrega: $entregaId');

    _entregaIdActual = entregaId;

    // Detener polling anterior si existe
    detenerPolling();

    // Cargar datos iniciales
    await _cargarTrackingCompleto(entregaId);

    // Escuchar eventos WebSocket de ubicación en tiempo real
    _iniciarEscuchaWebSocket();

    // Iniciar polling como fallback (en caso de que WebSocket falle)
    _iniciarPolling(entregaId);
  }

  /// Desuscribirse del tracking actual
  void desuscribirse() {
    debugPrint('📍 Desuscribiéndose del tracking');

    detenerPolling();
    _detenerEscuchaWebSocket();
    _entregaIdActual = null;
    _ubicacionActual = null;
    _historialUbicaciones = [];
    _distanciaEstimada = null;
    _errorMessage = null;

    notifyListeners();
  }

  /// Iniciar escucha de eventos WebSocket de ubicación
  void _iniciarEscuchaWebSocket() {
    debugPrint('🔌 TrackingProvider: Iniciando escucha WebSocket');

    // Escuchar eventos de ubicación en tiempo real
    _ubicacionSubscription = _webSocketService.ubicacionStream.listen((event) {
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('📍 TrackingProvider: Ubicación actualizada vía WebSocket');

      // Actualizar ubicación actual
      if (data['coordenadas'] != null) {
        final coords = data['coordenadas'] as Map<String, dynamic>;
        final nuevaUbicacion = UbicacionTracking(
          id: data['envio_id'] as int? ?? 0,
          entregaId: data['envio_id'] as int? ?? _entregaIdActual ?? 0,
          latitud: (coords['lat'] as num).toDouble(),
          longitud: (coords['lng'] as num).toDouble(),
          timestamp: DateTime.parse(data['timestamp'] as String),
          velocidad: (data['velocidad_kmh'] as num?)?.toDouble(),
          evento: 'en_ruta',
        );

        // Solo actualizar si cambió
        if (_ubicacionActual == null ||
            _ubicacionActual!.timestamp != nuevaUbicacion.timestamp) {
          _ubicacionActual = nuevaUbicacion;

          // Agregar al historial
          if (!_historialUbicaciones.any((u) => u.id == nuevaUbicacion.id)) {
            _historialUbicaciones.insert(0, nuevaUbicacion);
          }

          debugPrint('🔄 Ubicación actualizada vía WebSocket: ${nuevaUbicacion.latitud}, ${nuevaUbicacion.longitud}');

          // Actualizar distancia estimada si viene en el evento
          if (data['eta_minutos'] != null && data['distancia_km'] != null) {
            final distanciaKm = (data['distancia_km'] as num).toDouble();
            final etaMinutos = data['eta_minutos'] as int;

            _distanciaEstimada = DistanciaEstimada(
              distanciaMetros: distanciaKm * 1000,
              tiempoEstimadoMinutos: etaMinutos,
              distanciaFormateada: '${distanciaKm.toStringAsFixed(1)} km',
              tiempoFormateado: '$etaMinutos min',
            );
          }

          notifyListeners();
        }
      }
    });
  }

  /// Detener escucha de eventos WebSocket
  void _detenerEscuchaWebSocket() {
    debugPrint('🔌 TrackingProvider: Deteniendo escucha WebSocket');
    _ubicacionSubscription?.cancel();
  }

  /// Cargar tracking completo (historial + ubicación actual)
  Future<void> _cargarTrackingCompleto(int entregaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _trackingService.getUbicacionesEntrega(entregaId);

      if (response.success && response.data != null) {
        final data = response.data!;

        // Ubicación actual
        if (data['ubicacion_actual'] != null) {
          _ubicacionActual = UbicacionTracking.fromJson(
            data['ubicacion_actual'] as Map<String, dynamic>,
          );
        }

        // Historial
        if (data['historial'] != null) {
          _historialUbicaciones = (data['historial'] as List)
              .map((u) => UbicacionTracking.fromJson(u as Map<String, dynamic>))
              .toList();
        }

        _errorMessage = null;
        debugPrint('✅ Tracking cargado: ${_historialUbicaciones.length} ubicaciones');
      } else {
        _errorMessage = response.message;
        debugPrint('❌ Error cargando tracking: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ Error inesperado: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar solo la ubicación actual (lightweight para polling)
  Future<void> _actualizarUbicacionActual(int entregaId) async {
    try {
      final response = await _trackingService.getUltimaUbicacion(entregaId);

      if (response.success && response.data != null) {
        final nuevaUbicacion = response.data!;

        // Solo actualizar si cambió (timestamp diferente)
        if (_ubicacionActual == null ||
            _ubicacionActual!.timestamp != nuevaUbicacion.timestamp) {

          _ubicacionActual = nuevaUbicacion;

          // Agregar al historial si no está
          if (!_historialUbicaciones.any((u) => u.id == nuevaUbicacion.id)) {
            _historialUbicaciones.insert(0, nuevaUbicacion);
          }

          debugPrint('🔄 Ubicación actualizada: ${nuevaUbicacion.latitud}, ${nuevaUbicacion.longitud}');
          notifyListeners();
        }
      }
    } catch (e) {
      // No mostrar error en polling automático para no molestar al usuario
      debugPrint('⚠️ Error actualizando ubicación en polling: $e');
    }
  }

  /// Calcular distancia estimada hasta el destino
  Future<void> calcularDistancia(
    int entregaId,
    double latCliente,
    double lngCliente,
  ) async {
    try {
      final response = await _trackingService.calcularDistanciaLlegada(
        entregaId,
        latCliente,
        lngCliente,
      );

      if (response.success && response.data != null) {
        _distanciaEstimada = response.data;
        notifyListeners();
        debugPrint('📏 Distancia calculada: ${_distanciaEstimada!.distanciaFormateada}');
      }
    } catch (e) {
      debugPrint('⚠️ Error calculando distancia: $e');
    }
  }

  /// Iniciar polling automático cada 30 segundos
  void _iniciarPolling(int entregaId) {
    if (_isPollingActive) {
      debugPrint('⚠️ Polling ya está activo');
      return;
    }

    debugPrint('▶️ Iniciando polling cada ${_pollingInterval.inSeconds}s');
    _isPollingActive = true;

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (_entregaIdActual == entregaId) {
        debugPrint('🔄 Polling: Actualizando ubicación...');
        await _actualizarUbicacionActual(entregaId);
      } else {
        // Si cambió el ID, detener el timer
        timer.cancel();
        _isPollingActive = false;
      }
    });
  }

  /// Detener polling
  void detenerPolling() {
    if (_pollingTimer != null) {
      debugPrint('⏸️ Deteniendo polling');
      _pollingTimer!.cancel();
      _pollingTimer = null;
      _isPollingActive = false;
    }
  }

  /// Refrescar manualmente (pull-to-refresh)
  Future<void> refresh() async {
    if (_entregaIdActual != null) {
      await _cargarTrackingCompleto(_entregaIdActual!);

      // Recalcular distancia si había una calculada
      if (_distanciaEstimada != null && _ubicacionActual != null) {
        // Necesitamos las coordenadas del destino, pero no las tenemos aquí
        // El cálculo se hará desde la pantalla que tenga las coords
        debugPrint('ℹ️ Distancia no recalculada automáticamente');
      }
    }
  }

  /// Limpiar error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    detenerPolling();
    _detenerEscuchaWebSocket();
    super.dispose();
  }
}
