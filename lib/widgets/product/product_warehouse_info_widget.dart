import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/date_formatter.dart';

/// Widget que muestra la información de almacén, lote y vencimiento
class ProductWarehouseInfoWidget extends StatelessWidget {
  final Product product;

  const ProductWarehouseInfoWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    if (product.stockPrincipal == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWarehouseInfo(),
            if (product.stockPrincipal!.lote != null) _buildLoteInfo(),
            if (product.stockPrincipal!.fechaVencimiento != null)
              _buildExpiryInfo(),
          ],
        ),
      ],
    );
  }

  Widget _buildWarehouseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almacén',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          product.stockPrincipal!.almacenNombre ?? 'Principal',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoteInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Lote',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          product.stockPrincipal!.lote ?? 'N/A',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryInfo() {
    final expiryDate = product.stockPrincipal!.fechaVencimiento;
    final isExpiring = DateFormatter.isExpiringSoon(expiryDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Vencimiento',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          DateFormatter.format(expiryDate),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isExpiring ? Colors.orange : Colors.black,
          ),
        ),
      ],
    );
  }
}
