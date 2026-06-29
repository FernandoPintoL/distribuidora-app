import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../services/estados_helpers.dart';

class HeaderWidget extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;
  final Color Function(String) hexToColor;

  const HeaderWidget({
    super.key,
    required this.pedido,
    required this.parentContext,
    required this.hexToColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorHex = EstadosHelper.getEstadoColor(
      pedido.estadoCategoria,
      pedido.estadoCodigo,
    );
    final estadoColor = hexToColor(colorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: estadoColor.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pedido.numero,
            style: TextStyle(
              fontSize: AppTextStyles.displaySmall(parentContext).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  EstadosHelper.getEstadoIcon(
                    pedido.estadoCategoria,
                    pedido.estadoCodigo,
                  ),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  pedido.estadoNombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: AppTextStyles.bodyLarge(parentContext).fontSize!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
