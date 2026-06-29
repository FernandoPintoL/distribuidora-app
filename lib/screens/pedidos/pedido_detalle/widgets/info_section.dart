import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import 'info_row_widget.dart';

class InfoSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const InfoSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yy').format(fecha);
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
                'Información General',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              InfoRowWidget(
                icon: Icons.calendar_today,
                label: 'Fecha de creación',
                value: _formatearFecha(pedido.fechaCreacion),
                parentContext: parentContext,
              ),
              const SizedBox(height: 12),
              InfoRowWidget(
                icon: Icons.source,
                label: 'Canal de origen',
                value: pedido.canalOrigen,
                parentContext: parentContext,
              ),
              if (pedido.fechaAprobacion != null) ...[
                const SizedBox(height: 12),
                InfoRowWidget(
                  icon: Icons.check_circle,
                  label: 'Fecha de aprobación',
                  value: _formatearFecha(pedido.fechaAprobacion!),
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
