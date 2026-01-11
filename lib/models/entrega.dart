import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'venta.dart';
import 'chofer.dart';
import 'vehiculo.dart';

class Entrega {
  final int id;
  final int?
  proformaId; // Ahora opcional, ya que el backend no siempre lo envía
  final int? choferId;
  final int? vehiculoId;
  final int? direccionClienteId;
  final String
  estado; // ASIGNADA, EN_CAMINO, LLEGO, ENTREGADO, NOVEDAD, CANCELADA (legacy ENUM)
  final int? estadoEntregaId; // FK a estados_logistica.id (normalizado)
  final String?
  estadoEntregaCodigo; // Código del estado (PROGRAMADO, PREPARACION_CARGA, etc)
  final String?
  estadoEntregaNombre; // Nombre del estado (ej: "Preparación de Carga")
  final String? estadoEntregaColor; // Color hex del estado
  final String? estadoEntregaIcono; // Ícono del estado
  final DateTime? fechaAsignacion;
  final DateTime? fechaInicio;
  final DateTime? fechaEntrega;
  final String? observaciones;
  final String? motivoNovedad;
  final String? firmaDigitalUrl;
  final String? fotoEntregaUrl;

  // Campos adicionales del nuevo endpoint /api/chofer/trabajos
  final String?
  trabajoType; // 'entrega' | 'envio' (opcional, para compatibilidad)
  final String? numero; // Número de proforma o envío (opcional)
  final String? numeroEntrega; // Número de entrega (ej: ENT-20260108-12)
  final String? cliente; // Nombre del cliente (opcional)
  final String? direccion; // Dirección de entrega (opcional)

  // Campos de totales agregados
  final double? subtotalTotal; // Suma de subtotales de todas las ventas
  final double? impuestoTotal; // Suma de impuestos de todas las ventas
  final double? totalGeneral; // Total general de la entrega

  // Coordenadas del destino para navegación
  final double? latitudeDestino;
  final double? longitudeDestino;

  // Campos de coordinación mejorada (NUEVOS)
  final int? numeroIntentosContacto;
  final String?
  resultadoUltimoIntento; // 'Aceptado', 'No contactado', 'Rechazado', 'Reagendar'
  final DateTime? entregadoEn;
  final String? entregadoA;
  final String? observacionesEntrega;
  final DateTime? coordinacionActualizadaEn;

  // Campos SLA - FASE 5 (NUEVOS)
  final DateTime? fechaEntregaComprometida; // Fecha comprometida de entrega
  final TimeOfDay? ventanaEntregaIni; // Hora inicio ventana de entrega
  final TimeOfDay? ventanaEntregaFin; // Hora fin ventana de entrega

  // Historial de estados (viene en la respuesta principal)
  final List<EntregaEstadoHistorial> historialEstados;

  // Ventas asignadas a esta entrega
  final List<Venta> ventas;

  // Relaciones con objetos completos del backend
  final Chofer? chofer;
  final Vehiculo? vehiculo;

  Entrega({
    required this.id,
    this.proformaId, // Ahora opcional
    this.choferId,
    this.vehiculoId,
    this.direccionClienteId,
    required this.estado,
    this.estadoEntregaId,
    this.estadoEntregaCodigo,
    this.estadoEntregaNombre,
    this.estadoEntregaColor,
    this.estadoEntregaIcono,
    this.fechaAsignacion,
    this.fechaInicio,
    this.fechaEntrega,
    this.observaciones,
    this.motivoNovedad,
    this.firmaDigitalUrl,
    this.fotoEntregaUrl,
    this.trabajoType,
    this.numero,
    this.numeroEntrega,
    this.cliente,
    this.direccion,
    this.subtotalTotal,
    this.impuestoTotal,
    this.totalGeneral,
    this.latitudeDestino,
    this.longitudeDestino,
    // Coordinación mejorada
    this.numeroIntentosContacto,
    this.resultadoUltimoIntento,
    this.entregadoEn,
    this.entregadoA,
    this.observacionesEntrega,
    this.coordinacionActualizadaEn,
    // SLA - FASE 5
    this.fechaEntregaComprometida,
    this.ventanaEntregaIni,
    this.ventanaEntregaFin,
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

    // Buscar en direccionCliente (probar ambos formatos)
    if (json['direccionCliente'] is Map<String, dynamic>) {
      final dirCliente = json['direccionCliente'] as Map<String, dynamic>;
      latDestino = (dirCliente['latitud'] as num?)?.toDouble();
      lngDestino = (dirCliente['longitud'] as num?)?.toDouble();
    } else if (json['direccion_cliente'] is Map<String, dynamic>) {
      final dirCliente = json['direccion_cliente'] as Map<String, dynamic>;
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
          .map(
            (h) => EntregaEstadoHistorial.fromJson(h as Map<String, dynamic>),
          )
          .toList();
    }

    // Parsear ventas si existen en la respuesta
    List<Venta> ventasList = [];
    if (json['ventas'] is List) {
      ventasList = (json['ventas'] as List)
          .map((v) => Venta.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // Si no se encontraron coordenadas en el nivel Entrega,
    // buscar en la primera venta disponible
    if ((latDestino == null || lngDestino == null) && ventasList.isNotEmpty) {
      final primeraVenta = ventasList.first;
      // print('[ENTREGA_PARSE] Buscando coords en primera venta: venta.latitud=${primeraVenta.latitud}, venta.longitud=${primeraVenta.longitud}');
      if (primeraVenta.latitud != null && primeraVenta.longitud != null) {
        latDestino = primeraVenta.latitud;
        lngDestino = primeraVenta.longitud;
        // También extraer dirección de la venta si no hay dirección en Entrega
        direccionValue = direccionValue ?? primeraVenta.direccion;
        // print('[ENTREGA_PARSE] Coordenadas extraídas de venta: lat=$latDestino, lng=$lngDestino, dir=$direccionValue');
      }
    } else {
      // print('[ENTREGA_PARSE] Coordenadas a nivel Entrega: lat=$latDestino, lng=$lngDestino');
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

    // Parsear campos SLA - FASE 5
    TimeOfDay? ventanaIni;
    TimeOfDay? ventanaFin;

    if (json['ventana_entrega_ini'] is String) {
      final parts = (json['ventana_entrega_ini'] as String).split(':');
      if (parts.length >= 2) {
        ventanaIni = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    if (json['ventana_entrega_fin'] is String) {
      final parts = (json['ventana_entrega_fin'] as String).split(':');
      if (parts.length >= 2) {
        ventanaFin = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // Parsear estado_entrega desde la relación con tabla estados_logistica
    int? estadoEntregaId;
    String? estadoEntregaCodigo;
    String? estadoEntregaNombre;
    String? estadoEntregaColor;
    String? estadoEntregaIcono;

    if (json['estado_entrega'] is Map<String, dynamic>) {
      final estadoEntregaObj = json['estado_entrega'] as Map<String, dynamic>;
      estadoEntregaId = estadoEntregaObj['id'] as int?;
      estadoEntregaCodigo = estadoEntregaObj['codigo'] as String?;
      estadoEntregaNombre = estadoEntregaObj['nombre'] as String?;
      estadoEntregaColor = estadoEntregaObj['color'] as String?;
      estadoEntregaIcono = estadoEntregaObj['icono'] as String?;
    } else if (json['estado_entrega_id'] is int) {
      // Fallback: solo guardar el ID si no viene la relación completa
      estadoEntregaId = json['estado_entrega_id'] as int?;
    }

    return Entrega(
      id: json['id'] as int,
      proformaId: json['proforma_id'] as int?, // Ahora opcional
      choferId: json['chofer_id'] as int?,
      vehiculoId: json['vehiculo_id'] as int?,
      direccionClienteId: json['direccion_cliente_id'] as int?,
      estado: json['estado'] as String,
      estadoEntregaId: estadoEntregaId,
      estadoEntregaCodigo: estadoEntregaCodigo,
      estadoEntregaNombre: estadoEntregaNombre,
      estadoEntregaColor: estadoEntregaColor,
      estadoEntregaIcono: estadoEntregaIcono,
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
      numeroEntrega:
          json['numero_entrega'] as String? ?? json['numeroEntrega'] as String?,
      cliente: clienteName,
      direccion: direccionValue,
      // Totales agregados
      subtotalTotal: (json['subtotal_total'] as num?)?.toDouble(),
      impuestoTotal: (json['impuesto_total'] as num?)?.toDouble(),
      totalGeneral: (json['total_general'] as num?)?.toDouble(),
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
      // SLA - FASE 5
      fechaEntregaComprometida: json['fecha_entrega_comprometida'] != null
          ? DateTime.parse(json['fecha_entrega_comprometida'] as String)
          : null,
      ventanaEntregaIni: ventanaIni,
      ventanaEntregaFin: ventanaFin,
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
      'estado_entrega_id': estadoEntregaId,
      'estado_entrega_codigo': estadoEntregaCodigo,
      'estado_entrega_nombre': estadoEntregaNombre,
      'estado_entrega_color': estadoEntregaColor,
      'estado_entrega_icono': estadoEntregaIcono,
      'fecha_asignacion': fechaAsignacion?.toIso8601String(),
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'observaciones': observaciones,
      'motivo_novedad': motivoNovedad,
      'firma_digital_url': firmaDigitalUrl,
      'foto_entrega_url': fotoEntregaUrl,
      'trabajo_type': trabajoType,
      'numero': numero,
      'numero_entrega': numeroEntrega,
      'cliente': cliente,
      'direccion': direccion,
      'subtotal_total': subtotalTotal,
      'impuesto_total': impuestoTotal,
      'total_general': totalGeneral,
      'latitud_destino': latitudeDestino,
      'longitud_destino': longitudeDestino,
      // Coordinación mejorada
      'numero_intentos_contacto': numeroIntentosContacto,
      'resultado_ultimo_intento': resultadoUltimoIntento,
      'entregado_en': entregadoEn?.toIso8601String(),
      'entregado_a': entregadoA,
      'observaciones_entrega': observacionesEntrega,
      'coordinacion_actualizada_en': coordinacionActualizadaEn
          ?.toIso8601String(),
      // SLA - FASE 5
      'fecha_entrega_comprometida': fechaEntregaComprometida?.toIso8601String(),
      'ventana_entrega_ini': ventanaEntregaIni != null
          ? '${ventanaEntregaIni!.hour.toString().padLeft(2, '0')}:${ventanaEntregaIni!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'ventana_entrega_fin': ventanaEntregaFin != null
          ? '${ventanaEntregaFin!.hour.toString().padLeft(2, '0')}:${ventanaEntregaFin!.minute.toString().padLeft(2, '0')}:00'
          : null,
    };
  }

  /// @deprecated Use EstadosHelper.getEstadoLabel() instead
  /// Mantener por compatibilidad pero usar helpers dinámicos para nuevos código
  String get estadoLabel {
    // Importar dinámicamente para evitar dependencia circular
    // En nueva arquitectura, usar EstadosHelper.getEstadoLabel('entrega', estado)
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

  /// @deprecated Use EstadosHelper.getEstadoColor() instead
  /// Mantener por compatibilidad pero usar helpers dinámicos para nuevos código
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

  /// @deprecated Use EstadosHelper.getEstadoIcon() instead
  /// Mantener por compatibilidad pero usar helpers dinámicos para nuevos código
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
    String? numeroEntrega,
    double? subtotalTotal,
    double? impuestoTotal,
    double? totalGeneral,
    double? latitudeDestino,
    double? longitudeDestino,
    int? numeroIntentosContacto,
    String? resultadoUltimoIntento,
    DateTime? entregadoEn,
    String? entregadoA,
    String? observacionesEntrega,
    DateTime? coordinacionActualizadaEn,
    DateTime? fechaEntregaComprometida,
    TimeOfDay? ventanaEntregaIni,
    TimeOfDay? ventanaEntregaFin,
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
      numeroEntrega: numeroEntrega ?? this.numeroEntrega,
      subtotalTotal: subtotalTotal ?? this.subtotalTotal,
      impuestoTotal: impuestoTotal ?? this.impuestoTotal,
      totalGeneral: totalGeneral ?? this.totalGeneral,
      latitudeDestino: latitudeDestino ?? this.latitudeDestino,
      longitudeDestino: longitudeDestino ?? this.longitudeDestino,
      // Coordinación mejorada
      numeroIntentosContacto:
          numeroIntentosContacto ?? this.numeroIntentosContacto,
      resultadoUltimoIntento:
          resultadoUltimoIntento ?? this.resultadoUltimoIntento,
      entregadoEn: entregadoEn ?? this.entregadoEn,
      entregadoA: entregadoA ?? this.entregadoA,
      observacionesEntrega: observacionesEntrega ?? this.observacionesEntrega,
      coordinacionActualizadaEn:
          coordinacionActualizadaEn ?? this.coordinacionActualizadaEn,
      // SLA - FASE 5
      fechaEntregaComprometida:
          fechaEntregaComprometida ?? this.fechaEntregaComprometida,
      ventanaEntregaIni: ventanaEntregaIni ?? this.ventanaEntregaIni,
      ventanaEntregaFin: ventanaEntregaFin ?? this.ventanaEntregaFin,
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
