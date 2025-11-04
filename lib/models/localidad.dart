class Localidad {
  final int id;
  final String nombre;
  final String codigo;
  final bool activo;

  Localidad({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.activo,
  });

  factory Localidad.fromJson(Map<String, dynamic> json) {
    return Localidad(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'codigo': codigo, 'activo': activo};
  }
}
