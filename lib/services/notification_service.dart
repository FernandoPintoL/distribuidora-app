import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Servicio para gestionar notificaciones persistentes desde Laravel
class NotificationService {
  final ApiService _apiService = ApiService();

  /// Obtener todas las notificaciones no leídas
  Future<List<AppNotification>> getUnreadNotifications() async {
    try {
      final response = await _apiService.get('/notificaciones/no-leidas');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
      }

      throw Exception('Error al obtener notificaciones no leídas');
    } catch (e) {
      debugPrint('❌ Error en getUnreadNotifications: $e');
      rethrow;
    }
  }

  /// Obtener todas las notificaciones (con límite)
  Future<List<AppNotification>> getAllNotifications({int limit = 50}) async {
    try {
      final response = await _apiService.get(
        '/notificaciones',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
      }

      throw Exception('Error al obtener notificaciones');
    } catch (e) {
      debugPrint('❌ Error en getAllNotifications: $e');
      rethrow;
    }
  }

  /// Obtener notificaciones por tipo
  Future<List<AppNotification>> getNotificationsByType(
    String type, {
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/notificaciones/por-tipo/$type',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'] as List;
        return data.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
      }

      throw Exception('Error al obtener notificaciones por tipo');
    } catch (e) {
      debugPrint('❌ Error en getNotificationsByType: $e');
      rethrow;
    }
  }

  /// Marcar notificación como leída
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.post(
        '/notificaciones/$notificationId/marcar-leida',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error en markAsRead: $e');
      return false;
    }
  }

  /// Marcar notificación como no leída
  Future<bool> markAsUnread(int notificationId) async {
    try {
      final response = await _apiService.post(
        '/notificaciones/$notificationId/marcar-no-leida',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error en markAsUnread: $e');
      return false;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.post(
        '/notificaciones/marcar-todas-leidas',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error en markAllAsRead: $e');
      return false;
    }
  }

  /// Obtener estadísticas de notificaciones
  Future<NotificationStats?> getStats() async {
    try {
      final response = await _apiService.get('/notificaciones/estadisticas');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return NotificationStats.fromJson(response.data['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error en getStats: $e');
      return null;
    }
  }

  /// Obtener una notificación específica
  Future<AppNotification?> getNotification(int notificationId) async {
    try {
      final response = await _apiService.get(
        '/notificaciones/$notificationId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AppNotification.fromJson(response.data['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error en getNotification: $e');
      return null;
    }
  }

  /// Eliminar una notificación
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.delete(
        '/notificaciones/$notificationId',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error en deleteNotification: $e');
      return false;
    }
  }

  /// Eliminar todas las notificaciones del usuario
  Future<bool> deleteAllNotifications() async {
    try {
      final response = await _apiService.delete(
        '/notificaciones/eliminar-todas',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Error en deleteAllNotifications: $e');
      return false;
    }
  }
}
