import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Widget que muestra la imagen del producto con badge de categoría
class ProductImageWidget extends StatelessWidget {
  final Product product;

  const ProductImageWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.inventory_2, color: Colors.blue, size: 36),
          // Badge de categoría
          if (product.categoria != null)
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  product.categoria!.nombre.substring(0, 1),
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
