import 'product.dart';

class CarritoItem {
  final Product producto;
  final int cantidad;
  final double precioUnitario;
  final String? observaciones;
  final List<Map<String, dynamic>>? comboItemsSeleccionados;

  CarritoItem({
    required this.producto,
    required this.cantidad,
    double? precioUnitario,
    this.observaciones,
    this.comboItemsSeleccionados,
  }) : precioUnitario = precioUnitario ?? producto.precioVenta ?? 0.0;

  // Cálculo del subtotal
  double get subtotal {
    return precioUnitario * cantidad;
  }

  /// Verificar si el producto tiene stock suficiente para la cantidad solicitada
  bool tieneStockSuficiente() {
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    return cantidad <= (stockDisponible as num).toInt();
  }

  /// Obtener cantidad disponible del almacén principal
  int get cantidadDisponible {
    final stock = producto.stockPrincipal?.cantidadDisponible ?? 0;
    return (stock as num).toInt();
  }

  /// Obtener cantidad máxima que se puede agregar
  int get cantidadMaximaDisponible {
    return cantidadDisponible;
  }

  /// Obtener cantidad de unidades que exceden el stock
  int get cantidadExcedida {
    final exceso = cantidad - cantidadDisponible;
    return exceso > 0 ? exceso : 0;
  }

  /// Verificar si hay stock
  bool get hayStock {
    return cantidadDisponible > 0;
  }

  // Crear copia con modificaciones
  CarritoItem copyWith({
    Product? producto,
    int? cantidad,
    double? precioUnitario,
    String? observaciones,
    List<Map<String, dynamic>>? comboItemsSeleccionados,
  }) {
    return CarritoItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      observaciones: observaciones ?? this.observaciones,
      comboItemsSeleccionados: comboItemsSeleccionados ?? this.comboItemsSeleccionados,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'producto_id': producto.id,
      'producto': producto.toJson(),
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'observaciones': observaciones,
      if (comboItemsSeleccionados != null)
        'combo_items_seleccionados': comboItemsSeleccionados,
    };
  }

  // Crear desde JSON (para guardar localmente con Hive en el futuro)
  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      producto: Product.fromJson(json['producto']),
      cantidad: _parseInt(json['cantidad']),
      precioUnitario: _parseDouble(json['precio_unitario']),
      observaciones: json['observaciones'],
      comboItemsSeleccionados: json['combo_items_seleccionados'] != null
          ? List<Map<String, dynamic>>.from(json['combo_items_seleccionados'])
          : null,
    );
  }

  // Helper to safely parse int from string or number
  static int _parseInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return double.parse(value).toInt();
      } catch (e) {
        return 1;
      }
    }
    if (value is num) return value.toInt();
    return 1;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CarritoItem) return false;

    // Comparar producto ID
    if (other.producto.id != producto.id) return false;

    // Comparar comboItemsSeleccionados si es un combo
    if (comboItemsSeleccionados != null || other.comboItemsSeleccionados != null) {
      if (comboItemsSeleccionados == null || other.comboItemsSeleccionados == null) {
        return false;
      }
      // Comparar contenido de las listas
      if (comboItemsSeleccionados!.length != other.comboItemsSeleccionados!.length) {
        return false;
      }
      for (int i = 0; i < comboItemsSeleccionados!.length; i++) {
        if (comboItemsSeleccionados![i]['combo_item_id'] !=
            other.comboItemsSeleccionados![i]['combo_item_id']) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  int get hashCode {
    int hash = producto.id.hashCode;
    if (comboItemsSeleccionados != null) {
      for (final item in comboItemsSeleccionados!) {
        hash = hash ^ item['combo_item_id'].hashCode;
      }
    }
    return hash;
  }
}
