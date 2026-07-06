class Proveedor {
  final int id;
  final String nombre;
  final String? razonSocial;
  final String? nit;
  final String? telefono;
  final String? email;
  final bool activo;

  Proveedor({
    required this.id,
    required this.nombre,
    this.razonSocial,
    this.nit,
    this.telefono,
    this.email,
    this.activo = true,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      razonSocial: json['razon_social'] as String?,
      nit: json['nit'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
