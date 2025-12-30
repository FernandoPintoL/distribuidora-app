import 'package:intl/intl.dart';
import 'venta.dart';
import 'chofer.dart';
import 'vehiculo.dart';

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

  // Historial de estados (viene en la respuesta principal)
  final List<EntregaEstadoHistorial> historialEstados;

  // Ventas asignadas a esta entrega
  final List<Venta> ventas;

  // Relaciones con objetos completos del backend
  final Chofer? chofer;
  final Vehiculo? vehiculo;

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
    // Historial de estados
    this.historialEstados = const [],
    // Ventas
    this.ventas = const [],
    // Relaciones
    this.chofer,
    this.vehiculo,
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

    // Extraer nombre del cliente si es un objeto Map
    String? clienteName;
    if (json['cliente'] is Map<String, dynamic>) {
      final clienteObj = json['cliente'] as Map<String, dynamic>;
      clienteName = clienteObj['nombre'] as String?;
    } else {
      clienteName = json['cliente'] as String?;
    }

    // Extraer dirección si existe
    String? direccionValue;
    if (json['direccion'] is String) {
      direccionValue = json['direccion'] as String?;
    }

    // Parsear historial de estados si existe en la respuesta
    List<EntregaEstadoHistorial> historial = [];
    if (json['historial_estados'] is List) {
      historial = (json['historial_estados'] as List)
          .map((h) => EntregaEstadoHistorial.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    // Parsear ventas si existen en la respuesta
    List<Venta> ventasList = [];
    if (json['ventas'] is List) {
      ventasList = (json['ventas'] as List)
          .map((v) => Venta.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // Parsear chofer si existe en la respuesta
    Chofer? choferObj;
    if (json['chofer'] is Map<String, dynamic>) {
      choferObj = Chofer.fromJson(json['chofer'] as Map<String, dynamic>);
    }

    // Parsear vehículo si existe en la respuesta
    Vehiculo? vehiculoObj;
    if (json['vehiculo'] is Map<String, dynamic>) {
      vehiculoObj = Vehiculo.fromJson(json['vehiculo'] as Map<String, dynamic>);
    }

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
      cliente: clienteName,
      direccion: direccionValue,
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
      // Historial de estados
      historialEstados: historial,
      // Ventas
      ventas: ventasList,
      // Relaciones
      chofer: choferObj,
      vehiculo: vehiculoObj,
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
    // Estados sincronizados con base de datos real (check constraint migration)
    const estadoLabels = {
      // Estados principales
      'PROGRAMADO': 'Programado',
      'ASIGNADA': 'Asignada',
      // Flujo legacy
      'EN_CAMINO': 'En Camino',
      'LLEGO': 'Llegó',
      'ENTREGADO': 'Entregado',
      // Flujo nuevo de carga
      'PREPARACION_CARGA': 'Preparación de Carga',
      'EN_CARGA': 'En Carga',
      'LISTO_PARA_ENTREGA': 'Listo para Entrega',
      'EN_TRANSITO': 'En Tránsito',
      // Estados especiales
      'NOVEDAD': 'Novedad',
      'RECHAZADO': 'Rechazado',
      'CANCELADA': 'Cancelada',
    };
    return estadoLabels[estado] ?? estado;
  }

  String get estadoColor {
    const colors = {
      // Estados principales
      'PROGRAMADO': '#eab308', // yellow
      'ASIGNADA': '#3b82f6', // blue
      // Flujo legacy
      'EN_CAMINO': '#f97316', // orange
      'LLEGO': '#eab308', // yellow
      'ENTREGADO': '#22c55e', // light green
      // Flujo nuevo de carga
      'PREPARACION_CARGA': '#f97316', // orange
      'EN_CARGA': '#f97316', // orange
      'LISTO_PARA_ENTREGA': '#eab308', // yellow
      'EN_TRANSITO': '#f97316', // orange (similar a EN_CAMINO)
      // Estados especiales
      'NOVEDAD': '#ef4444', // red
      'RECHAZADO': '#ef4444', // red
      'CANCELADA': '#6b7280', // gray
    };
    return colors[estado] ?? '#000000';
  }

  String get estadoIcon {
    const icons = {
      // Estados principales
      'PROGRAMADO': '📅',
      'ASIGNADA': '📋',
      // Flujo legacy
      'EN_CAMINO': '🚚',
      'LLEGO': '🏁',
      'ENTREGADO': '✅',
      // Flujo nuevo de carga
      'PREPARACION_CARGA': '📦',
      'EN_CARGA': '📦',
      'LISTO_PARA_ENTREGA': '📦',
      'EN_TRANSITO': '🚚',
      // Estados especiales
      'NOVEDAD': '⚠️',
      'RECHAZADO': '❌',
      'CANCELADA': '🚫',
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

  // Validaciones de transiciones de estado
  bool get puedeIniciarRuta =>
      estado == 'ASIGNADA' || estado == 'LISTO_PARA_ENTREGA';

  // Backend solo acepta EN_CAMINO para marcar llegada (estado legacy)
  bool get puedeMarcarLlegada => estado == 'EN_CAMINO';

  bool get puedeConfirmarEntrega =>
      estado == 'LLEGO' || estado == 'EN_CAMINO' || estado == 'EN_TRANSITO';

  bool get puedeReportarNovedad =>
      !['ENTREGADO', 'CANCELADA'].contains(estado);

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
