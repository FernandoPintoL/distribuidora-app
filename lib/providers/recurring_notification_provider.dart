import 'package:flutter/foundation.dart';
import '../models/recurring_notification.dart';
import '../services/recurring_notification_service.dart';

/// Provider para gestionar el estado de las notificaciones recurrentes
class RecurringNotificationProvider with ChangeNotifier {
  final RecurringNotificationService _service = RecurringNotificationService();

  List<RecurringNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<RecurringNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _notifications.length;

  /// Cargar todas las notificaciones recurrentes
  Future<void> loadAllNotifications({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getAllNotifications(limit: limit);
      debugPrint('✅ ${_notifications.length} notificaciones recurrentes cargadas');
    } catch (e) {
      _error = 'Error al cargar notificaciones recurrentes: $e';
      debugPrint('❌ Error en loadAllNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar notificaciones recurrentes por tipo
  Future<void> loadByType(String type, {int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotificationsByType(type, limit: limit);
      debugPrint('✅ ${_notifications.length} notificaciones recurrentes de tipo $type cargadas');
    } catch (e) {
      _error = 'Error al cargar notificaciones por tipo: $e';
      debugPrint('❌ Error en loadByType: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar notificaciones
  void clear() {
    _notifications = [];
    _error = null;
    notifyListeners();
  }
}
