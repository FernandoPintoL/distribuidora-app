import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../extensions/theme_extension.dart';

class ProductCardImageSection extends StatelessWidget {
  final Producto product;
  final double imageSize;
  final int cantidadDisponible;
  final String? unidadMedida;
  final bool isPreventista;

  const ProductCardImageSection({
    super.key,
    required this.product,
    required this.imageSize,
    this.cantidadDisponible = 0,
    this.unidadMedida,
    this.isPreventista = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductImage(context),

        // Badge de disponibilidad para preventistas
        if (isPreventista && cantidadDisponible > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(200),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(150),
                  width: 0.5,
                ),
              ),
              child: Text(
                '📦Disp. $cantidadDisponible ${unidadMedida ?? ""}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductImage(BuildContext context) {
    final imagenes = product.imagenes;

    if (imagenes != null && imagenes.isNotEmpty) {
      final imagenPrincipal = imagenes.firstWhere(
        (img) => img.esPrincipal,
        orElse: () => imagenes.first,
      );

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: imageSize - 20,
          height: imageSize - 20,
          child: Image.network(
            imagenPrincipal.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error cargando imagen: ${imagenPrincipal.url}');
              return _buildImageError();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return _buildImageError();
  }

  Widget _buildImageError() {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 28,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text('Sin imagen', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
