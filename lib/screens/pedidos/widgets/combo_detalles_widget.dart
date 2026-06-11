import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../config/config.dart';
import '../../../extensions/theme_extension.dart';

class ComboDetallesWidget extends StatelessWidget {
  final BuildContext parentContext;
  final CarritoItem item;

  const ComboDetallesWidget({
    super.key,
    required this.parentContext,
    required this.item,
  });

  String? _obtenerNombreComboItem(int comboItemId) {
    final comboItemsDelProducto = item.producto.comboItems ?? [];
    try {
      return comboItemsDelProducto
          .firstWhere((c) => c.id == comboItemId)
          .productoNombre;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comboItems = item.comboItemsSeleccionados ?? [];

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Componentes - ${item.cantidad} combo${item.cantidad > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: AppTextStyles.bodySmall(parentContext)
                          .fontSize!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Column(
              children: comboItems.asMap().entries.map((entry) {
                final index = entry.key;
                final comboItem = entry.value;
                final cantidadRaw = comboItem['cantidad'] ?? 1;
                final cantidad = cantidadRaw is int
                    ? cantidadRaw
                    : (cantidadRaw as num).toInt();
                final comboItemId = comboItem['combo_item_id'] ?? 0;
                final nombreProducto =
                    _obtenerNombreComboItem(comboItemId) ?? 'Producto';
                final isLast = index == comboItems.length - 1;
                final cantidadTotal = cantidad * item.cantidad;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: Colors.blue.shade100),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• $nombreProducto',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(parentContext)
                                    .fontSize!,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${comboItem['producto_id']}',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(parentContext)
                                    .fontSize!,
                                color: Colors.blue.shade600,
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
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${cantidadTotal}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: AppTextStyles.bodySmall(parentContext)
                                    .fontSize!,
                              ),
                            ),
                          ),
                          if (item.cantidad > 1)
                            Text(
                              '($cantidad×${item.cantidad})',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(parentContext)
                                    .fontSize!,
                                color: Colors.blue.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
