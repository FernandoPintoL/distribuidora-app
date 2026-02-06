/// Modelo para productos agrupados de una entrega
///
/// Consolida los productos de múltiples ventas en una sola entrega,
/// sumando las cantidades de productos duplicados
class ProductoAgrupado {
  final int productoId;
  final String nombreProducto;
  final String codigoProducto;
  final double cantidadTotal;
  final double precioUnitario;
  final String subtotal;
  final String unidadMedida;
  final List<VentaProducto> ventas;

  ProductoAgrupado({
    required this.productoId,
    required this.nombreProducto,
    required this.codigoProducto,
    required this.cantidadTotal,
    required this.precioUnitario,
    required this.subtotal,
    required this.unidadMedida,
    required this.ventas,
  });

  /// Crear desde JSON del backend
  factory ProductoAgrupado.fromJson(Map<String, dynamic> json) {
    return ProductoAgrupado(
      productoId: json['producto_id'] as int? ?? 0,
      nombreProducto: json['producto_nombre'] as String? ?? 'Desconocido',
      codigoProducto: json['codigo_producto'] as String? ?? '',
      cantidadTotal: (json['cantidad_total'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: json['subtotal']?.toString() ?? '0.00',
      unidadMedida: json['unidad_medida'] as String? ?? 'Unidad',
      ventas: ((json['ventas'] as List?) ?? [])
          .map((v) => VentaProducto.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() => {
    'producto_id': productoId,
    'producto_nombre': nombreProducto,
    'codigo_producto': codigoProducto,
    'cantidad_total': cantidadTotal,
    'precio_unitario': precioUnitario,
    'subtotal': subtotal,
    'unidad_medida': unidadMedida,
    'ventas': ventas.map((v) => v.toJson()).toList(),
  };

  @override
  String toString() =>
      'ProductoAgrupado($productoId: $nombreProducto x$cantidadTotal)';
}

/// Información de venta en la que aparece un producto agrupado
class VentaProducto {
  final int ventaId;
  final String numeroVenta;
  final double cantidad;
  final int clienteId;
  final String nombreCliente;

  VentaProducto({
    required this.ventaId,
    required this.numeroVenta,
    required this.cantidad,
    required this.clienteId,
    required this.nombreCliente,
  });

  /// Crear desde JSON
  factory VentaProducto.fromJson(Map<String, dynamic> json) {
    return VentaProducto(
      ventaId: json['venta_id'] as int? ?? 0,
      numeroVenta: json['venta_numero'] as String? ?? 'N/A',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      clienteId: json['cliente_id'] as int? ?? 0,
      nombreCliente: json['cliente_nombre'] as String? ?? 'Sin cliente',
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() => {
    'venta_id': ventaId,
    'venta_numero': numeroVenta,
    'cantidad': cantidad,
    'cliente_id': clienteId,
    'cliente_nombre': nombreCliente,
  };

  @override
  String toString() =>
      'VentaProducto($numeroVenta: $nombreCliente x$cantidad)';
}

/// Respuesta del servidor con productos agrupados
class ProductosAgrupados {
  final int entregaId;
  final String numeroEntrega;
  final List<ProductoAgrupado> productos;
  final int totalItems;
  final double cantidadTotal;

  ProductosAgrupados({
    required this.entregaId,
    required this.numeroEntrega,
    required this.productos,
    required this.totalItems,
    required this.cantidadTotal,
  });

  /// Crear desde JSON del backend
  factory ProductosAgrupados.fromJson(Map<String, dynamic> json) {
    return ProductosAgrupados(
      entregaId: json['entrega_id'] as int? ?? 0,
      numeroEntrega: json['numero_entrega'] as String? ?? 'N/A',
      productos: ((json['productos'] as List?) ?? [])
          .map((p) => ProductoAgrupado.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalItems: json['total_items'] as int? ?? 0,
      cantidadTotal: (json['cantidad_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() => {
    'entrega_id': entregaId,
    'numero_entrega': numeroEntrega,
    'productos': productos.map((p) => p.toJson()).toList(),
    'total_items': totalItems,
    'cantidad_total': cantidadTotal,
  };

  @override
  String toString() =>
      'ProductosAgrupados($numeroEntrega: ${productos.length} tipos, ${cantidadTotal.toInt()} unidades)';
}
