class Prestable {
  final int id;
  final String nombre;
  final String codigo;
  final String tipo;
  final int? capacidad;
  final bool activo;

  Prestable({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.tipo,
    this.capacidad,
    this.activo = true,
  });

  factory Prestable.fromJson(Map<String, dynamic> json) {
    return Prestable(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      capacidad: json['capacidad'] as int?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
