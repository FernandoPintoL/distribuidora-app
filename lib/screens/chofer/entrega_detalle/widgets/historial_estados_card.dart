import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';

class HistorialEstadosCard extends StatelessWidget {
  final List<EntregaEstadoHistorial> estados;

  const HistorialEstadosCard({Key? key, required this.estados})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Estados',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estados.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final estado = estados[index];
                final bgColor = isDarkMode
                    ? Colors.blue[900]
                    : Colors.blue[100];
                final textColor = isDarkMode
                    ? Colors.blue[300]
                    : Colors.blue[900];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${estado.estadoAnterior} → ${estado.estadoNuevo}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estado.createdAt.toString(),
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),
                      if (estado.comentario != null &&
                          estado.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          estado.comentario!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
