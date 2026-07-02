import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../config/app_colors.dart';
import '../../../extensions/theme_extension.dart';
import '../../../screens/ventas/venta_detalle/producto_avatar_widget.dart';
import '../../../models/combo_item_seleccionado.dart';
import '../../../models/product.dart';

class ProductoCardWidget extends StatelessWidget {
  final String? imagenUrl;
  final String? nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final bool mostrarAvatarWidget;
  final List<ComboItemSeleccionado>? comboItemsSeleccionados;
  final List<ComboItem>? comboItems;
  final BuildContext? parentContext;

  const ProductoCardWidget({
    super.key,
    required this.imagenUrl,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.mostrarAvatarWidget = true,
    this.comboItemsSeleccionados,
    this.comboItems,
    this.parentContext,
  });

  ComboItem? _obtenerComboItem(int comboItemId) {
    if (comboItems == null || comboItems!.isEmpty) {
      return null;
    }
    try {
      return comboItems!.firstWhere((c) => c.id == comboItemId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagen = imagenUrl != null && imagenUrl!.isNotEmpty;
    final tieneCombo =
        comboItemsSeleccionados != null && comboItemsSeleccionados!.isNotEmpty;
    final ctx = parentContext ?? context;
    final isDark = ctx.isDark;
    final colorScheme = Theme.of(ctx).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(30),
      color: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withAlpha(20), width: 1),
      ),
      child: Column(
        children: [
          // SECCIÓN 1: Producto principal
          InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: colorScheme.primary.withAlpha(30),
            highlightColor: colorScheme.primary.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tieneImagen && mostrarAvatarWidget)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ProductoAvatarWidget(
                        imageUrl: imagenUrl!,
                        nombreProducto: nombreProducto,
                        radius: 28,
                      ),
                    )
                  else if (tieneImagen)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagenUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nombreProducto ?? 'Producto desconocido',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('x${cantidad.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Bs. ${precioUnitario.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Sub.: Bs. ${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.greenAccent
                                      : Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SECCIÓN 2: Componentes del combo
          if (tieneCombo) ...[
            Divider(height: 1, color: colorScheme.outline.withAlpha(40)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Componentes - ${cantidad.toInt()} combo${cantidad > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...comboItemsSeleccionados!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final comboItemSel = entry.value;
                    final comboItem = _obtenerComboItem(
                      comboItemSel.comboItemId,
                    );
                    final isLast = index == comboItemsSeleccionados!.length - 1;
                    final cantidadTotal =
                        comboItemSel.cantidad * cantidad.toInt();

                    final nombreProducto =
                        comboItem?.producto?.nombre ?? 'Producto desconocido';
                    final imagenUrl = comboItem?.producto?.imagenPrincipal?.url;
                    final tieneImagen =
                        imagenUrl != null && imagenUrl.isNotEmpty;
                    final sku = comboItem?.producto?.sku ?? 'N/A';

                    return Column(
                      children: [
                        Row(
                          children: [
                            if (tieneImagen)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    imagenUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withAlpha(
                                          30,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 24,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreProducto,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${comboItemSel.comboItemId}',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'SKU: $sku',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${cantidadTotal}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                                if (cantidad > 1)
                                  Text(
                                    '(${comboItemSel.cantidad}×${cantidad.toInt()})',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (!isLast) ...[
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: AppColors.secondary.withAlpha(20),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
