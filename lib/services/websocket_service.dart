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
  final _coordinacionController = StreamController<Map<String, dynamic>>.broadcast(); // NUEVO
  final _stockController = StreamController<Map<String, dynamic>>.broadcast();
  final _envioController = StreamController<Map<String, dynamic>>.broadcast();
  final _ubicacionController = StreamController<Map<String, dynamic>>.broadcast();
  final _rutaController = StreamController<Map<String, dynamic>>.broadcast();
  final _entregaController = StreamController<Map<String, dynamic>>.broadcast(); // NUEVO para entregas
  final _cargoController = StreamController<Map<String, dynamic>>.broadcast(); // NUEVO para cargas
  final _connectionController = StreamController<bool>.broadcast();

  // Getters de streams
  Stream<Map<String, dynamic>> get proformaStream => _proformaController.stream;
  Stream<Map<String, dynamic>> get coordinacionStream => _coordinacionController.stream; // NUEVO
  Stream<Map<String, dynamic>> get stockStream => _stockController.stream;
  Stream<Map<String, dynamic>> get envioStream => _envioController.stream;
  Stream<Map<String, dynamic>> get ubicacionStream => _ubicacionController.stream;
  Stream<Map<String, dynamic>> get rutaStream => _rutaController.stream;
  Stream<Map<String, dynamic>> get entregaStream => _entregaController.stream; // NUEVO para entregas
  Stream<Map<String, dynamic>> get cargoStream => _cargoController.stream; // NUEVO para cargas
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
    // Eventos de proformas
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

    // Evento de coordinación de entrega (NUEVO)
    _socket!.on(WebSocketConfig.eventProformaCoordinationUpdated, (data) {
      debugPrint('📍 Coordinación de entrega actualizada: $data');
      _coordinacionController.add({
        'type': 'coordination_updated',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventProformaCoordinationUpdated, data);
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

    // ✅ NUEVO: Evento chofer llegó
    _socket!.on('chofer.llego', (data) {
      debugPrint('📍 Chofer llegó: $data');
      _envioController.add({
        'type': 'chofer_llego',
        'data': data,
      });
      _handleEvent('chofer.llego', data);
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

    // Eventos de Rutas (nuevos)
    _socket!.on(WebSocketConfig.eventRutaPlanificada, (data) {
      debugPrint('📍 Ruta planificada: ${data['codigo']} (${data['cantidad_paradas']} paradas)');
      _rutaController.add({
        'type': 'planificada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventRutaPlanificada, data);
    });

    _socket!.on(WebSocketConfig.eventRutaModificada, (data) {
      debugPrint('📝 Ruta modificada: ${data['codigo']} - ${data['tipo_cambio']}');
      _rutaController.add({
        'type': 'modificada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventRutaModificada, data);
    });

    _socket!.on(WebSocketConfig.eventRutaDetalleActualizado, (data) {
      debugPrint('📦 Parada actualizada: ${data['cliente_nombre']} - ${data['estado_actual']}');
      _rutaController.add({
        'type': 'detalle_actualizado',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventRutaDetalleActualizado, data);
    });

    // Eventos de Entregas/Cargas (flujo de preparación y carga)
    _socket!.on(WebSocketConfig.eventEntregaProgramada, (data) {
      debugPrint('📅 Entrega programada: #${data['numero']}');
      _entregaController.add({
        'type': 'programada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaProgramada, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaEnPreparacionCarga, (data) {
      debugPrint('📋 Entrega en preparación de carga: #${data['numero']}');
      _entregaController.add({
        'type': 'preparacion_carga',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaEnPreparacionCarga, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaEnCarga, (data) {
      debugPrint('📦 Entrega en carga: #${data['numero']}');
      _entregaController.add({
        'type': 'en_carga',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaEnCarga, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaListoParaEntrega, (data) {
      debugPrint('✅ Entrega lista para entrega: #${data['numero']}');
      _entregaController.add({
        'type': 'listo_para_entrega',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaListoParaEntrega, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaEnTransito, (data) {
      debugPrint('🚚 Entrega en tránsito: #${data['numero']}');
      _entregaController.add({
        'type': 'en_transito',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaEnTransito, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaCompletada, (data) {
      debugPrint('🎉 Entrega completada: #${data['numero']}');
      _entregaController.add({
        'type': 'completada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaCompletada, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaNovedad, (data) {
      debugPrint('⚠️ Novedad en entrega: #${data['numero']} - ${data['motivo']}');
      _entregaController.add({
        'type': 'novedad',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaNovedad, data);
    });

    _socket!.on(WebSocketConfig.eventEntregaCancelada, (data) {
      debugPrint('❌ Entrega cancelada: #${data['numero']}');
      _entregaController.add({
        'type': 'cancelada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventEntregaCancelada, data);
    });

    // Eventos de Confirmación de Cargas
    _socket!.on(WebSocketConfig.eventVentaCargada, (data) {
      debugPrint('✔️ Venta cargada: #${data['venta_numero']} en entrega #${data['entrega_numero']}');
      _cargoController.add({
        'type': 'venta_cargada',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventVentaCargada, data);
    });

    _socket!.on(WebSocketConfig.eventCargoProgreso, (data) {
      debugPrint('📊 Progreso de carga: ${data['confirmadas']}/${data['total']} (${data['porcentaje']}%)');
      _cargoController.add({
        'type': 'progreso',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventCargoProgreso, data);
    });

    _socket!.on(WebSocketConfig.eventCargoConfirmado, (data) {
      debugPrint('🎉 Carga completamente confirmada: #${data['entrega_numero']}');
      _cargoController.add({
        'type': 'confirmado',
        'data': data,
      });
      _handleEvent(WebSocketConfig.eventCargoConfirmado, data);
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
    _coordinacionController.close();
    _stockController.close();
    _envioController.close();
    _ubicacionController.close();
    _rutaController.close();
    _entregaController.close();
    _cargoController.close();
    _connectionController.close();
    _eventHandlers.clear();
  }
}
