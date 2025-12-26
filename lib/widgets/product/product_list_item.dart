import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/stock_status.dart';
import '../../extensions/theme_extension.dart';
import '../product/index.dart';

/// Widget para mostrar un producto en vista de lista
class ProductListItem extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  int _quantity = 0;

  int _getMainWarehouseStock() {
    if (widget.product.stockPrincipal?.cantidad != null) {
      return (widget.product.stockPrincipal!.cantidad as num).toInt();
    }
    return 0;
  }

  void _incrementQuantity() {
    final stock = _getMainWarehouseStock();
    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
      final carritoProvider = context.read<CarritoProvider>();
      carritoProvider.agregarProducto(widget.product);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
      });
      final carritoProvider = context.read<CarritoProvider>();
      carritoProvider.decrementarCantidad(widget.product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final stock = _getMainWarehouseStock();
    final stockStatus = StockStatus.from(
      stock: stock,
      minimumStock: widget.product.stockMinimo,
    );
    final canAddToCart =
        widget.product.activo &&
        widget.product.precioVenta != null &&
        stock > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isDark ? 2 : 1,
      color: _quantity > 0
          ? (isDark
                ? colorScheme.primaryContainer.withAlpha(80)
                : colorScheme.primaryContainer.withAlpha(60))
          : (isDark ? colorScheme.surface : Colors.white),
      shadowColor: isDark
          ? Colors.black.withAlpha(80)
          : Colors.black.withAlpha(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageWidget(product: widget.product),
              const SizedBox(width: 12),
              ProductInfoWidget(product: widget.product),
              // Stock badge y botón/cantidad
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ProductStockBadgeWidget(
                    stock: stock,
                    status: stockStatus,
                  ),
                  const SizedBox(height: 6),
                  if (canAddToCart)
                    if (_quantity == 0)
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: _incrementQuantity,
                          icon: const Icon(Icons.add_shopping_cart),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Agregar al carrito',
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                onPressed: _decrementQuantity,
                                icon: const Icon(Icons.remove, size: 16),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: context.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                onPressed: _incrementQuantity,
                                icon: const Icon(Icons.add, size: 16),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
