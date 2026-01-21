import 'detalle_carrito_con_rango.dart';

/// Respuesta del carrito con cálculos de rangos de precio
/// 🔑 FASE 2: Incluye ahorro_disponible en nivel superior del backend
class CarritoConRangos {
  final int cantidadItems;
  final double subtotal;
  final double ahorroTotal; // Ahorro total si se alcanzara todos los próximos rangos
  final double ahorroDisponibleDelBackend; // 🔑 NUEVO: Ahorro disponible calculado por backend
  final bool tieneAhorroDisponible; // 🔑 NUEVO: Flag para saber si hay ahorro
  final List<DetalleCarritoConRango> detalles;

  CarritoConRangos({
    required this.cantidadItems,
    required this.subtotal,
    required this.ahorroTotal,
    required this.ahorroDisponibleDelBackend,
    required this.tieneAhorroDisponible,
    required this.detalles,
  });

  /// Total sin aplicar descuentos adicionales
  double get total => subtotal;

  /// Cantidad total de unidades en el carrito
  int get cantidadTotal {
    return detalles.fold(0, (sum, item) => sum + item.cantidad.toInt());
  }

  /// Ahorro potencial si se agrega más cantidad (calculado localmente como respaldo)
  double get ahorroDisponibleLocal {
    return detalles
        .where((item) => item.tieneOportunidadAhorro)
        .fold(0.0, (sum, item) => sum + (item.ahorroProximo ?? 0));
  }

  /// 🔑 NUEVO: Ahorro disponible (prefiere valor del backend)
  double get ahorroDisponible {
    return ahorroDisponibleDelBackend > 0
        ? ahorroDisponibleDelBackend
        : ahorroDisponibleLocal;
  }

  factory CarritoConRangos.fromJson(Map<String, dynamic> json) {
    final detallesList = (json['detalles'] as List?)
            ?.map((item) => DetalleCarritoConRango.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return CarritoConRangos(
      cantidadItems: json['cantidad_items'] ?? 0,
      subtotal: _parseDouble(json['subtotal'] ?? json['total']),
      ahorroTotal: _parseDouble(json['ahorro_total']),
      ahorroDisponibleDelBackend: _parseDouble(json['ahorro_disponible']),
      tieneAhorroDisponible: json['tiene_ahorro_disponible'] ?? false,
      detalles: detallesList,
    );
  }

  // Helper to safely parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_items': cantidadItems,
      'subtotal': subtotal,
      'ahorro_total': ahorroTotal,
      'ahorro_disponible': ahorroDisponibleDelBackend,
      'tiene_ahorro_disponible': tieneAhorroDisponible,
      'detalles': detalles.map((item) => item.toJson()).toList(),
    };
  }
}
