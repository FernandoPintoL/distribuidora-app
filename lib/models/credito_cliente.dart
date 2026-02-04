import 'package:flutter/foundation.dart';

class DetallesCreditoCliente {
  final double limiteCredito;
  final double saldoUtilizado;
  final double saldoDisponible;
  final double porcentajeUtilizacion;
  final List<CuentaPorCobrar> cuentasPendientes;
  final List<CuentaPorCobrar> cuentasVencidas;
  final List<Pago> historialPagos;

  DetallesCreditoCliente({
    required this.limiteCredito,
    required this.saldoUtilizado,
    required this.saldoDisponible,
    required this.porcentajeUtilizacion,
    required this.cuentasPendientes,
    required this.cuentasVencidas,
    required this.historialPagos,
  });

  factory DetallesCreditoCliente.fromJson(Map<String, dynamic> json) {
    try {
      // Extraer datos de crédito (puede estar anidado o plano)
      final creditoData = json['credito'] ?? json;

      // ✅ Parsear todas_las_cuentas de forma SUPER segura
      List<CuentaPorCobrar> cuentasPend = [];
      List<CuentaPorCobrar> cuentasVenc = [];

      if (json['todas_las_cuentas'] is List) {
        final List<dynamic> rawList = json['todas_las_cuentas'] as List;
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            final cuenta = CuentaPorCobrar.fromJson(item);
            // Solo agregar si tiene saldo pendiente
            if ((cuenta.saldoPendiente) > 0) {
              cuentasPend.add(cuenta);
              // Si está vencida, agregar también a vencidas
              if ((cuenta.diasVencido ?? 0) > 0) {
                cuentasVenc.add(cuenta);
              }
            }
          }
        }
      }

      return DetallesCreditoCliente(
        limiteCredito: creditoData['limite_credito'] != null
            ? double.tryParse(creditoData['limite_credito'].toString()) ?? 0.0
            : 0.0,
        saldoUtilizado: creditoData['saldo_utilizado'] != null
            ? double.tryParse(creditoData['saldo_utilizado'].toString()) ?? 0.0
            : 0.0,
        saldoDisponible: creditoData['saldo_disponible'] != null
            ? double.tryParse(creditoData['saldo_disponible'].toString()) ?? 0.0
            : 0.0,
        porcentajeUtilizacion: creditoData['porcentaje_utilizacion'] != null
            ? double.tryParse(creditoData['porcentaje_utilizacion'].toString()) ?? 0.0
            : 0.0,
        cuentasPendientes: cuentasPend,
        cuentasVencidas: cuentasVenc,
        historialPagos: json['historial_pagos'] is List
            ? (json['historial_pagos'] as List)
                .whereType<Map<String, dynamic>>()
                .map((p) => Pago.fromJson(p))
                .toList()
            : [],
      );
    } catch (e) {
      debugPrint('❌ Error parsing DetallesCreditoCliente: $e');
      debugPrint('   JSON keys: ${json.keys}');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }
}

class CuentaPorCobrar {
  final int id;
  final int? ventaId;
  final double montoOriginal;
  final double saldoPendiente;
  final String? fechaVencimiento;
  final int? diasVencido;
  final String? estado;
  final VentaInfo? venta;
  final List<Pago>? pagos;

  CuentaPorCobrar({
    required this.id,
    this.ventaId,
    required this.montoOriginal,
    required this.saldoPendiente,
    this.fechaVencimiento,
    this.diasVencido,
    this.estado,
    this.venta,
    this.pagos,
  });

  factory CuentaPorCobrar.fromJson(Map<String, dynamic> json) {
    try {
      // Crear objeto VentaInfo a partir de los datos planos del backend
      final venta = VentaInfo(
        id: json['venta_id'] is int
            ? json['venta_id']
            : int.tryParse(json['venta_id'].toString()) ?? 0,
        numero: json['numero_venta'] as String?, // El backend retorna numero_venta como string
        fecha: json['fecha_venta'] as String?,
        total: json['monto_original'] != null
            ? double.tryParse(json['monto_original'].toString())
            : null,
        estadoPago: json['estado'] as String?,
      );

      return CuentaPorCobrar(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        ventaId: json['venta_id'] != null
            ? (json['venta_id'] is int
                ? json['venta_id']
                : int.tryParse(json['venta_id'].toString()))
            : null,
        montoOriginal: json['monto_original'] != null
            ? double.tryParse(json['monto_original'].toString()) ?? 0.0
            : 0.0,
        saldoPendiente: json['saldo_pendiente'] != null
            ? double.tryParse(json['saldo_pendiente'].toString()) ?? 0.0
            : 0.0,
        fechaVencimiento: json['fecha_vencimiento'],
        diasVencido: json['dias_vencido'] is int
            ? json['dias_vencido']
            : (json['dias_vencido'] != null
                ? int.tryParse(json['dias_vencido'].toString())
                : null),
        estado: json['estado'],
        venta: venta,
        pagos: json['pagos'] != null
            ? (json['pagos'] as List)
                .whereType<Map<String, dynamic>>()
                .map((p) => Pago.fromJson(p))
                .toList()
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing CuentaPorCobrar: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }
}

class VentaInfo {
  final int id;
  final String? numero;
  final String? fecha;
  final double? total;
  final String? estadoPago;

  VentaInfo({
    required this.id,
    this.numero,
    this.fecha,
    this.total,
    this.estadoPago,
  });

  factory VentaInfo.fromJson(Map<String, dynamic> json) {
    return VentaInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      numero: json['numero'],
      fecha: json['fecha'],
      total: json['total'] != null
          ? double.tryParse(json['total'].toString())
          : null,
      estadoPago: json['estado_pago'],
    );
  }
}

class Pago {
  final int id;
  final int? ventaId;
  final int? tipoPagoId;
  final double monto;
  final String? fechaPago;
  final String? numeroRecibo;
  final int? usuarioId;
  final String? observaciones;
  final TipoPago? tipoPago;
  final Usuario? usuario;

  Pago({
    required this.id,
    this.ventaId,
    this.tipoPagoId,
    required this.monto,
    this.fechaPago,
    this.numeroRecibo,
    this.usuarioId,
    this.observaciones,
    this.tipoPago,
    this.usuario,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    try {
      return Pago(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        ventaId: json['venta_id'] != null
            ? (json['venta_id'] is int
                ? json['venta_id']
                : int.tryParse(json['venta_id'].toString()))
            : null,
        tipoPagoId: json['tipo_pago_id'] != null
            ? (json['tipo_pago_id'] is int
                ? json['tipo_pago_id']
                : int.tryParse(json['tipo_pago_id'].toString()))
            : null,
        monto: json['monto'] != null
            ? double.tryParse(json['monto'].toString()) ?? 0.0
            : 0.0,
        fechaPago: json['fecha_pago'],
        numeroRecibo: json['numero_recibo'],
        usuarioId: json['usuario_id'] != null
            ? (json['usuario_id'] is int
                ? json['usuario_id']
                : int.tryParse(json['usuario_id'].toString()))
            : null,
        observaciones: json['observaciones'],
        tipoPago: json['tipo_pago'] != null && json['tipo_pago'] is Map<String, dynamic>
            ? TipoPago.fromJson(json['tipo_pago'] as Map<String, dynamic>)
            : null,
        usuario: json['usuario'] != null && json['usuario'] is Map<String, dynamic>
            ? Usuario.fromJson(json['usuario'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Pago: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }
}

class TipoPago {
  final int id;
  final String nombre;
  final String? codigo; // ✅ NUEVO: código del tipo de pago

  TipoPago({required this.id, required this.nombre, this.codigo});

  factory TipoPago.fromJson(Map<String, dynamic> json) {
    try {
      return TipoPago(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        nombre: json['nombre'] ?? '',
        codigo: json['codigo'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Error parsing TipoPago: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}

class Usuario {
  final int id;
  final String? name;
  final String? email;

  Usuario({required this.id, this.name, this.email});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'],
        email: json['email'],
      );
    } catch (e) {
      debugPrint('❌ Error parsing Usuario: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }
}
