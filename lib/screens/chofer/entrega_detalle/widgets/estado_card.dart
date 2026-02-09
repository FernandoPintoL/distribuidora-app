import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../constants/estado_colors.dart';

class EstadoCard extends StatelessWidget {
  final Entrega entrega;

  const EstadoCard({Key? key, required this.entrega}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EstadoColors.getColorForEstado(
            entrega.estado,
            entrega.estadoEntregaColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado Actual',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(entrega.estadoIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
