import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../extensions/theme_extension.dart';
import '../../config/app_colors.dart';
import 'product_card_image_section.dart';
import 'product_card_price_section.dart';
import 'product_card_quantity_controls.dart';

/// Widget base compartido para mostrar información del producto (imagen, nombre, código, precio)
/// Se reutiliza en ProductListItem y CarritoItemCard
class ProductCardBase extends StatefulWidget {
  final Product product;
  final int quantity;
  final DetalleCarritoConRango? detalleConRango;
  final VoidCallback? onProductTap;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onAddToCart;
  final bool isInCart;
  final double imageSize;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Function(String)? onChanged;
  final int maxQuantity;
  final bool showQuantityControls;
  final int cantidadDisponible;
  final String? unidadMedida;
  final bool isPreventista;
  final bool showComboItems;
  final bool showImage;

  const ProductCardBase({
    super.key,
    required this.product,
    required this.quantity,
    this.detalleConRango,
    this.onProductTap,
    this.showDeleteButton = true,
    this.onDeletePressed,
    this.onAddToCart,
    this.isInCart = false,
    this.imageSize = 70,
    this.onIncrement,
    this.onDecrement,
    this.onChanged,
    this.maxQuantity = 0,
    this.showQuantityControls = true,
    this.cantidadDisponible = 0,
    this.unidadMedida,
    this.isPreventista = false,
    this.showComboItems = true,
    this.showImage = true,
  });

  @override
  State<ProductCardBase> createState() => _ProductCardBaseState();
}

class _ProductCardBaseState extends State<ProductCardBase> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Imagen + Nombre + Código + Botón eliminar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto con disponibilidad (solo si showImage es true)
            if (widget.showImage) ...[
              ProductCardImageSection(
                product: widget.product,
                imageSize: widget.imageSize,
                cantidadDisponible: widget.cantidadDisponible,
                unidadMedida: widget.unidadMedida,
                isPreventista: widget.isPreventista,
              ),
              const SizedBox(width: 12),
            ],

            // Nombre y código
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre clickeable
                  InkWell(
                    onTap: widget.onProductTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Text(
                      widget.product.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // SKU y Código
                  if (widget.product.sku != null &&
                      widget.product.sku!.isNotEmpty)
                    Text(
                      'SKU: ${widget.product.sku}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    )
                  else
                    Text(
                      'Código: ${widget.product.codigo}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ProductCardPriceSection(
                      product: widget.product,
                      quantity: widget.quantity,
                      detalleConRango: widget.detalleConRango,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Botón dinámico: Agregar o Eliminar del carrito
            if (widget.showDeleteButton)
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: widget.isInCart
                      ? widget.onDeletePressed
                      : widget.onAddToCart,
                  icon: Icon(
                    widget.isInCart
                        ? Icons.delete_outline
                        : Icons.add_shopping_cart,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.isInCart
                        ? Colors.red
                        : AppColors.secondary,
                  ),
                  tooltip: widget.isInCart ? 'Eliminar' : 'Agregar al carrito',
                ),
              ),
          ],
        ),

        // Sección de componentes del combo
        if (widget.showComboItems &&
            widget.product.esCombo &&
            widget.product.comboItems != null &&
            widget.product.comboItems!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Icon(CupertinoIcons.cube_box_fill, size: 16),
                const SizedBox(width: 6),
                Text(
                  'INCLUIDO EN COMBO',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...widget.product.comboItems!.asMap().entries.map((entry) {
            final index = entry.key;
            final comboItem = entry.value;
            final isLast = index == widget.product.comboItems!.length - 1;
            // Cantidad = cantidad del componente × cantidad del combo
            final cantidadFinal =
                (comboItem.cantidad *
                        (widget.quantity > 0 ? widget.quantity : 1))
                    .toInt();

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Row(
                children: [
                  // Imagen del producto combo
                  if (comboItem.producto?.imagenes != null &&
                      comboItem.producto!.imagenes!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.network(
                          comboItem.producto!.imagenes!
                              .firstWhere(
                                (img) => img.esPrincipal,
                                orElse: () =>
                                    comboItem.producto!.imagenes!.first,
                              )
                              .url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Información del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comboItem.productoNombre ??
                              comboItem.producto?.nombre ??
                              'Producto',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.amber.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (comboItem.producto?.sku != null)
                          Text(
                            comboItem.producto!.sku!.toUpperCase(),
                            style: TextStyle(color: Colors.amber.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Tipo de precio y precio unitario
                        if (comboItem.tipoPrecioNombre != null ||
                            comboItem.precioUnitario != null)
                          Row(
                            children: [
                              if (comboItem.tipoPrecioNombre != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    comboItem.tipoPrecioNombre!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9,
                                      color: Colors.amber.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (comboItem.tipoPrecioNombre != null &&
                                  comboItem.precioUnitario != null)
                                const SizedBox(width: 4),
                              if (comboItem.precioUnitario != null)
                                Text(
                                  'Bs ${comboItem.precioUnitario!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge de cantidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${cantidadFinal}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],

        // Controles de cantidad (full width)
        if (widget.showQuantityControls && widget.quantity > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: ProductCardQuantityControls(
                quantity: widget.quantity,
                maxQuantity: widget.maxQuantity,
                onIncrement: widget.onIncrement,
                onDecrement: widget.onDecrement,
                onChanged: widget.onChanged,
              ),
            ),
          ),
      ],
    );
  }
}
