class ReporteProductoDanado {
  final int id;
  final int ventaId;
  final int clienteId;
  final int usuarioId;
  final String observaciones;
  final String estado; // pendiente, en_revision, aprobado, rechazado
  final String? notasRespuesta;
  final String? fechaReporte;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? venta;
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? usuario;
  final List<ReporteProductoDanadoImagen> imagenes;

  ReporteProductoDanado({
    required this.id,
    required this.ventaId,
    required this.clienteId,
    required this.usuarioId,
    required this.observaciones,
    required this.estado,
    this.notasRespuesta,
    this.fechaReporte,
    required this.createdAt,
    required this.updatedAt,
    this.venta,
    this.cliente,
    this.usuario,
    this.imagenes = const [],
  });

  /// Obtener descripcion del estado en espanol
  String get estadoDescripcion {
    return switch (estado) {
      'pendiente' => 'Pendiente de Revision',
      'en_revision' => 'En Revision',
      'aprobado' => 'Aprobado',
      'rechazado' => 'Rechazado',
      _ => 'Desconocido',
    };
  }

  /// Obtener color para el estado
  String get estadoColor {
    return switch (estado) {
      'pendiente' => '#FFA500', // Naranja
      'en_revision' => '#4169E1', // Azul
      'aprobado' => '#28A745', // Verde
      'rechazado' => '#DC3545', // Rojo
      _ => '#6C757D', // Gris
    };
  }

  /// Obtener nombre del cliente
  String get nombreCliente {
    return cliente?['nombre'] ?? 'Cliente desconocido';
  }

  /// Obtener numero de venta
  String get numeroVenta {
    return venta?['numero_venta']?.toString() ?? 'Venta desconocida';
  }

  factory ReporteProductoDanado.fromJson(Map<String, dynamic> json) {
    return ReporteProductoDanado(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ventaId: json['venta_id'] is int
          ? json['venta_id']
          : int.tryParse(json['venta_id'].toString()) ?? 0,
      clienteId: json['cliente_id'] is int
          ? json['cliente_id']
          : int.tryParse(json['cliente_id'].toString()) ?? 0,
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : int.tryParse(json['usuario_id'].toString()) ?? 0,
      observaciones: json['observaciones'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      notasRespuesta: json['notas_respuesta'],
      fechaReporte: json['fecha_reporte'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      venta: json['venta'],
      cliente: json['cliente'],
      usuario: json['usuario'],
      imagenes: json['imagenes'] != null
          ? (json['imagenes'] as List)
              .map((i) => ReporteProductoDanadoImagen.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venta_id': ventaId,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'observaciones': observaciones,
      'estado': estado,
      'notas_respuesta': notasRespuesta,
      'fecha_reporte': fechaReporte,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'venta': venta,
      'cliente': cliente,
      'usuario': usuario,
      'imagenes': imagenes.map((i) => i.toJson()).toList(),
    };
  }
}

class ReporteProductoDanadoImagen {
  final int id;
  final int reporteId;
  final String rutaImagen;
  final String nombreArchivo;
  final String? descripcion;
  final DateTime fechaCarga;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReporteProductoDanadoImagen({
    required this.id,
    required this.reporteId,
    required this.rutaImagen,
    required this.nombreArchivo,
    this.descripcion,
    required this.fechaCarga,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Obtener URL completa de la imagen
  String get urlImagen => '/storage/$rutaImagen';

  factory ReporteProductoDanadoImagen.fromJson(Map<String, dynamic> json) {
    return ReporteProductoDanadoImagen(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      reporteId: json['reporte_id'] is int
          ? json['reporte_id']
          : int.tryParse(json['reporte_id'].toString()) ?? 0,
      rutaImagen: json['ruta_imagen'] ?? '',
      nombreArchivo: json['nombre_archivo'] ?? '',
      descripcion: json['descripcion'],
      fechaCarga: json['fecha_carga'] != null
          ? DateTime.parse(json['fecha_carga'].toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporte_id': reporteId,
      'ruta_imagen': rutaImagen,
      'nombre_archivo': nombreArchivo,
      'descripcion': descripcion,
      'fecha_carga': fechaCarga.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
