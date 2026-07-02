class EstadoLogistico {
  final int id;
  final String? codigo;
  final String? categoria;
  final String nombre;
  final String? descripcion;
  final int? orden;
  final bool activo;
  final String? color;
  final String? icono;
  final bool esEstadoFinal;
  final bool permiteEdicion;
  final bool requiereAprobacion;
  final Map<String, dynamic>? metadatos;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? visual; // {color, icono}

  EstadoLogistico({
    required this.id,
    this.codigo,
    this.categoria,
    required this.nombre,
    this.descripcion,
    this.orden,
    this.activo = true,
    this.color,
    this.icono,
    this.esEstadoFinal = false,
    this.permiteEdicion = false,
    this.requiereAprobacion = false,
    this.metadatos,
    this.createdAt,
    this.updatedAt,
    this.visual,
  });

  factory EstadoLogistico.fromJson(Map<String, dynamic> json) {
    return EstadoLogistico(
      id: json['id'] as int,
      codigo: json['codigo'] as String?,
      categoria: json['categoria'] as String?,
      nombre: json['nombre'] as String? ?? 'Desconocido',
      descripcion: json['descripcion'] as String?,
      orden: json['orden'] as int?,
      activo: json['activo'] as bool? ?? true,
      color: json['color'] as String?,
      icono: json['icono'] as String?,
      esEstadoFinal: json['es_estado_final'] as bool? ?? false,
      permiteEdicion: json['permite_edicion'] as bool? ?? false,
      requiereAprobacion: json['requiere_aprobacion'] as bool? ?? false,
      metadatos: json['metadatos'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      visual: json['visual'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'categoria': categoria,
        'nombre': nombre,
        'descripcion': descripcion,
        'orden': orden,
        'activo': activo,
        'color': color,
        'icono': icono,
        'es_estado_final': esEstadoFinal,
        'permite_edicion': permiteEdicion,
        'requiere_aprobacion': requiereAprobacion,
        'metadatos': metadatos,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'visual': visual,
      };
}
