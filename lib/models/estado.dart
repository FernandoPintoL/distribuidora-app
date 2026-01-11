/// Modelo para Estados centralizados desde API
///
/// Representa un estado de una categoría específica (entrega, proforma, etc.)
/// con información visual (color, icono) y metadatos.

enum CategoriaEstado {
  entrega,
  proforma,
  ventaLogistica,
  vehiculo,
  pago,
}

extension CategoriaEstadoExt on CategoriaEstado {
  String get value {
    switch (this) {
      case CategoriaEstado.entrega:
        return 'entrega';
      case CategoriaEstado.proforma:
        return 'proforma';
      case CategoriaEstado.ventaLogistica:
        return 'venta_logistica';
      case CategoriaEstado.vehiculo:
        return 'vehiculo';
      case CategoriaEstado.pago:
        return 'pago';
    }
  }

  static CategoriaEstado fromString(String value) {
    switch (value.toLowerCase()) {
      case 'entrega':
        return CategoriaEstado.entrega;
      case 'proforma':
        return CategoriaEstado.proforma;
      case 'venta_logistica':
        return CategoriaEstado.ventaLogistica;
      case 'vehiculo':
        return CategoriaEstado.vehiculo;
      case 'pago':
        return CategoriaEstado.pago;
      default:
        throw ArgumentError('Unknown CategoriaEstado: $value');
    }
  }
}

/// Modelo de Estado desde API
class Estado {
  final int id;
  final String categoria; // 'entrega', 'proforma', 'venta_logistica', etc.
  final String codigo; // 'PROGRAMADO', 'EN_CAMINO', 'ENTREGADO', etc.
  final String nombre; // Etiqueta legible: 'Programado', 'En Camino', etc.
  final String? descripcion;
  final String color; // Hex color: '#3B82F6'
  final String? icono; // Nombre del ícono o emoji
  final int orden; // Order for sorting
  final bool esEstadoFinal;
  final bool permiteEdicion;
  final bool requiereAprobacion;
  final bool activo;
  final Map<String, dynamic>? metadatos;
  final DateTime createdAt;
  final DateTime updatedAt;

  Estado({
    required this.id,
    required this.categoria,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.color,
    this.icono,
    required this.orden,
    required this.esEstadoFinal,
    required this.permiteEdicion,
    required this.requiereAprobacion,
    required this.activo,
    this.metadatos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'] as int,
      categoria: json['categoria'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      color: json['color'] as String? ?? '#000000',
      icono: json['icono'] as String?,
      orden: json['orden'] as int? ?? 0,
      esEstadoFinal: json['es_estado_final'] as bool? ?? false,
      permiteEdicion: json['permite_edicion'] as bool? ?? true,
      requiereAprobacion: json['requiere_aprobacion'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
      metadatos: json['metadatos'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria': categoria,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'icono': icono,
      'orden': orden,
      'es_estado_final': esEstadoFinal,
      'permite_edicion': permiteEdicion,
      'requiere_aprobacion': requiereAprobacion,
      'activo': activo,
      'metadatos': metadatos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Estado copyWith({
    int? id,
    String? categoria,
    String? codigo,
    String? nombre,
    String? descripcion,
    String? color,
    String? icono,
    int? orden,
    bool? esEstadoFinal,
    bool? permiteEdicion,
    bool? requiereAprobacion,
    bool? activo,
    Map<String, dynamic>? metadatos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Estado(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      orden: orden ?? this.orden,
      esEstadoFinal: esEstadoFinal ?? this.esEstadoFinal,
      permiteEdicion: permiteEdicion ?? this.permiteEdicion,
      requiereAprobacion: requiereAprobacion ?? this.requiereAprobacion,
      activo: activo ?? this.activo,
      metadatos: metadatos ?? this.metadatos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Estado($categoria:$codigo=$nombre)';
}

/// Fallback estados para Entrega (cuando API no está disponible)
final List<Estado> FALLBACK_ESTADOS_ENTREGA = [
  Estado(
    id: 1,
    categoria: 'entrega',
    codigo: 'PROGRAMADO',
    nombre: 'Programado',
    descripcion: 'Entrega programada, pendiente de preparación',
    color: '#eab308', // yellow
    icono: '📅',
    orden: 1,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 2,
    categoria: 'entrega',
    codigo: 'ASIGNADA',
    nombre: 'Asignada',
    descripcion: 'Asignada a chofer',
    color: '#3b82f6', // blue
    icono: '📋',
    orden: 2,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 3,
    categoria: 'entrega',
    codigo: 'EN_CAMINO',
    nombre: 'En Camino',
    descripcion: 'En camino al destino',
    color: '#f97316', // orange
    icono: '🚚',
    orden: 3,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 4,
    categoria: 'entrega',
    codigo: 'LLEGO',
    nombre: 'Llegó',
    descripcion: 'Llegó al destino',
    color: '#eab308', // yellow
    icono: '🏁',
    orden: 4,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 5,
    categoria: 'entrega',
    codigo: 'ENTREGADO',
    nombre: 'Entregado',
    descripcion: 'Entrega confirmada al cliente',
    color: '#22c55e', // green
    icono: '✅',
    orden: 5,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 6,
    categoria: 'entrega',
    codigo: 'NOVEDAD',
    nombre: 'Novedad',
    descripcion: 'Con novedad en la entrega',
    color: '#ef4444', // red
    icono: '⚠️',
    orden: 6,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 7,
    categoria: 'entrega',
    codigo: 'CANCELADA',
    nombre: 'Cancelada',
    descripcion: 'Entrega cancelada, stock revertido',
    color: '#6b7280', // gray
    icono: '🚫',
    orden: 7,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

/// Fallback estados para Proforma (cuando API no está disponible)
final List<Estado> FALLBACK_ESTADOS_PROFORMA = [
  Estado(
    id: 1,
    categoria: 'proforma',
    codigo: 'PENDIENTE',
    nombre: 'Pendiente',
    descripcion: 'Proforma pendiente de aprobación',
    color: '#6b7280', // gray
    icono: '⏳',
    orden: 1,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: true,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 2,
    categoria: 'proforma',
    codigo: 'APROBADA',
    nombre: 'Aprobada',
    descripcion: 'Proforma aprobada, lista para convertir',
    color: '#22c55e', // green
    icono: '✅',
    orden: 2,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 3,
    categoria: 'proforma',
    codigo: 'RECHAZADA',
    nombre: 'Rechazada',
    descripcion: 'Proforma rechazada',
    color: '#ef4444', // red
    icono: '❌',
    orden: 3,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 4,
    categoria: 'proforma',
    codigo: 'CONVERTIDA',
    nombre: 'Convertida',
    descripcion: 'Convertida a pedido/venta',
    color: '#3b82f6', // blue
    icono: '🔄',
    orden: 4,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 5,
    categoria: 'proforma',
    codigo: 'VENCIDA',
    nombre: 'Vencida',
    descripcion: 'Proforma vencida',
    color: '#f97316', // orange
    icono: '⏰',
    orden: 5,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

/// Fallback estados para Venta Logística (cuando API no está disponible)
final List<Estado> FALLBACK_ESTADOS_VENTA_LOGISTICA = [
  Estado(
    id: 1,
    categoria: 'venta_logistica',
    codigo: 'EN_TRANSITO',
    nombre: 'En Tránsito',
    descripcion: 'Venta en tránsito hacia destino',
    color: '#f97316', // orange
    icono: '🚚',
    orden: 1,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 2,
    categoria: 'venta_logistica',
    codigo: 'ENTREGADA',
    nombre: 'Entregada',
    descripcion: 'Venta entregada al cliente',
    color: '#22c55e', // green
    icono: '✅',
    orden: 2,
    esEstadoFinal: true,
    permiteEdicion: false,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 3,
    categoria: 'venta_logistica',
    codigo: 'PENDIENTE',
    nombre: 'Pendiente',
    descripcion: 'Venta pendiente de entrega',
    color: '#eab308', // yellow
    icono: '⏳',
    orden: 3,
    esEstadoFinal: false,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Estado(
    id: 4,
    categoria: 'venta_logistica',
    codigo: 'NO_ENTREGADA',
    nombre: 'No Entregada',
    descripcion: 'Venta no entregada por diversos motivos',
    color: '#ef4444', // red
    icono: '❌',
    orden: 4,
    esEstadoFinal: true,
    permiteEdicion: true,
    requiereAprobacion: false,
    activo: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
