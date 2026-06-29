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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha Programada',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              InfoRowWidget(
                icon: Icons.event,
                label: 'Fecha',
                value: _formatearSoloFecha(pedido.fechaProgramada!),
                parentContext: parentContext,
              ),
              if (pedido.horaInicioPreferida != null ||
                  pedido.horaFinPreferida != null) ...[
                const SizedBox(height: 12),
                InfoRowWidget(
                  icon: Icons.access_time,
                  label: 'Horario',
                  value: '${pedido.horaInicioPreferida != null ? DateFormat('HH:mm').format(pedido.horaInicioPreferida!) : '--:--'} - ${pedido.horaFinPreferida != null ? DateFormat('HH:mm').format(pedido.horaFinPreferida!) : '--:--'}',
                  parentContext: parentContext,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
