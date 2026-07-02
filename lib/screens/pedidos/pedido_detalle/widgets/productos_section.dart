import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import '../../../shared/widgets/index.dart'; // NUEVO: ProductoCardWidget

class ProductosSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const ProductosSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Productos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...pedido.detalles.map(
            (item) => ProductoCardWidget(
              imagenUrl: item.producto?.imagenPrincipal?.url,
              nombreProducto: item.producto?.nombre,
              cantidad: item.cantidad.toDouble(),
              precioUnitario: item.precioUnitario,
              subtotal: item.subtotal,
              mostrarAvatarWidget: false,
              comboItemsSeleccionados: item.comboItemsSeleccionados,
              comboItems: item.producto?.comboItems,
              parentContext: parentContext,
            ),
          ),
        ],
      ),
    );
  }
}
