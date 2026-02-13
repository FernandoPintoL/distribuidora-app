import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';

class IniciarEntregaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('¿Confirmas que deseas iniciar la entrega?'),
            const SizedBox(height: 12),
            Text(
              'Se cambiar el estado a EN_RUTA y se actualizarán los estados de las ventas.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (entrega.cliente != null) ...[
              const SizedBox(height: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.cliente!,
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
            child: const Text('Iniciar Entrega'),
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
        debugPrint('🚀 Iniciando entrega #${entrega.id}...');

        final success = await provider.iniciarEntrega(
          entrega.id,
          onSuccess: (mensaje) {
            debugPrint('✅ Entrega iniciada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
        );

        if (context.mounted) {
          Navigator.pop(context);

          if (success) {
            debugPrint('✅ Entrega iniciada correctamente');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '✅ Entrega iniciada correctamente.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            await provider.obtenerEntrega(entrega.id);
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
