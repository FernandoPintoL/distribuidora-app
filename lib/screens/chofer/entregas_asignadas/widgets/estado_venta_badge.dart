import 'package:flutter/material.dart';
import '../../../../services/estados_helpers.dart';

class EstadoVentaBadge extends StatelessWidget {
  final int? estadoLogisticoId;
  final String? estadoLogisticoCodigo;
  final String? estadoLogisticoColor;
  final String? estadoLogisticoIcon;
  final bool isDarkMode;

  const EstadoVentaBadge({
    Key? key,
    required this.estadoLogisticoId,
    required this.estadoLogisticoCodigo,
    required this.estadoLogisticoColor,
    required this.estadoLogisticoIcon,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar directamente los datos del backend si están disponibles
    String nombre = estadoLogisticoCodigo ?? 'Desconocido';
    String icono = estadoLogisticoIcon ?? '📦';
    String colorHex = estadoLogisticoColor ?? '#000000';

    // Si no tenemos color/icon del backend, intentar buscar en el caché
    if ((estadoLogisticoColor == null || estadoLogisticoIcon == null) &&
        estadoLogisticoId != null) {
      final id = estadoLogisticoId!;
      final estado = EstadosHelper.getEstadoPorId(
        'venta_logistica',
        id,
      );
      if (estado != null) {
        nombre = estado.nombre;
        icono = estado.icono ?? '📦';
        colorHex = estado.color;
      }
    }

    // Convertir color hex a Color
    final color = Color(EstadosHelper.colorHexToInt(colorHex));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icono, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            nombre,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
