import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/detalle_carrito_con_rango.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra la información del producto (nombre, SKU, marca, precio)
/// Adaptado para modo oscuro y con soporte para rangos de precios
class ProductInfoWidget extends StatelessWidget {
  final Product product;
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
    final tipoPrecionNombre = detalleConRango?.tipoPrecioNombre.toUpperCase() ?? '';
    final bool esDescuento = detalleConRango != null &&
        cantidad > 0 &&
        tipoPrecionNombre.contains('DESCUENTO');
    final bool esEspecial = detalleConRango != null &&
        cantidad > 0 &&
        tipoPrecionNombre.contains('ESPECIAL');
    final bool tieneDescuento = esDescuento || esEspecial;

    final precioActual = detalleConRango?.precioUnitario ?? product.precioVenta ?? 0.0;
    final subtotal = precioActual * cantidad;
    final precioOriginal = product.precioVenta ?? 0.0;

    // Colores para cada tipo de descuento
    final colorDescuento = esDescuento ? Colors.orange : (esEspecial ? Colors.green : colorScheme.primary);

    return Flexible(
      fit: FlexFit.loose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Text(
            product.nombre,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: isGridView ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ✅ Badge de COMBO (debajo del nombre)
          if (product.esCombo)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.shade700,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'COMBO',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 6),

          // SKU, Marca y Categoría en fila
          Row(
            children: [
              Flexible(
                child: Text(
                  'SKU: ${product.sku}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (product.marca != null) ...[
                const SizedBox(width: 6),
                Text('•', style: context.textTheme.bodySmall),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    product.marca!.nombre,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (product.categoria != null) ...[
                const SizedBox(width: 6),
                Text('•', style: context.textTheme.bodySmall),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    product.categoria!.nombre,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Unidad de medida
          if (product.unidadMedida != null)
            Text(
              'Unidad: ${product.unidadMedida!.nombre}',
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),

          // ✅ NUEVO: Precio con soporte para rangos y descuentos
          if (product.precioVenta != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar precio original tachado si hay descuento
                if (tieneDescuento)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Bs ${precioOriginal.toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),

                // Mostrar precio actual con color según tipo
                Row(
                  children: [
                    Text(
                      'Bs ${precioActual.toStringAsFixed(2)}',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: colorDescuento,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ✅ NUEVO: Mostrar tipo de precio si aplica rango
                    if (detalleConRango != null && cantidad > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorDescuento.withAlpha(100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            detalleConRango!.tipoPrecioNombre,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: esDescuento
                                  ? Colors.orange.shade900
                                  : (esEspecial ? Colors.green.shade900 : colorScheme.onPrimaryContainer),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ✅ NUEVO: Mostrar subtotal si hay cantidad
                if (cantidad > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Subtotal: Bs ${subtotal.toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
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
