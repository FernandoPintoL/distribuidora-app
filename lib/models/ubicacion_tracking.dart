class UbicacionTracking {
  final int id;
  final int entregaId;
  final int? choferId;
  final double latitud;
  final double longitud;
  final double? altitud;
  final double? precision; // Accuracy en metros
  final double? velocidad; // km/h
  final double? rumbo; // Bearing en grados (0-360)
  final DateTime timestamp;
  final String? evento; // "inicio_ruta", "llegada", "entrega", "en_ruta"

  UbicacionTracking({
    required this.id,
    required this.entregaId,
    this.choferId,
    required this.latitud,
    required this.longitud,
    this.altitud,
    this.precision,
    this.velocidad,
    this.rumbo,
    required this.timestamp,
    this.evento,
  });

  factory UbicacionTracking.fromJson(Map<String, dynamic> json) {
    return UbicacionTracking(
      id: json['id'] as int,
      entregaId: json['entrega_id'] as int,
      choferId: json['chofer_id'] as int?,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      altitud: json['altitud'] != null ? (json['altitud'] as num).toDouble() : null,
      precision: json['precision'] != null ? (json['precision'] as num).toDouble() : null,
      velocidad: json['velocidad'] != null ? (json['velocidad'] as num).toDouble() : null,
      rumbo: json['rumbo'] != null ? (json['rumbo'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      evento: json['evento'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrega_id': entregaId,
      'chofer_id': choferId,
      'latitud': latitud,
      'longitud': longitud,
      'altitud': altitud,
      'precision': precision,
      'velocidad': velocidad,
      'rumbo': rumbo,
      'timestamp': timestamp.toIso8601String(),
      'evento': evento,
    };
  }

  UbicacionTracking copyWith({
    int? id,
    int? entregaId,
    int? choferId,
    double? latitud,
    double? longitud,
    double? altitud,
    double? precision,
    double? velocidad,
    double? rumbo,
    DateTime? timestamp,
    String? evento,
  }) {
    return UbicacionTracking(
      id: id ?? this.id,
      entregaId: entregaId ?? this.entregaId,
      choferId: choferId ?? this.choferId,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      altitud: altitud ?? this.altitud,
      precision: precision ?? this.precision,
      velocidad: velocidad ?? this.velocidad,
      rumbo: rumbo ?? this.rumbo,
      timestamp: timestamp ?? this.timestamp,
      evento: evento ?? this.evento,
    );
  }

  // Helpers
  String get velocidadFormateada {
    if (velocidad == null) return 'N/A';
    return '${velocidad!.toStringAsFixed(1)} km/h';
  }

  String get precisionFormateada {
    if (precision == null) return 'N/A';
    return '±${precision!.toStringAsFixed(0)}m';
  }

  bool get esEventoImportante {
    if (evento == null) return false;
    return ['inicio_ruta', 'llegada', 'entrega'].contains(evento);
  }
}

class DistanciaEstimada {
  final double distanciaMetros;
  final int tiempoEstimadoMinutos;
  final String distanciaFormateada;
  final String tiempoFormateado;

  DistanciaEstimada({
    required this.distanciaMetros,
    required this.tiempoEstimadoMinutos,
    required this.distanciaFormateada,
    required this.tiempoFormateado,
  });

  factory DistanciaEstimada.fromJson(Map<String, dynamic> json) {
    return DistanciaEstimada(
      distanciaMetros: (json['distancia_metros'] as num).toDouble(),
      tiempoEstimadoMinutos: json['tiempo_estimado_minutos'] as int,
      distanciaFormateada: json['distancia_formateada'] as String,
      tiempoFormateado: json['tiempo_formateado'] as String,
    );
  }

  double get distanciaKm => distanciaMetros / 1000;

  bool get estaCerca => distanciaMetros < 500; // Menos de 500 metros
  bool get estaMuyCerca => distanciaMetros < 100; // Menos de 100 metros
}
