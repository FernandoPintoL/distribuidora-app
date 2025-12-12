class Ruta {
  final int id;
  final String codigo;
  final DateTime fechaRuta;
  final int localidadId;
  final String? localidadNombre;
  final int choferId;
  final String choferNombre;
  final int vehiculoId;
  final String vehiculoPlaca;
  final String estado; // planificada, en_progreso, completada
  final int cantidadParadas;
  final double? distanciaKm;
  final int? tiempoEstimadoMinutos;
  final DateTime? horaSalida;
  final DateTime? horaLlegada;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ruta({
    required this.id,
    required this.codigo,
    required this.fechaRuta,
    required this.localidadId,
    this.localidadNombre,
    required this.choferId,
    required this.choferNombre,
    required this.vehiculoId,
    required this.vehiculoPlaca,
    required this.estado,
    required this.cantidadParadas,
    this.distanciaKm,
    this.tiempoEstimadoMinutos,
    this.horaSalida,
    this.horaLlegada,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde JSON (WebSocket o API)
  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['ruta_id'] ?? json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      fechaRuta: json['fecha_ruta'] != null
          ? DateTime.parse(json['fecha_ruta'].toString())
          : DateTime.now(),
      localidadId: json['localidad_id'] ?? json['zona_id'] ?? 0,
      localidadNombre: json['localidad_nombre'],
      choferId: json['chofer_id'] ?? 0,
      choferNombre: json['chofer_nombre'] ?? json['chofer'] ?? 'N/A',
      vehiculoId: json['vehiculo_id'] ?? 0,
      vehiculoPlaca: json['vehiculo_placa'] ?? json['vehiculo'] ?? 'N/A',
      estado: json['estado'] ?? 'planificada',
      cantidadParadas: json['cantidad_paradas'] ?? json['paradas'] ?? 0,
      distanciaKm: json['distancia_km'] != null
          ? double.tryParse(json['distancia_km'].toString())
          : null,
      tiempoEstimadoMinutos: json['tiempo_estimado_minutos'] ?? json['tiempo_estimado'],
      horaSalida: json['hora_salida'] != null
          ? DateTime.parse(json['hora_salida'].toString())
          : null,
      horaLlegada: json['hora_llegada'] != null
          ? DateTime.parse(json['hora_llegada'].toString())
          : null,
      observaciones: json['observaciones'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ruta_id': id,
      'codigo': codigo,
      'fecha_ruta': fechaRuta.toIso8601String(),
      'localidad_id': localidadId,
      'localidad_nombre': localidadNombre,
      'chofer_id': choferId,
      'chofer_nombre': choferNombre,
      'vehiculo_id': vehiculoId,
      'vehiculo_placa': vehiculoPlaca,
      'estado': estado,
      'cantidad_paradas': cantidadParadas,
      'distancia_km': distanciaKm,
      'tiempo_estimado_minutos': tiempoEstimadoMinutos,
      'hora_salida': horaSalida?.toIso8601String(),
      'hora_llegada': horaLlegada?.toIso8601String(),
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copiar con cambios
  Ruta copyWith({
    int? id,
    String? codigo,
    DateTime? fechaRuta,
    int? localidadId,
    String? localidadNombre,
    int? choferId,
    String? choferNombre,
    int? vehiculoId,
    String? vehiculoPlaca,
    String? estado,
    int? cantidadParadas,
    double? distanciaKm,
    int? tiempoEstimadoMinutos,
    DateTime? horaSalida,
    DateTime? horaLlegada,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ruta(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      fechaRuta: fechaRuta ?? this.fechaRuta,
      localidadId: localidadId ?? this.localidadId,
      localidadNombre: localidadNombre ?? this.localidadNombre,
      choferId: choferId ?? this.choferId,
      choferNombre: choferNombre ?? this.choferNombre,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      vehiculoPlaca: vehiculoPlaca ?? this.vehiculoPlaca,
      estado: estado ?? this.estado,
      cantidadParadas: cantidadParadas ?? this.cantidadParadas,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      tiempoEstimadoMinutos: tiempoEstimadoMinutos ?? this.tiempoEstimadoMinutos,
      horaSalida: horaSalida ?? this.horaSalida,
      horaLlegada: horaLlegada ?? this.horaLlegada,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters útiles
  bool get estaPlanificada => estado == 'planificada';
  bool get estaEnProgreso => estado == 'en_progreso';
  bool get estaCompletada => estado == 'completada';

  bool get yaInicio => horaSalida != null;
  bool get yaTermino => horaLlegada != null;

  String get estadoTexto {
    switch (estado) {
      case 'planificada':
        return 'Planificada';
      case 'en_progreso':
        return 'En Progreso';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }

  @override
  String toString() => 'Ruta($codigo - $choferNombre)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ruta &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          codigo == other.codigo;

  @override
  int get hashCode => id.hashCode ^ codigo.hashCode;
}
