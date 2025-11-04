import 'package:flutter/foundation.dart';
import 'client.dart';
import 'estado_pedido.dart';
import 'pedido_item.dart';
import 'pedido_estado_historial.dart';
import 'reserva_stock.dart';
import 'chofer.dart';
import 'camion.dart';

class Pedido {
  final int id;
  final String numero;
  final int clienteId;
  final Client? cliente;
  final int? direccionId;
  final ClientAddress? direccionEntrega;

  // Estados del pedido
  final EstadoPedido estado;
  final DateTime? fechaProgramada;
  final DateTime? horaInicioPreferida;
  final DateTime? horaFinPreferida;

  // Montos
  final double subtotal;
  final double impuesto;
  final double total;
  final String? observaciones;

  // Items del pedido
  final List<PedidoItem> items;

  // Tracking
  final List<PedidoEstadoHistorial> historialEstados;
  final List<ReservaStock> reservas;

  // Asignaciones (para admin/chofer)
  final int? choferId;
  final Chofer? chofer;
  final int? camionId;
  final Camion? camion;

  // Metadata
  final String canalOrigen;
  final DateTime fechaCreacion;
  final DateTime? fechaAprobacion;
  final DateTime? fechaEntrega;
  final int? usuarioAprobadorId;
  final String? comentariosAprobacion;

  // Comprobantes de entrega
  final String? firmaDigitalUrl;
  final String? fotoEntregaUrl;
  final DateTime? fechaFirmaEntrega;

  Pedido({
    required this.id,
    required this.numero,
    required this.clienteId,
    this.cliente,
    this.direccionId,
    this.direccionEntrega,
    required this.estado,
    this.fechaProgramada,
    this.horaInicioPreferida,
    this.horaFinPreferida,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    this.observaciones,
    this.items = const [],
    this.historialEstados = const [],
    this.reservas = const [],
    this.choferId,
    this.chofer,
    this.camionId,
    this.camion,
    required this.canalOrigen,
    required this.fechaCreacion,
    this.fechaAprobacion,
    this.fechaEntrega,
    this.usuarioAprobadorId,
    this.comentariosAprobacion,
    this.firmaDigitalUrl,
    this.fotoEntregaUrl,
    this.fechaFirmaEntrega,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse all datetime fields (backend can use created_at or fecha_creacion)
      final createdAtString = json['created_at'] ?? json['fecha_creacion'];
      final createdAt = createdAtString != null
          ? DateTime.parse(createdAtString as String)
          : DateTime.now();

      return Pedido(
        id: json['id'] as int,
        numero: json['numero'] as String,
        clienteId: json['cliente_id'] as int,
        cliente: json['cliente'] != null
            ? Client.fromJson(json['cliente'] as Map<String, dynamic>)
            : null,
        direccionId: json['direccion_id'] as int?,
        direccionEntrega: json['direccion_entrega'] != null
            ? ClientAddress.fromJson(json['direccion_entrega'] as Map<String, dynamic>)
            : null,
        estado: EstadoInfo.fromString(json['estado'] as String),
        // Backend can use fecha_programada, fecha_entrega_solicitada, or fecha
        fechaProgramada: json['fecha_programada'] != null
            ? DateTime.parse(json['fecha_programada'] as String)
            : (json['fecha_entrega_solicitada'] != null
                ? DateTime.parse(json['fecha_entrega_solicitada'] as String)
                : (json['fecha'] != null
                    ? DateTime.parse(json['fecha'] as String)
                    : null)),
        // Backend returns hora_entrega_solicitada or hora_inicio_preferida
        horaInicioPreferida: json['hora_inicio_preferida'] != null
            ? DateTime.parse(json['hora_inicio_preferida'] as String)
            : (json['hora_entrega_solicitada'] != null
                ? DateTime.parse('2025-01-01T${json['hora_entrega_solicitada']}:00')
                : null),
        horaFinPreferida: json['hora_fin_preferida'] != null
            ? DateTime.parse(json['hora_fin_preferida'] as String)
            : null,
        // Convert string numbers to double
        subtotal: _parseDouble(json['subtotal']),
        impuesto: _parseDouble(json['impuesto']),
        total: _parseDouble(json['total']),
        observaciones: json['observaciones'] as String?,
        // Backend returns detalles instead of items
        items: json['items'] != null
            ? (json['items'] as List)
                .map((item) => PedidoItem.fromJson(item as Map<String, dynamic>))
                .toList()
            : (json['detalles'] != null
                ? (json['detalles'] as List)
                    .map((item) => PedidoItem.fromJson(item as Map<String, dynamic>))
                    .toList()
                : []),
        historialEstados: json['historial_estados'] != null
            ? (json['historial_estados'] as List)
                .map((h) => PedidoEstadoHistorial.fromJson(h as Map<String, dynamic>))
                .toList()
            : [],
        reservas: json['reservas'] != null
            ? (json['reservas'] as List)
                .map((r) => ReservaStock.fromJson(r as Map<String, dynamic>))
                .toList()
            : [],
        choferId: json['chofer_id'] as int?,
        chofer: json['chofer'] != null
            ? Chofer.fromJson(json['chofer'] as Map<String, dynamic>)
            : null,
        camionId: json['camion_id'] as int?,
        camion: json['camion'] != null
            ? Camion.fromJson(json['camion'] as Map<String, dynamic>)
            : null,
        canalOrigen: json['canal_origen'] as String? ?? 'APP_EXTERNA',
        fechaCreacion: createdAt,
        fechaAprobacion: json['fecha_aprobacion'] != null
            ? DateTime.parse(json['fecha_aprobacion'] as String)
            : null,
        fechaEntrega: json['fecha_entrega'] != null
            ? DateTime.parse(json['fecha_entrega'] as String)
            : null,
        usuarioAprobadorId: json['usuario_aprobador_id'] as int?,
        comentariosAprobacion: json['comentarios_aprobacion'] as String?,
        firmaDigitalUrl: json['firma_digital_url'] as String?,
        fotoEntregaUrl: json['foto_entrega_url'] as String?,
        fechaFirmaEntrega: json['fecha_firma_entrega'] != null
            ? DateTime.parse(json['fecha_firma_entrega'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Pedido: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  // Helper to safely parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('⚠️  Could not parse "$value" as double, defaulting to 0.0');
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'cliente_id': clienteId,
      'cliente': cliente?.toJson(),
      'direccion_id': direccionId,
      'direccion_entrega': direccionEntrega?.toJson(),
      'estado': EstadoInfo.enumToString(estado),
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'hora_inicio_preferida': horaInicioPreferida?.toIso8601String(),
      'hora_fin_preferida': horaFinPreferida?.toIso8601String(),
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'observaciones': observaciones,
      'items': items.map((item) => item.toJson()).toList(),
      'historial_estados': historialEstados.map((h) => h.toJson()).toList(),
      'reservas': reservas.map((r) => r.toJson()).toList(),
      'chofer_id': choferId,
      'chofer': chofer?.toJson(),
      'camion_id': camionId,
      'camion': camion?.toJson(),
      'canal_origen': canalOrigen,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_aprobacion': fechaAprobacion?.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'usuario_aprobador_id': usuarioAprobadorId,
      'comentarios_aprobacion': comentariosAprobacion,
      'firma_digital_url': firmaDigitalUrl,
      'foto_entrega_url': fotoEntregaUrl,
      'fecha_firma_entrega': fechaFirmaEntrega?.toIso8601String(),
    };
  }

  Pedido copyWith({
    int? id,
    String? numero,
    int? clienteId,
    Client? cliente,
    int? direccionId,
    ClientAddress? direccionEntrega,
    EstadoPedido? estado,
    DateTime? fechaProgramada,
    DateTime? horaInicioPreferida,
    DateTime? horaFinPreferida,
    double? subtotal,
    double? impuesto,
    double? total,
    String? observaciones,
    List<PedidoItem>? items,
    List<PedidoEstadoHistorial>? historialEstados,
    List<ReservaStock>? reservas,
    int? choferId,
    Chofer? chofer,
    int? camionId,
    Camion? camion,
    String? canalOrigen,
    DateTime? fechaCreacion,
    DateTime? fechaAprobacion,
    DateTime? fechaEntrega,
    int? usuarioAprobadorId,
    String? comentariosAprobacion,
    String? firmaDigitalUrl,
    String? fotoEntregaUrl,
    DateTime? fechaFirmaEntrega,
  }) {
    return Pedido(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      cliente: cliente ?? this.cliente,
      direccionId: direccionId ?? this.direccionId,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      estado: estado ?? this.estado,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      horaInicioPreferida: horaInicioPreferida ?? this.horaInicioPreferida,
      horaFinPreferida: horaFinPreferida ?? this.horaFinPreferida,
      subtotal: subtotal ?? this.subtotal,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      observaciones: observaciones ?? this.observaciones,
      items: items ?? this.items,
      historialEstados: historialEstados ?? this.historialEstados,
      reservas: reservas ?? this.reservas,
      choferId: choferId ?? this.choferId,
      chofer: chofer ?? this.chofer,
      camionId: camionId ?? this.camionId,
      camion: camion ?? this.camion,
      canalOrigen: canalOrigen ?? this.canalOrigen,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      usuarioAprobadorId: usuarioAprobadorId ?? this.usuarioAprobadorId,
      comentariosAprobacion: comentariosAprobacion ?? this.comentariosAprobacion,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      fotoEntregaUrl: fotoEntregaUrl ?? this.fotoEntregaUrl,
      fechaFirmaEntrega: fechaFirmaEntrega ?? this.fechaFirmaEntrega,
    );
  }

  // Helpers
  EstadoInfo get estadoInfo => EstadoInfo.getInfo(estado);

  bool get tieneReservasActivas {
    return reservas.any((r) => r.estado == EstadoReserva.ACTIVA);
  }

  bool get tieneReservasProximasAVencer {
    return reservas.any((r) =>
      r.estado == EstadoReserva.ACTIVA &&
      r.tiempoRestante.inHours < 24
    );
  }

  ReservaStock? get reservaMasProximaAVencer {
    final reservasActivas = reservas
        .where((r) => r.estado == EstadoReserva.ACTIVA)
        .toList();

    if (reservasActivas.isEmpty) return null;

    reservasActivas.sort((a, b) => a.fechaExpiracion.compareTo(b.fechaExpiracion));
    return reservasActivas.first;
  }

  bool get puedeExtenderReservas {
    return estado == EstadoPedido.PENDIENTE && tieneReservasActivas;
  }

  int get cantidadItems {
    return items.length;
  }

  int get cantidadTotalProductos {
    return items.fold(0, (sum, item) => sum + item.cantidad.toInt());
  }
}
