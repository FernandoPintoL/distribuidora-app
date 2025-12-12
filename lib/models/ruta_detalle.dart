class RutaDetalle {
  final int id;
  final int rutaId;
  final int clienteId;
  final String clienteNombre;
  final int secuencia;
  final String direccionEntrega;
  final double? latitud;
  final double? longitud;
  final String estado; // pendiente, en_entrega, entregado, no_entregado, reprogramado
  final DateTime? horaEntregaEstimada;
  final DateTime? horaEntregaReal;
  final String? razonNoEntrega;
  final int intentosEntrega;
  final bool fueOnTime;
  final int minutosDiferencia;
  final DateTime createdAt;
  final DateTime updatedAt;

  RutaDetalle({
    required this.id,
    required this.rutaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.secuencia,
    required this.direccionEntrega,
    this.latitud,
    this.longitud,
    required this.estado,
    this.horaEntregaEstimada,
    this.horaEntregaReal,
    this.razonNoEntrega,
    required this.intentosEntrega,
    this.fueOnTime = false,
    this.minutosDiferencia = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde JSON (WebSocket o API)
  factory RutaDetalle.fromJson(Map<String, dynamic> json) {
    return RutaDetalle(
      id: json['detalle_id'] ?? json['id'] ?? 0,
      rutaId: json['ruta_id'] ?? 0,
      clienteId: json['cliente_id'] ?? 0,
      clienteNombre: json['cliente_nombre'] ?? 'N/A',
      secuencia: json['secuencia'] ?? 0,
      direccionEntrega: json['direccion_entrega'] ?? json['direccion'] ?? '',
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
      estado: json['estado_actual'] ?? json['estado'] ?? 'pendiente',
      horaEntregaEstimada: json['hora_entrega_estimada'] != null
          ? DateTime.parse(json['hora_entrega_estimada'].toString())
          : null,
      horaEntregaReal: json['hora_entrega_real'] != null
          ? DateTime.parse(json['hora_entrega_real'].toString())
          : null,
      razonNoEntrega: json['razon_no_entrega'],
      intentosEntrega: json['intentos_entrega'] ?? 0,
      fueOnTime: json['fue_on_time'] ?? false,
      minutosDiferencia: json['minutos_diferencia'] ?? 0,
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
      'detalle_id': id,
      'ruta_id': rutaId,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'secuencia': secuencia,
      'direccion_entrega': direccionEntrega,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'estado_actual': estado,
      'hora_entrega_estimada': horaEntregaEstimada?.toIso8601String(),
      'hora_entrega_real': horaEntregaReal?.toIso8601String(),
      'razon_no_entrega': razonNoEntrega,
      'intentos_entrega': intentosEntrega,
      'fue_on_time': fueOnTime,
      'minutos_diferencia': minutosDiferencia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copiar con cambios
  RutaDetalle copyWith({
    int? id,
    int? rutaId,
    int? clienteId,
    String? clienteNombre,
    int? secuencia,
    String? direccionEntrega,
    double? latitud,
    double? longitud,
    String? estado,
    DateTime? horaEntregaEstimada,
    DateTime? horaEntregaReal,
    String? razonNoEntrega,
    int? intentosEntrega,
    bool? fueOnTime,
    int? minutosDiferencia,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RutaDetalle(
      id: id ?? this.id,
      rutaId: rutaId ?? this.rutaId,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      secuencia: secuencia ?? this.secuencia,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      horaEntregaEstimada: horaEntregaEstimada ?? this.horaEntregaEstimada,
      horaEntregaReal: horaEntregaReal ?? this.horaEntregaReal,
      razonNoEntrega: razonNoEntrega ?? this.razonNoEntrega,
      intentosEntrega: intentosEntrega ?? this.intentosEntrega,
      fueOnTime: fueOnTime ?? this.fueOnTime,
      minutosDiferencia: minutosDiferencia ?? this.minutosDiferencia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Getters útiles
  bool get estaPendiente => estado == 'pendiente';
  bool get estaEnEntrega => estado == 'en_entrega';
  bool get estaEntregado => estado == 'entregado';
  bool get noEstaEntregado => estado == 'no_entregado';
  bool get estaReprogramado => estado == 'reprogramado';

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_entrega':
        return 'En Entrega';
      case 'entregado':
        return 'Entregado';
      case 'no_entregado':
        return 'No Entregado';
      case 'reprogramado':
        return 'Reprogramado';
      default:
        return estado;
    }
  }

  String get estadoIcon {
    switch (estado) {
      case 'pendiente':
        return '⏳';
      case 'en_entrega':
        return '🚗';
      case 'entregado':
        return '✅';
      case 'no_entregado':
        return '❌';
      case 'reprogramado':
        return '🔄';
      default:
        return '❓';
    }
  }

  @override
  String toString() => 'RutaDetalle(#$secuencia - $clienteNombre)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RutaDetalle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rutaId == other.rutaId;

  @override
  int get hashCode => id.hashCode ^ rutaId.hashCode;
}
