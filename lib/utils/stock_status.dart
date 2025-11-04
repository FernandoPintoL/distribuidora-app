import 'package:flutter/material.dart';

/// Información sobre el estado del stock de un producto
class StockStatus {
  final String text;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const StockStatus({
    required this.text,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  /// Calcula el estado de stock basado en cantidad y stock mínimo
  factory StockStatus.from({
    required int stock,
    required int? minimumStock,
  }) {
    final minimo = minimumStock ?? 0;

    if (stock == 0) {
      return const StockStatus(
        text: 'Agotado',
        color: Colors.red,
        backgroundColor: Colors.red,
        icon: Icons.block,
      );
    } else if (stock <= minimo) {
      return const StockStatus(
        text: 'Stock Bajo',
        color: Colors.orange,
        backgroundColor: Colors.orange,
        icon: Icons.warning,
      );
    } else {
      return const StockStatus(
        text: 'Disponible',
        color: Colors.green,
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    }
  }

  /// Retorna el background color con opacidad
  Color get backgroundWithOpacity => backgroundColor.withValues(alpha: 0.1);
}
