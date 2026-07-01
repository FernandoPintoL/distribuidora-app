/// Modelo para información de entrega asignada
class DetalleEntrega {
  final int id;
  final String numeroEntrega;
  final String estado;
  final int? choferId;
  final int? vehiculoId;
  final String? choferNombre;
  final String? vehiculoPlaca;
  final String? vehiculoMarca;
  final DateTime? fechaAsignacion;
  final DateTime? fechaEntrega;
  final String? observaciones;

  DetalleEntrega({
    required this.id,
    required this.numeroEntrega,
    required this.estado,
    this.choferId,
    this.vehiculoId,
    this.choferNombre,
    this.vehiculoPlaca,
    this.vehiculoMarca,
    this.fechaAsignacion,
    this.fechaEntrega,
    this.observaciones,
  });

  factory DetalleEntrega.fromJson(Map<String, dynamic> json) {
    return DetalleEntrega(
      id: json['id'] as int,
      numeroEntrega: json['numero_entrega'] as String? ?? 'N/A',
      estado: json['estado'] as String? ?? 'PENDIENTE',
      choferId: json['chofer_id'] as int?,
      vehiculoId: json['vehiculo_id'] as int?,
      choferNombre: (json['chofer'] as Map<String, dynamic>?)?['name'] as String?,
      vehiculoPlaca: (json['vehiculo'] as Map<String, dynamic>?)?['placa'] as String?,
      vehiculoMarca: (json['vehiculo'] as Map<String, dynamic>?)?['marca'] as String?,
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.parse(json['fecha_asignacion'] as String)
          : null,
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
    );
  }
}
