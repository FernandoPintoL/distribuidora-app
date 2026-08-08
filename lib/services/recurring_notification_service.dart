import 'package:flutter/foundation.dart';
import '../models/recurring_notification.dart';
import 'api_service.dart';

/// Servicio para gestionar notificaciones recurrentes desde Laravel
class RecurringNotificationService {
  final ApiService _apiService = ApiService();

  /// Obtener todas las notificaciones recurrentes activas
  Future<List<RecurringNotification>> getAllNotifications({int limit = 50}) async {
    try {
      debugPrint('📤 GET → notificaciones recurrentes');

      final response = await _apiService.get(
        '/notificaciones/public/list',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final success = response.data['success'] == true;
        if (!success) {
          throw Exception('API retornó success: false');
        }

        final List data = response.data['notificaciones'] as List? ??
                         response.data['data'] as List? ?? [];

        debugPrint('✅ Notificaciones recurrentes cargadas: ${data.length}');

        final notificaciones = data.map((n) {
          try {
            if (n is! Map<String, dynamic>) {
              debugPrint('⚠️ Elemento ignorado: no es Map - $n');
              return null;
            }
            return RecurringNotification.fromJson(n);
          } catch (e) {
            debugPrint('⚠️ Error parseando notificación: $e - Data: $n');
            return null;
          }
        })
        .whereType<RecurringNotification>()
        .toList();

        return notificaciones;
      }

      throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
    } catch (e) {
      debugPrint('❌ Error en getAllNotifications: $e');
      rethrow;
    }
  }

  /// Obtener notificaciones filtradas por tipo
  Future<List<RecurringNotification>> getNotificationsByType(
    String type, {
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/notificaciones/public/list',
        queryParameters: {
          'limit': limit,
          'tipo': type,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['notificaciones'] as List? ??
                         response.data['data'] as List? ?? [];

        return data
            .map((n) => RecurringNotification.fromJson(n as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Error al obtener notificaciones por tipo');
    } catch (e) {
      debugPrint('❌ Error en getNotificationsByType: $e');
      rethrow;
    }
  }
}
