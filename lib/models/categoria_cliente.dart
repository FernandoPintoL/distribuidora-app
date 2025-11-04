class CategoriaCliente {
  final int id;
  final String? clave;
  final String? nombre;
  final String? descripcion;
  final bool activo;
  final String? createdAt;
  final String? updatedAt;

  CategoriaCliente({
    required this.id,
    this.clave,
    this.nombre,
    this.descripcion,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoriaCliente.fromJson(Map<String, dynamic> json) {
    return CategoriaCliente(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      clave: json['clave'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activo: json['activo'] is bool
          ? json['activo']
          : (json['activo']?.toString() == '1' || json['activo']?.toString() == 'true'),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clave': clave,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
