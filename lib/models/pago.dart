class Pago {
  final int id;
  final int? cuentaPorCobrarId;
  final double monto;
  final DateTime? fechaPago;
  final String? numeroRecibo;
  final String? numeroTransferencia;
  final String? numeroCheque;
  final String? observaciones;
  final String estado; // REGISTRADO, ANULADO
  final int? tipoPagoId;
  final String? tipoPagoNombre;
  final int? usuarioId;
  final String? usuarioNombre;

  Pago({
    required this.id,
    this.cuentaPorCobrarId,
    required this.monto,
    this.fechaPago,
    this.numeroRecibo,
    this.numeroTransferencia,
    this.numeroCheque,
    this.observaciones,
    required this.estado,
    this.tipoPagoId,
    this.tipoPagoNombre,
    this.usuarioId,
    this.usuarioNombre,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as int,
      cuentaPorCobrarId: json['cuenta_por_cobrar_id'] as int?,
      monto: _parseDouble(json['monto']),
      fechaPago: json['fecha_pago'] != null
          ? DateTime.tryParse(json['fecha_pago'] as String)
          : null,
      numeroRecibo: json['numero_recibo'] as String?,
      numeroTransferencia: json['numero_transferencia'] as String?,
      numeroCheque: json['numero_cheque'] as String?,
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] as String? ?? 'REGISTRADO',
      tipoPagoId: json['tipo_pago_id'] as int?,
      tipoPagoNombre: json['tipo_pago_nombre'] as String?,
      usuarioId: json['usuario_id'] as int?,
      usuarioNombre: json['usuario_nombre'] as String?,
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
      'cuenta_por_cobrar_id': cuentaPorCobrarId,
      'monto': monto,
      'fecha_pago': fechaPago?.toIso8601String(),
      'numero_recibo': numeroRecibo,
      'numero_transferencia': numeroTransferencia,
      'numero_cheque': numeroCheque,
      'observaciones': observaciones,
      'estado': estado,
      'tipo_pago_id': tipoPagoId,
      'tipo_pago_nombre': tipoPagoNombre,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
    };
  }

  @override
  String toString() => 'Pago(id: $id, monto: $monto, fecha: $fechaPago)';
}
