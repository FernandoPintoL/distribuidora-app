import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra la información del producto (nombre, SKU, marca, precio)
/// Adaptado para modo oscuro
class ProductInfoWidget extends StatelessWidget {
  final Product product;
  final bool isGridView;

  const ProductInfoWidget({
    super.key,
    required this.product,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          Text(
            product.nombre,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isGridView ? 14 : 15,
              height: 1.2,
              color: colorScheme.onSurface,
            ),
            maxLines: isGridView ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // SKU y Marca
          Row(
            children: [
              Flexible(
                child: Text(
                  'SKU: ${product.sku}',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: context.textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.marca != null && !isGridView) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.secondaryContainer
                        : colorScheme.secondaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.secondary.withAlpha(80)
                          : colorScheme.secondary.withAlpha(100),
                    ),
                  ),
                  child: Text(
                    product.marca!.nombre,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Precio
          if (product.precioVenta != null)
            Text(
              'Bs ${product.precioVenta!.toStringAsFixed(2)}',
              style: context.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: isGridView ? 15 : 16,
              ),
            ),
        ],
      ),
    );
  }
}
