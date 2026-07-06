class PrestamoClienteAlmacen {
  final int id;
  final int prestamoClienteDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoClienteAlmacen({
    required this.id,
    required this.prestamoClienteDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    this.esProveedor = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoClienteAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoClienteAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoClienteDetalleId:
          json['prestamo_cliente_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
