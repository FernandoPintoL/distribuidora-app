class TipoPago {
  final int id;
  final String codigo;  // EFECTIVO, TRANSFERENCIA, CHEQUE, TARJETA
  final String nombre;   // Ej: "Efectivo", "Transferencia Bancaria"
  final String? descripcion;
  final bool activo;

  TipoPago({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  factory TipoPago.fromJson(Map<String, dynamic> json) {
    return TipoPago(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }

  @override
  String toString() => 'TipoPago(id: $id, codigo: $codigo, nombre: $nombre)';
}
