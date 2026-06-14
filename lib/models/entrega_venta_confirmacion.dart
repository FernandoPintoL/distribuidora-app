import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class EntregaVentaConfirmacion {
  final int id;
  final int entregaId;
  final int ventaId;
  final String? firmaDigitalUrl;
  final List<String>? fotos;
  final String? observacionesLogistica;
  final bool? tiendaAbierta;
  final bool? clientePresente;
  final String? motivoRechazo;
  final String estadoPago;
  final double montoRecibido;
  final int tipoPagoId;
  final String? motivoNoPago;
  final int? confirmadoPor;
  final DateTime? confirmadoEn;
  final DateTime? creadoEn;
  final String? fotoComprobante;
  final String tipoEntrega;
  final String? tipoNovedad;
  final bool tuvoProblema;
  final List<DesglosePago> desglosePageos;
  final double totalDineroRecibido;
  final double montoPendiente;
  final String tipoConfirmacion;
  final List<dynamic>? productosDevueltos;
  final double? montoDevuelto;
  final double montoAceptado;

  EntregaVentaConfirmacion({
    required this.id,
    required this.entregaId,
    required this.ventaId,
    this.firmaDigitalUrl,
    this.fotos,
    this.observacionesLogistica,
    this.tiendaAbierta,
    this.clientePresente,
    this.motivoRechazo,
    required this.estadoPago,
    required this.montoRecibido,
    required this.tipoPagoId,
    this.motivoNoPago,
    this.confirmadoPor,
    this.confirmadoEn,
    this.creadoEn,
    this.fotoComprobante,
    required this.tipoEntrega,
    this.tipoNovedad,
    required this.tuvoProblema,
    this.desglosePageos = const [],
    required this.totalDineroRecibido,
    required this.montoPendiente,
    required this.tipoConfirmacion,
    this.productosDevueltos,
    this.montoDevuelto,
    required this.montoAceptado,
  });

  factory EntregaVentaConfirmacion.fromJson(Map<String, dynamic> json) {
    List<DesglosePago> desgloses = [];
    if (json['desglose_pagos'] is List) {
      desgloses = (json['desglose_pagos'] as List)
          .map((item) => DesglosePago.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final tipoConfirmacionParsed = json['tipo_confirmacion'] as String? ?? 'COMPLETA';
    final tipoNovededadParsed = json['tipo_novedad'] as String?;
    final tipoEntregaParsed = json['tipo_entrega'] as String? ?? 'COMPLETA';

    debugPrint(
      '✅ Parseando EntregaVentaConfirmacion - Venta: ${json['venta_id']} | '
      'tipoConfirmacion: $tipoConfirmacionParsed | '
      'tipoNovedad: $tipoNovededadParsed | '
      'tipoEntrega: $tipoEntregaParsed',
    );

    return EntregaVentaConfirmacion(
      id: json['id'] as int,
      entregaId: (json['entrega_id'] as int?) ?? 0,
      ventaId: (json['venta_id'] as int?) ?? 0,
      firmaDigitalUrl: json['firma_digital_url'] as String?,
      fotos: (json['fotos'] as List<dynamic>?)?.cast<String>(),
      observacionesLogistica: json['observaciones_logistica'] as String?,
      tiendaAbierta: json['tienda_abierta'] as bool?,
      clientePresente: json['cliente_presente'] as bool?,
      motivoRechazo: json['motivo_rechazo'] as String?,
      estadoPago: json['estado'] as String? ?? json['estado_pago'] as String? ?? 'PENDIENTE',
      montoRecibido: _parseDouble(json['monto_recibido']),
      tipoPagoId: json['tipo_pago_id'] as int? ?? 0,
      motivoNoPago: json['motivo_no_pago'] as String?,
      confirmadoPor: json['confirmado_por'] as int?,
      confirmadoEn: json['confirmado_en'] != null
          ? _parseUtcToLocal(json['confirmado_en'] as String)
          : null,
      creadoEn: json['created_at'] != null
          ? _parseUtcToLocal(json['created_at'] as String)
          : json['fecha_registro'] != null
              ? _parseUtcToLocal(json['fecha_registro'] as String)
              : null,
      fotoComprobante: json['foto_comprobante'] as String?,
      tipoEntrega: tipoEntregaParsed,
      tipoNovedad: tipoNovededadParsed,
      tuvoProblema: json['tuvo_problema'] as bool? ?? false,
      desglosePageos: desgloses,
      totalDineroRecibido: _parseDouble(json['total_dinero_recibido']),
      montoPendiente: _parseDouble(json['pendiente'] ?? json['monto_pendiente']),
      tipoConfirmacion: tipoConfirmacionParsed,
      productosDevueltos: json['productos_devueltos'] as List<dynamic>?,
      montoDevuelto: (json['monto_devuelto'] as num?)?.toDouble(),
      montoAceptado: _parseDouble(json['monto_aceptado']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  String get fechaConfirmacionFormato {
    if (confirmadoEn == null) return 'N/A';
    try {
      final formatter = DateFormat('dd MMM yyyy HH:mm', 'es_ES');
      return formatter.format(confirmadoEn!);
    } catch (e) {
      return confirmadoEn.toString();
    }
  }

  String get estadoPagoFormato {
    switch (estadoPago.toUpperCase()) {
      case 'PAGADO':
        return '✅ Pagado';
      case 'PARCIAL':
        return '⚠️ Parcialmente Pagado';
      case 'PENDIENTE':
        return '⏳ Pendiente';
      default:
        return estadoPago;
    }
  }

  String get tipoEntregaFormato {
    switch (tipoEntrega.toUpperCase()) {
      case 'COMPLETA':
        return '✅ Entrega Completa';
      case 'PARCIAL':
        return '⚠️ Entrega Parcial';
      case 'CON_NOVEDAD':
        return '⚠️ Con Novedad';
      default:
        return tipoEntrega;
    }
  }

  /// ✅ NUEVO 2026-06-14: Parsear fecha UTC y convertir a zona horaria local
  static DateTime _parseUtcToLocal(String dateString) {
    try {
      final utcDateTime = DateTime.parse(dateString);
      // Convertir UTC a zona horaria local
      return utcDateTime.toLocal();
    } catch (e) {
      debugPrint('⚠️ Error parseando fecha: $e');
      return DateTime.now();
    }
  }
}

class DesglosePago {
  final int tipoPagoId;
  final String tipoPagoNombre;
  final double monto;
  final String? referencia;

  DesglosePago({
    required this.tipoPagoId,
    required this.tipoPagoNombre,
    required this.monto,
    this.referencia,
  });

  factory DesglosePago.fromJson(Map<String, dynamic> json) {
    return DesglosePago(
      tipoPagoId: json['tipo_pago_id'] as int,
      tipoPagoNombre: json['tipo_pago_nombre'] as String,
      monto: _parseDouble(json['monto']),
      referencia: json['referencia'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }
}
