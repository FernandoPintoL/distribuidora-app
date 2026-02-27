import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../services/location_service.dart';

class MarcarLlegadaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar Llegada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('¿Confirmas que has llegado al destino?'),
            const SizedBox(height: 8),
            if (entrega.direccion != null)
              Text(
                entrega.direccion!,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar Llegada'),
          ),
        ],
      ),
    );

    if (resultado == true && context.mounted) {
      if (entrega.estado != 'EN_CAMINO') {
        debugPrint('⚠️ Estado incorrecto: ${entrega.estado}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La entrega debe estar EN_CAMINO. Estado actual: ${entrega.estadoLabel}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      try {
        debugPrint('📍 Obteniendo ubicación...');
        final locationService = LocationService();
        final position = await locationService.getCurrentLocationWithRetry(
          maxRetries: 3,
          retryDelay: const Duration(seconds: 1),
        );

        if (!context.mounted) return;

        if (position == null) {
          debugPrint('⚠️ No se pudo obtener la ubicación');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo obtener la ubicación. Verifica que el GPS esté habilitado.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        debugPrint('📤 Llamando API para marcar llegada...');
        final success = await provider.marcarLlegada(
          entrega.id,
          latitud: position.latitude,
          longitud: position.longitude,
        );

        if (!context.mounted) return;

        if (success) {
          debugPrint('✅ Llegada marcada correctamente');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Llegada marcada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await provider.obtenerEntrega(entrega.id);
        } else {
          debugPrint('❌ Error: ${provider.errorMessage}');
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
