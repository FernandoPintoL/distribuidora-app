import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';

class ReportarNovedadDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    final motivoController = TextEditingController();
    final descripcionController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Novedad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo *',
                  hintText: 'Ej: Cliente ausente, Dirección incorrecta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Detalles adicionales...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: motivoController.text.isEmpty
                ? null
                : () {
                    Navigator.pop(context, true);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reportar'),
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
        final success = await provider.reportarNovedad(
          entrega.id,
          motivo: motivoController.text,
          descripcion: descripcionController.text.isNotEmpty
              ? descripcionController.text
              : null,
        );

        if (context.mounted) {
          Navigator.pop(context);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Novedad reportada correctamente'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            await provider.obtenerEntrega(entrega.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${provider.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        motivoController.dispose();
        descripcionController.dispose();
      }
    } else {
      motivoController.dispose();
      descripcionController.dispose();
    }
  }
}
