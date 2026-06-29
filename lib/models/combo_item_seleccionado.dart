import 'package:flutter/foundation.dart';

class ComboItemSeleccionado {
  final int comboItemId;
  final int productoId;
  final int cantidad;
  final bool incluido;

  ComboItemSeleccionado({
    required this.comboItemId,
    required this.productoId,
    required this.cantidad,
    required this.incluido,
  });

  factory ComboItemSeleccionado.fromJson(Map<String, dynamic> json) {
    try {
      return ComboItemSeleccionado(
        comboItemId: json['combo_item_id'] as int? ?? 0,
        productoId: json['producto_id'] as int? ?? 0,
        cantidad: _parseInt(json['cantidad']),
        incluido: json['incluido'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ Error parsing ComboItemSeleccionado: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'combo_item_id': comboItemId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'incluido': incluido,
    };
  }

  ComboItemSeleccionado copyWith({
    int? comboItemId,
    int? productoId,
    int? cantidad,
    bool? incluido,
  }) {
    return ComboItemSeleccionado(
      comboItemId: comboItemId ?? this.comboItemId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      incluido: incluido ?? this.incluido,
    );
  }

  @override
  String toString() =>
      'ComboItemSeleccionado(comboItemId: $comboItemId, productoId: $productoId, cantidad: $cantidad, incluido: $incluido)';
}
