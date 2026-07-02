import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/detalle_carrito_con_rango.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra la información del producto (nombre, SKU, marca, precio)
/// Adaptado para modo oscuro y con soporte para rangos de precios
class ProductInfoWidget extends StatelessWidget {
  final Producto product;
  final bool isGridView;
  final int cantidad;
  final DetalleCarritoConRango? detalleConRango;

  const ProductInfoWidget({
    super.key,
    required this.product,
    this.isGridView = false,
    this.cantidad = 0,
    this.detalleConRango,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    // ✅ NUEVO: Calcular descuentos y precios
    final tipoPrecionNombre =
        detalleConRango?.tipoPrecioNombre.toUpperCase() ?? '';
    final bool esDescuento =
        detalleConRango != null &&
        cantidad > 0 &&
        tipoPrecionNombre.contains('DESCUENTO');
    final bool esEspecial =
        detalleConRango != null &&
        cantidad > 0 &&
        tipoPrecionNombre.contains('ESPECIAL');
    final bool tieneDescuento = esDescuento || esEspecial;

    final precioActual =
        detalleConRango?.precioUnitario ?? product.precioVenta ?? 0.0;
    final subtotal = precioActual * cantidad;
    final precioOriginal = product.precioVenta ?? 0.0;

    // Colores para cada tipo de descuento
    final colorDescuento = esDescuento
        ? Colors.orange
        : (esEspecial
              ? Colors.green
              : isDark
              ? Colors.white
              : colorScheme.primary);

    return Flexible(
      fit: FlexFit.loose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Text(
            product.nombre,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: isGridView ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ✅ Badge de COMBO (debajo del nombre)
          Text(
            'SKU: ${product.sku}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // SKU, Marca y Categoría en fila
          if (product.esCombo)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      'COMBO',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),

          // ✅ NUEVO: Precio con soporte para rangos y descuentos
          if (product.precioVenta != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NUEVO: Mostrar tipo de precio si aplica rango
                    if (detalleConRango != null && cantidad > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorDescuento.withAlpha(100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          detalleConRango!.tipoPrecioNombre,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: esDescuento
                                ? Colors.orange
                                : (esEspecial
                                      ? Colors.green
                                      : colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                    // Mostrar precio actual con color según tipo
                    Row(
                      children: [
                        // Mostrar precio original tachado si hay descuento
                        if (tieneDescuento)
                          Text(
                            'Bs ${precioOriginal.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          'Bs ${precioActual.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colorDescuento,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
                // ✅ NUEVO: Mostrar subtotal si hay cantidad
                if (cantidad > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Sub.: Bs ${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorDescuento,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
