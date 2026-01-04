import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/stock_status.dart';
import '../../extensions/theme_extension.dart';
import '../product/index.dart';

/// Widget para mostrar un producto en vista de grid
class ProductGridItem extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
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
      elevation: isDark ? 2 : 1,
      color: _quantity > 0
          ? (isDark
                ? colorScheme.primaryContainer.withAlpha(80)
                : colorScheme.primaryContainer.withAlpha(60))
          : (isDark ? colorScheme.surface : Colors.white),
      shadowColor: isDark
          ? Colors.black.withAlpha(80)
          : Colors.black.withAlpha(30),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen grande
              Center(
                child: ProductImageWidget(product: widget.product, size: 100),
              ),
              const SizedBox(height: 12),

              // Nombre y detalles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.nombre,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${widget.product.sku}',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: context.textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 8),

              // Precio y acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Precio
                  if (widget.product.precioVenta != null)
                    Flexible(
                      child: Text(
                        'Bs ${widget.product.precioVenta!.toStringAsFixed(2)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),

                  // Stock y botón/cantidad
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      /* ProductStockBadgeWidget(
                        stock: stock,
                        status: stockStatus,
                      ), */
                      if (canAddToCart) ...[
                        const SizedBox(height: 4),
                        if (_quantity == 0)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              onPressed: _incrementQuantity,
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: IconButton(
                                    onPressed: _decrementQuantity,
                                    icon: const Icon(Icons.remove, size: 14),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Center(
                                    child: Text(
                                      '$_quantity',
                                      style: context.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: IconButton(
                                    onPressed: _incrementQuantity,
                                    icon: const Icon(Icons.add, size: 14),
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
                    ],
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
