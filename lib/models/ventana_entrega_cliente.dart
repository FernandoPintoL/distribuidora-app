class VentanaEntregaCliente {
  final int? id;
  final int? clienteId;
  final int diaSemana; // 0..6
  final String horaInicio; // HH:mm
  final String horaFin; // HH:mm
  final bool activo;
  final String? createdAt;
  final String? updatedAt;

  VentanaEntregaCliente({
    this.id,
    this.clienteId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory VentanaEntregaCliente.fromJson(Map<String, dynamic> json) {
    return VentanaEntregaCliente(
      id: json['id'],
      clienteId: json['cliente_id'],
      diaSemana: json['dia_semana'] ?? json['diaSemana'] ?? 0,
      horaInicio: json['hora_inicio'] ?? json['horaInicio'] ?? '',
      horaFin: json['hora_fin'] ?? json['horaFin'] ?? '',
      activo: json['activo'] is bool
          ? json['activo']
          : (json['activo']?.toString() == '1' || json['activo']?.toString() == 'true'),
      createdAt: json['created_at'] ?? json['createdAt'],
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activo': activo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
