import 'package:flutter/material.dart';

class MovimientoCaja {
  final int id;
  final int cajaId;
  final int tipoOperacionId;
  final String numeroDocumento;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final int userId;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones opcionales
  final String? tipoOperacionCodigo;
  final String? tipoOperacionNombre;
  final String? usuarioNombre;

  MovimientoCaja({
    required this.id,
    required this.cajaId,
    required this.tipoOperacionId,
    required this.numeroDocumento,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.userId,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
    this.tipoOperacionCodigo,
    this.tipoOperacionNombre,
    this.usuarioNombre,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    // Parsear tipo de operación
    String? tipoOpCodigo;
    String? tipoOpNombre;

    if (json['tipo_operacion'] is Map<String, dynamic>) {
      final tipoOp = json['tipo_operacion'] as Map<String, dynamic>;
      tipoOpCodigo = tipoOp['codigo'] as String?;
      tipoOpNombre = tipoOp['nombre'] as String?;
    }

    // Parsear usuario
    String? usuarioNom;
    if (json['usuario'] is Map<String, dynamic>) {
      final usuario = json['usuario'] as Map<String, dynamic>;
      usuarioNom = usuario['name'] as String? ?? usuario['nombre'] as String?;
    }

    return MovimientoCaja(
      id: json['id'] as int,
      cajaId: json['caja_id'] as int,
      tipoOperacionId: json['tipo_operacion_id'] as int,
      numeroDocumento: json['numero_documento'] as String? ?? '',
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      userId: json['user_id'] as int,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tipoOperacionCodigo: tipoOpCodigo,
      tipoOperacionNombre: tipoOpNombre,
      usuarioNombre: usuarioNom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caja_id': cajaId,
      'tipo_operacion_id': tipoOperacionId,
      'numero_documento': numeroDocumento,
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'user_id': userId,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get esIngreso => monto > 0;
  bool get esEgreso => monto < 0;

  String get montoFormato {
    final signo = esIngreso ? '+' : '';
    return '$signo${monto.toStringAsFixed(2)}';
  }

  String get tipoLabel => tipoOperacionNombre ?? tipoOperacionCodigo ?? 'Movimiento';

  IconData get tipoIcono {
    switch (tipoOperacionCodigo) {
      case 'APERTURA':
        return Icons.lock_open;
      case 'CIERRE':
        return Icons.lock;
      case 'VENTA':
        return Icons.shopping_cart;
      case 'COMPRA':
        return Icons.inventory;
      case 'GASTO':
        return Icons.money_off;
      case 'INGRESO_EXTRA':
        return Icons.add_circle;
      default:
        return Icons.attach_money;
    }
  }

  Color get tipoColor {
    if (esIngreso) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }
}
