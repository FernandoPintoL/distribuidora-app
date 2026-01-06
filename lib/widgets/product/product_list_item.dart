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

class _ProductListItemState extends State<ProductListItem>
    with TickerProviderStateMixin {
  int _quantity = 0;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Tap scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Add to cart bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

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

      // Trigger bounce animation
      _bounceController.forward(from: 0.0);

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

    // Color marrón fijo para botones, precios y categoría
    const brownColor = Color(0xFF795548);
    final brownColorLight = brownColor.withAlpha(isDark ? 100 : 40);
    final brownShadow = brownColor.withAlpha(isDark ? 30 : 15);
    final brownBorder = brownColor.withAlpha(120);

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        color: _quantity > 0
            ? brownColorLight
            : (isDark ? colorScheme.surface : Colors.white),
        shadowColor: brownShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _quantity > 0 ? brownBorder : colorScheme.outline.withAlpha(20),
            width: _quantity > 0 ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: colorScheme.primary.withAlpha(30),
          highlightColor: colorScheme.primary.withAlpha(15),
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  /* ProductStockBadgeWidget(
                    stock: stock,
                    status: stockStatus,
                  ),
                  const SizedBox(height: 6), */
                  if (canAddToCart)
                    if (_quantity == 0)
                      ScaleTransition(
                        scale: _bounceAnimation,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add_shopping_cart),
                            style: IconButton.styleFrom(
                              backgroundColor: brownColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: brownColor.withAlpha(40),
                            ),
                            tooltip: 'Agregar al carrito',
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: brownColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: brownColor,
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
                                  foregroundColor: brownColor,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.elasticOut,
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Text(
                                    '$_quantity',
                                    key: ValueKey(_quantity),
                                    style: context.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: brownColor,
                                        ),
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
                                  foregroundColor: brownColor,
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
