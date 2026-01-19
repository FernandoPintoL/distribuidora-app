class Caja {
  final int id;
  final int userId;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final double montoApertura;
  final double? montosCierre;
  final double diferencia;
  final String estado; // ABIERTA, CERRADA, SUSPENDIDA
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Caja({
    required this.id,
    required this.userId,
    required this.fechaApertura,
    this.fechaCierre,
    required this.montoApertura,
    this.montosCierre,
    required this.diferencia,
    required this.estado,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Caja.fromJson(Map<String, dynamic> json) {
    return Caja(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
      montoApertura: (json['monto_apertura'] as num).toDouble(),
      montosCierre: json['montos_cierre'] != null
          ? (json['montos_cierre'] as num).toDouble()
          : null,
      diferencia: (json['diferencia'] as num).toDouble(),
      estado: json['estado'] as String,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fecha_apertura': fechaApertura.toIso8601String(),
      'fecha_cierre': fechaCierre?.toIso8601String(),
      'monto_apertura': montoApertura,
      'montos_cierre': montosCierre,
      'diferencia': diferencia,
      'estado': estado,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get estaAbierta => estado == 'ABIERTA';
  bool get estaCerrada => estado == 'CERRADA';

  String get tiempoTranscurrido {
    final ahora = DateTime.now();
    final duracion = ahora.difference(fechaApertura);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    return '${horas}h ${minutos}m';
  }
}
