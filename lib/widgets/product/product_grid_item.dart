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

class _ProductGridItemState extends State<ProductGridItem>
    with TickerProviderStateMixin {
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
    if (widget.product.stockPrincipal?.cantidadDisponible != null) {
      return (widget.product.stockPrincipal!.cantidadDisponible as num).toInt();
    }
    return 0;
  }

  void _incrementQuantity() {
    final stock = _getMainWarehouseStock();
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.product.id);

    if (cantidadActual < stock) {
      // Trigger bounce animation
      _bounceController.forward(from: 0.0);

      // Actualizar el provider (esto dispara notifyListeners)
      carritoProvider.agregarProducto(widget.product);
    }
  }

  void _decrementQuantity() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.product.id);

    if (cantidadActual > 0) {
      // Actualizar el provider (esto dispara notifyListeners)
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

    // 🔑 NUEVO: Usar Consumer para leer cantidad sincronizada del provider
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final cantidad = carritoProvider.obtenerCantidadProducto(widget.product.id);

        return Card(
          elevation: 3,
          color: cantidad > 0
              ? brownColorLight
              : (isDark ? colorScheme.surface : Colors.white),
          shadowColor: brownShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cantidad > 0 ? brownBorder : colorScheme.outline.withAlpha(20),
              width: cantidad > 0 ? 2 : 1,
            ),
          ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withAlpha(30),
        highlightColor: colorScheme.primary.withAlpha(15),
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badges superior (Categoría) - Color marrón fijo
              if (widget.product.categoria != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: brownColor.withAlpha(100),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: brownColor.withAlpha(150),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brownColor.withAlpha(30),
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

              // Imagen compacta
              Center(
                child: ProductImageWidget(product: widget.product, size: 70),
              ),
              const SizedBox(height: 4),

              // Nombre y detalles (compacto)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre en 1 línea, fuente más pequeña
                  Text(
                    widget.product.nombre,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.0,
                      letterSpacing: 0,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),

                  // SKU en una línea compacta
                  Text(
                    'SKU: ${widget.product.sku}',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 7,
                      color: colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.product.marca != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      widget.product.marca!.nombre,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 7,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Precio y acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Precio - Color marrón fijo
                  if (widget.product.precioVenta != null)
                    Flexible(
                      child: Text(
                        'Bs ${widget.product.precioVenta!.toStringAsFixed(2)}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: brownColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                  // Stock y botón/cantidad
                  if (canAddToCart) ...[
                    if (cantidad == 0)
                      ScaleTransition(
                        scale: _bounceAnimation,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              size: 14,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: brownColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: brownColor.withAlpha(40),
                              padding: EdgeInsets.zero,
                            ),
                            tooltip: 'Agregar',
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: brownColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: brownColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                onPressed: _decrementQuantity,
                                icon: const Icon(Icons.remove, size: 10),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  foregroundColor: brownColor,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 24,
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
                                    '$cantidad',
                                    key: ValueKey(cantidad),
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: brownColor,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                onPressed: _incrementQuantity,
                                icon: const Icon(Icons.add, size: 10),
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
                ],
              ),
            ],
          ),
        ),
      ));
        },
      );
  }
}
