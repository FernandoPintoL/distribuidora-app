import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
  final DateTime? actualizadoEn;

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
    this.actualizadoEn,
  });

  /// ✅ Factory para crear una instancia inicial (nueva confirmación)
  factory EntregaVentaConfirmacion.inicial({
    required int entregaId,
    required int ventaId,
    String tipoEntrega = 'COMPLETA',
    String tipoConfirmacion = 'COMPLETA',
  }) {
    return EntregaVentaConfirmacion(
      id: 0,
      entregaId: entregaId,
      ventaId: ventaId,
      tipoEntrega: tipoEntrega,
      tipoConfirmacion: tipoConfirmacion,
      estadoPago: 'PENDIENTE',
      montoRecibido: 0,
      tipoPagoId: 0,
      tuvoProblema: false,
      totalDineroRecibido: 0,
      montoPendiente: 0,
      montoAceptado: 0,
    );
  }

  factory EntregaVentaConfirmacion.fromJson(Map<String, dynamic> json) {
    List<DesglosePago> desgloses = [];

    // desglose_pagos puede venir como string JSON o como array directo
    List<dynamic>? desgloseList;
    if (json['desglose_pagos'] is String) {
      try {
        desgloseList = jsonDecode(json['desglose_pagos'] as String) as List;
      } catch (e) {
        debugPrint('⚠️ Error parseando desglose_pagos string: $e');
        desgloseList = null;
      }
    } else if (json['desglose_pagos'] is List) {
      desgloseList = json['desglose_pagos'] as List;
    }

    if (desgloseList != null) {
      desgloses = desgloseList
          .map((item) => DesglosePago.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<dynamic>? productosDevueltos;
    if (json['productos_devueltos'] is String) {
      try {
        final jsonDecoded = jsonDecode(json['productos_devueltos'] as String) as List;
        productosDevueltos = jsonDecoded;
      } catch (e) {
        debugPrint('⚠️ Error parseando productos_devueltos: $e');
        productosDevueltos = null;
      }
    } else if (json['productos_devueltos'] is List) {
      productosDevueltos = json['productos_devueltos'] as List<dynamic>;
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
      id: _parseInt(json['id']),
      entregaId: _parseInt(json['entrega_id']),
      ventaId: _parseInt(json['venta_id']),
      firmaDigitalUrl: json['firma_digital_url'] as String?,
      fotos: (json['fotos'] as List<dynamic>?)?.cast<String>(),
      observacionesLogistica: json['observaciones_logistica'] as String?,
      tiendaAbierta: json['tienda_abierta'] as bool?,
      clientePresente: json['cliente_presente'] as bool?,
      motivoRechazo: json['motivo_rechazo'] as String?,
      estadoPago: json['estado'] as String? ?? json['estado_pago'] as String? ?? 'PENDIENTE',
      montoRecibido: _parseDouble(json['monto_recibido']),
      tipoPagoId: _parseInt(json['tipo_pago_id']),
      motivoNoPago: json['motivo_no_pago'] as String?,
      confirmadoPor: _extractIntFromValue(json['confirmado_por']),
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
      totalDineroRecibido: _parseDouble(json['total_dinero_recibido'] ?? json['monto_recibido']),
      montoPendiente: _parseDouble(json['pendiente'] ?? json['monto_pendiente']),
      tipoConfirmacion: tipoConfirmacionParsed,
      productosDevueltos: productosDevueltos,
      montoDevuelto: _parseDouble(json['monto_devuelto']),
      montoAceptado: _parseDouble(json['monto_aceptado'] ?? json['monto_recibido']),
      actualizadoEn: json['updated_at'] != null
          ? _parseUtcToLocal(json['updated_at'] as String)
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
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

  static int? _extractIntFromValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is Map<String, dynamic>) {
      return (value['id'] as int?);
    }
    return null;
  }

  EntregaVentaConfirmacion copyWith({
    int? id,
    int? entregaId,
    int? ventaId,
    String? firmaDigitalUrl,
    List<String>? fotos,
    String? observacionesLogistica,
    bool? tiendaAbierta,
    bool? clientePresente,
    String? motivoRechazo,
    String? estadoPago,
    double? montoRecibido,
    int? tipoPagoId,
    String? motivoNoPago,
    int? confirmadoPor,
    DateTime? confirmadoEn,
    DateTime? creadoEn,
    String? fotoComprobante,
    String? tipoEntrega,
    String? tipoNovedad,
    bool? tuvoProblema,
    List<DesglosePago>? desglosePageos,
    double? totalDineroRecibido,
    double? montoPendiente,
    String? tipoConfirmacion,
    List<dynamic>? productosDevueltos,
    double? montoDevuelto,
    double? montoAceptado,
    DateTime? actualizadoEn,
  }) {
    return EntregaVentaConfirmacion(
      id: id ?? this.id,
      entregaId: entregaId ?? this.entregaId,
      ventaId: ventaId ?? this.ventaId,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      fotos: fotos ?? this.fotos,
      observacionesLogistica: observacionesLogistica ?? this.observacionesLogistica,
      tiendaAbierta: tiendaAbierta ?? this.tiendaAbierta,
      clientePresente: clientePresente ?? this.clientePresente,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      estadoPago: estadoPago ?? this.estadoPago,
      montoRecibido: montoRecibido ?? this.montoRecibido,
      tipoPagoId: tipoPagoId ?? this.tipoPagoId,
      motivoNoPago: motivoNoPago ?? this.motivoNoPago,
      confirmadoPor: confirmadoPor ?? this.confirmadoPor,
      confirmadoEn: confirmadoEn ?? this.confirmadoEn,
      creadoEn: creadoEn ?? this.creadoEn,
      fotoComprobante: fotoComprobante ?? this.fotoComprobante,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      tipoNovedad: tipoNovedad ?? this.tipoNovedad,
      tuvoProblema: tuvoProblema ?? this.tuvoProblema,
      desglosePageos: desglosePageos ?? this.desglosePageos,
      totalDineroRecibido: totalDineroRecibido ?? this.totalDineroRecibido,
      montoPendiente: montoPendiente ?? this.montoPendiente,
      tipoConfirmacion: tipoConfirmacion ?? this.tipoConfirmacion,
      productosDevueltos: productosDevueltos ?? this.productosDevueltos,
      montoDevuelto: montoDevuelto ?? this.montoDevuelto,
      montoAceptado: montoAceptado ?? this.montoAceptado,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrega_id': entregaId,
      'venta_id': ventaId,
      'firma_digital_url': firmaDigitalUrl,
      'fotos': fotos,
      'observaciones_logistica': observacionesLogistica,
      'tienda_abierta': tiendaAbierta,
      'cliente_presente': clientePresente,
      'motivo_rechazo': motivoRechazo,
      'estado_pago': estadoPago,
      'monto_recibido': montoRecibido,
      'tipo_pago_id': tipoPagoId,
      'motivo_no_pago': motivoNoPago,
      'confirmado_por': confirmadoPor,
      'confirmado_en': confirmadoEn?.toIso8601String(),
      'created_at': creadoEn?.toIso8601String(),
      'foto_comprobante': fotoComprobante,
      'tipo_entrega': tipoEntrega,
      'tipo_novedad': tipoNovedad,
      'tuvo_problema': tuvoProblema,
      'desglose_pagos': desglosePageos.map((d) => d.toJson()).toList(),
      'total_dinero_recibido': totalDineroRecibido,
      'monto_pendiente': montoPendiente,
      'tipo_confirmacion': tipoConfirmacion,
      'productos_devueltos': productosDevueltos,
      'monto_devuelto': montoDevuelto,
      'monto_aceptado': montoAceptado,
      'updated_at': actualizadoEn?.toIso8601String(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'tipo_pago_id': tipoPagoId,
      'tipo_pago_nombre': tipoPagoNombre,
      'monto': monto,
      'referencia': referencia,
    };
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
