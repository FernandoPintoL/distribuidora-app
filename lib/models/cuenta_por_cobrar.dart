import 'package:flutter/foundation.dart';
import 'cliente.dart';

class CuentaPorCobrar {
  final int id;
  final int? ventaId;
  final int clienteId;
  final double montoOriginal;
  final double montoPagado;
  final double saldoPendiente;
  final DateTime? fechaVencimiento;
  final int? diasVencido;
  final String estado; // PENDIENTE, PARCIAL, PAGADO
  final String? referenciaDocumento;
  final String? observaciones;
  final Cliente? cliente;
  final CuentaVenta? venta;
  final int pagosCount;

  CuentaPorCobrar({
    required this.id,
    this.ventaId,
    required this.clienteId,
    required this.montoOriginal,
    required this.montoPagado,
    required this.saldoPendiente,
    this.fechaVencimiento,
    this.diasVencido,
    required this.estado,
    this.referenciaDocumento,
    this.observaciones,
    this.cliente,
    this.venta,
    this.pagosCount = 0,
  });

  factory CuentaPorCobrar.fromJson(Map<String, dynamic> json) {
    // Parsear cliente
    Cliente? clienteObj;
    if (json['cliente'] is Map<String, dynamic>) {
      clienteObj = Cliente.fromJson(json['cliente'] as Map<String, dynamic>);
    }

    // Parsear venta relacionada
    CuentaVenta? ventaObj;
    if (json['venta'] is Map<String, dynamic>) {
      ventaObj = CuentaVenta.fromJson(json['venta'] as Map<String, dynamic>);
    }

    return CuentaPorCobrar(
      id: json['id'] as int,
      ventaId: json['venta_id'] as int?,
      clienteId: json['cliente_id'] as int,
      montoOriginal: _parseDouble(json['monto_original']),
      montoPagado: _parseDouble(json['monto_pagado']),
      saldoPendiente: _parseDouble(json['saldo_pendiente']),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'] as String)
          : null,
      diasVencido: json['dias_vencido'] as int?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      referenciaDocumento: json['referencia_documento'] as String?,
      observaciones: json['observaciones'] as String?,
      cliente: clienteObj,
      venta: ventaObj,
      pagosCount: json['pagos_count'] as int? ?? 0,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venta_id': ventaId,
      'cliente_id': clienteId,
      'monto_original': montoOriginal,
      'monto_pagado': montoPagado,
      'saldo_pendiente': saldoPendiente,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'dias_vencido': diasVencido,
      'estado': estado,
      'referencia_documento': referenciaDocumento,
      'observaciones': observaciones,
      'cliente': cliente?.toJson(),
      'venta': venta?.toJson(),
      'pagos_count': pagosCount,
    };
  }

  // ✅ Getter para determinar si está vencida
  bool get estaVencida {
    if (fechaVencimiento == null) return false;
    return fechaVencimiento!.isBefore(DateTime.now()) && estado != 'PAGADO';
  }

  // ✅ Getter para porcentaje pagado
  double get porcentajePagado {
    if (montoOriginal == 0) return 0;
    return (montoPagado / montoOriginal) * 100;
  }

  @override
  String toString() => 'CuentaPorCobrar(id: $id, cliente: ${cliente?.nombre}, saldo: $saldoPendiente)';
}

/// Información simplificada de venta relacionada
class CuentaVenta {
  final int id;
  final String? numero;
  final DateTime? fecha;

  CuentaVenta({
    required this.id,
    this.numero,
    this.fecha,
  });

  factory CuentaVenta.fromJson(Map<String, dynamic> json) {
    return CuentaVenta(
      id: json['id'] as int,
      numero: json['numero'] as String?,
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'fecha': fecha?.toIso8601String(),
    };
  }
}
