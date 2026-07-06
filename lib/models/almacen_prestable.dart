class AlmacenPrestable {
  final int id;
  final String nombre;
  final String? direccion;
  final String? ubicacionFisica;
  final bool requiereTransporteExterno;
  final String? responsable;
  final String? telefono;
  final bool activo;
  final String? createdAt;
  final String? updatedAt;
  final bool esProveedor;

  AlmacenPrestable({
    required this.id,
    required this.nombre,
    this.direccion,
    this.ubicacionFisica,
    this.requiereTransporteExterno = false,
    this.responsable,
    this.telefono,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
    this.esProveedor = false,
  });

  factory AlmacenPrestable.fromJson(Map<String, dynamic> json) {
    return AlmacenPrestable(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      ubicacionFisica: json['ubicacion_fisica'] as String?,
      requiereTransporteExterno:
          json['requiere_transporte_externo'] as bool? ?? false,
      responsable: json['responsable'] as String?,
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      esProveedor: json['es_proveedor'] as bool? ?? false,
    );
  }
}
