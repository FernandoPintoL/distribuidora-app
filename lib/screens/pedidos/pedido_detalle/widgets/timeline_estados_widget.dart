import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../services/estados_helpers.dart';

class TimelineEstadosWidget extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;
  final Color Function(String) hexToColor;

  const TimelineEstadosWidget({
    super.key,
    required this.pedido,
    required this.parentContext,
    required this.hexToColor,
  });

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(parentContext).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Estados',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...pedido.historialEstados.asMap().entries.map((entry) {
            final index = entry.key;
            final historial = entry.value;
            final isFirst = index == 0;
            final isLast = index == pedido.historialEstados.length - 1;

            final colorHex = EstadosHelper.getEstadoColor(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );
            final estadoColor = hexToColor(colorHex);
            final estadoNombre = EstadosHelper.getEstadoLabel(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );
            final estadoIcon = EstadosHelper.getEstadoIcon(
              pedido.estadoCategoria,
              historial.estadoNuevo,
            );

            return TimelineTile(
              isFirst: isFirst,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 32,
                height: 32,
                indicator: Container(
                  decoration: BoxDecoration(
                    color: estadoColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    estadoIcon as IconData?,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: estadoColor.withOpacity(0.3),
                thickness: 2,
              ),
              endChild: Container(
                padding: const EdgeInsets.only(left: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estadoNombre,
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyLarge(parentContext).fontSize!,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(historial.fecha),
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(parentContext).fontSize!,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (historial.nombreUsuario != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Por: ${historial.nombreUsuario}',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(parentContext).fontSize!,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    if (historial.comentario != null &&
                        historial.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          historial.comentario!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
