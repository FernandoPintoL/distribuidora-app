import 'package:flutter/material.dart';
import 'package:distribuidora/config/app_text_styles.dart';
import 'package:distribuidora/models/venta.dart';

/// ✅ Widget Stateless para mostrar detalles de la venta
class VentaDetallesCard extends StatelessWidget {
  final Venta venta;
  final bool isDarkMode;

  const VentaDetallesCard({
    Key? key,
    required this.venta,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue[900]!.withOpacity(0.2)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.blue[700]!.withOpacity(0.5)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente
          _buildDetailRow(
            context,
            'Cliente:',
            venta.cliente?.nombre ?? 'Sin nombre',
          ),
          const SizedBox(height: 8),
          // Tipo Pago
          _buildDetailRow(
            context,
            'Tipo Pago:',
            venta.tipoPago?.nombre ?? 'Sin nombre',
          ),
          const SizedBox(height: 8),
          // Total (destacado)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDarkMode
                      ? Colors.blue[700]!.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.2),
                ),
                bottom: BorderSide(
                  color: isDarkMode
                      ? Colors.blue[700]!.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de la Venta:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                Text(
                  'Bs. ${venta.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
