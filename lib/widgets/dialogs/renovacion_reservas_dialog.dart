import 'package:flutter/material.dart';

class RenovacionReservasDialog extends StatefulWidget {
  final String proformaNumero;
  final int reservasExpiradas;
  final VoidCallback onRenovar;
  final VoidCallback onCancelar;
  final bool isLoading;

  const RenovacionReservasDialog({
    Key? key,
    required this.proformaNumero,
    required this.reservasExpiradas,
    required this.onRenovar,
    required this.onCancelar,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<RenovacionReservasDialog> createState() =>
      _RenovacionReservasDialogState();
}

class _RenovacionReservasDialogState extends State<RenovacionReservasDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.amber),
          SizedBox(width: 8),
          Text('Reservas Expiradas'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Las reservas de la proforma ${widget.proformaNumero} han expirado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.reservasExpiradas} reserva(s) necesitan renovación.\n\n'
              'Renovar extenderá las reservas por 7 días más con los mismos productos y cantidades.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : widget.onCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onRenovar,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(widget.isLoading ? 'Renovando...' : 'Renovar Reservas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
