import 'package:flutter/material.dart';
import '../../../models/models.dart';

class EntregaTimelineWidget {
  /// Construir timeline de entrega combinado (Entrega + Detalles en un único item)
  static List<Widget> buildTimelineItems(
    Pedido pedido,
    ColorScheme colorScheme,
    BuildContext ctx,
    Widget Function(ColorScheme) buildSeparator,
    Widget Function(
      BuildContext,
      String,
      ({Color color, String subtitle}),
      ColorScheme,
    )
    buildTimelineItem,
    ({Color color, String subtitle}) Function(Pedido) getLogisticaStatus,
    ({Color color, String subtitle}) Function(EntregaVentaConfirmacion)
    getConfirmacionStatusDetallado,
    bool Function(EntregaVentaConfirmacion) debeActualizarConfirmacion,
  ) {
    final items = <Widget>[];

    // ESTADO LOGÍSTICO / ENTREGAS
    if (pedido.tieneEstadoLogistico ||
        (pedido.venta?.confirmaciones.isNotEmpty ?? false)) {
      final logisticaStatus = getLogisticaStatus(pedido);
      final logisticaColor = logisticaStatus.color;
      final logisticaSubtitle = logisticaStatus.subtitle;

      // Obtener detalles de confirmación si existen
      String? detallesText;
      Color? detallesColor;

      if (pedido.venta?.confirmaciones.isNotEmpty ?? false) {
        final todasLasConfirmaciones = pedido.venta!.confirmaciones;
        debugPrint(
          '🔍 Timeline Pedido #${pedido.numero}: ${todasLasConfirmaciones.length} confirmaciones totales',
        );

        final confirmacionesFiltradas = todasLasConfirmaciones
            .where((c) => debeActualizarConfirmacion(c))
            .toList();

        debugPrint(
          '   ✅ ${confirmacionesFiltradas.length} confirmaciones filtradas',
        );

        if (confirmacionesFiltradas.isNotEmpty) {
          final ultimaConfirmacion = confirmacionesFiltradas.last;
          debugPrint(
            '   📍 Última confirmación: tipo_entrega=${ultimaConfirmacion.tipoEntrega}, tipo_confirmacion=${ultimaConfirmacion.tipoConfirmacion}',
          );

          final detallesStatus = getConfirmacionStatusDetallado(
            ultimaConfirmacion,
          );
          detallesText =
              '${ultimaConfirmacion.tipoEntrega} - ${ultimaConfirmacion.tipoConfirmacion}';
          detallesColor = detallesStatus.color;
        }
      }

      // Construir widget combinado
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: logisticaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: logisticaColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ENTREGA
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🚚 Entrega',
                      style: TextStyle(
                        color: logisticaColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      logisticaSubtitle,
                      style: TextStyle(
                        color: logisticaColor.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
                // DETALLES (si existen)
                if (detallesText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📋 Detalles:',
                        style: TextStyle(
                          color: detallesColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detallesText,
                        style: TextStyle(
                          color: detallesColor?.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return items;
  }
}
