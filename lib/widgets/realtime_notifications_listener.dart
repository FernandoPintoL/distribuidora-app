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
          // No mostrar notificación (el usuario acaba de crear)
          debugPrint('ℹ️ Proforma creada (sin notificación)');
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
        case 'asignada':
          _mostrarNotificacionEntregaAsignada(data);
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

    // ✅ Mostrar notificación NATIVA del sistema
    if (numero != null) {
      _notificationService.showProformaRejectedNotification(
        numero: numero,
        motivo: motivo,
      );
    }

    // ✅ Recargar solo las estadísticas (contador) sin cargar todas las notificaciones
    context.read<NotificationProvider>().loadStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Proforma Rechazada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (numero != null) Text('Proforma $numero'),
                  if (motivo != null)
                    Text(
                      motivo,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionProformaConvertida(Map<String, dynamic> data) {
    // ✅ NUEVO: Extraer datos completos del evento de conversión
    final proformaNumero = data['proforma_numero'] as String?;
    final ventaNumero = data['venta_numero'] as String?;
    final clienteNombre = data['cliente_nombre'] as String?;
    final ventaId = data['venta_id'] as int?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (proformaNumero != null && ventaId != null) {
      // Pasar todos los datos a la notificación
      _notificationService.showProformaConvertedNotification(
        numero: proformaNumero,
        ventaNumero: ventaNumero,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🚚 ¡Nueva Entrega Asignada!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (numeroEntrega != null)
                    Text('Entrega: $numeroEntrega'),
                  if (pesoKg != null)
                    Text('Peso: ${pesoKg.toStringAsFixed(1)} kg'),
                  if (vehiculoPlaca != null)
                    Text('Vehículo: $vehiculoPlaca'),
                  const SizedBox(height: 4),
                  const Text(
                    'Por favor inicia la carga de mercadería',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 7),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navegar a pantalla de carga de entrega
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
