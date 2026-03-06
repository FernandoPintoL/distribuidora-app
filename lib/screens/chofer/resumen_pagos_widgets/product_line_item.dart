import 'package:flutter/material.dart';

/// Widget para mostrar un producto con cantidad, precio unitario y subtotal
class ProductLineItem extends StatelessWidget {
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final bool isDarkMode;
  final Color subtotalColor;
  final TextStyle? nameStyle;
  final TextStyle? detailStyle;
  final TextStyle? subtotalStyle;

  const ProductLineItem({
    Key? key,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.isDarkMode,
    this.subtotalColor = Colors.red,
    this.nameStyle,
    this.detailStyle,
    this.subtotalStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style:
                      nameStyle ??
                      TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.grey[50] : Colors.grey[900],
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Cant: $quantity × Bs. ${unitPrice.toStringAsFixed(2)}',
                  style:
                      detailStyle ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
          Text(
            'Bs. ${subtotal.toStringAsFixed(2)}',
            style:
                subtotalStyle ??
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: subtotalColor,
                ),
          ),
        ],
      ),
    );
  }
}
