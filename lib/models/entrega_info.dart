
class EstadoEntregaInfo {
  final int id;
  final String codigo;
  final String nombre;
  final String? color;

  EstadoEntregaInfo({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.color,
  });

  factory EstadoEntregaInfo.fromJson(Map<String, dynamic> json) {
    return EstadoEntregaInfo(
      id: json['id'] as int? ?? 0,
      codigo: json['codigo'] as String? ?? 'DESCONOCIDO',
      nombre: json['nombre'] as String? ?? 'Desconocido',
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'color': color,
    };
  }
}

class ChoferInfo {
  final int id;
  final String nombre;
  final String? telefono;

  ChoferInfo({
    required this.id,
    required this.nombre,
    this.telefono,
  });

  factory ChoferInfo.fromJson(Map<String, dynamic> json) {
    return ChoferInfo(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? 'Desconocido',
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
    };
  }
}

class VehiculoInfo {
  final int id;
  final String placa;
  final String? descripcion;

  VehiculoInfo({
    required this.id,
    required this.placa,
    this.descripcion,
  });

  factory VehiculoInfo.fromJson(Map<String, dynamic> json) {
    return VehiculoInfo(
      id: json['id'] as int? ?? 0,
      placa: json['placa'] as String? ?? 'N/A',
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'descripcion': descripcion,
    };
  }
}

class EntregaInfo {
  final int id;
  final String? numero;
  final DateTime? fecha;
  final DateTime? fechaEntrega;
  final EstadoEntregaInfo? estadoEntrega;
  final ChoferInfo? chofer;
  final VehiculoInfo? vehiculo;

  EntregaInfo({
    required this.id,
    this.numero,
    this.fecha,
    this.fechaEntrega,
    this.estadoEntrega,
    this.chofer,
    this.vehiculo,
  });

  factory EntregaInfo.fromJson(Map<String, dynamic> json) {
    return EntregaInfo(
      id: json['id'] as int? ?? 0,
      numero: json['numero'] as String?,
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'] as String) : null,
      fechaEntrega: json['fecha_entrega'] != null ? DateTime.tryParse(json['fecha_entrega'] as String) : null,
      estadoEntrega: json['estado_entrega'] != null
          ? EstadoEntregaInfo.fromJson(json['estado_entrega'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null ? ChoferInfo.fromJson(json['chofer'] as Map<String, dynamic>) : null,
      vehiculo: json['vehiculo'] != null ? VehiculoInfo.fromJson(json['vehiculo'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'fecha': fecha?.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'estado_entrega': estadoEntrega?.toJson(),
      'chofer': chofer?.toJson(),
      'vehiculo': vehiculo?.toJson(),
    };
  }
}
