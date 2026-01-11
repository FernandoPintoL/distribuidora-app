import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../screens/carrito/carrito_screen.dart';

/// Widget que muestra el botón de acción (agregar al carrito o cantidad)
class ProductActionButtonWidget extends StatelessWidget {
  final Product product;
  final bool canAddToCart;
  final VoidCallback onAddToCart;

  const ProductActionButtonWidget({
    super.key,
    required this.product,
    required this.canAddToCart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    if (canAddToCart) {
      return _buildCartButton(context);
    } else if (!product.activo) {
      return _buildStatusBadge('Inactivo', Colors.red);
    } else {
      return _buildStatusBadge('Sin stock', Colors.red);
    }
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final yaEnCarrito = carritoProvider.tieneProducto(product.id);
        final cantidad = carritoProvider.getCantidadProducto(product.id);

        return SizedBox(
          height: 32,
          child: yaEnCarrito
              ? _buildCartCountBadge(cantidad)
              : _buildAddToCartButton(context),
        );
      },
    );
  }

  Widget _buildCartCountBadge(int cantidad) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 14,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$cantidad',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onAddToCart,
      icon: const Icon(Icons.add_shopping_cart, size: 16),
      label: const Text('Agregar'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
