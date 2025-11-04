import 'package:flutter/widgets.dart';
import '../services/websocket_service.dart';

/// Modelo para datos de ubicación en tiempo real
class LocationData {
  final int entregaId;
  final double latitud;
  final double longitud;
  final double? velocidad;
  final String? direccion;
  final DateTime timestamp;

  LocationData({
    required this.entregaId,
    required this.latitud,
    required this.longitud,
    this.velocidad,
    this.direccion,
    required this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      entregaId: json['entrega_id'] ?? 0,
      latitud: (json['latitud'] ?? 0).toDouble(),
      longitud: (json['longitud'] ?? 0).toDouble(),
      velocidad: json['velocidad']?.toDouble(),
      direccion: json['direccion'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Modelo para cambios de estado de entrega
class DeliveryStatusChange {
  final int entregaId;
  final String estadoAnterior;
  final String estadoNuevo;
  final String? motivo;
  final DateTime timestamp;

  DeliveryStatusChange({
    required this.entregaId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.motivo,
    required this.timestamp,
  });

  factory DeliveryStatusChange.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusChange(
      entregaId: json['entrega_id'] ?? 0,
      estadoAnterior: json['estado_anterior'] ?? '',
      estadoNuevo: json['estado_nuevo'] ?? '',
      motivo: json['motivo'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Provider para rastreo en tiempo real de entregas
class TrackerProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();

  // Estado de conexión
  bool _isConnected = false;
  String? _connectionError;

  // Datos de rastreo
  final Map<int, LocationData> _currentLocations = {};
  final Map<int, List<LocationData>> _locationHistory = {};
  final Map<int, String> _deliveryStatus = {};
  final Map<int, DeliveryStatusChange> _lastStatusChange = {};
  final Map<int, List<String>> _deliveryNotes = {};

  // Estado general
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para estado de conexión
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;

  // Getters para rastreo
  LocationData? getLocation(int entregaId) => _currentLocations[entregaId];
  List<LocationData> getLocationHistory(int entregaId) =>
      _locationHistory[entregaId] ?? [];
  String? getDeliveryStatus(int entregaId) => _deliveryStatus[entregaId];
  DeliveryStatusChange? getLastStatusChange(int entregaId) =>
      _lastStatusChange[entregaId];
  List<String> getDeliveryNotes(int entregaId) => _deliveryNotes[entregaId] ?? [];

  // Getters generales
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, LocationData> get allLocations => Map.unmodifiable(_currentLocations);

  /// Inicializar conexión WebSocket
  Future<void> initializeWebSocket({
    required String token,
    required int userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await _webSocketService.connect(
        token: token,
        userId: userId,
      );

      _isConnected = true;
      _connectionError = null;

      // Escuchar cambios de estado de conexión
      _webSocketService.connectionStream.listen((isConnected) {
        _isConnected = isConnected;
        if (!isConnected) {
          _connectionError = 'Desconectado de WebSocket';
        } else {
          _connectionError = null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      });

      // Escuchar eventos de ubicación
      _webSocketService.ubicacionStream.listen((event) {
        if (event['type'] == 'ubicacion') {
          _handleLocationUpdate(event['data'] ?? {});
        }
      });

      // Escuchar eventos de envío
      _webSocketService.envioStream.listen((event) {
        final type = event['type'] ?? '';
        final data = event['data'] ?? {};

        switch (type) {
          case 'en_ruta':
            _handleChoferEnCamino(data);
            break;
          case 'proximo':
            _handleChoferLlegada(data);
            break;
          case 'entregado':
            _handleEntregado(data);
            break;
          case 'rechazada':
            _handleNovedad(data);
            break;
        }
      });

      print('✅ WebSocket inicializado correctamente');
    } catch (e) {
      _isConnected = false;
      _connectionError = 'No se pudo conectar: ${e.toString()}';
      _errorMessage = _connectionError;
      print('❌ Error inicializando WebSocket: $e');
    } finally {
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }


  /// Manejar actualización de ubicación
  void _handleLocationUpdate(Map<String, dynamic> data) {
    try {
      final location = LocationData.fromJson(data);
      _currentLocations[location.entregaId] = location;

      // Agregar al historial
      if (!_locationHistory.containsKey(location.entregaId)) {
        _locationHistory[location.entregaId] = [];
      }
      _locationHistory[location.entregaId]!.add(location);

      print('📍 Ubicación actualizada - Entrega ${location.entregaId}: '
          '${location.latitud}, ${location.longitud}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error procesando actualización de ubicación: $e');
    }
  }

  /// Manejar novedad reportada
  void _handleNovedad(Map<String, dynamic> data) {
    try {
      final entregaId = data['entrega_id'] ?? 0;
      final descripcion = data['descripcion'] ?? '';

      if (!_deliveryNotes.containsKey(entregaId)) {
        _deliveryNotes[entregaId] = [];
      }
      _deliveryNotes[entregaId]!.add(descripcion);

      print('⚠️ Novedad reportada - Entrega $entregaId: $descripcion');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error procesando novedad: $e');
    }
  }

  /// Manejar chofer en camino
  void _handleChoferEnCamino(Map<String, dynamic> data) {
    try {
      final entregaId = data['entrega_id'] ?? 0;
      _deliveryStatus[entregaId] = 'en_camino';

      print('🚗 Chofer en camino - Entrega $entregaId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error procesando chofer en camino: $e');
    }
  }

  /// Manejar llegada del chofer
  void _handleChoferLlegada(Map<String, dynamic> data) {
    try {
      final entregaId = data['entrega_id'] ?? 0;
      _deliveryStatus[entregaId] = 'llegada';

      print('📍 Chofer llegó - Entrega $entregaId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error procesando llegada: $e');
    }
  }

  /// Manejar entrega confirmada
  void _handleEntregado(Map<String, dynamic> data) {
    try {
      final entregaId = data['entrega_id'] ?? 0;
      _deliveryStatus[entregaId] = 'entregado';

      print('✅ Entregado - Entrega $entregaId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print('Error procesando entrega: $e');
    }
  }

  /// Suscribirse a una entrega
  void subscribeToDelivery(int entregaId) {
    if (!_isConnected) {
      print('⚠️ WebSocket no está conectado');
      return;
    }

    print('📡 Suscribiendo a entrega: $entregaId');

    // Limpiar datos previos
    _currentLocations.remove(entregaId);
    _locationHistory.remove(entregaId);
    _deliveryNotes.remove(entregaId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Desuscribirse de una entrega
  void unsubscribeFromDelivery(int entregaId) {
    print('🚫 Desuscribiendo de entrega: $entregaId');

    _currentLocations.remove(entregaId);
    _locationHistory.remove(entregaId);
    _deliveryStatus.remove(entregaId);
    _lastStatusChange.remove(entregaId);
    _deliveryNotes.remove(entregaId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Suscribirse a múltiples entregas
  void subscribeToDeliveries(List<int> entregaIds) {
    for (final id in entregaIds) {
      subscribeToDelivery(id);
    }
  }

  /// Desuscribirse de todas las entregas
  void unsubscribeFromAll() {
    final ids = List.from(_currentLocations.keys);
    for (final id in ids) {
      unsubscribeFromDelivery(id);
    }
  }

  /// Desconectar WebSocket
  void disconnect() {
    print('Desconectando WebSocket...');
    _webSocketService.disconnect();
    _isConnected = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Reconectar WebSocket
  Future<void> reconnect({required String token, required int userId}) async {
    await initializeWebSocket(token: token, userId: userId);
  }

  /// Limpiar datos
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
