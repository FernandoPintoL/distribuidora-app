import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../models/models.dart';
import 'combo_item_list.dart';

class CarritoComboDetalles extends StatelessWidget {
  final CarritoItem item;
  final Map<int, Product>? productosMap;

  const CarritoComboDetalles({
    super.key,
    required this.item,
    this.productosMap,
  });

  @override
  Widget build(BuildContext context) {
    final comboItems = item.comboItemsSeleccionados ?? [];

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
          _buildComboHeader(context),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.amber.shade200)),
            ),
            child: ComboItemList(
              comboItems: comboItems,
              comboCantidad: item.cantidad,
              comboItemsDelProducto: item.producto.comboItems,
              productosMap: productosMap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboHeader(BuildContext context) {
    return Padding(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
