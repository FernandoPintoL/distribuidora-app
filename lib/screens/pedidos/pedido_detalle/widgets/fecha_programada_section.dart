import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import 'info_row_widget.dart';

class FechaProgramadaSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const FechaProgramadaSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  String _formatearSoloFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Fecha y Hora
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InfoRowWidget(
                    icon: Icons.event,
                    label: 'Entrega Solicitada',
                    value: _formatearSoloFecha(pedido.fechaEntregaSolicitada!),
                    parentContext: parentContext,
                    colorIcon: colorScheme.tertiary,
                    colorText: colorScheme.tertiary,
                  ),
                ),
                if (pedido.horaEntregaSolicitada != null) ...[
                  Flexible(
                    child: InfoRowWidget(
                      icon: Icons.access_time,
                      label: 'Hora Solicitada',
                      value: pedido.horaEntregaSolicitada ?? '--:--',
                      parentContext: parentContext,
                      colorIcon: colorScheme.tertiary,
                      colorText: colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoLogistico estado) {
    Color badgeColor = Colors.grey;
    if (estado.color != null) {
      try {
        final hex = estado.color!.replaceFirst('#', '');
        badgeColor = Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        debugPrint('⚠️ Error al parsear color: ${estado.color}');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono del estado (si existe)
          if (estado.icono != null) ...[
            Text(estado.icono!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
          ],
          // Nombre del estado
          Flexible(
            child: Text(
              estado.nombre,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
