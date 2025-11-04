import 'package:flutter/material.dart';
import '../../models/product.dart';

/// Widget que muestra la información del producto (nombre, SKU, marca, precio)
class ProductInfoWidget extends StatelessWidget {
  final Product product;

  const ProductInfoWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          Text(
            product.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // SKU y Marca
          Row(
            children: [
              Text(
                'SKU: ${product.sku}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              if (product.marca != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    product.marca!.nombre,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
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
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}
