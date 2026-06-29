import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../extensions/carrito_theme_extension.dart';
import '../../extensions/theme_extension.dart';
import '../../config/app_colors.dart';
import '../product/product_card_base.dart';

class CarritoItemCard extends StatefulWidget {
  final CarritoItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final Function(int) onUpdateCantidad;
  final DetalleCarritoConRango? detalleConRango;
  final VoidCallback? onAgregarParaAhorrar;
  final VoidCallback? onProductoTap;
  final bool isPreventista;
  final bool showDeleteButton;
  final bool showQuantityControls;

  const CarritoItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateCantidad,
    this.detalleConRango,
    this.onAgregarParaAhorrar,
    this.onProductoTap,
    this.isPreventista = false,
    this.showDeleteButton = true,
    this.showQuantityControls = true,
  });

  @override
  State<CarritoItemCard> createState() => _CarritoItemCardState();
}

class _CarritoItemCardState extends State<CarritoItemCard> {
  @override
  Widget build(BuildContext context) {
    final producto = widget.item.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispInt = (stockDisponible as num).toInt();
    final tieneStockSuficiente = widget.item.cantidad <= stockDispInt;
    final excedido = widget.item.cantidadExcedida;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryAccentColor = AppColors.secondary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(30),
      color: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: excedido > 0
              ? AppColors.error
              : colorScheme.outline.withAlpha(20),
          width: excedido > 0 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Componente base: imagen, nombre, código, precio, subtotal y controles de cantidad
            ProductCardBase(
              product: producto,
              quantity: widget.item.cantidad,
              detalleConRango: widget.detalleConRango,
              onProductTap: widget.onProductoTap,
              showDeleteButton: widget.showDeleteButton,
              isInCart: true,
              onDeletePressed: widget.onRemove,
              imageSize: 90,
              onIncrement: widget.onIncrement,
              onDecrement: widget.onDecrement,
              onChanged: (valor) {
                final cantidad = int.tryParse(valor) ?? 0;
                widget.onUpdateCantidad(cantidad);
              },
              maxQuantity: stockDispInt,
              showQuantityControls: widget.showQuantityControls,
              cantidadDisponible: stockDispInt,
              unidadMedida: producto.unidadMedida?.nombre,
              isPreventista: widget.isPreventista,
            ),

            const SizedBox(height: 12),

            // Línea compacta de ahorro
            if (widget.detalleConRango?.tieneOportunidadAhorro ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '💚 Ahorro: Bs ${widget.detalleConRango!.ahorroProximo!.toStringAsFixed(2)} | Agrega ${widget.detalleConRango!.proximoRango!.faltaCantidad}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          onPressed: widget.onAgregarParaAhorrar,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text(
                            'Añadir',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
