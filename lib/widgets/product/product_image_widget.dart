import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra la imagen del producto con badge de categoría
/// Adaptado para modo oscuro, con soporte para imagenes_producto
class ProductImageWidget extends StatelessWidget {
  final Product product;
  final double size;

  const ProductImageWidget({
    super.key,
    required this.product,
    this.size = 70,
  });

  /// Obtiene la URL de la imagen principal o la primera imagen disponible
  String? _getPrimaryImageUrl() {
    if (product.imagenes == null || product.imagenes!.isEmpty) {
      return null;
    }

    // Buscar imagen marcada como principal
    final primaryImage = product.imagenes!.firstWhere(
      (img) => img.esPrincipal,
      orElse: () => product.imagenes!.first,
    );

    // Usar el getter url que formatea correctamente la URL
    final url = primaryImage.url;
    return url.isNotEmpty ? url : null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final imageUrl = _getPrimaryImageUrl();

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
          // Mostrar imagen si está disponible, si no mostrar icono
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2_rounded,
                    color: isDark
                        ? colorScheme.primary.withAlpha(200)
                        : colorScheme.primary,
                    size: size * 0.5,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            )
          else
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
