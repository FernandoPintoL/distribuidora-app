import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../extensions/theme_extension.dart';
import '../../config/app_colors.dart';
import '../product/product_card_base.dart';

/// Widget para mostrar un producto en vista de lista
class ProductListItem extends StatefulWidget {
  final Producto product;
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
    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
        );
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

  // ✅ NUEVO: Construir combo items (solo items obligatorios al agregar desde lista)
  List<Map<String, dynamic>>? _construirComboItemsObligatorios() {
    if (!widget.product.esCombo) return null;

    final items = widget.product.comboItems ?? [];
    final itemsObligatorios = items.where((i) => i.esObligatorio).toList();

    if (itemsObligatorios.isEmpty) return null;

    return itemsObligatorios
        .map(
          (i) => {
            'combo_item_id': i.id,
            'producto_id': i.productoId,
            'cantidad': i.cantidad,
          },
        )
        .toList();
  }

  void _incrementQuantity() {
    final stock = _getMainWarehouseStock();
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(
      widget.product.id,
    );

    if (cantidadActual < stock) {
      // Trigger bounce animation
      _bounceController.forward(from: 0.0);

      // ✅ ACTUALIZADO: Agregar combo con items obligatorios precargados
      carritoProvider.agregarProducto(
        widget.product,
        comboItemsSeleccionados: _construirComboItemsObligatorios(),
      );
      // ✅ NUEVO: Recalcular con rangos después de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();
    }
  }

  void _decrementQuantity() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(
      widget.product.id,
    );

    if (cantidadActual > 0) {
      // Decrementar del carrito (esto dispara notifyListeners en el provider)
      carritoProvider.decrementarCantidad(widget.product.id);
      // ✅ NUEVO: Recalcular con rangos después de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();
    }
  }

  // ✅ NUEVO: Método para actualizar cantidad desde TextField - Actualiza directamente al carrito
  void _actualizarCantidadDesdeInput(String valor) {
    final carritoProvider = context.read<CarritoProvider>();
    final stock = _getMainWarehouseStock();

    if (valor.isEmpty) {
      // Si está vacío, no hacer nada (permitir que el usuario borre)
      return;
    }

    final cantidadIngresada = int.tryParse(valor) ?? 0;

    // Validar que no exceda el stock
    if (cantidadIngresada <= 0) {
      // Si es 0 o negativo, no hacer nada
      return;
    }

    if (cantidadIngresada > stock) {
      // Si excede stock, ajustar al máximo disponible
      carritoProvider.actualizarCantidad(widget.product.id, stock);
      // ✅ NUEVO: Recalcular con rangos después de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();
      return;
    }

    // ✅ NUEVO: Actualizar cantidad directamente
    carritoProvider.actualizarCantidad(widget.product.id, cantidadIngresada);
    // ✅ NUEVO: Recalcular con rangos después de cambiar cantidad
    carritoProvider.calcularCarritoConRangos();
  }

  void _eliminarDelCarrito() {
    final carritoProvider = context.read<CarritoProvider>();
    carritoProvider.eliminarProducto(widget.product.id);
    carritoProvider.calcularCarritoConRangos();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final colorScheme = context.colorScheme;
        final isDark = context.isDark;
        final stock = _getMainWarehouseStock();
        final canAddToCart =
            widget.product.activo &&
            widget.product.precioVentaFinal > 0 &&
            (widget.product.esCombo || stock > 0);

        // ✅ NUEVO: Obtener cantidad actual del carrito (sincronizada globalmente)
        final _quantity = carritoProvider.obtenerCantidadProducto(
          widget.product.id,
        );

        // ✅ NUEVO: Obtener detalles con rango de precios
        final detalleConRango = carritoProvider.obtenerDetalleConRango(
          widget.product.id,
        );

        // Verificar si el usuario es preventista
        bool isPreventista = false;
        try {
          final authProvider = context.read<AuthProvider>();
          final userRoles = authProvider.user?.roles ?? [];
          isPreventista = userRoles.any(
            (role) => role.toLowerCase() == 'preventista',
          );
        } catch (e) {
          debugPrint('❌ Error al verificar rol en ProductListItem: $e');
        }

        // Obtener cantidad disponible
        final cantidadDisponible =
            widget.product.stockPrincipal?.cantidadDisponible != null
            ? (widget.product.stockPrincipal!.cantidadDisponible as num).toInt()
            : 0;

        // Color dorado secundario de AppColors
        final primaryAccentColor = AppColors.secondary;

        // Colores para estado seleccionado
        final isSelected = _quantity > 0;
        final selectedBgColor = AppColors.secondary.withAlpha(isDark ? 40 : 25);
        final selectedBorderColor = AppColors.secondary;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isSelected ? 6 : 4,
          shadowColor: isSelected
              ? AppColors.secondary.withAlpha(80)
              : Colors.black.withAlpha(30),
          color: isSelected
              ? selectedBgColor
              : (isDark ? colorScheme.surface : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? selectedBorderColor
                  : colorScheme.outline.withAlpha(20),
              width: isSelected ? 2 : 1,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Componente base: imagen, nombre, código, precio, subtotal y controles de cantidad
                  ProductCardBase(
                    product: widget.product,
                    quantity: _quantity,
                    detalleConRango: detalleConRango,
                    onProductTap: widget.onTap,
                    showDeleteButton: canAddToCart,
                    isInCart: _quantity > 0,
                    onDeletePressed: _eliminarDelCarrito,
                    onAddToCart: _incrementQuantity,
                    imageSize: 90,
                    onIncrement: _incrementQuantity,
                    onDecrement: _decrementQuantity,
                    onChanged: _actualizarCantidadDesdeInput,
                    maxQuantity: stock,
                    showQuantityControls: _quantity > 0,
                    cantidadDisponible: cantidadDisponible,
                    unidadMedida: widget.product.unidadMedida?.nombre,
                    isPreventista: isPreventista,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
