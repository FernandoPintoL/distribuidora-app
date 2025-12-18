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

  // Campos adicionales del nuevo endpoint /api/chofer/trabajos
  final String? trabajoType; // 'entrega' | 'envio' (opcional, para compatibilidad)
  final String? numero; // Número de proforma o envío (opcional)
  final String? cliente; // Nombre del cliente (opcional)
  final String? direccion; // Dirección de entrega (opcional)

  // Coordenadas del destino para navegación
  final double? latitudeDestino;
  final double? longitudeDestino;

  // Campos de coordinación mejorada (NUEVOS)
  final int? numeroIntentosContacto;
  final String? resultadoUltimoIntento; // 'Aceptado', 'No contactado', 'Rechazado', 'Reagendar'
  final DateTime? entregadoEn;
  final String? entregadoA;
  final String? observacionesEntrega;
  final DateTime? coordinacionActualizadaEn;

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
    this.trabajoType,
    this.numero,
    this.cliente,
    this.direccion,
    this.latitudeDestino,
    this.longitudeDestino,
    // Coordinación mejorada
    this.numeroIntentosContacto,
    this.resultadoUltimoIntento,
    this.entregadoEn,
    this.entregadoA,
    this.observacionesEntrega,
    this.coordinacionActualizadaEn,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    // Intentar obtener coordenadas del destino de diferentes fuentes
    double? latDestino;
    double? lngDestino;

    // Buscar en direccionCliente
    if (json['direccionCliente'] is Map<String, dynamic>) {
      final dirCliente = json['direccionCliente'] as Map<String, dynamic>;
      latDestino = (dirCliente['latitud'] as num?)?.toDouble();
      lngDestino = (dirCliente['longitud'] as num?)?.toDouble();
    }

    // O buscar en campos raíz
    latDestino = (json['latitud_destino'] as num?)?.toDouble() ?? latDestino;
    lngDestino = (json['longitud_destino'] as num?)?.toDouble() ?? lngDestino;

    return Entrega(
      id: json['id'] as int,
      proformaId: json['proforma_id'] as int? ?? json['id'] as int,
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
      // Nuevos campos del endpoint /api/chofer/trabajos
      trabajoType: json['trabajoType'] as String? ?? json['type'] as String?,
      numero: json['numero'] as String?,
      cliente: json['cliente'] as String?,
      direccion: json['direccion'] as String?,
      // Coordenadas del destino
      latitudeDestino: latDestino,
      longitudeDestino: lngDestino,
      // Coordinación mejorada (NUEVOS)
      numeroIntentosContacto: json['numero_intentos_contacto'] as int?,
      resultadoUltimoIntento: json['resultado_ultimo_intento'] as String?,
      entregadoEn: json['entregado_en'] != null
          ? DateTime.parse(json['entregado_en'] as String)
          : null,
      entregadoA: json['entregado_a'] as String?,
      observacionesEntrega: json['observaciones_entrega'] as String?,
      coordinacionActualizadaEn: json['coordinacion_actualizada_en'] != null
          ? DateTime.parse(json['coordinacion_actualizada_en'] as String)
          : null,
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
      'trabajo_type': trabajoType,
      'numero': numero,
      'cliente': cliente,
      'direccion': direccion,
      'latitud_destino': latitudeDestino,
      'longitud_destino': longitudeDestino,
      // Coordinación mejorada
      'numero_intentos_contacto': numeroIntentosContacto,
      'resultado_ultimo_intento': resultadoUltimoIntento,
      'entregado_en': entregadoEn?.toIso8601String(),
      'entregado_a': entregadoA,
      'observaciones_entrega': observacionesEntrega,
      'coordinacion_actualizada_en': coordinacionActualizadaEn?.toIso8601String(),
    };
  }

  String get estadoLabel {
    // Soporta tanto estados de entregas como de envios
    const estadoLabels = {
      // Estados de entregas (proformas)
      'ASIGNADA': 'Asignada',
      'EN_CAMINO': 'En Camino',
      'LLEGO': 'Llegó',
      'ENTREGADO': 'Entregado',
      'NOVEDAD': 'Novedad',
      'CANCELADA': 'Cancelada',
      // Estados de envios (ventas)
      'PROGRAMADO': 'Programado',
      'EN_PREPARACION': 'En Preparación',
      'EN_RUTA': 'En Ruta',
    };
    return estadoLabels[estado] ?? estado;
  }

  String get estadoColor {
    const colors = {
      // Estados de entregas (proformas)
      'ASIGNADA': '#3b82f6', // blue
      'EN_CAMINO': '#f97316', // orange
      'LLEGO': '#eab308', // yellow
      'ENTREGADO': '#22c55e', // green
      'NOVEDAD': '#ef4444', // red
      'CANCELADA': '#6b7280', // gray
      // Estados de envios (ventas)
      'PROGRAMADO': '#3b82f6', // blue
      'EN_PREPARACION': '#f97316', // orange
      'EN_RUTA': '#eab308', // yellow
    };
    return colors[estado] ?? '#000000';
  }

  String get estadoIcon {
    const icons = {
      // Estados de entregas (proformas)
      'ASIGNADA': '📋',
      'EN_CAMINO': '🚚',
      'LLEGO': '🏁',
      'ENTREGADO': '✅',
      'NOVEDAD': '⚠️',
      'CANCELADA': '❌',
      // Estados de envios (ventas)
      'PROGRAMADO': '📅',
      'EN_PREPARACION': '📦',
      'EN_RUTA': '🚚',
    };
    return icons[estado] ?? '❓';
  }

  /// Retorna ícono adicional basado en el tipo de trabajo
  String get tipoWorkIcon {
    if (trabajoType == 'entrega') {
      return '🚐'; // Entrega directa
    } else if (trabajoType == 'envio') {
      return '📦'; // Envío desde almacén
    }
    return '📋'; // Por defecto
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
    double? latitudeDestino,
    double? longitudeDestino,
    int? numeroIntentosContacto,
    String? resultadoUltimoIntento,
    DateTime? entregadoEn,
    String? entregadoA,
    String? observacionesEntrega,
    DateTime? coordinacionActualizadaEn,
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
      latitudeDestino: latitudeDestino ?? this.latitudeDestino,
      longitudeDestino: longitudeDestino ?? this.longitudeDestino,
      // Coordinación mejorada
      numeroIntentosContacto: numeroIntentosContacto ?? this.numeroIntentosContacto,
      resultadoUltimoIntento: resultadoUltimoIntento ?? this.resultadoUltimoIntento,
      entregadoEn: entregadoEn ?? this.entregadoEn,
      entregadoA: entregadoA ?? this.entregadoA,
      observacionesEntrega: observacionesEntrega ?? this.observacionesEntrega,
      coordinacionActualizadaEn: coordinacionActualizadaEn ?? this.coordinacionActualizadaEn,
    );
  }

  @override
  String toString() =>
      'Entrega(id: $id, proformaId: $proformaId, estado: $estado, choferId: $choferId)';
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
