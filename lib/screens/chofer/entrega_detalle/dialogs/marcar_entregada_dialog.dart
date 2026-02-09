import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';

class MarcarEntregadaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar Carga como Entregada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('¿Confirmas que has entregado la carga?'),
            const SizedBox(height: 8),
            if (entrega.cliente != null)
              Text(
                'Cliente: ${entrega.cliente!}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Marcando entrega...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      try {
        debugPrint('🚀 Marcando carga #${entrega.id} como entregada...');

        final success = await provider.marcarCargaEntregada(entrega.id);

        if (context.mounted) {
          Navigator.pop(context);

          if (success) {
            debugPrint('✅ Carga marcada como entregada correctamente');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Carga marcada como entregada correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
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
