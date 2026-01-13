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

  @override
  void initState() {
    super.initState();
    _iniciarEscucha();
  }

  @override
  void dispose() {
    _proformaSubscription?.cancel();
    _envioSubscription?.cancel();
    _entregaSubscription?.cancel(); // ✅ Cancelar suscripción de entregas
    super.dispose();
  }

  void _iniciarEscucha() {
    // Escuchar eventos de proformas
    _proformaSubscription = _webSocketService.proformaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      switch (type) {
        case 'created':
          // No mostrar notificación (el usuario acaba de crear)
          break;
        case 'approved':
          _mostrarNotificacionProformaAprobada(data);
          break;
        case 'rejected':
          _mostrarNotificacionProformaRechazada(data);
          break;
        case 'converted':
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
                    '¡Proforma Aprobada!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (numero != null)
                    Text('Proforma $numero ha sido aprobada'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navegar a detalles de proforma
          },
        ),
      ),
    );
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
    final numero = data['numero'] as String?;
    final ventaNumero = data['venta_numero'] as String?;

    if (!mounted) return;

    // ✅ Mostrar notificación NATIVA del sistema
    if (numero != null) {
      _notificationService.showProformaConvertedNotification(
        numero: numero,
        ventaNumero: ventaNumero,
      );
    }

    // ✅ Recargar solo las estadísticas (contador) sin cargar todas las notificaciones
    context.read<NotificationProvider>().loadStats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Pedido Confirmado!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (ventaNumero != null)
                    Text('Pedido $ventaNumero creado exitosamente'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
