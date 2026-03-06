import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../services/local_notification_service.dart';
import '../providers/providers.dart';

/// Widget que escucha eventos WebSocket y muestra notificaciones en tiempo real
///
/// Uso:
/// ```dart
/// RealtimeNotificationsListener(
///   child: Scaffold(...),
/// )
/// ```
class RealtimeNotificationsListener extends StatefulWidget {
  final Widget child;

  const RealtimeNotificationsListener({
    super.key,
    required this.child,
  });

  @override
  State<RealtimeNotificationsListener> createState() =>
      _RealtimeNotificationsListenerState();
}

class _RealtimeNotificationsListenerState
    extends State<RealtimeNotificationsListener> {
  final WebSocketService _webSocketService = WebSocketService();
  final LocalNotificationService _notificationService = LocalNotificationService();
  StreamSubscription? _proformaSubscription;
  StreamSubscription? _envioSubscription;
  StreamSubscription? _entregaSubscription; // ✅ NUEVO para entregas consolidadas
  StreamSubscription? _cargoSubscription; // ✅ NUEVO para reportes de carga
  StreamSubscription? _ventaSubscription; // ✅ NUEVO para eventos de ventas
  StreamSubscription? _creditoSubscription; // ✅ NUEVA FASE 3 para créditos

  @override
  void initState() {
    super.initState();
    // ✅ NUEVO: Log de inicialización
    debugPrint('🔌 [RealtimeNotificationsListener] initState - Iniciando escucha de WebSocket');
    debugPrint('   WebSocket conectado: ${_webSocketService.isConnected}');
    _iniciarEscucha();
  }

  @override
  void dispose() {
    _proformaSubscription?.cancel();
    _envioSubscription?.cancel();
    _entregaSubscription?.cancel(); // ✅ Cancelar suscripción de entregas
    _cargoSubscription?.cancel(); // ✅ Cancelar suscripción de carga
    _ventaSubscription?.cancel(); // ✅ Cancelar suscripción de ventas
    _creditoSubscription?.cancel(); // ✅ Cancelar suscripción de créditos
    super.dispose();
  }

  void _iniciarEscucha() {
    debugPrint('🔔 [RealtimeNotificationsListener] Iniciando escucha de eventos de WebSocket');

    // Escuchar eventos de proformas
    _proformaSubscription = _webSocketService.proformaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('📬 [RealtimeNotificationsListener] Evento recibido: type=$type');
      debugPrint('   Data: $data');

      switch (type) {
        case 'created':
          // ✅ NUEVO: Mostrar notificación si NO es el creador
          // Si el usuario actual es el creador, no mostrar (ya sabe que la creó)
          _mostrarNotificacionProformaCreada(data);
          break;
        case 'approved':
          // ✅ RESTAURADO: Mostrar notificación cuando proforma es aprobada
          debugPrint('✅ Proforma aprobada - Mostrando notificación');
          _mostrarNotificacionProformaAprobada(data);
          break;
        case 'rejected':
          debugPrint('❌ Proforma rechazada - Mostrando notificación');
          _mostrarNotificacionProformaRechazada(data);
          break;
        case 'updated':
        case 'actualizada':
          // ✅ NUEVO: Mostrar notificación cuando proforma es actualizada
          debugPrint('📝 Proforma actualizada - Mostrando notificación');
          _mostrarNotificacionProformaActualizada(data);
          break;
        case 'converted':
          // ✅ NUEVO: Escuchar evento de conversión que incluye cliente_nombre y venta_id
          debugPrint('🔄 Proforma convertida - Mostrando notificación');
          _mostrarNotificacionProformaConvertida(data);
          break;
      }
    });

    // Escuchar eventos de envíos
    _envioSubscription = _webSocketService.envioStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'programado':
          _mostrarNotificacionEnvioProgramado(data);
          break;
        case 'en_ruta':
          _mostrarNotificacionEnvioEnRuta(data);
          break;
        case 'proximo':
          _mostrarNotificacionEnvioProximo(data);
          break;
        case 'entregado':
          _mostrarNotificacionEnvioEntregado(data);
          break;
        case 'rechazada':
          _mostrarNotificacionEntregaRechazada(data);
          break;
      }
    });

    // ✅ NUEVO: Escuchar eventos de entregas consolidadas
    _entregaSubscription = _webSocketService.entregaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'creada':
          // ✅ NUEVO: Mostrar notificación cuando se crea una entrega consolidada
          debugPrint('🚚 Entrega consolidada creada - Mostrando notificación');
          _mostrarNotificacionEntregaCreada(data);
          break;
        case 'asignada':
          _mostrarNotificacionEntregaAsignada(data);
          break;
        case 'venta_asignada':
          // ✅ NUEVO: Mostrar notificación cuando venta es asignada a entrega
          debugPrint('📦 Venta asignada a entrega - Mostrando notificación');
          _mostrarNotificacionVentaAsignadaAEntrega(data);
          break;
      }
    });

    // ✅ NUEVO: Escuchar eventos de carga (reportes de carga)
    _cargoSubscription = _webSocketService.cargoStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'reporte_generado':
          // ✅ NUEVO: Mostrar notificación cuando se genera un reporte de carga
          debugPrint('📋 Reporte de carga generado - Mostrando notificación');
          _mostrarNotificacionReporteCargoGenerado(data);
          break;
      }
    });

    // ✅ NUEVO: Escuchar eventos de ventas (tracking logístico)
    _ventaSubscription = _webSocketService.ventaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'estado_cambio':
          // ✅ NUEVO: Mostrar notificación cuando estado de venta cambia
          debugPrint('📊 Venta cambió estado - Mostrando notificación');
          _mostrarNotificacionVentaEstadoCambio(data);
          break;
        case 'en_transito':
          _mostrarNotificacionVentaEnTransito(data);
          break;
        case 'entregada':
          _mostrarNotificacionVentaEntregada(data);
          break;
        case 'preparacion_carga':
          _mostrarNotificacionVentaPreparacionCarga(data);
          break;
        case 'listo_para_entrega':
          _mostrarNotificacionVentaListoParaEntrega(data);
          break;
      }
    });

    // ✅ NUEVA FASE 3: Escuchar eventos de créditos
    _creditoSubscription = _webSocketService.creditoStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'vencido':
          _mostrarNotificacionCreditoVencido(data);
          break;
        case 'critico':
          _mostrarNotificacionCreditoCritico(data);
          break;
        case 'pago_registrado':
          _mostrarNotificacionCreditoPagoRegistrado(data);
          break;
      }
    });
  }

  // ✅ Mostrar notificación cuando una proforma es APROBADA desde el panel
  // ✅ NUEVO: Mostrar notificación cuando se crea una proforma
  void _mostrarNotificacionProformaCreada(Map<String, dynamic> data) {
    final numero = data['numero'] as String?;
    final proformaNumero = data['proforma_numero'] as String? ?? numero;
    final clientName = data['cliente']?['nombre'] as String? ??
        data['cliente_nombre'] as String?;
    final total = data['total'] as num?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (proformaNumero != null) {
      _notificationService.showProformaCreatedNotification(
        numero: proformaNumero,
        clientName: clientName,
        total: total?.toDouble() ?? 0,
      );
    }

    // ✅ Recargar solo las estadísticas (contador)
    context.read<NotificationProvider>().loadStats();
  }

  // ✅ NUEVO: Mostrar notificación cuando se actualiza una proforma
  void _mostrarNotificacionProformaActualizada(Map<String, dynamic> data) {
    final numero = data['numero'] as String?;
    final proformaNumero = data['proforma_numero'] as String? ?? numero;
    final clientName = data['cliente']?['nombre'] as String? ??
        data['cliente_nombre'] as String?;
    final total = data['total'] as num?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (proformaNumero != null) {
      _notificationService.showProformaUpdatedNotification(
        numero: proformaNumero,
        clientName: clientName,
        total: total?.toDouble() ?? 0,
      );
    }

    // ✅ Recargar solo las estadísticas (contador)
    context.read<NotificationProvider>().loadStats();
  }

  void _mostrarNotificacionProformaAprobada(Map<String, dynamic> data) {
    final numero = data['numero'] as String?;
    final clientName = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (numero != null) {
      _notificationService.showProformaApprovedNotification(
        numero: numero,
        clientName: clientName,
      );
    }

    // ✅ Recargar solo las estadísticas (contador) sin cargar todas las notificaciones
    context.read<NotificationProvider>().loadStats();
  }

  void _mostrarNotificacionProformaRechazada(Map<String, dynamic> data) {
    final numero = data['numero'] as String?;
    final motivo = data['motivo_rechazo'] as String?;

    if (!mounted) return;

    // ✅ Mostrar SOLO notificación NATIVA del sistema
    // No mostrar snackbar (la notificación nativa es suficiente)
    if (numero != null) {
      _notificationService.showProformaRejectedNotification(
        numero: numero,
        motivo: motivo,
      );
    }

    // ✅ Recargar solo las estadísticas (contador)
    context.read<NotificationProvider>().loadStats();
  }

  void _mostrarNotificacionProformaConvertida(Map<String, dynamic> data) {
    // ✅ NUEVO: Extraer datos completos del evento de conversión
    final proformaNumero = data['proforma_numero'] as String?;
    final ventaId = data['venta_id'] as int?;
    final clienteNombre = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (proformaNumero != null && ventaId != null) {
      // Pasar todos los datos a la notificación
      _notificationService.showProformaConvertedNotification(
        numero: proformaNumero,
        ventaId: ventaId,
        clientName: clienteNombre,
      );
    }

    // ✅ Recargar solo las estadísticas (contador) sin cargar todas las notificaciones
    context.read<NotificationProvider>().loadStats();
  }

  void _mostrarNotificacionEnvioProgramado(Map<String, dynamic> data) {
    final envioId = data['id'] as int?;
    final cliente = data['cliente_nombre'] as String?;
    final fechaProgramada = data['fecha_programada'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (envioId != null) {
      _notificationService.showEnvioProgramadoNotification(
        envioId: envioId,
        cliente: cliente,
        fecha: fechaProgramada,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.event, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Envío Programado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (fechaProgramada != null)
                    Text('Entrega programada para $fechaProgramada'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionEnvioEnRuta(Map<String, dynamic> data) {
    final envioId = data['id'] as int?;
    final chofer = data['chofer_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (envioId != null) {
      _notificationService.showEnvioEnRutaNotification(
        envioId: envioId,
        chofer: chofer,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Tu pedido está en camino!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('El chofer ha salido a entregar tu pedido'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'SEGUIR',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navegar a tracking
          },
        ),
      ),
    );
  }

  void _mostrarNotificacionEnvioProximo(Map<String, dynamic> data) {
    final envioId = data['id'] as int?;
    final direccion = data['direccion'] as String?;
    final tiempoEstimado = data['tiempo_estimado_min'] as int?;
    final distanciaKm = data['distancia_km'] as double?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (envioId != null) {
      _notificationService.showEnvioProximoNotification(
        envioId: envioId,
        direccion: direccion,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Tu pedido está próximo!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (tiempoEstimado != null)
                    Text('Llegará en aproximadamente $tiempoEstimado minutos'),
                  if (distanciaKm != null)
                    Text('Distancia: ${distanciaKm.toStringAsFixed(1)} km'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionEnvioEntregado(Map<String, dynamic> data) {
    final envioId = data['id'] as int?;
    final cliente = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (envioId != null) {
      _notificationService.showEnvioEntregadoNotification(
        envioId: envioId,
        cliente: cliente,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡Pedido Entregado!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Tu pedido ha sido entregado exitosamente'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionEntregaRechazada(Map<String, dynamic> data) {
    final envioId = data['id'] as int?;
    final motivo = data['motivo'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (envioId != null) {
      _notificationService.showEntregaRechazadaNotification(
        envioId: envioId,
        motivo: motivo,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Problema con la entrega',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (motivo != null) Text(motivo),
                  const Text('Nos pondremos en contacto contigo pronto'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ✅ NUEVO: Mostrar notificación de entrega consolidada asignada al chofer
  void _mostrarNotificacionEntregaAsignada(Map<String, dynamic> data) {
    final entregaId = data['entrega_id'] as int?;
    final numeroEntrega = data['numero_entrega'] as String?;
    final pesoKg = data['peso_kg'] as num?;
    final vehiculoPlaca = data['vehiculo']?['placa'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (entregaId != null && numeroEntrega != null) {
      _notificationService.showNewDeliveryNotification(
        deliveryId: entregaId,
        clientName: numeroEntrega,
        address: vehiculoPlaca ?? 'Vehículo asignado',
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación de entrega consolidada creada
  void _mostrarNotificacionEntregaCreada(Map<String, dynamic> data) {
    final entregaId = data['entrega_id'] as int?;
    final entregaNumero = data['entrega_numero'] as String?;
    final estado = data['estado'] as String?;
    final choferNombre = data['chofer_nombre'] as String?;
    final vehiculoPlaca = data['vehiculo_placa'] as String?;
    final ventasCount = data['ventas_count'] as int?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (entregaId != null && entregaNumero != null) {
      _notificationService.showEntregaCreatedNotification(
        entregaId: entregaId,
        numeroEntrega: entregaNumero,
        choferNombre: choferNombre,
        vehiculoPlaca: vehiculoPlaca,
        ventasCount: ventasCount,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación de venta asignada a entrega
  void _mostrarNotificacionVentaAsignadaAEntrega(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] as int?;
    final entregaId = data['entrega_id'] as int?;
    final clienteNombre = data['cliente_nombre'] as String?;
    final choferNombre = data['chofer_nombre'] as String?;
    final vehiculoPlaca = data['vehiculo_placa'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaId != null && entregaId != null) {
      _notificationService.showVentaAsignadaAEntregaNotification(
        ventaId: ventaId,
        entregaId: entregaId,
        clientName: clienteNombre,
        choferName: choferNombre,
        vehiculoPlaca: vehiculoPlaca,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación de reporte de carga generado
  void _mostrarNotificacionReporteCargoGenerado(Map<String, dynamic> data) {
    final entregaId = data['entrega_id'] as int?;
    final entregaNumero = data['entrega_numero'] as String?;
    final reporteId = data['reporte_id'] as int?;
    final reporteNumero = data['reporte_numero'] as String?;
    final estado = data['estado'] as String?;
    final choferNombre = data['chofer_nombre'] as String?;
    final vehiculoPlaca = data['vehiculo_placa'] as String?;
    final ventasCount = data['ventas_count'] as int?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (reporteId != null && reporteNumero != null) {
      _notificationService.showReporteCargoGeneradoNotification(
        reporteId: reporteId,
        reporteNumero: reporteNumero,
        entregaNumero: entregaNumero,
        choferNombre: choferNombre,
        vehiculoPlaca: vehiculoPlaca,
        ventasCount: ventasCount,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();

    // ✅ Mostrar snackbar para UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.assignment, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '📋 Reporte de Carga Generado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (reporteNumero != null)
                    Text('Reporte: $reporteNumero'),
                  if (entregaNumero != null)
                    Text('Entrega: $entregaNumero'),
                  if (ventasCount != null)
                    Text('Ventas cargadas: $ventasCount'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ NUEVA FASE 3: Mostrar notificaciones de Créditos

  /// Mostrar notificación de crédito vencido
  void _mostrarNotificacionCreditoVencido(Map<String, dynamic> data) {
    final cuentaId = data['cuenta_por_cobrar_id'] as int?;
    final clienteNombre = data['cliente_nombre'] as String?;
    final saldoPendiente = data['saldo_pendiente'] as num?;
    final diasVencido = data['dias_vencido'] as int?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (cuentaId != null && clienteNombre != null) {
      _notificationService.showCreditoVencidoNotification(
        cuentaId: cuentaId,
        clienteNombre: clienteNombre,
        saldoPendiente: (saldoPendiente ?? 0).toDouble(),
        diasVencido: diasVencido ?? 0,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠️ Crédito Vencido',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (clienteNombre != null)
                    Text('Cliente: $clienteNombre'),
                  if (saldoPendiente != null)
                    Text('Deuda: Bs. ${saldoPendiente.toStringAsFixed(2)}'),
                  if (diasVencido != null)
                    Text('Vencido hace $diasVencido días'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostrar notificación de crédito crítico
  void _mostrarNotificacionCreditoCritico(Map<String, dynamic> data) {
    final clienteId = data['cliente_id'] as int?;
    final clienteNombre = data['cliente_nombre'] as String?;
    final porcentajeUtilizado = data['porcentaje_utilizado'] as num?;
    final saldoDisponible = data['saldo_disponible'] as num?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (clienteId != null && clienteNombre != null) {
      _notificationService.showCreditoCriticoNotification(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        porcentajeUtilizado: (porcentajeUtilizado ?? 0).toDouble(),
        saldoDisponible: (saldoDisponible ?? 0).toDouble(),
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔴 Crédito Crítico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (clienteNombre != null)
                    Text('Cliente: $clienteNombre'),
                  if (porcentajeUtilizado != null)
                    Text('Utilización: ${porcentajeUtilizado.toStringAsFixed(0)}%'),
                  if (saldoDisponible != null)
                    Text('Disponible: Bs. ${saldoDisponible.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostrar notificación de pago registrado en crédito
  void _mostrarNotificacionCreditoPagoRegistrado(Map<String, dynamic> data) {
    final pagoId = data['pago_id'] as int?;
    final clienteNombre = data['cliente_nombre'] as String?;
    final monto = data['monto'] as num?;
    final saldoRestante = data['saldo_restante'] as num?;
    final metodoPago = data['metodo_pago'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (pagoId != null && clienteNombre != null) {
      _notificationService.showCreditoPagoRegistradoNotification(
        pagoId: pagoId,
        clienteNombre: clienteNombre,
        monto: (monto ?? 0).toDouble(),
        saldoRestante: (saldoRestante ?? 0).toDouble(),
        metodoPago: metodoPago ?? 'efectivo',
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✅ Pago Registrado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (clienteNombre != null)
                    Text('Cliente: $clienteNombre'),
                  if (monto != null)
                    Text('Pagó: Bs. ${monto.toStringAsFixed(2)}'),
                  if (saldoRestante != null)
                    Text('Saldo: Bs. ${saldoRestante.toStringAsFixed(2)}'),
                  if (metodoPago != null)
                    Text('Método: $metodoPago'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ✅ NUEVO: Mostrar notificación cuando estado de venta cambia
  /// ✅ Actualizado: Incluye ID de venta (Folio) y entrega asignada
  void _mostrarNotificacionVentaEstadoCambio(Map<String, dynamic> data) {
    final ventaNumero = data['venta_numero'] as String?;
    final ventaId = data['venta_id'] as int?;
    final estadoNuevo = data['estado_nuevo'] as Map<String, dynamic>?;
    final clienteNombre = data['cliente_nombre'] as String?;

    // ✅ NUEVO: Obtener información de entrega asignada
    final entrega = data['entrega'] as Map<String, dynamic>?;
    final entregaId = entrega?['id'] as int?;
    final entregaNumero = entrega?['numero_entrega'] as String?;

    if (!mounted) return;

    final estadoLabel = estadoNuevo?['nombre'] as String? ?? 'Cambió estado';
    final stateEmoji = _getEstadoEmoji(estadoNuevo?['codigo'] as String? ?? '');

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaNumero != null) {
      _notificationService.showVentaEstadoCambioNotification(
        ventaNumero: ventaNumero,
        ventaId: ventaId ?? 0,  // Usar 0 como fallback si no viene el ID
        nuevoEstado: estadoLabel,
        clienteNombre: clienteNombre,
        entregaId: entregaId,  // ✅ NUEVO: Pasar ID de entrega
        entregaNumero: entregaNumero,  // ✅ NUEVO: Pasar número de entrega
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta entra en tránsito
  void _mostrarNotificacionVentaEnTransito(Map<String, dynamic> data) {
    final ventaNumero = data['venta_numero'] as String?;
    final clienteNombre = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaNumero != null) {
      _notificationService.showVentaEnTransitoNotification(
        ventaNumero: ventaNumero,
        clienteNombre: clienteNombre,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta es entregada
  void _mostrarNotificacionVentaEntregada(Map<String, dynamic> data) {
    final ventaNumero = data['venta_numero'] as String?;
    final clienteNombre = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaNumero != null) {
      _notificationService.showVentaEntregadaNotification(
        ventaNumero: ventaNumero,
        clienteNombre: clienteNombre,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta entra en preparación de carga
  void _mostrarNotificacionVentaPreparacionCarga(Map<String, dynamic> data) {
    final ventaNumero = data['venta_numero'] as String?;
    final clienteNombre = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaNumero != null) {
      _notificationService.showVentaPreparacionCargaNotification(
        ventaNumero: ventaNumero,
        clienteNombre: clienteNombre,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ NUEVO: Mostrar notificación cuando venta está lista para entrega
  void _mostrarNotificacionVentaListoParaEntrega(Map<String, dynamic> data) {
    final ventaNumero = data['venta_numero'] as String?;
    final clienteNombre = data['cliente_nombre'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (ventaNumero != null) {
      _notificationService.showVentaListoParaEntregaNotification(
        ventaNumero: ventaNumero,
        clienteNombre: clienteNombre,
      );
    }

    // ✅ Recargar estadísticas
    context.read<NotificationProvider>().loadStats();
  }

  /// ✅ Helper: Obtener emoji según estado
  String _getEstadoEmoji(String estado) {
    switch (estado) {
      case 'PENDIENTE_PAGO':
        return '💰';
      case 'PAGADA':
        return '✅';
      case 'EN_PREPARACION':
        return '📦';
      case 'PENDIENTE_ENVIO':
        return '🚚';
      case 'EN_TRANSITO':
        return '📍';
      case 'ENTREGADA':
        return '✅';
      case 'CANCELADA':
        return '❌';
      default:
        return '📊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
