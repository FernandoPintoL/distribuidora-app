/// Modelo para Créditos de Clientes
/// Representa el crédito total aprobado y disponible para un cliente
class Credito {
  final int id;
  final int clienteId;
  final double limiteCreditoAprobado;
  final double saldoDisponible;
  final double saldoUtilizado;
  final double porcentajeUtilizado;
  final int cuentasVencidasCount;
  final int cuentasPendientesCount;
  final DateTime fechaAprobacion;
  final DateTime? fechaUltimaActualizacion;

  Credito({
    required this.id,
    required this.clienteId,
    required this.limiteCreditoAprobado,
    required this.saldoDisponible,
    required this.saldoUtilizado,
    required this.porcentajeUtilizado,
    required this.cuentasVencidasCount,
    required this.cuentasPendientesCount,
    required this.fechaAprobacion,
    this.fechaUltimaActualizacion,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      id: json['id'] as int,
      clienteId: json['cliente_id'] as int,
      limiteCreditoAprobado: (json['limite_credito_aprobado'] as num).toDouble(),
      saldoDisponible: (json['saldo_disponible'] as num).toDouble(),
      saldoUtilizado: (json['saldo_utilizado'] as num).toDouble(),
      porcentajeUtilizado: (json['porcentaje_utilizado'] as num).toDouble(),
      cuentasVencidasCount: json['cuentas_vencidas_count'] as int? ?? 0,
      cuentasPendientesCount: json['cuentas_pendientes_count'] as int? ?? 0,
      fechaAprobacion: DateTime.parse(json['fecha_aprobacion'] as String),
      fechaUltimaActualizacion: json['fecha_ultima_actualizacion'] != null
          ? DateTime.parse(json['fecha_ultima_actualizacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'limite_credito_aprobado': limiteCreditoAprobado,
      'saldo_disponible': saldoDisponible,
      'saldo_utilizado': saldoUtilizado,
      'porcentaje_utilizado': porcentajeUtilizado,
      'cuentas_vencidas_count': cuentasVencidasCount,
      'cuentas_pendientes_count': cuentasPendientesCount,
      'fecha_aprobacion': fechaAprobacion.toIso8601String(),
      'fecha_ultima_actualizacion': fechaUltimaActualizacion?.toIso8601String(),
    };
  }

  /// Determinar estado del crédito
  String get estado {
    if (porcentajeUtilizado >= 100) return 'excedido';
    if (porcentajeUtilizado >= 80) return 'critico';
    if (porcentajeUtilizado > 0) return 'en_uso';
    return 'disponible';
  }

  /// Obtener color según estado
  int get colorEstado {
    switch (estado) {
      case 'excedido':
        return 0xFFD32F2F; // Rojo
      case 'critico':
        return 0xFFF57C00; // Naranja
      case 'en_uso':
        return 0xFF1976D2; // Azul
      default:
        return 0xFF388E3C; // Verde
    }
  }

  /// Copiar con modificaciones
  Credito copyWith({
    int? id,
    int? clienteId,
    double? limiteCreditoAprobado,
    double? saldoDisponible,
    double? saldoUtilizado,
    double? porcentajeUtilizado,
    int? cuentasVencidasCount,
    int? cuentasPendientesCount,
    DateTime? fechaAprobacion,
    DateTime? fechaUltimaActualizacion,
  }) {
    return Credito(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      limiteCreditoAprobado: limiteCreditoAprobado ?? this.limiteCreditoAprobado,
      saldoDisponible: saldoDisponible ?? this.saldoDisponible,
      saldoUtilizado: saldoUtilizado ?? this.saldoUtilizado,
      porcentajeUtilizado: porcentajeUtilizado ?? this.porcentajeUtilizado,
      cuentasVencidasCount: cuentasVencidasCount ?? this.cuentasVencidasCount,
      cuentasPendientesCount: cuentasPendientesCount ?? this.cuentasPendientesCount,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      fechaUltimaActualizacion: fechaUltimaActualizacion ?? this.fechaUltimaActualizacion,
    );
  }
}

/// Modelo para Cuentas por Cobrar (Créditos en detalle)
/// Representa una deuda específica de un cliente por una venta
class CuentaPorCobrar {
  final int id;
  final int clienteId;
  final int ventaId;
  final double montoOriginal;
  final double saldoPendiente;
  final int diasVencido;
  final DateTime fechaVencimiento;
  final String estado;
  final String? clienteNombre;
  final String? ventaNumero;
  final List<Pago>? pagos;

  CuentaPorCobrar({
    required this.id,
    required this.clienteId,
    required this.ventaId,
    required this.montoOriginal,
    required this.saldoPendiente,
    required this.diasVencido,
    required this.fechaVencimiento,
    required this.estado,
    this.clienteNombre,
    this.ventaNumero,
    this.pagos,
  });

  factory CuentaPorCobrar.fromJson(Map<String, dynamic> json) {
    return CuentaPorCobrar(
      id: json['id'] as int,
      clienteId: json['cliente_id'] as int,
      ventaId: json['venta_id'] as int,
      montoOriginal: (json['monto_original'] as num).toDouble(),
      saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
      diasVencido: json['dias_vencido'] as int? ?? 0,
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] as String),
      estado: json['estado'] as String,
      clienteNombre: json['cliente_nombre'] as String?,
      ventaNumero: json['venta_numero'] as String?,
      pagos: json['pagos'] != null
          ? (json['pagos'] as List).map((p) => Pago.fromJson(p as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'venta_id': ventaId,
      'monto_original': montoOriginal,
      'saldo_pendiente': saldoPendiente,
      'dias_vencido': diasVencido,
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'estado': estado,
      'cliente_nombre': clienteNombre,
      'venta_numero': ventaNumero,
      'pagos': pagos?.map((p) => p.toJson()).toList(),
    };
  }

  /// Determinar si está vencida
  bool get estaVencida => diasVencido > 0;

  /// Obtener porcentaje pagado
  double get porcentajePagado {
    if (montoOriginal == 0) return 0;
    return ((montoOriginal - saldoPendiente) / montoOriginal * 100);
  }

  /// Copiar con modificaciones
  CuentaPorCobrar copyWith({
    int? id,
    int? clienteId,
    int? ventaId,
    double? montoOriginal,
    double? saldoPendiente,
    int? diasVencido,
    DateTime? fechaVencimiento,
    String? estado,
    String? clienteNombre,
    String? ventaNumero,
    List<Pago>? pagos,
  }) {
    return CuentaPorCobrar(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      ventaId: ventaId ?? this.ventaId,
      montoOriginal: montoOriginal ?? this.montoOriginal,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      diasVencido: diasVencido ?? this.diasVencido,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      ventaNumero: ventaNumero ?? this.ventaNumero,
      pagos: pagos ?? this.pagos,
    );
  }
}

/// Modelo para Pagos de Créditos
class Pago {
  final int id;
  final int cuentaPorCobrarId;
  final double monto;
  final String tipoPago;
  final String? numeroRecibo;
  final DateTime fechaPago;
  final String? observaciones;
  final int? usuarioId;
  final String? usuarioNombre;

  Pago({
    required this.id,
    required this.cuentaPorCobrarId,
    required this.monto,
    required this.tipoPago,
    this.numeroRecibo,
    required this.fechaPago,
    this.observaciones,
    this.usuarioId,
    this.usuarioNombre,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as int,
      cuentaPorCobrarId: json['cuenta_por_cobrar_id'] as int,
      monto: (json['monto'] as num).toDouble(),
      tipoPago: json['tipo_pago'] as String,
      numeroRecibo: json['numero_recibo'] as String?,
      fechaPago: DateTime.parse(json['fecha_pago'] as String),
      observaciones: json['observaciones'] as String?,
      usuarioId: json['usuario_id'] as int?,
      usuarioNombre: json['usuario_nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cuenta_por_cobrar_id': cuentaPorCobrarId,
      'monto': monto,
      'tipo_pago': tipoPago,
      'numero_recibo': numeroRecibo,
      'fecha_pago': fechaPago.toIso8601String(),
      'observaciones': observaciones,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
    };
  }
}
