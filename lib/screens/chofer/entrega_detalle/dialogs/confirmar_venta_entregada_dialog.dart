import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
import '../../../../providers/entrega_provider.dart';

class ConfirmarVentaEntregadaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    Venta venta,
    EntregaProvider provider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega de Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('¿Confirmas que la venta fue entregada?'),
            const SizedBox(height: 12),
            Text(
              'Se cambiar el estado a ENTREGADA.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (venta.clienteNombre != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.green[900]?.withOpacity(0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.green[700]! : Colors.green[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${venta.numero} - ${venta.clienteNombre}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue[900]?.withOpacity(0.3)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDarkMode ? Colors.blue[400] : Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nota: puedes detallar detalles de pago en observaciones',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Entrega'),
          ),
        ],
      ),
    );

    if (resultado == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        debugPrint('✅ Confirmando venta #${venta.id} como entregada...');

        final success = await provider.confirmarVentaEntregada(
          entrega.id,
          venta.id,
          onSuccess: (mensaje) {
            debugPrint('✅ Venta entregada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
        );

        if (context.mounted) {
          Navigator.pop(context);

          if (success) {
            debugPrint('✅ Venta entregada correctamente');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '✅ Venta entregada correctamente.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: ${provider.errorMessage ?? 'Error desconocido'}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Excepción: $e');
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
