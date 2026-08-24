import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    // Usar 'ic_notification' - nuestro ícono personalizado copiado a res/drawable
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

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
    // debugPrint('✅ LocalNotificationService inicializado');
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

    const AndroidNotificationChannel
    proformasChannel = AndroidNotificationChannel(
      'proformas',
      'Proformas',
      description:
          'Notificaciones de proformas (aprobadas, rechazadas, convertidas)',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    // ✅ NUEVO: Canal para notificaciones de entregas consolidadas
    const AndroidNotificationChannel
    entregasConsolidadasChannel = AndroidNotificationChannel(
      'entregas',
      'Entregas Consolidadas',
      description:
          'Notificaciones de entregas creadas, ventas asignadas y reportes de carga',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    // ✅ NUEVA FASE 3: Canal para notificaciones de créditos
    const AndroidNotificationChannel creditosChannel =
        AndroidNotificationChannel(
          'creditos',
          'Notificaciones de Crédito',
          description: 'Créditos vencidos, críticos y pagos registrados',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        );

    // ✅ FASE 3: Canal para notificaciones recurrentes
    const AndroidNotificationChannel notificacionesRecurrentesChannel =
        AndroidNotificationChannel(
          'notificaciones_recurrentes',
          'Notificaciones Recurrentes',
          description: 'Anuncios, promociones y ofertas',
          importance: Importance.defaultImportance,
          enableVibration: false,
          enableLights: false,
        );

    // ✅ NUEVO: Canal para notificaciones de préstamos
    const AndroidNotificationChannel prestamosChannel =
        AndroidNotificationChannel(
          'prestamos',
          'Notificaciones de Préstamos',
          description: 'Préstamos a clientes y eventos',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        );

    const AndroidNotificationChannel devolucionesChannel =
        AndroidNotificationChannel(
          'devoluciones',
          'Notificaciones de Devoluciones',
          description: 'Devoluciones de préstamos registradas',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(entregasChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(estadosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(recordatoriosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(proformasChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(entregasConsolidadasChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(creditosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notificacionesRecurrentesChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(prestamosChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(devolucionesChannel);
  }

  /// Solicitar permisos en iOS y Android 13+
  Future<void> _requestPermissions() async {
    // iOS: solicitar permisos para notificaciones
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

    debugPrint('✅ Permisos solicitados en iOS');

    // Android 13+ (API 33+): solicitar permiso POST_NOTIFICATIONS
    // Nota: El permiso también debe estar en AndroidManifest.xml
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Solicitar el permiso en Android 13+
      final hasNotificationPermission = await androidPlugin
          ?.requestNotificationsPermission();
      if (hasNotificationPermission == true) {
        debugPrint('✅ Permiso POST_NOTIFICATIONS otorgado en Android');
      }
    } catch (e) {
      debugPrint('⚠️ Error solicitando permiso POST_NOTIFICATIONS: $e');
    }
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
    String? clientName,
    String? address,
  }) async {
    await _showNotification(
      id: deliveryId,
      title: '🚚 Nueva Entrega Asignada',
      body: 'Entrega #$deliveryId',
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
  Future<void> showReminderNotification({required int pendingCount}) async {
    await _showNotification(
      id: 9999, // ID fijo para recordatorios
      title: '⏰ Recordatorio de Entregas',
      body:
          'Tienes $pendingCount entrega${pendingCount > 1 ? 's' : ''} pendiente${pendingCount > 1 ? 's' : ''}',
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
      debugPrint('\n═══════════════════════════════════════');
      debugPrint('📤 Intentando mostrar notificación');
      debugPrint('   ID: $id');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   Channel: $channelId');
      debugPrint('═══════════════════════════════════════\n');

      // Determinar la importancia según el canal
      final Importance importance = _getImportanceForChannel(channelId);
      final Priority priority = _getPriorityForChannel(channelId);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            channelDescription: _getChannelDescription(channelId),
            importance: importance,
            priority: priority,
            enableVibration: _shouldVibrate(channelId),
            playSound: true,
            // Mostrar cuerpo completo en notificaciones grandes
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              htmlFormatBigText: false,
              htmlFormatContent: false,
            ),
            showWhen: true,
            autoCancel: true,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      try {
        await _notificationsPlugin.show(
          id,
          title,
          body,
          details,
          payload: payload,
        );

        debugPrint('\n═══════════════════════════════════════');
        debugPrint('✅ NOTIFICACIÓN MOSTRADA EXITOSAMENTE');
        debugPrint('   Title: $title');
        debugPrint('   Canal: $channelId');
        debugPrint('═══════════════════════════════════════\n');
      } catch (platformException) {
        // En algunos dispositivos/versiones, flutter_local_notifications falla
        // Pero el snackbar ya se muestra desde el listener, así que es aceptable
        debugPrint('\n═══════════════════════════════════════');
        debugPrint('⚠️ NOTIFICACIÓN NATIVA FALLÓ (pero snackbar se mostró)');
        debugPrint('   Title: $title');
        debugPrint('   Error: $platformException');
        debugPrint('═══════════════════════════════════════\n');
      }
    } catch (e) {
      debugPrint('\n═══════════════════════════════════════');
      debugPrint('❌ ERROR CRÍTICO EN NOTIFICACIÓN');
      debugPrint('   Title: $title');
      debugPrint('   Error: $e');
      debugPrint('═══════════════════════════════════════\n');
    }
  }

  /// Obtener importancia según el canal
  Importance _getImportanceForChannel(String channelId) {
    switch (channelId) {
      case 'entregas_nuevas':
      case 'proformas':
        return Importance.max;
      case 'cambio_estados':
      case 'entregas': // ✅ NUEVO: Entregas consolidadas
      case 'creditos': // ✅ NUEVA FASE 3
        return Importance.high;
      case 'recordatorios':
      default:
        return Importance.defaultImportance;
    }
  }

  /// Obtener prioridad según el canal
  Priority _getPriorityForChannel(String channelId) {
    switch (channelId) {
      case 'entregas_nuevas':
      case 'proformas':
        return Priority.high;
      case 'cambio_estados':
      case 'entregas': // ✅ NUEVO: Entregas consolidadas
      case 'creditos': // ✅ NUEVA FASE 3
        return Priority.high;
      case 'recordatorios':
      default:
        return Priority.defaultPriority;
    }
  }

  /// Determinar si debe vibrar según el canal
  bool _shouldVibrate(String channelId) {
    switch (channelId) {
      case 'entregas_nuevas':
      case 'cambio_estados':
      case 'proformas':
      case 'entregas': // ✅ NUEVO: Entregas consolidadas
      case 'creditos': // ✅ NUEVA FASE 3
        return true;
      case 'recordatorios':
      default:
        return false;
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
      case 'entregas': // ✅ NUEVO: Entregas consolidadas
        return 'Entregas Consolidadas';
      case 'creditos': // ✅ NUEVA FASE 3
        return 'Notificaciones de Crédito';
      case 'notificaciones_recurrentes': // ✅ FASE 3
        return 'Notificaciones Recurrentes';
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
      case 'entregas': // ✅ NUEVO: Entregas consolidadas
        return 'Notificaciones de entregas creadas, ventas asignadas y reportes de carga';
      case 'creditos': // ✅ NUEVA FASE 3
        return 'Notificaciones de créditos vencidos, críticos y pagos';
      case 'notificaciones_recurrentes': // ✅ FASE 3
        return 'Anuncios, promociones y ofertas';
      default:
        return 'Notificaciones de la aplicación';
    }
  }

  /// Obtener emoji para el estado
  String _getStateEmoji(String state) {
    switch (state) {
      case 'PROGRAMADO':
        return '📅';
      case 'ASIGNADA':
        return '📋';
      case 'EN_CAMINO':
      case 'EN_TRANSITO':
        return '🚚';
      case 'LLEGO':
        return '🏁';
      case 'ENTREGADO':
        return '✅';
      case 'PREPARACION_CARGA':
      case 'EN_CARGA':
      case 'LISTO_PARA_ENTREGA':
        return '📦';
      case 'NOVEDAD':
        return '⚠️';
      case 'RECHAZADO':
        return '❌';
      case 'CANCELADA':
        return '🚫';
      default:
        return '📋';
    }
  }

  /// Obtener etiqueta para el estado
  String _getStateLabel(String state) {
    switch (state) {
      case 'PROGRAMADO':
        return 'Programado';
      case 'ASIGNADA':
        return 'Asignada';
      case 'EN_CAMINO':
        return 'En Camino';
      case 'EN_TRANSITO':
        return 'En Tránsito';
      case 'LLEGO':
        return 'Llegó';
      case 'ENTREGADO':
        return 'Entregado';
      case 'PREPARACION_CARGA':
        return 'Preparación de Carga';
      case 'EN_CARGA':
        return 'En Carga';
      case 'LISTO_PARA_ENTREGA':
        return 'Listo para Entrega';
      case 'NOVEDAD':
        return 'Novedad Reportada';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return state;
    }
  }

  /// ✅ NUEVO: Mostrar notificación de proforma creada
  Future<void> showProformaCreatedNotification({
    required String numero,
    String? clientName,
    double? total,
  }) async {
    // ✅ Extraer solo el ID numérico (últimos dígitos)
    // De "PRO-20260304-0505" extraer "505"
    final idNumerico = numero.contains('-') ? numero.split('-').last : numero;

    final mensaje = clientName != null && total != null
        ? '📋 Nueva proforma de $clientName por Bs. ${total.toStringAsFixed(2)}'
        : clientName != null
        ? '📋 Nueva proforma de $clientName'
        : '📋 Nueva proforma #$idNumerico creada';

    await _showNotification(
      id: numero.hashCode,
      title: '📋 Proforma Creada',
      body: mensaje,
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación de proforma actualizada
  Future<void> showProformaUpdatedNotification({
    required String numero,
    String? clientName,
    double? total,
  }) async {
    // ✅ Extraer solo el ID numérico (últimos dígitos)
    // De "PRO-20260304-0505" extraer "505"
    final idNumerico = numero.contains('-') ? numero.split('-').last : numero;

    final mensaje = clientName != null && total != null
        ? '📝 Proforma de $clientName actualizada por Bs. ${total.toStringAsFixed(2)}'
        : clientName != null
        ? '📝 Proforma de $clientName actualizada'
        : '📝 Proforma #$idNumerico actualizada';

    await _showNotification(
      id: numero.hashCode,
      title: '📝 Proforma Actualizada',
      body: mensaje,
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// Mostrar notificación de proforma aprobada
  Future<void> showProformaApprovedNotification({
    required String numero,
    String? clientName,
  }) async {
    // ✅ NUEVO: Extraer solo el ID numérico (últimos dígitos)
    // De "PRO-20260302-0413" extraer "413"
    final idNumerico = numero.contains('-') ? numero.split('-').last : numero;

    final mensaje = clientName != null
        ? 'Proforma #$idNumerico aprobada del cliente $clientName'
        : 'Proforma #$idNumerico ha sido aprobada';

    await _showNotification(
      id: numero.hashCode,
      title: '✅ Proforma Aprobada',
      body: mensaje,
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
      body:
          'La proforma $numero fue rechazada${motivo != null ? ': $motivo' : ''}',
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// Mostrar notificación de proforma convertida a venta
  Future<void> showProformaConvertedNotification({
    required String numero,
    int? ventaId,
    String? clientName,
  }) async {
    // ✅ NUEVO: Extraer solo los IDs numéricos
    // De "PRO-20260302-0413" extraer "413"
    final proformaId = numero.contains('-') ? numero.split('-').last : numero;

    final mensaje = clientName != null && ventaId != null
        ? 'Proforma #$proformaId convertida. Folio: $ventaId - Cliente: $clientName'
        : clientName != null
        ? 'Proforma #$proformaId convertida. Cliente: $clientName'
        : ventaId != null
        ? 'Proforma #$proformaId convertida. Folio: $ventaId'
        : 'Proforma #$proformaId se convirtió en pedido';

    await _showNotification(
      id: numero.hashCode,
      title: '✅ Pedido Confirmado',
      body: mensaje,
      channelId: 'proformas',
      payload: 'proforma_$numero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando estado de venta cambia
  /// ✅ Actualizado: Muestra ID de venta (Folio) y entrega asignada
  Future<void> showVentaEstadoCambioNotification({
    required String ventaNumero,
    required int ventaId,
    required String nuevoEstado,
    String? clienteNombre,
    int? entregaId,
    String? entregaNumero,
  }) async {
    // ✅ NUEVO: Construir mensaje con Folio:ID y entrega asignada
    String mensaje = 'Venta #$ventaId cambió a $nuevoEstado';

    if (entregaId != null) {
      mensaje += ' | Asig. Entrega #:$entregaId';
    }

    if (clienteNombre != null) {
      mensaje += ' - $clienteNombre';
    }

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '📊 Estado de Venta Cambió',
      body: mensaje,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta está en tránsito
  Future<void> showVentaEnTransitoNotification({
    required String ventaNumero,
    String? clienteNombre,
  }) async {
    final mensaje = clienteNombre != null
        ? 'Tu venta $ventaNumero está en tránsito - $clienteNombre'
        : 'Venta $ventaNumero está en tránsito';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '🚚 Venta En Tránsito',
      body: mensaje,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta es entregada
  Future<void> showVentaEntregadaNotification({
    required String ventaNumero,
    String? clienteNombre,
    String? tipoConfirmacion,
  }) async {
    final tituloIcon = _generarTituloIconoConfirmacion(tipoConfirmacion);
    final titulo = tituloIcon['titulo'] as String;
    final mensaje = clienteNombre != null
        ? 'Tu venta $ventaNumero - $clienteNombre'
        : 'Venta $ventaNumero';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: titulo,
      body: mensaje,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta entra en preparación de carga
  Future<void> showVentaPreparacionCargaNotification({
    required String ventaNumero,
    String? clienteNombre,
  }) async {
    final mensaje = clienteNombre != null
        ? 'Tu venta $ventaNumero está en preparación - $clienteNombre'
        : 'Venta $ventaNumero en preparación de carga';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '📦 En Preparación',
      body: mensaje,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta está lista para entrega
  Future<void> showVentaListoParaEntregaNotification({
    required String ventaNumero,
    String? clienteNombre,
  }) async {
    final mensaje = clienteNombre != null
        ? 'Tu venta $ventaNumero está lista para entrega - $clienteNombre'
        : 'Venta $ventaNumero lista para entrega';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '✅ Listo Para Entrega',
      body: mensaje,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación de venta asignada a entrega
  Future<void> showVentaAsignadaAEntregaNotification({
    required int ventaId,
    required int entregaId,
    String? clientName,
    String? choferName,
    String? vehiculoPlaca,
  }) async {
    final mensaje =
        clientName != null && choferName != null && vehiculoPlaca != null
        ? 'Folio: $ventaId asignado a Entrega Folio: $entregaId\nChofer: $choferName | Vehículo: $vehiculoPlaca'
        : clientName != null && choferName != null
        ? 'Folio: $ventaId asignado a Entrega Folio: $entregaId\nChofer: $choferName'
        : 'Folio: $ventaId asignado a Entrega Folio: $entregaId';

    await _showNotification(
      id: ventaId,
      title: '📦 Venta Asignada a Entrega',
      body: mensaje,
      channelId: 'entregas',
      payload: 'venta_entrega_${ventaId}_$entregaId',
    );
  }

  /// ✅ NUEVO: Mostrar notificación de entrega consolidada creada
  Future<void> showEntregaCreatedNotification({
    required int entregaId,
    required String numeroEntrega,
    String? choferNombre,
    String? vehiculoPlaca,
    int? ventasCount,
  }) async {
    final mensaje = choferNombre != null && vehiculoPlaca != null
        ? 'Entrega $numeroEntrega - Chofer: $choferNombre\nVehículo: $vehiculoPlaca${ventasCount != null ? ' - $ventasCount ventas' : ''}'
        : choferNombre != null
        ? 'Entrega $numeroEntrega - Chofer: $choferNombre'
        : 'Entrega $numeroEntrega creada';

    await _showNotification(
      id: entregaId,
      title: '🚚 Nueva Entrega Consolidada',
      body: mensaje,
      channelId: 'entregas',
      payload: 'entrega_$entregaId',
    );
  }

  /// ✅ NUEVO: Mostrar notificación de reporte de carga generado
  Future<void> showReporteCargoGeneradoNotification({
    required int reporteId,
    required String reporteNumero,
    String? entregaNumero,
    String? choferNombre,
    String? vehiculoPlaca,
    int? ventasCount,
  }) async {
    final mensaje = entregaNumero != null && choferNombre != null
        ? 'Reporte $reporteNumero - Entrega: $entregaNumero\nChofer: $choferNombre${vehiculoPlaca != null ? ' | Vehículo: $vehiculoPlaca' : ''}${ventasCount != null ? ' - $ventasCount ventas' : ''}'
        : entregaNumero != null
        ? 'Reporte $reporteNumero - Entrega: $entregaNumero'
        : 'Reporte $reporteNumero generado';

    await _showNotification(
      id: reporteId,
      title: '📋 Reporte de Carga Generado',
      body: mensaje,
      channelId: 'entregas',
      payload: 'reporte_$reporteId',
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
      body:
          'Nuevo envío #$envioId${cliente != null ? ' para $cliente' : ''}${fecha != null ? ' - $fecha' : ''}',
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
      body:
          'El envío #$envioId está en camino${chofer != null ? ' - Chofer: $chofer' : ''}',
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
      body:
          'El envío #$envioId está por llegar${direccion != null ? ' a $direccion' : ''}',
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
      body:
          'El envío #$envioId fue entregado exitosamente${cliente != null ? ' a $cliente' : ''}',
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

  // ✅ NUEVA FASE 3: Notificaciones de Créditos

  /// Mostrar notificación de crédito vencido
  Future<void> showCreditoVencidoNotification({
    required int cuentaId,
    required String clienteNombre,
    required double saldoPendiente,
    required int diasVencido,
  }) async {
    await _showNotification(
      id: cuentaId,
      title: '⚠️ Crédito Vencido',
      body:
          'Cliente $clienteNombre - Deuda: Bs. ${saldoPendiente.toStringAsFixed(2)} - Vencido hace $diasVencido días',
      channelId: 'creditos',
      payload: 'credito_vencido_$cuentaId',
    );
  }

  /// Mostrar notificación de crédito crítico (>80% utilización)
  Future<void> showCreditoCriticoNotification({
    required int clienteId,
    required String clienteNombre,
    required double porcentajeUtilizado,
    required double saldoDisponible,
  }) async {
    await _showNotification(
      id: clienteId,
      title: '🔴 Crédito Crítico',
      body:
          'Cliente $clienteNombre - Utilización: ${porcentajeUtilizado.toStringAsFixed(0)}% - Disponible: Bs. ${saldoDisponible.toStringAsFixed(2)}',
      channelId: 'creditos',
      payload: 'credito_critico_$clienteId',
    );
  }

  /// Mostrar notificación de pago registrado en crédito
  Future<void> showCreditoPagoRegistradoNotification({
    required int pagoId,
    required String clienteNombre,
    required double monto,
    required double saldoRestante,
    required String metodoPago,
  }) async {
    await _showNotification(
      id: pagoId,
      title: '✅ Pago de Crédito Registrado',
      body:
          'Cliente $clienteNombre - Pagó: Bs. ${monto.toStringAsFixed(2)} via $metodoPago - Saldo: Bs. ${saldoRestante.toStringAsFixed(2)}',
      channelId: 'creditos',
      payload: 'credito_pago_$pagoId',
    );
  }

  // ✅ FASE 3: Notificaciones Recurrentes

  /// Mostrar notificación recurrente (broadcasts globales desde Scheduler)
  Future<void> showRecurringNotification({
    required int notificacionId,
    required String titulo,
    required String descripcion,
    required String tipo,
  }) async {
    await _showNotification(
      id: notificacionId,
      title: titulo,
      body: descripcion,
      channelId: 'notificaciones_recurrentes',
      payload: 'notificacion_recurrente_$notificacionId',
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

  /// 🧪 MÉTODO DE PRUEBA: Enviar notificación de prueba
  /// Útil para verificar que todo funciona correctamente
  Future<void> sendTestNotification({required String channel}) async {
    switch (channel) {
      case 'entregas':
        await showNewDeliveryNotification(
          deliveryId: 9999,
          clientName: 'CLIENTE PRUEBA',
          address: 'Calle de prueba 123',
        );
        break;
      case 'estado':
        await showDeliveryStateChangeNotification(
          deliveryId: 9999,
          newState: 'EN_CAMINO',
          clientName: 'CLIENTE PRUEBA',
        );
        break;
      case 'proforma':
        await showProformaApprovedNotification(
          numero: 'PRO-TEST-001',
          clientName: 'CLIENTE PRUEBA',
        );
        break;
      case 'envio':
        await showEnvioProgramadoNotification(
          envioId: 9999,
          cliente: 'CLIENTE PRUEBA',
          fecha: 'Mañana a las 10:00',
        );
        break;
    }
  }

  /// 🔍 VERIFICACIÓN: Estado del servicio
  Future<void> printServiceStatus() async {
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('📊 ESTADO DEL SERVICIO DE NOTIFICACIONES');
    debugPrint('═══════════════════════════════════════');
    debugPrint('✅ Inicializado: $_isInitialized');
    debugPrint('✅ Plugin: ${_notificationsPlugin.runtimeType}');
    debugPrint(
      '✅ Canales Android: entregas_nuevas, cambio_estados, recordatorios, proformas, creditos',
    );
    debugPrint('✅ Permisos iOS: Alert, Badge, Sound');
    debugPrint('✅ Permisos Android: POST_NOTIFICATIONS, VIBRATE');
    debugPrint('═══════════════════════════════════════\n');
  }

  // Generar título e icono basado en tipo_confirmacion
  Map<String, String> _generarTituloIconoConfirmacion(String? tipoConfirmacion) {
    return {
      'COMPLETA': {'titulo': '✅ Venta Entregada', 'icono': '✅'},
      'RECHAZADO': {'titulo': '❌ Venta Rechazada', 'icono': '❌'},
      'DEVOLUCION_PARCIAL': {'titulo': '⚠️ Devolución Parcial', 'icono': '⚠️'},
      'CLIENTE_CERRADO': {'titulo': '🏪 Local Cerrado', 'icono': '🏪'},
      'NO_CONTACTADO': {'titulo': '📞 No Contactado', 'icono': '📞'},
    }[tipoConfirmacion ?? 'COMPLETA'] ?? {'titulo': 'ℹ️ Actualización de Entrega', 'icono': 'ℹ️'};
  }

  /// ✅ NUEVO: Mostrar notificación cuando entrega está lista para entrega
  Future<void> showEntregaListoNotification({
    required int entregaId,
    required String entregaNumero,
    String? choferNombre,
    String? vehiculoPlaca,
    required int ventasCount,
  }) async {
    final chofer = choferNombre ?? 'Chofer asignado';
    final vehiculo = vehiculoPlaca ?? 'Vehículo';
    final body = '📤 $entregaNumero con $ventasCount ventas. Chofer: $chofer | Vehículo: $vehiculo';

    await _showNotification(
      id: entregaId,
      title: '📤 Entrega Lista para Salida',
      body: body,
      channelId: 'entregas_nuevas',
      payload: 'delivery_$entregaId',
    );
  }

  /// ✅ NUEVO: Mostrar notificación al cliente que su venta está lista
  Future<void> showClienteEntregaListoNotification({
    required String ventaNumero,
    required String entregaNumero,
    String? vehiculoPlaca,
    String? choferNombre,
  }) async {
    final vehiculo = vehiculoPlaca ?? 'Vehículo';
    final chofer = choferNombre ?? 'Chofer';
    final body = '📤 Tu pedido #$ventaNumero está en $vehiculo. Chofer: $chofer';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '📤 Tu Pedido Salió a Entrega',
      body: body,
      channelId: 'cambio_estados',
      payload: 'venta_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación venta confirmada como entregada (para admin/manager)
  Future<void> showVentaConfirmadaEntregaNotification({
    required String ventaNumero,
    required String entregaNumero,
    String? clienteNombre,
    String? choferNombre,
    String? tipoConfirmacion,
  }) async {
    final cliente = clienteNombre ?? 'Cliente';
    final chofer = choferNombre ?? 'Chofer';
    final tipo = tipoConfirmacion ?? 'COMPLETA';
    final body = '✅ Venta #$ventaNumero de $cliente confirmada por $chofer - $tipo';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '✅ Venta Confirmada como Entregada',
      body: body,
      channelId: 'cambio_estados',
      payload: 'venta_confirmada_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cliente venta confirmada (para cliente)
  Future<void> showClienteVentaConfirmadaNotification({
    required String ventaNumero,
    String? entregaNumero,
    String? choferNombre,
    String? tipoConfirmacion,
  }) async {
    final chofer = choferNombre ?? 'Chofer';
    String titulo = '✅ Tu Pedido Fue Confirmado';
    String body = '✅ Tu pedido #$ventaNumero ha sido confirmado y entregado';

    // Ajustar mensaje según tipo de confirmación
    switch (tipoConfirmacion) {
      case 'RECHAZADO':
        titulo = '❌ Tu Pedido Fue Rechazado';
        body = '❌ Tu pedido #$ventaNumero fue rechazado';
        break;
      case 'DEVOLUCION_PARCIAL':
        titulo = '⚠️ Devolución Parcial';
        body = '⚠️ Tu pedido #$ventaNumero tiene devolución parcial';
        break;
      case 'CLIENTE_CERRADO':
        titulo = '🏪 Local Cerrado';
        body = '🏪 Tu local estaba cerrado - Pedido #$ventaNumero';
        break;
      case 'NO_CONTACTADO':
        titulo = '📞 No Contactado';
        body = '📞 No pudimos contactarte para pedido #$ventaNumero';
        break;
      default:
        body = '✅ Tu pedido #$ventaNumero ha sido confirmado por $chofer';
    }

    await _showNotification(
      id: ventaNumero.hashCode,
      title: titulo,
      body: body,
      channelId: 'cambio_estados',
      payload: 'cliente_venta_confirmada_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación preventista venta confirmada (para preventista)
  Future<void> showPreventistaVentaConfirmadaNotification({
    required String ventaNumero,
    String? entregaNumero,
    String? clienteNombre,
    String? choferNombre,
    String? tipoConfirmacion,
  }) async {
    final cliente = clienteNombre ?? 'Cliente';
    final chofer = choferNombre ?? 'Chofer';
    String titulo = '✅ Tu Venta Fue Confirmada';
    String body = '✅ Tu venta #$ventaNumero a $cliente fue confirmada y entregada';

    // Ajustar mensaje según tipo de confirmación
    switch (tipoConfirmacion) {
      case 'RECHAZADO':
        titulo = '❌ Tu Venta Fue Rechazada';
        body = '❌ Tu venta #$ventaNumero a $cliente fue rechazada';
        break;
      case 'DEVOLUCION_PARCIAL':
        titulo = '⚠️ Devolución Parcial';
        body = '⚠️ Tu venta #$ventaNumero a $cliente tiene devolución parcial';
        break;
      case 'CLIENTE_CERRADO':
        titulo = '🏪 Local Cerrado';
        body = '🏪 Tu venta #$ventaNumero - local de $cliente estaba cerrado';
        break;
      case 'NO_CONTACTADO':
        titulo = '📞 No Contactado';
        body = '📞 Tu venta #$ventaNumero a $cliente - no contactado';
        break;
      default:
        body = '✅ Tu venta #$ventaNumero a $cliente ha sido confirmada por $chofer';
    }

    await _showNotification(
      id: ventaNumero.hashCode,
      title: titulo,
      body: body,
      channelId: 'cambio_estados',
      payload: 'preventista_venta_confirmada_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cliente entrega salió a entrega
  Future<void> showClienteEntregaSalidoAEntregaNotification({
    required String ventaNumero,
    String? entregaNumero,
    String? choferNombre,
    String? vehiculoPlaca,
  }) async {
    final chofer = choferNombre ?? 'Chofer';
    final vehiculo = vehiculoPlaca ?? 'Vehículo';
    final body = '🚚 Tu pedido #$ventaNumero está en $vehiculo. Chofer: $chofer';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '🚚 Tu Pedido Salió a Entrega',
      body: body,
      channelId: 'cambio_estados',
      payload: 'entrega_salido_cliente_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación preventista entrega salió a entrega
  Future<void> showPreventistaEntregaSalidoAEntregaNotification({
    required String ventaNumero,
    String? entregaNumero,
    String? clienteNombre,
    String? choferNombre,
    String? vehiculoPlaca,
  }) async {
    final cliente = clienteNombre ?? 'Cliente';
    final chofer = choferNombre ?? 'Chofer';
    final vehiculo = vehiculoPlaca ?? 'Vehículo';
    final body = '🚚 Tu venta #$ventaNumero a $cliente está en $vehiculo. Chofer: $chofer';

    await _showNotification(
      id: ventaNumero.hashCode,
      title: '🚚 Tu Venta Salió a Entrega',
      body: body,
      channelId: 'cambio_estados',
      payload: 'entrega_salido_preventista_$ventaNumero',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando se crea un préstamo a cliente
  Future<void> showPrestamoClienteCreatedNotification({
    required int prestamoId,
    required String clienteNombre,
    required int cantidad,
    String? creadorNombre,
  }) async {
    final creator = creadorNombre ?? 'Sistema';
    final body = '🎁 Se creó un préstamo a $clienteNombre con $cantidad artículos. Creador: $creator';

    await _showNotification(
      id: prestamoId,
      title: '🎁 Nuevo Préstamo a Cliente',
      body: body,
      channelId: 'prestamos',
      payload: 'prestamo_cliente_$prestamoId',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando se crea un préstamo a evento
  Future<void> showPrestamoEventoCreatedNotification({
    required int prestamoId,
    required String nombreEvento,
    required int cantidad,
    String? creadorNombre,
  }) async {
    final creator = creadorNombre ?? 'Sistema';
    final body = '🎁 Se creó un préstamo para el evento $nombreEvento con $cantidad artículos. Creador: $creator';

    await _showNotification(
      id: prestamoId,
      title: '🎁 Nuevo Préstamo a Evento',
      body: body,
      channelId: 'prestamos',
      payload: 'prestamo_evento_$prestamoId',
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando se registra una devolución de préstamo
  Future<void> showDevolucionRegistradaNotification({
    required int devolucionId,
    required String prestamoNumero,
    String? clienteNombre,
    String? choferNombre,
    int? totalDevuelto,
  }) async {
    final cliente = clienteNombre ?? 'Cliente';
    final chofer = choferNombre ?? 'Chofer';
    final body = '🔄 Devolución registrada: $prestamoNumero - $cliente ($totalDevuelto items). Chofer: $chofer';

    await _showNotification(
      id: devolucionId,
      title: '🔄 Devolución Registrada',
      body: body,
      channelId: 'devoluciones',
      payload: 'devolucion_$devolucionId',
    );
  }
}
