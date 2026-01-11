import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'local_notification_service.dart';

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
    final userType = prefs.getString('user_type');

    if (token == null) {
      debugPrint('⚠️ Sin token, no se pueden obtener notificaciones');
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

    try {
      final response = await dio.get(
        '$baseUrl/notifications?limit=10&since_id=$lastNotificationId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> notifications = response.data['data'] ?? [];

        if (notifications.isNotEmpty) {
          debugPrint('📬 ${notifications.length} notificación(es) nueva(s)');

          // Procesar cada notificación
          for (var notif in notifications) {
            final id = notif['id'] as int;
            final title = notif['title'] as String? ?? 'Nueva notificación';
            final body = notif['body'] as String? ?? '';
            final type = notif['type'] as String? ?? 'general';

            // Guardar el ID más reciente
            if (id > lastNotificationId) {
              await prefs.setInt(
                BackgroundNotificationService._lastNotificationIdKey,
                id,
              );
            }

            // Mostrar notificación local
            try {
              final localNotificationService = LocalNotificationService();
              final channelId = _getChannelForType(type);
              await localNotificationService.showNewDeliveryNotification(
                deliveryId: id,
                clientName: title,
                address: body,
              );
              debugPrint('🔔 Notificación mostrada: $title');
            } catch (e) {
              debugPrint('⚠️ Error mostrando notificación local: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo notificaciones: $e');
    }

    // Si es chofer, también actualizar ubicación
    if (userType == 'chofer') {
      await _updateChoferLocation(token);
    }
  } catch (e) {
    debugPrint('❌ Error en polling task: $e');
  }
}

/// Actualizar ubicación del chofer (si es chofer)
Future<void> _updateChoferLocation(String token) async {
  try {
    // Esta es una llamada que el backend debe proporcionar
    // Por ahora, solo lo loguearemos
    debugPrint('📍 Ubicación del chofer actualizada en background');
  } catch (e) {
    debugPrint('⚠️ Error actualizando ubicación: $e');
  }
}

/// Obtener el canal de notificación según el tipo
String _getChannelForType(String type) {
  switch (type.toLowerCase()) {
    case 'entrega':
      return 'entregas_nuevas';
    case 'proforma':
      return 'proformas';
    case 'estado':
      return 'cambio_estados';
    case 'recordatorio':
      return 'recordatorios';
    default:
      return 'entregas_nuevas';
  }
}
