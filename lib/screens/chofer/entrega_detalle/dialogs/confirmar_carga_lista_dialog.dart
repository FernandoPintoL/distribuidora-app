import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../extensions/theme_extension.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';

class ConfirmarCargaListaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider, {
    VoidCallback? onReload,
    Function(String)? onError,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            const Text('¿Toda la carga está lista para entrega?'),
            const SizedBox(height: 12),
            Text(
              'Se cambiar el estado a LISTO_PARA_ENTREGA y podrás iniciar el viaje.',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            if (entrega.numeroEntrega != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // color: context.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorScheme.secondary),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entrega',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "#${entrega.id}" ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
            style: TextButton.styleFrom(foregroundColor: Colors.black26),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.secondary,
            ),
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
            // ✅ Usar callback para mostrar error desde contexto válido
            final errorMsg = provider.errorMessage ?? 'Error desconocido';
            debugPrint('❌ [DIALOG] Mostrando error: $errorMsg');
            onError?.call(errorMsg);
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
