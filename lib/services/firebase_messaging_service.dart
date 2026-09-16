import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:distribuidora/config/app_urls.dart';
import 'package:distribuidora/services/local_notification_service.dart';
import 'package:uuid/uuid.dart';

import 'firebase_options.dart';

/// Manejador de notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Notificación recibida en BACKGROUND: ${message.messageId}');
  debugPrint('   Título: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');

  // Mostrar notificación local cuando llega en background
  try {
    final localNotificationService = LocalNotificationService();
    // No inicializar en background - ya está inicializado

    // ✅ Usar el método correcto para notificaciones recurrentes con imagen
    await localNotificationService.showRecurringNotification(
      notificacionId: message.hashCode,
      titulo: message.notification?.title ?? 'Notificación',
      descripcion: message.notification?.body ?? 'Nueva notificación recibida',
      tipo: message.data['tipo'] ?? 'informativo',
    );
  } catch (e) {
    debugPrint('⚠️ Error mostrando notificación en background: $e');
  }
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  late FirebaseMessaging _firebaseMessaging;
  late LocalNotificationService _localNotificationService;

  bool _isInitialized = false;

  /// Inicializar Firebase y configurar handlers
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ FirebaseMessagingService ya fue inicializado');
      return;
    }

    try {
      debugPrint('🔄 Inicializando Firebase...');

      // Inicializar Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotificationService = LocalNotificationService();

      // Inicializar notificaciones locales
      try {
        await _localNotificationService.initialize();
      } catch (e) {
        debugPrint('⚠️ LocalNotificationService falló pero continuamos: $e');
      }

      // Solicitar permiso de notificaciones
      await _requestNotificationPermission();

      // Configurar handlers para notificaciones
      _setupNotificationHandlers();

      // Registrar token de dispositivo
      await registerDeviceToken();

      _isInitialized = true;

      debugPrint('✅ Firebase Messaging inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
      rethrow;
    }
  }

  /// Solicitar permiso de notificaciones
  Future<void> _requestNotificationPermission() async {
    try {
      debugPrint('📲 Solicitando permisos de notificaciones...');

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📲 Permiso de notificaciones: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ Permiso de notificaciones denegado');
      } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permiso de notificaciones otorgado');
      }
    } catch (e) {
      debugPrint('⚠️ Error solicitando permisos: $e');
    }
  }

  /// Configurar handlers para diferentes estados de notificaciones
  void _setupNotificationHandlers() {
    // 1️⃣ Notificaciones en FOREGROUND (app abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Notificación recibida en FOREGROUND: ${message.messageId}');
      debugPrint('   Título: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // ✅ NUEVO: Mostrar notificación local con imagen si existe
      _localNotificationService.showRecurringNotification(
        notificacionId: message.hashCode,
        titulo: message.notification?.title ?? 'Notificación',
        descripcion: message.notification?.body ?? 'Nueva notificación',
        tipo: message.data['tipo'] ?? 'informativo',
        imageUrl: message.data['image_url'], // Pasar imagen si existe
      );
    });

    // 2️⃣ Notificaciones en BACKGROUND (app cerrada)
    // Se maneja con _firebaseMessagingBackgroundHandler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3️⃣ Cuando el usuario hace clic en una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Usuario hizo clic en notificación: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // 4️⃣ Cuando la app se abre desde una notificación (cold start)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App abierta desde notificación (cold start): ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Manejar cuando el usuario hace clic en una notificación
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📌 Manejando clic en notificación...');
    debugPrint('   ID: ${message.messageId}');
    debugPrint('   Data: ${message.data}');

    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
    final notificacionId = message.data['notificacion_id'];
    final tipo = message.data['tipo'];

    debugPrint('   Tipo: $tipo, ID Notificación: $notificacionId');

    // Ejemplo: navegar según el tipo
    // if (tipo == 'oferta') {
    //   navigateToOfferScreen(notificacionId);
    // } else if (tipo == 'evento') {
    //   navigateToEventScreen(notificacionId);
    // }
  }

  /// Obtener token FCM del dispositivo
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔑 Token FCM obtenido: ${token?.substring(0, 50)}...');
      return token;
    } catch (e) {
      debugPrint('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  /// Registrar dispositivo en el backend (guardar token FCM)
  Future<bool> registerDeviceToken() async {
    try {
      final token = await getToken();

      if (token == null) {
        debugPrint('⚠️ No se pudo obtener token FCM');
        return false;
      }

      // Generar o obtener ID único del dispositivo
      final prefs = await SharedPreferences.getInstance();
      String? dispositivoId = prefs.getString('dispositivo_id');

      if (dispositivoId == null) {
        // Generar nuevo ID si no existe
        dispositivoId = const Uuid().v4();
        await prefs.setString('dispositivo_id', dispositivoId);
        debugPrint('📱 Nuevo ID de dispositivo generado: $dispositivoId');
      }

      // Obtener versión de la app
      const appVersion = '1.1.16';

      debugPrint('📤 Registrando token en el servidor...');

      final dio = Dio();
      final response = await dio.post(
        '${AppUrls.baseUrl}/fcm/registrar-token',
        data: {
          'dispositivo_id': dispositivoId,
          'token_fcm': token,
          'platform': 'android',
          'device_name': 'Distribuidora App',
          'app_version': appVersion,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Token registrado en el servidor');
        return true;
      } else {
        debugPrint('❌ Error registrando token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error registrando token FCM: $e');
      return false;
    }
  }

  /// Desactivar token cuando se desloguea (opcional)
  Future<bool> deactivateDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dispositivoId = prefs.getString('dispositivo_id');

      if (dispositivoId == null) {
        debugPrint('⚠️ No hay dispositivo_id para desactivar');
        return false;
      }

      debugPrint('📤 Desactivando token en el servidor...');

      final dio = Dio();
      final response = await dio.post(
        '${AppUrls.baseUrl}/fcm/desactivar-token',
        data: {
          'dispositivo_id': dispositivoId,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token desactivado en el servidor');
        return true;
      } else {
        debugPrint('❌ Error desactivando token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error desactivando token: $e');
      return false;
    }
  }

  /// Suscribirse a un topic (opcional)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al topic: $topic');
    } catch (e) {
      debugPrint('❌ Error suscribiéndose al topic: $e');
    }
  }

  /// Desuscribirse de un topic (opcional)
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del topic: $topic');
    } catch (e) {
      debugPrint('❌ Error desuscribiéndose del topic: $e');
    }
  }
}
