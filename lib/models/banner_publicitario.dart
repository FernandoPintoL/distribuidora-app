class BannerPublicitario {
  final int id;
  final String titulo;
  final String? descripcion;
  String imagen; // NO es final para que el servicio pueda actualizar la URL
  final String nombreArchivo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final int orden;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerPublicitario({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.imagen,
    required this.nombreArchivo,
    this.fechaInicio,
    this.fechaFin,
    required this.activo,
    required this.orden,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerPublicitario.fromJson(Map<String, dynamic> json) {
    return BannerPublicitario(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      imagen: json['imagen'] as String,
      nombreArchivo: json['nombre_archivo'] as String? ?? '',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      activo: json['activo'] as bool? ?? true,
      orden: json['orden'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'nombre_archivo': nombreArchivo,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'activo': activo,
      'orden': orden,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Obtener URL completa de la imagen
  /// El servicio ya completa la URL con la baseUrl, así que simplemente retorna la imagen
  String get urlImagenCompleta => imagen;

  /// Verificar si el banner está vigente (dentro de las fechas)
  bool get estaVigente {
    final ahora = DateTime.now();

    if (fechaInicio != null && ahora.isBefore(fechaInicio!)) {
      return false; // Banner aún no ha iniciado
    }

    if (fechaFin != null && ahora.isAfter(fechaFin!)) {
      return false; // Banner ha vencido
    }

    return true; // Banner está vigente
  }
}
