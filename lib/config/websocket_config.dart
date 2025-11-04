import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebSocketConfig {
  // URL del WebSocket desde variables de entorno
  static String get currentUrl {
    // Intenta obtener NODE_WEBSOCKET_URL primero, si no está disponible usa WEBSOCKET_URL
    final url = dotenv.env['NODE_WEBSOCKET_URL'] ??
                dotenv.env['WEBSOCKET_URL'] ??
                'http://localhost:3000';
    return url;
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectionDelay = Duration(seconds: 2);
  static const int maxReconnectionAttempts = 5;

  // Eventos
  static const String eventAuthenticate = 'authenticate';
  static const String eventAuthenticated = 'authenticated';
  static const String eventAuthenticationError = 'authentication_error';

  // Eventos de Proformas
  // ✅ Sincronizados con Node.js WebSocket Server
  static const String eventProformaCreated = 'proforma.creada';
  static const String eventProformaApproved = 'proforma.aprobada';
  static const String eventProformaRejected = 'proforma.rechazada';
  static const String eventProformaConverted = 'proforma.convertida';

  // Eventos de Stock
  static const String eventStockReserved = 'stock_reserved';
  static const String eventStockExpiring = 'stock_reservation_expiring';
  static const String eventStockUpdated = 'product_stock_updated';

  // Eventos de Pagos
  static const String eventPaymentConfirmed = 'payment_confirmed';

  // Eventos de Envíos/Logística
  static const String eventEnvioProgramado = 'envio_programado';
  static const String eventEnvioEnPreparacion = 'envio_en_preparacion';
  static const String eventEnvioEnRuta = 'envio_en_ruta';
  static const String eventUbicacionActualizada = 'ubicacion_actualizada';
  static const String eventEnvioProximo = 'envio_proximo';
  static const String eventEnvioEntregado = 'envio_entregado';
  static const String eventEntregaRechazada = 'entrega_rechazada';

  // Eventos del Sistema
  static const String eventConnect = 'connect';
  static const String eventDisconnect = 'disconnect';
  static const String eventError = 'error';
  static const String eventServerShutdown = 'server_shutdown';
}
