import 'package:flutter/material.dart';
import '../../utils/stock_status.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra el badge de estado de stock
/// Adaptado para modo oscuro con colores mejorados
class ProductStockBadgeWidget extends StatelessWidget {
  final int stock;
  final StockStatus status;

  const ProductStockBadgeWidget({
    super.key,
    required this.stock,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    // Obtener colores adaptativos según el estado
    final adaptiveColors = _getAdaptiveColors(status, isDark, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: adaptiveColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: adaptiveColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 14,
            color: adaptiveColors.foreground,
          ),
          const SizedBox(width: 4),
          Text(
            '$stock',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: adaptiveColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene colores adaptativos según el estado y el tema
  _AdaptiveColors _getAdaptiveColors(
      StockStatus status, bool isDark, ColorScheme colorScheme) {
    if (stock == 0) {
      // Agotado - Rojo
      return _AdaptiveColors(
        foreground: colorScheme.error,
        background: colorScheme.error.withAlpha(40),
        border: colorScheme.error.withAlpha(100),
      );
    } else if (status.text == 'Stock Bajo') {
      // Stock bajo - Naranja/Amarillo
      return _AdaptiveColors(
        foreground: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
        background:
            isDark ? const Color(0xFFFB923C).withAlpha(40) : const Color(0xFFFFF7ED),
        border: isDark ? const Color(0xFFFB923C).withAlpha(100) : const Color(0xFFFED7AA),
      );
    } else {
      // Disponible - Usar color primario del tema
      return _AdaptiveColors(
        foreground: colorScheme.primary,
        background: colorScheme.primary.withAlpha(40),
        border: colorScheme.primary.withAlpha(100),
      );
    }
  }
}

/// Clase helper para colores adaptativos
class _AdaptiveColors {
  final Color foreground;
  final Color background;
  final Color border;

  _AdaptiveColors({
    required this.foreground,
    required this.background,
    required this.border,
  });
}
