import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/stock_status.dart';
import '../../utils/product_color_utils.dart';
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

class _ProductGridItemState extends State<ProductGridItem>
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

    // Obtener colores únicos para este producto
    final productColor = ProductColorUtils.getProductColor(
      widget.product.id,
      isDark: isDark,
    );
    final productColorLight = ProductColorUtils.getProductColorLight(
      widget.product.id,
      isDark: isDark,
    );
    final productShadowColor = ProductColorUtils.getProductShadowColor(
      widget.product.id,
      isDark: isDark,
    );
    final productBorderColor = ProductColorUtils.getProductBorderColor(
      widget.product.id,
      isDark: isDark,
    );

    return Card(
      elevation: 4,
      color: _quantity > 0
          ? productColorLight
          : (isDark ? colorScheme.surface : Colors.white),
      shadowColor: productShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _quantity > 0 ? productBorderColor : colorScheme.outline.withAlpha(20),
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
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges superior (Categoría) - Premium style con color único del producto
              if (widget.product.categoria != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: productColor.withAlpha(100),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: productColor.withAlpha(150),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: productColor.withAlpha(30),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.product.categoria!.nombre,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // Imagen grande
              Center(
                child: ProductImageWidget(product: widget.product, size: 85),
              ),
              const SizedBox(height: 10),

              // Nombre y detalles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.nombre,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                        letterSpacing: 0.1,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // SKU y Marca en fila
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'SKU: ${widget.product.sku}',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: context.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.product.marca != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: context.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.product.marca!.nombre,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Unidad de medida
                    if (widget.product.unidadMedida != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Unidad: ${widget.product.unidadMedida!.nombre}',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                          color: productColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                  // Stock y botón/cantidad
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (canAddToCart) ...[
                        const SizedBox(height: 8),
                        if (_quantity == 0)
                          ScaleTransition(
                            scale: _bounceAnimation,
                            child: SizedBox(
                              width: 38,
                              height: 38,
                              child: IconButton(
                                onPressed: _incrementQuantity,
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: productColor,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: productColor.withAlpha(40),
                                  padding: EdgeInsets.zero,
                                ),
                                tooltip: 'Agregar al carrito',
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: productColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: productColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: IconButton(
                                    onPressed: _decrementQuantity,
                                    icon: const Icon(Icons.remove, size: 14),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: productColor,
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
                                              color: productColor,
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
                                    icon: const Icon(Icons.add, size: 14),
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      foregroundColor: productColor,
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
