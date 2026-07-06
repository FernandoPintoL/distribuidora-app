class PrestamoEventoAlmacen {
  final int id;
  final int prestamoEventoDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoEventoAlmacen({
    required this.id,
    required this.prestamoEventoDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    required this.esProveedor,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoEventoAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoEventoAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoEventoDetalleId: json['prestamo_evento_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
