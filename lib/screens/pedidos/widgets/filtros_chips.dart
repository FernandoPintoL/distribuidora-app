import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_text_styles.dart';
import '../../../extensions/theme_extension.dart';

class FiltrosChips extends StatelessWidget {
  final String? filtroEstadoSeleccionado;
  final DateTime? filtroFechaDesde;
  final DateTime? filtroFechaHasta;
  final DateTime? filtroFechaVencimientoDesde;
  final DateTime? filtroFechaVencimientoHasta;
  final DateTime? filtroFechaEntregaSolicitadaDesde;
  final DateTime? filtroFechaEntregaSolicitadaHasta;
  final TextEditingController searchController;
  final VoidCallback? onEliminarEstado;
  final VoidCallback? onEliminarFechaCreacion;
  final VoidCallback? onEliminarFechaEntrega;
  final VoidCallback? onEliminarFechaVencimiento;
  final VoidCallback? onEliminarBusqueda;
  final VoidCallback? onCargarPedidos;

  const FiltrosChips({
    required this.filtroEstadoSeleccionado,
    required this.filtroFechaDesde,
    required this.filtroFechaHasta,
    required this.filtroFechaVencimientoDesde,
    required this.filtroFechaVencimientoHasta,
    required this.filtroFechaEntregaSolicitadaDesde,
    required this.filtroFechaEntregaSolicitadaHasta,
    required this.searchController,
    this.onEliminarEstado,
    this.onEliminarFechaCreacion,
    this.onEliminarFechaEntrega,
    this.onEliminarFechaVencimiento,
    this.onEliminarBusqueda,
    this.onCargarPedidos,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final chips = <Widget>[];

    if (filtroEstadoSeleccionado != null) {
      chips.add(
        Chip(
          label: Text(
            'Estado: $filtroEstadoSeleccionado',
            style: AppTextStyles.bodySmall(context),
          ),
          backgroundColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
          onDeleted: onEliminarEstado,
        ),
      );
    }

    if (filtroFechaDesde != null || filtroFechaHasta != null) {
      final desdeText = filtroFechaDesde != null
          ? DateFormat('dd/MM').format(filtroFechaDesde!)
          : '';
      final hastaText = filtroFechaHasta != null
          ? DateFormat('dd/MM').format(filtroFechaHasta!)
          : '';

      final texto = filtroFechaDesde != null && filtroFechaHasta != null
          ? desdeText == hastaText
              ? 'Creación: $desdeText'
              : 'Creación: $desdeText - $hastaText'
          : 'Creación';

      chips.add(
        Chip(
          label: Text(texto, style: AppTextStyles.bodySmall(context)),
          backgroundColor: Colors.green.withOpacity(0.2),
          labelStyle: TextStyle(color: Colors.green[700]),
          onDeleted: onEliminarFechaCreacion,
        ),
      );
    }

    if (filtroFechaEntregaSolicitadaDesde != null ||
        filtroFechaEntregaSolicitadaHasta != null) {
      final desdeText = filtroFechaEntregaSolicitadaDesde != null
          ? DateFormat('dd/MM').format(filtroFechaEntregaSolicitadaDesde!)
          : '';
      final hastaText = filtroFechaEntregaSolicitadaHasta != null
          ? DateFormat('dd/MM').format(filtroFechaEntregaSolicitadaHasta!)
          : '';

      final texto = filtroFechaEntregaSolicitadaDesde != null &&
              filtroFechaEntregaSolicitadaHasta != null
          ? desdeText == hastaText
              ? 'Entrega solicitada: $desdeText'
              : 'Entrega solicitada: $desdeText - $hastaText'
          : 'Entrega solicitada';

      chips.add(
        Chip(
          label: Text(texto, style: AppTextStyles.bodySmall(context)),
          backgroundColor: Colors.orange.withOpacity(0.2),
          labelStyle: TextStyle(color: Colors.orange[700]),
          onDeleted: onEliminarFechaEntrega,
        ),
      );
    }

    if (filtroFechaVencimientoDesde != null ||
        filtroFechaVencimientoHasta != null) {
      final desdeText = filtroFechaVencimientoDesde != null
          ? DateFormat('dd/MM').format(filtroFechaVencimientoDesde!)
          : '';
      final hastaText = filtroFechaVencimientoHasta != null
          ? DateFormat('dd/MM').format(filtroFechaVencimientoHasta!)
          : '';

      final texto = filtroFechaVencimientoDesde != null &&
              filtroFechaVencimientoHasta != null
          ? desdeText == hastaText
              ? 'Vencimiento: $desdeText'
              : 'Vencimiento: $desdeText - $hastaText'
          : 'Vencimiento';

      chips.add(
        Chip(
          label: Text(texto, style: AppTextStyles.bodySmall(context)),
          backgroundColor: Colors.red.withOpacity(0.2),
          labelStyle: TextStyle(color: Colors.red[700]),
          onDeleted: onEliminarFechaVencimiento,
        ),
      );
    }

    if (searchController.text.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            '"${searchController.text}"',
            style: AppTextStyles.bodySmall(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.blue.withOpacity(0.2),
          labelStyle: TextStyle(color: Colors.blue[700]),
          onDeleted: onEliminarBusqueda,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}
