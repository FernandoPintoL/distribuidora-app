import 'package:flutter/material.dart';
import '../../utils/stock_status.dart';

/// Widget que muestra el badge de estado de stock
class ProductStockBadgeWidget extends StatelessWidget {
  final int stock;
  final StockStatus status;

  const ProductStockBadgeWidget({
    super.key,
    required this.stock,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundWithOpacity,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            '$stock',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
