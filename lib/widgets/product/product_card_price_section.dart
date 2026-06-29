import 'package:flutter/material.dart';
import '../../models/models.dart';

class ProductCardPriceSection extends StatelessWidget {
  final Product product;
  final int quantity;
  final DetalleCarritoConRango? detalleConRango;

  const ProductCardPriceSection({
    super.key,
    required this.product,
    required this.quantity,
    this.detalleConRango,
  });

  @override
  Widget build(BuildContext context) {
    final precioActual = product.precioVentaFinal;
    final precioBajoRango = detalleConRango?.precioUnitario ?? precioActual;

    final cambioDePrecio =
        detalleConRango != null &&
        detalleConRango!.tipoPrecioId != 2 &&
        precioBajoRango != precioActual;

    final precioUnitarioFinal = cambioDePrecio ? precioBajoRango : precioActual;
    final subtotal = quantity * precioUnitarioFinal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precio unitario
        if (!cambioDePrecio)
          Column(
            children: [
              if (detalleConRango != null && detalleConRango!.tipoPrecioId != 2)
                _buildTipoPrecioBadge(detalleConRango!.tipoPrecioNombre),
              const SizedBox(height: 2),
              Text('Bs ${precioActual.toStringAsFixed(2)} c/u'),
            ],
          )
        else
          Column(
            children: [
              _buildTipoPrecioBadge(detalleConRango!.tipoPrecioNombre),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bs ${precioActual.toStringAsFixed(2)}',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.red.shade500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Bs ${precioBajoRango.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

        // Subtotal cuando hay cantidad
        if (quantity > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Subtotal: Bs ${subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber.shade300
                  : Colors.amber.shade700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTipoPrecioBadge(String tipoPrecioNombre) {
    final colorMap = {
      'Precio de Venta': Colors.blue,
      'P. Descuento': Colors.green,
      'P. Especial': Colors.orange,
      'Descuento': Colors.green,
      'Especial': Colors.orange,
    };

    final color = colorMap.entries
        .firstWhere(
          (e) => tipoPrecioNombre.contains(e.key),
          orElse: () => const MapEntry('default', Colors.blue),
        )
        .value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade600,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipoPrecioNombre,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
