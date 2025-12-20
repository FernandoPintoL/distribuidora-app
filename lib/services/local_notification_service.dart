import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Servicio centralizado para manejar notificaciones locales (push)
/// Soporta notificaciones de nuevas entregas, cambios de estado, y recordatorios
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  factory LocalNotificationService() {
    return _instance;
  }

  LocalNotificationService._internal();

  /// Inicializar el servicio de notificaciones locales
  Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Configuración para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    // Configuración para iOS
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Combinar configuraciones
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Inicializar
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canales de notificación para Android
    await _createNotificationChannels();

    // Solicitar permisos en iOS
    await _requestPermissions();

    _isInitialized = true;
    debugPrint('✅ LocalNotificationService inicializado');
  }

  /// Crear canales de notificación para Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel entregasChannel =
        AndroidNotificationChannel(
      'entregas_nuevas',
      'Nuevas Entregas',
      description: 'Notificaciones de entregas asignadas',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel estadosChannel =
        AndroidNotificationChannel(
      'cambio_estados',
      'Cambios de Estado',
      description: 'Notificaciones de cambios en estado de entregas',
      importance: Importance.high,
      enableVibration: true,
    );

    const AndroidNotificationChannel recordatoriosChannel =
        AndroidNotificationChannel(
      'recordatorios',
      'Recordatorios',
      description: 'Recordatorios de entregas pendientes',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel proformasChannel =
        AndroidNotificationChannel(
      'proformas',
      'Proformas',
      description: 'Notificaciones de proformas (aprobadas, rechazadas, convertidas)',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(entregasChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(estadosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(recordatoriosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(proformasChannel);
  }

  /// Solicitar permisos en iOS
  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
    // Aquí se podría navegar a una pantalla específica
    // basada en el payload de la notificación
  }

  /// Mostrar notificación de nueva entrega
  Future<void> showNewDeliveryNotification({
    required int deliveryId,
    required String clientName,
    required String address,
  }) async {
    await _showNotification(
      id: deliveryId,
      title: '🚚 Nueva Entrega Asignada',
      body: 'Entrega #$deliveryId para $clientName',
      channelId: 'entregas_nuevas',
      payload: 'delivery_$deliveryId',
    );
  }

  /// Mostrar notificación de cambio de estado
  Future<void> showDeliveryStateChangeNotification({
    required int deliveryId,
    required String newState,
    required String clientName,
  }) async {
    final stateEmoji = _getStateEmoji(newState);
    final stateLabel = _getStateLabel(newState);

    await _showNotification(
      id: deliveryId,
      title: '$stateEmoji Entrega $stateLabel',
      body: 'Entrega #$deliveryId para $clientName',
      channelId: 'cambio_estados',
      payload: 'delivery_$deliveryId',
    );
  }

  /// Mostrar notificación de recordatorio
  Future<void> showReminderNotification({
    required int pendingCount,
  }) async {
    await _showNotification(
      id: 9999, // ID fijo para recordatorios
      title: '⏰ Recordatorio de Entregas',
      body: 'Tienes $pendingCount entrega${pendingCount > 1 ? 's' : ''} pendiente${pendingCount > 1 ? 's' : ''}',
      channelId: 'recordatorios',
      payload: 'reminder',
    );
  }

  /// Mostrar notificación de completación de todas las entregas
  Future<void> showCompletionNotification() async {
    await _showNotification(
      id: 10000,
      title: '✅ ¡Trabajo Completado!',
      body: 'Has finalizado todas tus entregas del día',
      channelId: 'entregas_nuevas',
      payload: 'completion',
    );
  }

  /// Método privado para mostrar notificación
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification',
        styleInformation: const BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iOSDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error mostrando notificación: $e');
    }
  }

  /// Obtener nombre del canal
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'entregas_nuevas':
        return 'Nuevas Entregas';
      case 'cambio_estados':
        return 'Cambios de Estado';
      case 'recordatorios':
        return 'Recordatorios';
      case 'proformas':
        return 'Proformas';
      default:
        return 'Notificaciones';
    }
  }

  /// Obtener descripción del canal
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'entregas_nuevas':
        return 'Notificaciones de entregas asignadas';
      case 'cambio_estados':
        return 'Notificaciones de cambios en estado de entregas';
      case 'recordatorios':
        return 'Recordatorios de entregas pendientes';
      case 'proformas':
        return 'Notificaciones de proformas (aprobadas, rechazadas, convertidas)';
      default:
        return 'Notificaciones de la aplicación';
    }
  }

  /// Obtener emoji para el estado
  String _getStateEmoji(String state) {
    switch (state) {
      case 'EN_CAMINO':
        return '🚚';
      case 'LLEGO':
        return '🏁';
      case 'ENTREGADO':
        return '✅';
      case 'NOVEDAD':
        return '⚠️';
      default:
        return '📋';
    }
  }

  /// Obtener etiqueta para el estado
  String _getStateLabel(String state) {
    switch (state) {
      case 'ASIGNADA':
        return 'Asignada';
      case 'EN_CAMINO':
        return 'En Camino';
      case 'LLEGO':
        return 'Llegó';
      case 'ENTREGADO':
        return 'Entregada';
      case 'NOVEDAD':
        return 'Novedad Reportada';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return state;
    }
  }

  /// Mostrar notificación de proforma aprobada
  Future<void> showProformaApprovedNotification({
    required String numero,
    String? clientName,
  }) async {
    await _showNotification(
      id: numero.hashCode,
      title: '✅ Proforma Aprobada',
      body: 'La proforma $numero ha sido aprobada${clientName != null ? ' - Cliente: $clientName' : ''}',
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// Mostrar notificación de proforma rechazada
  Future<void> showProformaRejectedNotification({
    required String numero,
    String? motivo,
  }) async {
    await _showNotification(
      id: numero.hashCode,
      title: '❌ Proforma Rechazada',
      body: 'La proforma $numero fue rechazada${motivo != null ? ': $motivo' : ''}',
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// Mostrar notificación de proforma convertida a venta
  Future<void> showProformaConvertedNotification({
    required String numero,
    String? ventaNumero,
  }) async {
    await _showNotification(
      id: numero.hashCode,
      title: '🛒 Proforma Convertida',
      body: 'La proforma $numero se convirtió en venta${ventaNumero != null ? ' #$ventaNumero' : ''}',
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// Mostrar notificación de envío programado
  Future<void> showEnvioProgramadoNotification({
    required int envioId,
    String? cliente,
    String? fecha,
  }) async {
    await _showNotification(
      id: envioId,
      title: '📦 Envío Programado',
      body: 'Nuevo envío #$envioId${cliente != null ? ' para $cliente' : ''}${fecha != null ? ' - $fecha' : ''}',
      channelId: 'cambio_estados',
      payload: 'envio_$envioId',
    );
  }

  /// Mostrar notificación de envío en ruta
  Future<void> showEnvioEnRutaNotification({
    required int envioId,
    String? chofer,
  }) async {
    await _showNotification(
      id: envioId,
      title: '🚚 Envío En Ruta',
      body: 'El envío #$envioId está en camino${chofer != null ? ' - Chofer: $chofer' : ''}',
      channelId: 'cambio_estados',
      payload: 'envio_$envioId',
    );
  }

  /// Mostrar notificación de envío próximo
  Future<void> showEnvioProximoNotification({
    required int envioId,
    String? direccion,
  }) async {
    await _showNotification(
      id: envioId,
      title: '📍 Envío Próximo',
      body: 'El envío #$envioId está por llegar${direccion != null ? ' a $direccion' : ''}',
      channelId: 'cambio_estados',
      payload: 'envio_$envioId',
    );
  }

  /// Mostrar notificación de envío entregado
  Future<void> showEnvioEntregadoNotification({
    required int envioId,
    String? cliente,
  }) async {
    await _showNotification(
      id: envioId,
      title: '✅ Envío Entregado',
      body: 'El envío #$envioId fue entregado exitosamente${cliente != null ? ' a $cliente' : ''}',
      channelId: 'cambio_estados',
      payload: 'envio_$envioId',
    );
  }

  /// Mostrar notificación de entrega rechazada/con novedad
  Future<void> showEntregaRechazadaNotification({
    required int envioId,
    String? motivo,
  }) async {
    await _showNotification(
      id: envioId,
      title: '⚠️ Entrega con Novedad',
      body: 'Problema con envío #$envioId${motivo != null ? ': $motivo' : ''}',
      channelId: 'cambio_estados',
      payload: 'envio_$envioId',
    );
  }

  /// Cancelar notificación
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('❌ Error cancelando notificación: $e');
    }
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('❌ Error cancelando todas las notificaciones: $e');
    }
  }
}
