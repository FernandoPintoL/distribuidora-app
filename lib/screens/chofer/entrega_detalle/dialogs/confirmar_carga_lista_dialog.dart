import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';

class ConfirmarCargaListaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider, {
    VoidCallback? onReload,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text('¿Toda la carga está lista para entrega?'),
            const SizedBox(height: 12),
            Text(
              'Se cambiar el estado a LISTO_PARA_ENTREGA y podrás iniciar el viaje.',
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize!,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (entrega.numeroEntrega != null) ...[
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
                      'Entrega',
                      style: TextStyle(
                        fontSize: AppTextStyles.labelSmall(context).fontSize!,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.numeroEntrega ?? 'N/A',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmar Carga'),
          ),
        ],
      ),
    );

    if (resultado == true && context.mounted) {
      try {
        debugPrint('📦 Confirmando carga lista para entrega #${entrega.id}...');

        final success = await provider.confirmarCargaLista(
          entrega.id,
          onSuccess: (mensaje) {
            debugPrint('✅ Carga confirmada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
        );

        if (success) {
          debugPrint('✅ Carga confirmada correctamente');

          // ✅ Recargar entrega completa CON reinicio de isLoading
          await provider.obtenerEntrega(entrega.id);

          debugPrint('✅ Datos de entrega actualizados');
        }

        // ✅ Mostrar mensaje al usuario
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '✅ Carga confirmada. Listo para iniciar entrega.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            onReload?.call();
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
