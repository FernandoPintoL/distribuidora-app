import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

/// Servicio de background para polling periódico de notificaciones
/// Solo se activa si el usuario es chofer
class BackgroundNotificationService {
  static final BackgroundNotificationService _instance =
      BackgroundNotificationService._internal();

  factory BackgroundNotificationService() {
    return _instance;
  }

  BackgroundNotificationService._internal();

  static const String _lastNotificationIdKey = 'last_notification_id';
  static const int _pollingIntervalSeconds = 30; // Cada 30 segundos

  /// Obtener base URL desde .env
  static String _getBaseUrl() {
    if (dotenv.env.isEmpty) {
      return 'http://192.168.100.21:8000/api';
    }
    final url = dotenv.env['BASE_URL'];
    return url ?? 'http://192.168.100.21:8000/api';
  }

  /// Inicializar el servicio de background
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Configurar el servicio
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // Esto se ejecutará en el background
        onStart: onStart,
        // ID único para la notificación de foreground
        isForegroundMode: false,
        autoStart: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    debugPrint('✅ BackgroundNotificationService inicializado');
  }

  /// Iniciar el servicio de background (solo para choferes)
  static Future<void> startForChofer() async {
    try {
      final service = FlutterBackgroundService();

      // Iniciar el servicio
      await service.startService();
      debugPrint('✅ Servicio de background iniciado para chofer');
    } catch (e) {
      debugPrint('⚠️ Error iniciando servicio de background: $e');
    }
  }

  /// Detener el servicio de background
  static Future<void> stop() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      debugPrint('✅ Servicio de background detenido');
    } catch (e) {
      debugPrint('⚠️ Error deteniendo servicio de background: $e');
    }
  }
}

/// Función que se ejecuta en el background (Android)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  debugPrint('🔄 Background service iniciado');

  // Escuchar comando para detener
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Polling periódico cada 30 segundos
  Timer.periodic(
    const Duration(seconds: BackgroundNotificationService._pollingIntervalSeconds),
    (timer) async {
      await _pollingTask();
    },
  );
}

/// Función que se ejecuta en el background (iOS)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  debugPrint('🔄 Background service iOS');
  await _pollingTask();
  return true;
}

/// Tarea de polling para obtener notificaciones nuevas
Future<void> _pollingTask() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      return;
    }

    // Obtener el último ID de notificación guardado
    final lastNotificationId =
        prefs.getInt(BackgroundNotificationService._lastNotificationIdKey) ?? 0;

    // Obtener la base URL
    final baseUrl = BackgroundNotificationService._getBaseUrl();

    // Hacer llamada API para obtener notificaciones nuevas
    final dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 5);

    try {
      final response = await dio.get(
        '$baseUrl/notifications?limit=10&since_id=$lastNotificationId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> notifications = response.data['data'] ?? [];

        if (notifications.isNotEmpty) {
          // Solo guardar el último ID, no mostrar notificaciones en background
          for (var notif in notifications) {
            final id = notif['id'] as int;

            // Guardar el ID más reciente
            if (id > lastNotificationId) {
              await prefs.setInt(
                BackgroundNotificationService._lastNotificationIdKey,
                id,
              );
            }
          }
        }
      }
    } catch (e) {
      // Error silencioso en background
    }
  } catch (e) {
    // Ignorar errores en background
  }
}
