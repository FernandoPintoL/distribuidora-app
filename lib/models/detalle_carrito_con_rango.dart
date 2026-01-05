import 'rango_aplicado.dart';
import 'proximo_rango.dart';

/// Detalles de un item del carrito con información de rangos de precio
class DetalleCarritoConRango {
  final int productoId;
  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final RangoAplicado? rangoAplicado;
  final ProximoRango? proximoRango;
  final double? ahorroProximo; // Monto de dinero que se ahorraría en el próximo rango

  DetalleCarritoConRango({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
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
      cantidad: (json['cantidad'] ?? 0).toDouble(),
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
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'rango_aplicado': rangoAplicado?.toJson(),
      'proximo_rango': proximoRango?.toJson(),
      'ahorro_proximo': ahorroProximo,
    };
  }
}
