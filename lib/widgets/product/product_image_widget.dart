import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra la imagen del producto con badge de categoría
/// Adaptado para modo oscuro
class ProductImageWidget extends StatelessWidget {
  final Product product;
  final double size;

  const ProductImageWidget({
    super.key,
    required this.product,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainer,
                ]
              : [
                  colorScheme.primaryContainer.withAlpha(30),
                  colorScheme.surface,
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withAlpha(60)
              : colorScheme.primary.withAlpha(30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(30)
                : colorScheme.primary.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            color: isDark
                ? colorScheme.primary.withAlpha(200)
                : colorScheme.primary,
            size: size * 0.5,
          ),
          // Badge de categoría
          if (product.categoria != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(100),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  product.categoria!.nombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
