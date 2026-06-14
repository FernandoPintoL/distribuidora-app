class EstadoLogistico {
  final int id;
  final String? codigo;
  final String nombre;
  final String? descripcion;
  final String? color;
  final String? icono;
  final int? orden;
  final bool esEstadoFinal;
  final bool permiteEdicion;
  final bool requiereAprobacion;

  EstadoLogistico({
    required this.id,
    this.codigo,
    required this.nombre,
    this.descripcion,
    this.color,
    this.icono,
    this.orden,
    this.esEstadoFinal = false,
    this.permiteEdicion = false,
    this.requiereAprobacion = false,
  });

  factory EstadoLogistico.fromJson(Map<String, dynamic> json) {
    return EstadoLogistico(
      id: json['id'] as int,
      codigo: json['codigo'] as String?,
      nombre: json['nombre'] as String? ?? 'Desconocido',
      descripcion: json['descripcion'] as String?,
      color: json['color'] as String?,
      icono: json['icono'] as String?,
      orden: json['orden'] as int?,
      esEstadoFinal: json['es_estado_final'] as bool? ?? false,
      permiteEdicion: json['permite_edicion'] as bool? ?? false,
      requiereAprobacion: json['requiere_aprobacion'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'color': color,
        'icono': icono,
        'orden': orden,
        'es_estado_final': esEstadoFinal,
        'permite_edicion': permiteEdicion,
        'requiere_aprobacion': requiereAprobacion,
      };
}
