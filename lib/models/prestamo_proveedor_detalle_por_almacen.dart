// ✅ NUEVO: Almacenes en los que se distribuyó un préstamo de proveedor
class PrestamoProveedorAlmacen {
  final int id;
  final int prestamoProveedorDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoProveedorAlmacen({
    required this.id,
    required this.prestamoProveedorDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    required this.esProveedor,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoProveedorAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoProveedorAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoProveedorDetalleId:
          json['prestamo_proveedor_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
