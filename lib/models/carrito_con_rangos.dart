import 'detalle_carrito_con_rango.dart';

/// Respuesta del carrito con cálculos de rangos de precio
class CarritoConRangos {
  final int cantidadItems;
  final double subtotal;
  final double ahorroTotal; // Ahorro total si se alcanzara todos los próximos rangos
  final List<DetalleCarritoConRango> detalles;

  CarritoConRangos({
    required this.cantidadItems,
    required this.subtotal,
    required this.ahorroTotal,
    required this.detalles,
  });

  /// Total sin aplicar descuentos adicionales
  double get total => subtotal;

  /// Cantidad total de unidades en el carrito
  int get cantidadTotal {
    return detalles.fold(0, (sum, item) => sum + item.cantidad.toInt());
  }

  /// Ahorro potencial si se agrega más cantidad
  double get ahorroDisponible {
    return detalles
        .where((item) => item.tieneOportunidadAhorro)
        .fold(0.0, (sum, item) => sum + (item.ahorroProximo ?? 0));
  }

  factory CarritoConRangos.fromJson(Map<String, dynamic> json) {
    final detallesList = (json['detalles'] as List?)
            ?.map((item) => DetalleCarritoConRango.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return CarritoConRangos(
      cantidadItems: json['cantidad_items'] ?? 0,
      subtotal: (json['subtotal'] ?? json['total'] ?? 0).toDouble(),
      ahorroTotal: (json['ahorro_total'] ?? 0).toDouble(),
      detalles: detallesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_items': cantidadItems,
      'subtotal': subtotal,
      'ahorro_total': ahorroTotal,
      'detalles': detalles.map((item) => item.toJson()).toList(),
    };
  }
}
