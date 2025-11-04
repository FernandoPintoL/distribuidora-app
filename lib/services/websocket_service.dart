import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/websocket_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  int _reconnectionAttempts = 0;

  // Callbacks para eventos
  final Map<String, Function(dynamic)> _eventHandlers = {};

  // Stream controllers para notificaciones
  final _proformaController = StreamController<Map<String, dynamic>>.broadcast();
  final _stockController = StreamController<Map<String, dynamic>>.broadcast();
  final _envioController = StreamController<Map<String, dynamic>>.broadcast();
  final _ubicacionController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters de streams
  Stream<Map<String, dynamic>> get proformaStream => _proformaController.stream;
  Stream<Map<String, dynamic>> get stockStream => _stockController.stream;
  Stream<Map<String, dynamic>> get envioStream => _envioController.stream;
  Stream<Map<String, dynamic>> get ubicacionStream => _ubicacionController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Conectar al servidor WebSocket
  Future<void> connect({
    required String token,
    required int userId,
    String userType = 'cliente',
  }) async {
    if (_socket != null && _isConnected) {
      debugPrint('⚠️ Ya conectado al WebSocket');
      return;
    }

    try {
      debugPrint('🔌 Conectando a WebSocket: ${WebSocketConfig.currentUrl}');

      final connectionCompleter = Completer<void>();

      _socket = io.io(
        WebSocketConfig.currentUrl,
        io.OptionBuilder()
            .setTransports(['websocket']) // Forzar WebSocket (no polling)
            .disableAutoConnect() // Conectar manualmente
            .setTimeout(WebSocketConfig.connectionTimeout.inMilliseconds)
            .setReconnectionDelay(WebSocketConfig.reconnectionDelay.inMilliseconds)
            .setReconnectionAttempts(WebSocketConfig.maxReconnectionAttempts)
            .setExtraHeaders({
              'Authorization': 'Bearer $token',
            })
            .build(),
      );

      // Listener temporal para la conexión inicial
      _socket!.onConnect((_) {
        debugPrint('🔌 Socket conectado (inicial)');
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.complete();
        }
      });

      _socket!.onConnectError((data) {
        debugPrint('❌ Error de conexión (inicial): $data');
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(Exception('Error de conexión: $data'));
        }
      });

      // Configurar listeners de conexión
      _setupConnectionListeners();

      // Configurar listeners de eventos
      _setupEventListeners();

      // Conectar
      _socket!.connect();

      // Esperar a que conecte
      await connectionCompleter.future.timeout(
        WebSocketConfig.connectionTimeout,
        onTimeout: () {
          throw TimeoutException('Timeout al conectar a WebSocket');
        },
      );

      // Autenticar
      await _authenticate(
        token: token,
        userId: userId,
        userType: userType,
      );

      debugPrint('✅ Conectado a WebSocket');
    } catch (e) {
      debugPrint('❌ Error conectando a WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Autenticar usuario con token Sanctum
  Future<void> _authenticate({
    required String token,
    required int userId,
    required String userType,
  }) async {
    final completer = Completer<void>();

    // Listener temporal para respuesta de autenticación
    _socket!.once(WebSocketConfig.eventAuthenticated, (data) {
      debugPrint('✅ Autenticado en WebSocket: $data');
      debugPrint('   - userId: ${data['userId']}');
      debugPrint('   - userType: ${data['userType']}');
      debugPrint('   - tokenValidated: ${data['tokenValidated'] ?? 'N/A'}');
      debugPrint('   - authMethod: ${data['authMethod'] ?? 'N/A'}');
      _isConnected = true;
      _reconnectionAttempts = 0;
      _connectionController.add(true);
      completer.complete();
    });

    _socket!.once(WebSocketConfig.eventAuthenticationError, (data) {
      debugPrint('❌ Error de autenticación: $data');
      debugPrint('   - Code: ${data['code'] ?? 'UNKNOWN'}');
      debugPrint('   - Message: ${data['message'] ?? 'Sin mensaje'}');
      _isConnected = false;
      _connectionController.add(false);
      completer.completeError(Exception('Error de autenticación: ${data['message']}'));
    });

    // Enviar credenciales con token Sanctum
    // ⭐ IMPORTANTE: El servidor valida el token contra la BD de Laravel
    _socket!.emit(WebSocketConfig.eventAuthenticate, {
      'userId': userId,
      'userType': userType,
      'token': token, // ⭐ Token Sanctum - validado contra PostgreSQL
    });

    debugPrint('📡 Enviando evento authenticate con token Sanctum');

    // Esperar respuesta con timeout
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Timeout esperando autenticación');
      },
    );
  }

  /// Configurar listeners de conexión
  void _setupConnectionListeners() {
    _socket!.onConnect((_) {
      debugPrint('🔌 Socket conectado');
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 Socket desconectado');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ Error de conexión: $data');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onError((data) {
      debugPrint('❌ Error en socket: $data');
    });

    _socket!.on(WebSocketConfig.eventServerShutdown, (data) {
      debugPrint('⚠️ Servidor cerrándose: ${data['message']}');
      // Opcional: Mostrar mensaje al usuario
    });

    _socket!.onReconnect((data) {
      debugPrint('🔄 Reconectado (intento ${_reconnectionAttempts + 1})');
      _reconnectionAttempts++;
    });

    _socket!.onReconnectError((data) {
      debugPrint('❌ Error reconectando: $data');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('❌ Falló reconexión después de ${WebSocketConfig.maxReconnectionAttempts} intentos');
      _isConnected = false;
      _connectionController.add(false);
    });
  }

  /// Configurar listeners de eventos de negocio
  void _setupEventListeners() {
    // Eventos de Proformas
    _socket!.on(WebSocketConfig.eventProformaCreated, (data) {
      debugPrint('📦 Proforma creada: $data');
      _proformaController.add({
        'type': 'created',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventProformaCreated, data);
    });

    _socket!.on(WebSocketConfig.eventProformaApproved, (data) {
      debugPrint('✅ Proforma aprobada: $data');
      _proformaController.add({
        'type': 'approved',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventProformaApproved, data);
    });

    _socket!.on(WebSocketConfig.eventProformaRejected, (data) {
      debugPrint('❌ Proforma rechazada: $data');
      _proformaController.add({
        'type': 'rejected',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventProformaRejected, data);
    });

    _socket!.on(WebSocketConfig.eventProformaConverted, (data) {
      debugPrint('🔄 Proforma convertida a venta: $data');
      _proformaController.add({
        'type': 'converted',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventProformaConverted, data);
    });

    // Eventos de Stock
    _socket!.on(WebSocketConfig.eventStockReserved, (data) {
      debugPrint('🔒 Stock reservado: $data');
      _stockController.add({
        'type': 'reserved',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventStockReserved, data);
    });

    _socket!.on(WebSocketConfig.eventStockExpiring, (data) {
      debugPrint('⏰ Reserva expirando: $data');
      _stockController.add({
        'type': 'expiring',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventStockExpiring, data);
    });

    _socket!.on(WebSocketConfig.eventStockUpdated, (data) {
      debugPrint('📦 Stock actualizado: $data');
      _stockController.add({
        'type': 'updated',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventStockUpdated, data);
    });

    // Eventos de Pagos
    _socket!.on(WebSocketConfig.eventPaymentConfirmed, (data) {
      debugPrint('💰 Pago confirmado: $data');
      _handleEvent(WebSocketConfig.eventPaymentConfirmed, data);
    });

    // Eventos de Envíos/Logística
    _socket!.on(WebSocketConfig.eventEnvioProgramado, (data) {
      debugPrint('📅 Envío programado: $data');
      _envioController.add({
        'type': 'programado',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEnvioProgramado, data);
    });

    _socket!.on(WebSocketConfig.eventEnvioEnPreparacion, (data) {
      debugPrint('📦 Envío en preparación: $data');
      _envioController.add({
        'type': 'en_preparacion',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEnvioEnPreparacion, data);
    });

    _socket!.on(WebSocketConfig.eventEnvioEnRuta, (data) {
      debugPrint('🚛 Envío en ruta: $data');
      _envioController.add({
        'type': 'en_ruta',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEnvioEnRuta, data);
    });

    _socket!.on(WebSocketConfig.eventUbicacionActualizada, (data) {
      debugPrint('📍 Ubicación actualizada: ${data['coordenadas']}');
      _ubicacionController.add({
        'type': 'ubicacion',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventUbicacionActualizada, data);
    });

    _socket!.on(WebSocketConfig.eventEnvioProximo, (data) {
      debugPrint('⏰ Envío próximo: ${data['tiempo_estimado_min']} min');
      _envioController.add({
        'type': 'proximo',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEnvioProximo, data);
    });

    _socket!.on(WebSocketConfig.eventEnvioEntregado, (data) {
      debugPrint('✅ Envío entregado: $data');
      _envioController.add({
        'type': 'entregado',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEnvioEntregado, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaRechazada, (data) {
      debugPrint('❌ Entrega rechazada: ${data['motivo']}');
      _envioController.add({
        'type': 'rechazada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaRechazada, data);
    });
  }

  /// Registrar callback para evento específico
  void on(String event, Function(dynamic) callback) {
    _eventHandlers[event] = callback;
  }

  /// Remover callback de evento
  void off(String event) {
    _eventHandlers.remove(event);
  }

  /// Manejar evento y ejecutar callback si existe
  void _handleEvent(String event, dynamic data) {
    if (_eventHandlers.containsKey(event)) {
      _eventHandlers[event]!(data);
    }
  }

  /// Desconectar del WebSocket
  void disconnect() {
    debugPrint('🔌 Desconectando WebSocket');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _reconnectionAttempts = 0;
    _connectionController.add(false);
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _proformaController.close();
    _stockController.close();
    _envioController.close();
    _ubicacionController.close();
    _connectionController.close();
    _eventHandlers.clear();
  }
}
