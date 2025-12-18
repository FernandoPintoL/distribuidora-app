import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../models/entrega.dart';

/// Widget que muestra un timeline visual del progreso de una entrega
/// Displays states: ASIGNADA → EN_CAMINO → LLEGO → ENTREGADO
class EntregaTimeline extends StatelessWidget {
  final Entrega entrega;

  const EntregaTimeline({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final estados = _getEstadosProgresion();
    final currentEstadoIndex = _getCurrentEstadoIndex();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '📋 Estado de la Entrega',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estados.length,
              itemBuilder: (context, index) {
                final estadoInfo = estados[index];
                final isCompleted = index <= currentEstadoIndex;
                final isCurrent = index == currentEstadoIndex;

                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: index == 0,
                  isLast: index == estados.length - 1,
                  beforeLineStyle: LineStyle(
                    color: isCompleted ? Colors.green : Colors.grey[300]!,
                    thickness: 3,
                  ),
                  afterLineStyle: LineStyle(
                    color: (index < currentEstadoIndex)
                        ? Colors.green
                        : Colors.grey[300]!,
                    thickness: 3,
                  ),
                  startChild: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        estadoInfo['label'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  endChild: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.only(left: 16, right: 12, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Información del estado
                        if (estadoInfo['info'] != null)
                          Text(
                            estadoInfo['info'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        if (estadoInfo['info'] != null)
                          const SizedBox(height: 4),

                        // Fecha y hora
                        if (estadoInfo['fecha'] != null)
                          Text(
                            estadoInfo['fecha'] as String,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener orden de estados para esta entrega
  List<Map<String, dynamic>> _getEstadosProgresion() {
    return [
      {
        'estado': 'ASIGNADA',
        'label': 'Asignada',
        'icon': '📋',
        'info': 'Entrega asignada al chofer',
        'fecha': entrega.fechaAsignacion != null
            ? entrega.formatFecha(entrega.fechaAsignacion)
            : null,
      },
      {
        'estado': 'EN_CAMINO',
        'label': 'En Camino',
        'icon': '🚚',
        'info': 'El chofer se dirige hacia la dirección',
        'fecha': entrega.fechaInicio != null
            ? entrega.formatFecha(entrega.fechaInicio)
            : null,
      },
      {
        'estado': 'LLEGO',
        'label': 'Llegó',
        'icon': '🏁',
        'info': 'El chofer ha llegado al lugar de entrega',
        'fecha': null,
      },
      {
        'estado': 'ENTREGADO',
        'label': 'Entregado',
        'icon': '✅',
        'info': 'Entrega completada y confirmada',
        'fecha': entrega.fechaEntrega != null
            ? entrega.formatFecha(entrega.fechaEntrega)
            : null,
      },
    ];
  }

  /// Obtener índice del estado actual en la progresión
  int _getCurrentEstadoIndex() {
    const estadoOrder = ['ASIGNADA', 'EN_CAMINO', 'LLEGO', 'ENTREGADO'];
    int index = estadoOrder.indexOf(entrega.estado);
    return index >= 0 ? index : 0;
  }
}
