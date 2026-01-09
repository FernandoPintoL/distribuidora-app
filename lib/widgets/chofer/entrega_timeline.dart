import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../models/entrega.dart';

/// Widget que muestra un timeline visual del progreso de una entrega
/// Displays states: ASIGNADA → EN_CAMINO/EN_TRANSITO → LLEGO → ENTREGADO (sincronizado con BD)
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

                debugPrint('[TIMELINE] Estado ${estadoInfo['codigo']}: index=$index, current=$currentEstadoIndex, isCurrent=$isCurrent');

                return TimelineTile(
                  alignment: TimelineAlign.center,
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
  /// Sincronizado con estados reales de la BD (tabla estados_logistica)
  /// Incluye estados de preparación, carga y transito
  List<Map<String, dynamic>> _getEstadosProgresion() {
    return [
      {
        'codigo': 'PROGRAMADO',
        'label': 'Programada',
        'icon': '📅',
        'info': 'Entrega programada',
        'fecha': entrega.fechaAsignacion != null
            ? entrega.formatFecha(entrega.fechaAsignacion)
            : null,
      },
      {
        'codigo': 'PREPARACION_CARGA',
        'label': 'Preparación',
        'icon': '📦',
        'info': 'Preparando la carga en almacén',
        'fecha': null,
      },
      {
        'codigo': 'EN_CARGA',
        'label': 'En Carga',
        'icon': '⚙️',
        'info': 'Cargando productos al vehículo',
        'fecha': null,
      },
      {
        'codigo': 'LISTO_PARA_ENTREGA',
        'label': 'Listo para Entrega',
        'icon': '✓',
        'info': 'Carga completada, listo para salir',
        'fecha': null,
      },
      {
        'codigo': 'EN_TRANSITO',
        'label': 'En Tránsito',
        'icon': '🚚',
        'info': 'El chofer se dirige hacia la entrega',
        'fecha': entrega.fechaInicio != null
            ? entrega.formatFecha(entrega.fechaInicio)
            : null,
      },
      {
        'codigo': 'LLEGO',
        'label': 'Llegó',
        'icon': '🏁',
        'info': 'El chofer ha llegado al lugar de entrega',
        'fecha': null,
      },
      {
        'codigo': 'ENTREGADO',
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
  /// Usa el código de estado dinámico desde tabla estados_logistica
  int _getCurrentEstadoIndex() {
    const estadoOrder = ['PROGRAMADO', 'PREPARACION_CARGA', 'EN_CARGA', 'LISTO_PARA_ENTREGA', 'EN_TRANSITO', 'LLEGO', 'ENTREGADO'];

    // Usar estadoEntregaCodigo (desde tabla estados_logistica) si disponible
    // Fallback al ENUM legacy si no está disponible
    String estadoActual = entrega.estadoEntregaCodigo ?? entrega.estado;

    // Mapeo compatible con ENUM legacy para retrocompatibilidad
    final mapeoLegacy = {
      'ASIGNADA': 'PROGRAMADO',
      'EN_CAMINO': 'EN_TRANSITO',
      'LLEGO': 'LLEGO',
      'ENTREGADO': 'ENTREGADO',
    };

    estadoActual = mapeoLegacy[estadoActual] ?? estadoActual;

    int index = estadoOrder.indexOf(estadoActual);
    return index >= 0 ? index : 0;
  }
}
