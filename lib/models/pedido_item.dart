import 'package:flutter/foundation.dart';
import 'product.dart';

class PedidoItem {
  final int id;
  final int pedidoId;
  final int productoId;
  final Product? producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? observaciones;
  final double? descuento; // Added field for backend compatibility

  PedidoItem({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.observaciones,
    this.descuento,
  });

  factory PedidoItem.fromJson(Map<String, dynamic> json) {
    try {
      return PedidoItem(
        id: json['id'] as int,
        pedidoId: json['pedido_id'] as int? ?? json['proforma_id'] as int? ?? 0,
        productoId: json['producto_id'] as int,
        producto: json['producto'] != null
            ? Product.fromJson(json['producto'] as Map<String, dynamic>)
            : null,
        cantidad: _parseInt(json['cantidad']),
        precioUnitario: _parseDouble(json['precio_unitario']),
        subtotal: _parseDouble(json['subtotal']),
        observaciones: json['observaciones'] as String?,
        descuento: _parseDouble(json['descuento']),
      );
    } catch (e) {
      debugPrint('❌ Error parsing PedidoItem: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  // Helper to safely parse int from string or number
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        // Try to parse as double first (handles "2.000000"), then convert to int
        return double.parse(value).toInt();
      } catch (e) {
        debugPrint('⚠️  Could not parse "$value" as int, defaulting to 0');
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
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
        debugPrint('⚠️  Could not parse "$value" as double, defaulting to 0.0');
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedido_id': pedidoId,
      'producto_id': productoId,
      'producto': producto?.toJson(),
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'observaciones': observaciones,
      'descuento': descuento,
    };
  }

  PedidoItem copyWith({
    int? id,
    int? pedidoId,
    int? productoId,
    Product? producto,
    int? cantidad,
    double? precioUnitario,
    double? subtotal,
    String? observaciones,
    double? descuento,
  }) {
    return PedidoItem(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      productoId: productoId ?? this.productoId,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      observaciones: observaciones ?? this.observaciones,
      descuento: descuento ?? this.descuento,
    );
  }
}
