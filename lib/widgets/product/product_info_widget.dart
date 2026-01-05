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
              fontWeight: FontWeight.w700,
              fontSize: isGridView ? 15 : 15,
              height: 1.3,
              letterSpacing: 0.2,
              color: colorScheme.onSurface,
            ),
            maxLines: isGridView ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // SKU, Marca y Categoría en fila
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
              if (product.marca != null) ...[
                const SizedBox(width: 6),
                Text('•', style: context.textTheme.bodySmall),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    product.marca!.nombre,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (product.categoria != null) ...[
                const SizedBox(width: 6),
                Text('•', style: context.textTheme.bodySmall),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    product.categoria!.nombre,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Unidad de medida
          if (product.unidadMedida != null)
            Text(
              'Unidad: ${product.unidadMedida!.nombre}',
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),

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
