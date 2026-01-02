/// Event model para cambios de estado en tiempo real
///
/// Representa un evento que ocurre cuando un estado cambia en el backend

enum EstadoEventType {
  created,   // Nuevo estado creado
  updated,   // Estado actualizado
  deleted,   // Estado eliminado
  ordered,   // Orden de estados cambió
}

extension EstadoEventTypeExt on EstadoEventType {
  String get value {
    switch (this) {
      case EstadoEventType.created:
        return 'created';
      case EstadoEventType.updated:
        return 'updated';
      case EstadoEventType.deleted:
        return 'deleted';
      case EstadoEventType.ordered:
        return 'ordered';
    }
  }

  static EstadoEventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'created':
        return EstadoEventType.created;
      case 'updated':
        return EstadoEventType.updated;
      case 'deleted':
        return EstadoEventType.deleted;
      case 'ordered':
        return EstadoEventType.ordered;
      default:
        throw ArgumentError('Unknown EstadoEventType: $value');
    }
  }
}

/// Evento de cambio de estado
class EstadoEvent {
  final EstadoEventType type;
  final String categoria;
  final String codigo;
  final String nombre;
  final String? color;
  final String? icono;
  final String? descripcion;
  final int? orden;
  final bool? esEstadoFinal;
  final bool? activo;
  final DateTime timestamp;
  final String? userId; // Usuario que causó el cambio
  final String? ipAddress; // IP del cliente

  EstadoEvent({
    required this.type,
    required this.categoria,
    required this.codigo,
    required this.nombre,
    this.color,
    this.icono,
    this.descripcion,
    this.orden,
    this.esEstadoFinal,
    this.activo,
    required this.timestamp,
    this.userId,
    this.ipAddress,
  });

  /// Crea un EstadoEvent desde JSON (de WebSocket)
  factory EstadoEvent.fromJson(Map<String, dynamic> json) {
    return EstadoEvent(
      type: EstadoEventTypeExt.fromString(json['type'] as String? ?? 'updated'),
      categoria: json['categoria'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      color: json['color'] as String?,
      icono: json['icono'] as String?,
      descripcion: json['descripcion'] as String?,
      orden: json['orden'] as int?,
      esEstadoFinal: json['es_estado_final'] as bool?,
      activo: json['activo'] as bool?,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      userId: json['user_id'] as String?,
      ipAddress: json['ip_address'] as String?,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'categoria': categoria,
    'codigo': codigo,
    'nombre': nombre,
    'color': color,
    'icono': icono,
    'descripcion': descripcion,
    'orden': orden,
    'es_estado_final': esEstadoFinal,
    'activo': activo,
    'timestamp': timestamp.toIso8601String(),
    'user_id': userId,
    'ip_address': ipAddress,
  };

  /// Crea una copia con campos modificados
  EstadoEvent copyWith({
    EstadoEventType? type,
    String? categoria,
    String? codigo,
    String? nombre,
    String? color,
    String? icono,
    String? descripcion,
    int? orden,
    bool? esEstadoFinal,
    bool? activo,
    DateTime? timestamp,
    String? userId,
    String? ipAddress,
  }) {
    return EstadoEvent(
      type: type ?? this.type,
      categoria: categoria ?? this.categoria,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      esEstadoFinal: esEstadoFinal ?? this.esEstadoFinal,
      activo: activo ?? this.activo,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  @override
  String toString() =>
      'EstadoEvent($type: $categoria/$codigo=$nombre @${timestamp.toIso8601String()})';
}

/// Wrapper para eventos con estado de conexión
class EstadoConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final DateTime lastConnected;
  final DateTime? lastDisconnected;

  EstadoConnectionState({
    required this.isConnected,
    required this.isConnecting,
    this.error,
    required this.lastConnected,
    this.lastDisconnected,
  });

  factory EstadoConnectionState.disconnected(String error) {
    return EstadoConnectionState(
      isConnected: false,
      isConnecting: false,
      error: error,
      lastConnected: DateTime.now(),
      lastDisconnected: DateTime.now(),
    );
  }

  factory EstadoConnectionState.connecting() {
    return EstadoConnectionState(
      isConnected: false,
      isConnecting: true,
      lastConnected: DateTime.now(),
    );
  }

  factory EstadoConnectionState.connected() {
    return EstadoConnectionState(
      isConnected: true,
      isConnecting: false,
      lastConnected: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'EstadoConnectionState(connected: $isConnected, connecting: $isConnecting, error: $error)';
}
