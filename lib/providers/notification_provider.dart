import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider para gestionar el estado de las notificaciones
class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  NotificationStats? _stats;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppNotification> get notifications => _notifications;
  NotificationStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _stats?.unread ?? 0;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.read).toList();

  /// Cargar notificaciones no leídas
  Future<void> loadUnreadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getUnreadNotifications();
      await loadStats();
    } catch (e) {
      _error = 'Error al cargar notificaciones: $e';
      debugPrint('❌ Error en loadUnreadNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar todas las notificaciones
  Future<void> loadAllNotifications({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getAllNotifications(limit: limit);
      await loadStats();
    } catch (e) {
      _error = 'Error al cargar notificaciones: $e';
      debugPrint('❌ Error en loadAllNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar notificaciones por tipo
  Future<void> loadNotificationsByType(String type, {int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotificationsByType(type, limit: limit);
      await loadStats();
    } catch (e) {
      _error = 'Error al cargar notificaciones: $e';
      debugPrint('❌ Error en loadNotificationsByType: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar estadísticas
  Future<void> loadStats() async {
    try {
      _stats = await _service.getStats();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error en loadStats: $e');
    }
  }

  /// Marcar notificación como leída
  Future<bool> markAsRead(int notificationId) async {
    final success = await _service.markAsRead(notificationId);

    if (success) {
      // Actualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          read: true,
          readAt: DateTime.now(),
        );
      }
      await loadStats();
      notifyListeners();
    }

    return success;
  }

  /// Marcar notificación como no leída
  Future<bool> markAsUnread(int notificationId) async {
    final success = await _service.markAsUnread(notificationId);

    if (success) {
      // Actualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          read: false,
          readAt: null,
        );
      }
      await loadStats();
      notifyListeners();
    }

    return success;
  }

  /// Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead() async {
    final success = await _service.markAllAsRead();

    if (success) {
      // Actualizar todas localmente
      _notifications = _notifications.map((n) {
        return n.copyWith(read: true, readAt: DateTime.now());
      }).toList();

      await loadStats();
      notifyListeners();
    }

    return success;
  }

  /// Eliminar una notificación
  Future<bool> deleteNotification(int notificationId) async {
    final success = await _service.deleteNotification(notificationId);

    if (success) {
      _notifications.removeWhere((n) => n.id == notificationId);
      await loadStats();
      notifyListeners();
    }

    return success;
  }

  /// Eliminar todas las notificaciones
  Future<bool> deleteAllNotifications() async {
    final success = await _service.deleteAllNotifications();

    if (success) {
      _notifications.clear();
      _stats = NotificationStats(total: 0, unread: 0, read: 0);
      notifyListeners();
    }

    return success;
  }

  /// Agregar nueva notificación (cuando llega vía WebSocket)
  void addNotification(AppNotification notification) {
    // Verificar que no exista ya (evitar duplicados)
    final exists = _notifications.any((n) => n.id == notification.id);
    if (exists) {
      debugPrint('⚠️ Notificación ${notification.id} ya existe, ignorando');
      return;
    }

    _notifications.insert(0, notification);

    // Actualizar estadísticas
    if (_stats != null) {
      _stats = NotificationStats(
        total: _stats!.total + 1,
        unread: _stats!.unread + (notification.read ? 0 : 1),
        read: _stats!.read + (notification.read ? 1 : 0),
      );
    }

    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar notificaciones (pull-to-refresh)
  Future<void> refresh() async {
    await loadAllNotifications();
  }
}
