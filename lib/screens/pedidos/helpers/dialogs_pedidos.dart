import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';

/// ✅ NUEVO: Helper para mostrar diálogo de anulación de proforma
void mostrarDialogoAnularProforma(BuildContext context, Pedido proforma) {
  final TextEditingController motivoController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Anular Proforma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Estás seguro que deseas anular la proforma #${proforma.numero}?',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: motivoController,
            decoration: InputDecoration(
              hintText: 'Motivo de anulación (requerido)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.info_outlined),
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final motivo = motivoController.text.trim();

            if (motivo.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El motivo de anulación es requerido'),
                ),
              );
              return;
            }

            Navigator.pop(dialogContext);

            final pedidoProvider = context.read<PedidoProvider>();
            final result = await pedidoProvider.anularProforma(
              proforma.id,
              motivo,
            );

            // ✅ No mostrar snackbar en caso de éxito
            // La notificación nativa será mostrada por el listener de WebSocket
            if (!result) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: ${pedidoProvider.errorMessage ?? "No se pudo anular la proforma"}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Anular'),
        ),
      ],
    ),
  );
}
