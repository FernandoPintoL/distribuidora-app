import 'rango_aplicado.dart';
import 'proximo_rango.dart';

/// Detalles de un item del carrito con información de rangos de precio
/// 🔑 FASE 2: Incluye tipo_precio_id y tipo_precio_nombre en nivel superior
class DetalleCarritoConRango {
  final int productoId;
  final String nombreProducto;
  final String skuProducto; // 🔑 NUEVO
  final int cantidad;
  final int tipoPrecioId; // 🔑 NUEVO: ID del tipo de precio aplicado
  final String tipoPrecioNombre; // 🔑 NUEVO: Nombre del tipo de precio
  final double precioUnitario;
  final double subtotal;
  final RangoAplicado? rangoAplicado;
  final ProximoRango? proximoRango;
  final double? ahorroProximo; // Monto de dinero que se ahorraría en el próximo rango

  DetalleCarritoConRango({
    required this.productoId,
    required this.nombreProducto,
    required this.skuProducto,
    required this.cantidad,
    required this.tipoPrecioId,
    required this.tipoPrecioNombre,
    required this.precioUnitario,
    required this.subtotal,
    this.rangoAplicado,
    this.proximoRango,
    this.ahorroProximo,
  });

  /// ¿Hay oportunidad de ahorro?
  bool get tieneOportunidadAhorro {
    return proximoRango != null && ahorroProximo != null && ahorroProximo! > 0;
  }

  factory DetalleCarritoConRango.fromJson(Map<String, dynamic> json) {
    return DetalleCarritoConRango(
      productoId: json['producto_id'] ?? 0,
      nombreProducto: json['nombre_producto'] ?? json['producto_nombre'] ?? '',
      skuProducto: json['producto_sku'] ?? json['sku'] ?? '',
      cantidad: ((json['cantidad'] ?? 0) as num).toInt(),
      tipoPrecioId: json['tipo_precio_id'] ?? 2, // Default a VENTA (ID 2)
      tipoPrecioNombre: json['tipo_precio_nombre'] ?? 'Precio de Venta',
      precioUnitario: (json['precio_unitario'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      rangoAplicado: json['rango_aplicado'] != null
          ? RangoAplicado.fromJson(json['rango_aplicado'])
          : null,
      proximoRango: json['proximo_rango'] != null
          ? ProximoRango.fromJson(json['proximo_rango'])
          : null,
      ahorroProximo: json['ahorro_proximo'] != null
          ? (json['ahorro_proximo'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'nombre_producto': nombreProducto,
      'producto_sku': skuProducto,
      'cantidad': cantidad,
      'tipo_precio_id': tipoPrecioId,
      'tipo_precio_nombre': tipoPrecioNombre,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'rango_aplicado': rangoAplicado?.toJson(),
      'proximo_rango': proximoRango?.toJson(),
      'ahorro_proximo': ahorroProximo,
    };
  }
}
