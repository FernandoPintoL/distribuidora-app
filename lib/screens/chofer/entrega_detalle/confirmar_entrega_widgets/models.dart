// ✅ NUEVA 2026-02-12: Modelo para pagos múltiples (compartido entre widgets)
class PagoEntrega {
  int tipoPagoId;
  double monto;
  String? referencia;

  PagoEntrega({required this.tipoPagoId, required this.monto, this.referencia});

  Map<String, dynamic> toJson() => {
    'tipo_pago_id': tipoPagoId,
    'monto': monto,
    'referencia': referencia,
  };
}

// ✅ NUEVA 2026-02-15: Modelo para productos rechazados en devolución parcial
class ProductoRechazado {
  int detalleVentaId;
  int? productoId; // ✅ NUEVO: ID del producto (requerido por backend)
  String nombreProducto;
  double cantidadOriginal; // ✅ Cantidad original en la venta
  double cantidadRechazada; // ✅ Cantidad que el cliente rechaza (editable)
  double precioUnitario;
  double subtotalOriginal;

  ProductoRechazado({
    required this.detalleVentaId,
    this.productoId, // ✅ NUEVO: Opcional en constructor, requerido en JSON
    required this.nombreProducto,
    required this.cantidadOriginal,
    required this.cantidadRechazada,
    required this.precioUnitario,
    required this.subtotalOriginal,
  });

  /// Calcular el subtotal basado en cantidad rechazada
  double get subtotalRechazado => cantidadRechazada * precioUnitario;

  /// Calcular cantidad entregada
  double get cantidadEntregada => cantidadOriginal - cantidadRechazada;

  Map<String, dynamic> toJson() => {
    'producto_id': productoId ?? 0, // ✅ Backend lo requiere
    'producto_nombre': nombreProducto, // ✅ Backend espera producto_nombre
    'cantidad':
        cantidadRechazada, // ✅ CAMBIO: Backend espera "cantidad" (lo rechazado)
    'precio_unitario': precioUnitario, // ✅ Backend lo requiere
    'subtotal':
        subtotalRechazado, // ✅ CAMBIO: Backend espera "subtotal" (no subtotal_rechazado)
    // ✅ CAMPOS OPCIONALES PARA AUDITORÍA (no requeridos por validación):
    'detalle_venta_id': detalleVentaId,
    'cantidad_original': cantidadOriginal,
    'cantidad_entregada': cantidadEntregada,
  };
}
