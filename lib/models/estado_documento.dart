/// Modelo para estado del documento (Proforma, Venta, etc.)
class EstadoDocumento {
  final int id;
  final String? codigo;
  final String nombre;
  final String? color;
  final String? descripcion;

  EstadoDocumento({
    required this.id,
    this.codigo,
    required this.nombre,
    this.color,
    this.descripcion,
  });

  factory EstadoDocumento.fromJson(Map<String, dynamic> json) {
    return EstadoDocumento(
      id: json['id'] as int,
      codigo: json['codigo'] as String?,
      nombre: json['nombre'] as String? ?? 'Desconocido',
      color: json['color'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }
}
