/// Servicio para conectar a Socket.IO y escuchar cambios de estado en tiempo real
///
/// Gestiona la conexión WebSocket, emisión de eventos de estado y reconexión automática.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/estado_event.dart';

class EstadosRealtimeService {
  late IO.Socket _socket;
  late String _baseUrl;
  late FlutterSecureStorage _secureStorage;

  // Stream controllers para eventos y estado de conexión
  final _eventStreamController = StreamController<EstadoEvent>.broadcast();
  final _connectionStateController =
      StreamController<EstadoConnectionState>.broadcast();

  // Estado actual
  EstadoConnectionState _currentConnectionState = EstadoConnectionState.connecting();
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _baseReconnectDelayMs = 1000; // 1 segundo
  Timer? _reconnectTimer;

  EstadosRealtimeService({
    required FlutterSecureStorage secureStorage,
    String? baseUrl,
  }) {
    _secureStorage = secureStorage;
    _baseUrl = baseUrl ?? _getDefaultBaseUrl();

    debugPrint('[EstadosRealtimeService] Initialized with baseUrl: $_baseUrl');
  }

  /// Obtiene la URL base desde .env o usa default
  static String _getDefaultBaseUrl() {
    if (dotenv.env.isEmpty) {
      try {
        dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('[EstadosRealtimeService] Error loading .env: $e');
      }
    }
    final websocketUrl =
        dotenv.env['WEBSOCKET_URL'] ?? 'http://192.168.100.21:3000';
    return websocketUrl;
  }

  // Streams públicos
  Stream<EstadoEvent> get eventStream => _eventStreamController.stream;
  Stream<EstadoConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  // Getters para estado actual
  bool get isConnected => _currentConnectionState.isConnected;
  bool get isConnecting => _currentConnectionState.isConnecting;
  String? get lastError => _currentConnectionState.error;
  EstadoConnectionState get connectionState => _currentConnectionState;

  /// Conecta al servidor WebSocket
  Future<void> connect() async {
    try {
      debugPrint('[EstadosRealtimeService] Iniciando conexión a $_baseUrl...');

      // Obtener token de autenticación
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Configurar Socket.IO
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'authorization': 'Bearer $token'})
            .build(),
      );

      // Listeners para conexión
      _socket.onConnect((_) {
        _onConnected();
      });

      _socket.onDisconnect((_) {
        _onDisconnected();
      });

      _socket.onError((error) {
        _onError(error);
      });

      // Listeners para eventos de estado
      _socket.on('estado:cambio', (data) {
        _onEstadoChanged(data);
      });

      _socket.on('estado:creado', (data) {
        _onEstadoCreated(data);
      });

      _socket.on('estado:borrado', (data) {
        _onEstadoDeleted(data);
      });

      // Conectar
      _socket.connect();

      // Esperar a que se conecte con timeout
      await Future.delayed(const Duration(seconds: 5));

      if (!isConnected) {
        throw Exception('Connection timeout');
      }

      _reconnectAttempts = 0;
      debugPrint('[EstadosRealtimeService] Conectado exitosamente');
    } catch (e) {
      debugPrint('[EstadosRealtimeService] Error conectando: $e');
      _onError(e.toString());
      _scheduleReconnect();
    }
  }

  /// Desconecta del servidor WebSocket
  void disconnect() {
    debugPrint('[EstadosRealtimeService] Desconectando...');

    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_socket.connected) {
      _socket.disconnect();
    }

    _updateConnectionState(
      EstadoConnectionState.disconnected('Usuario desconectó'),
    );
  }

  /// Maneja la conexión exitosa
  void _onConnected() {
    debugPrint('[EstadosRealtimeService] ✓ WebSocket conectado');

    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    _updateConnectionState(EstadoConnectionState.connected());

    // Informar al servidor que estamos listos para recibir eventos
    _socket.emit('client:ready', {
      'timestamp': DateTime.now().toIso8601String(),
      'app': 'flutter',
    });
  }

  /// Maneja la desconexión
  void _onDisconnected() {
    debugPrint(
      '[EstadosRealtimeService] × WebSocket desconectado (intento ${_reconnectAttempts + 1}/$_maxReconnectAttempts)',
    );

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _updateConnectionState(EstadoConnectionState.connecting());
      _scheduleReconnect();
    } else {
      _updateConnectionState(
        EstadoConnectionState.disconnected(
          'Máximo número de reintentos alcanzado',
        ),
      );
    }
  }

  /// Maneja errores de conexión
  void _onError(String error) {
    debugPrint('[EstadosRealtimeService] ⚠️ Error: $error');

    _updateConnectionState(
      EstadoConnectionState.disconnected(error),
    );

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Maneja cambio de estado (actualización)
  void _onEstadoChanged(dynamic data) {
    try {
      debugPrint('[EstadosRealtimeService] 📝 Estado cambió: $data');

      final json = data as Map<String, dynamic>;
      final evento = EstadoEvent.fromJson(json);

      debugPrint(
        '[EstadosRealtimeService] Evento parseado: ${evento.categoria}/${evento.codigo}',
      );

      _eventStreamController.add(evento);
    } catch (e) {
      debugPrint('[EstadosRealtimeService] Error procesando evento: $e');
    }
  }

  /// Maneja creación de nuevo estado
  void _onEstadoCreated(dynamic data) {
    try {
      debugPrint('[EstadosRealtimeService] ➕ Estado creado: $data');

      final json = data as Map<String, dynamic>;
      final evento = EstadoEvent.fromJson({
        ...json,
        'type': 'created',
      });

      _eventStreamController.add(evento);
    } catch (e) {
      debugPrint('[EstadosRealtimeService] Error procesando creación: $e');
    }
  }

  /// Maneja eliminación de estado
  void _onEstadoDeleted(dynamic data) {
    try {
      debugPrint('[EstadosRealtimeService] 🗑️ Estado borrado: $data');

      final json = data as Map<String, dynamic>;
      final evento = EstadoEvent.fromJson({
        ...json,
        'type': 'deleted',
      });

      _eventStreamController.add(evento);
    } catch (e) {
      debugPrint('[EstadosRealtimeService] Error procesando eliminación: $e');
    }
  }

  /// Programa un reintento de conexión con exponential backoff
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delayMs = _baseReconnectDelayMs *
        pow(2, _reconnectAttempts.toDouble()).toInt();
    final jitterMs = Random().nextInt(1000); // Agregar jitter (0-1s)
    final totalDelayMs = min(delayMs + jitterMs, 30000); // Max 30 segundos

    debugPrint(
      '[EstadosRealtimeService] Reconectando en ${totalDelayMs}ms (intento ${_reconnectAttempts + 1})',
    );

    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(milliseconds: totalDelayMs), () {
      if (!isConnected && !isConnecting) {
        connect();
      }
    });
  }

  /// Actualiza el estado de conexión y emite a los listeners
  void _updateConnectionState(EstadoConnectionState newState) {
    _currentConnectionState = newState;
    _connectionStateController.add(newState);

    if (newState.isConnected) {
      debugPrint('[EstadosRealtimeService] 🟢 Estado: Conectado');
    } else if (newState.isConnecting) {
      debugPrint('[EstadosRealtimeService] 🟡 Estado: Conectando...');
    } else {
      debugPrint('[EstadosRealtimeService] 🔴 Estado: Desconectado - ${newState.error}');
    }
  }

  /// Emite un evento al servidor (para futuro uso)
  void emit(String event, dynamic data) {
    if (isConnected) {
      _socket.emit(event, data);
    } else {
      debugPrint(
        '[EstadosRealtimeService] No se puede emitir "$event" - no conectado',
      );
    }
  }

  /// Limpia recursos
  void dispose() {
    disconnect();
    _eventStreamController.close();
    _connectionStateController.close();
    _reconnectTimer?.cancel();
  }
}
