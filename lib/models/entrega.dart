import 'package:intl/intl.dart';

class Entrega {
  final int id;
  final int proformaId;
  final int? choferId;
  final int? vehiculoId;
  final int? direccionClienteId;
  final String estado; // ASIGNADA, EN_CAMINO, LLEGO, ENTREGADO, NOVEDAD, CANCELADA
  final DateTime? fechaAsignacion;
  final DateTime? fechaInicio;
  final DateTime? fechaEntrega;
  final String? observaciones;
  final String? motivoNovedad;
  final String? firmaDigitalUrl;
  final String? fotoEntregaUrl;

  Entrega({
    required this.id,
    required this.proformaId,
    this.choferId,
    this.vehiculoId,
    this.direccionClienteId,
    required this.estado,
    this.fechaAsignacion,
    this.fechaInicio,
    this.fechaEntrega,
    this.observaciones,
    this.motivoNovedad,
    this.firmaDigitalUrl,
    this.fotoEntregaUrl,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'] as int,
      proformaId: json['proforma_id'] as int,
      choferId: json['chofer_id'] as int?,
      vehiculoId: json['vehiculo_id'] as int?,
      direccionClienteId: json['direccion_cliente_id'] as int?,
      estado: json['estado'] as String,
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.parse(json['fecha_asignacion'] as String)
          : null,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
      motivoNovedad: json['motivo_novedad'] as String?,
      firmaDigitalUrl: json['firma_digital_url'] as String?,
      fotoEntregaUrl: json['foto_entrega_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proforma_id': proformaId,
      'chofer_id': choferId,
      'vehiculo_id': vehiculoId,
      'direccion_cliente_id': direccionClienteId,
      'estado': estado,
      'fecha_asignacion': fechaAsignacion?.toIso8601String(),
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'observaciones': observaciones,
      'motivo_novedad': motivoNovedad,
      'firma_digital_url': firmaDigitalUrl,
      'foto_entrega_url': fotoEntregaUrl,
    };
  }

  String get estadoLabel {
    const estadoLabels = {
      'ASIGNADA': 'Asignada',
      'EN_CAMINO': 'En Camino',
      'LLEGO': 'Llegó',
      'ENTREGADO': 'Entregado',
      'NOVEDAD': 'Novedad',
      'CANCELADA': 'Cancelada',
    };
    return estadoLabels[estado] ?? estado;
  }

  String get estadoColor {
    const colors = {
      'ASIGNADA': '#3b82f6', // blue
      'EN_CAMINO': '#f97316', // orange
      'LLEGO': '#eab308', // yellow
      'ENTREGADO': '#22c55e', // green
      'NOVEDAD': '#ef4444', // red
      'CANCELADA': '#6b7280', // gray
    };
    return colors[estado] ?? '#000000';
  }

  String get estadoIcon {
    const icons = {
      'ASIGNADA': '📋',
      'EN_CAMINO': '🚚',
      'LLEGO': '🏁',
      'ENTREGADO': '✅',
      'NOVEDAD': '⚠️',
      'CANCELADA': '❌',
    };
    return icons[estado] ?? '❓';
  }

  bool get puedeIniciarRuta => estado == 'ASIGNADA';
  bool get puedeMarcarLlegada => estado == 'EN_CAMINO';
  bool get puedeConfirmarEntrega => estado == 'LLEGO' || estado == 'EN_CAMINO';
  bool get puedeReportarNovedad => !['ENTREGADO', 'CANCELADA'].contains(estado);

  String formatFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  Entrega copyWith({
    int? id,
    int? proformaId,
    int? choferId,
    int? vehiculoId,
    int? direccionClienteId,
    String? estado,
    DateTime? fechaAsignacion,
    DateTime? fechaInicio,
    DateTime? fechaEntrega,
    String? observaciones,
    String? motivoNovedad,
    String? firmaDigitalUrl,
    String? fotoEntregaUrl,
  }) {
    return Entrega(
      id: id ?? this.id,
      proformaId: proformaId ?? this.proformaId,
      choferId: choferId ?? this.choferId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      direccionClienteId: direccionClienteId ?? this.direccionClienteId,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      observaciones: observaciones ?? this.observaciones,
      motivoNovedad: motivoNovedad ?? this.motivoNovedad,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      fotoEntregaUrl: fotoEntregaUrl ?? this.fotoEntregaUrl,
    );
  }

  @override
  String toString() =>
      'Entrega(id: $id, proformaId: $proformaId, estado: $estado, choferId: $choferId)';
}

class UbicacionTracking {
  final int id;
  final int entregaId;
  final int choferId;
  final double latitud;
  final double longitud;
  final double? velocidad;
  final double? rumbo;
  final double? altitud;
  final double? precision;
  final DateTime timestamp;
  final String? evento;

  UbicacionTracking({
    required this.id,
    required this.entregaId,
    required this.choferId,
    required this.latitud,
    required this.longitud,
    this.velocidad,
    this.rumbo,
    this.altitud,
    this.precision,
    required this.timestamp,
    this.evento,
  });

  factory UbicacionTracking.fromJson(Map<String, dynamic> json) {
    return UbicacionTracking(
      id: json['id'] as int,
      entregaId: json['entrega_id'] as int,
      choferId: json['chofer_id'] as int,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      velocidad: json['velocidad'] != null
          ? (json['velocidad'] as num).toDouble()
          : null,
      rumbo: json['rumbo'] != null ? (json['rumbo'] as num).toDouble() : null,
      altitud: json['altitud'] != null
          ? (json['altitud'] as num).toDouble()
          : null,
      precision: json['precision'] != null
          ? (json['precision'] as num).toDouble()
          : null,
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
      'velocidad': velocidad,
      'rumbo': rumbo,
      'altitud': altitud,
      'precision': precision,
      'timestamp': timestamp.toIso8601String(),
      'evento': evento,
    };
  }

  @override
  String toString() =>
      'UbicacionTracking(id: $id, entregaId: $entregaId, latitud: $latitud, longitud: $longitud)';
}

class EntregaEstadoHistorial {
  final int id;
  final int entregaId;
  final String estadoAnterior;
  final String estadoNuevo;
  final int? usuarioId;
  final String? comentario;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  EntregaEstadoHistorial({
    required this.id,
    required this.entregaId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.usuarioId,
    this.comentario,
    required this.createdAt,
    this.metadata,
  });

  factory EntregaEstadoHistorial.fromJson(Map<String, dynamic> json) {
    return EntregaEstadoHistorial(
      id: json['id'] as int,
      entregaId: json['entrega_id'] as int,
      estadoAnterior: json['estado_anterior'] as String,
      estadoNuevo: json['estado_nuevo'] as String,
      usuarioId: json['usuario_id'] as int?,
      comentario: json['comentario'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrega_id': entregaId,
      'estado_anterior': estadoAnterior,
      'estado_nuevo': estadoNuevo,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'EntregaEstadoHistorial(id: $id, entregaId: $entregaId, $estadoAnterior -> $estadoNuevo)';
}
