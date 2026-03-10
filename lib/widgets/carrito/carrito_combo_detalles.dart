import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../models/carrito_item.dart';

class CarritoComboDetalles extends StatelessWidget {
  final CarritoItem item;

  const CarritoComboDetalles({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final comboItems = item.comboItemsSeleccionados ?? [];
    final comboItemsDelProducto = item.producto.comboItems ?? [];

    String? obtenerNombreComboItem(int comboItemId) {
      try {
        return comboItemsDelProducto
            .firstWhere((c) => c.id == comboItemId)
            .productoNombre;
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
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
                  color: Colors.amber.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Componentes - ${item.cantidad} combo${item.cantidad > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.amber.shade200)),
            ),
            child: Column(
              children: comboItems.asMap().entries.map((entry) {
                final index = entry.key;
                final comboItem = entry.value;
                // ✅ Convertir cantidad de forma segura (puede ser int o double)
                final cantidadRaw = comboItem['cantidad'] ?? 1;
                final cantidad = cantidadRaw is int
                    ? cantidadRaw
                    : (cantidadRaw as num).toInt();
                final comboItemId = comboItem['combo_item_id'] ?? 0;
                final nombreProducto =
                    obtenerNombreComboItem(comboItemId) ?? 'Producto';
                final isLast = index == comboItems.length - 1;

                // Mostrar cantidad total si el combo tiene cantidad > 1
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
                            bottom: BorderSide(color: Colors.amber.shade100),
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
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${comboItem['producto_id']}',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
                                color: Colors.amber.shade600,
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
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${cantidadTotal}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
                              ),
                            ),
                          ),
                          if (item.cantidad > 1)
                            Text(
                              '($cantidad×${item.cantidad})',
                              style: TextStyle(
                                fontSize: AppTextStyles.labelSmall(
                                  context,
                                ).fontSize!,
                                color: Colors.amber.shade600,
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
