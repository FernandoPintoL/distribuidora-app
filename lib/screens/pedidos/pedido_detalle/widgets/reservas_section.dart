import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../extensions/theme_extension.dart';

class ReservasSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const ReservasSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(parentContext).colorScheme;
    final isDark = parentContext.isDark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reservas de Stock',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              ...pedido.reservas.map((reserva) {
                final isActiva = reserva.estado == EstadoReserva.ACTIVA;
                final estaVencida = reserva.estaVencida;

                Color bgColor;
                Color borderColor;
                Color statusColor;

                if (estaVencida) {
                  bgColor = colorScheme.error.withOpacity(isDark ? 0.15 : 0.1);
                  borderColor = colorScheme.error.withOpacity(0.3);
                  statusColor = colorScheme.error;
                } else if (isActiva) {
                  bgColor = Colors.green.withOpacity(
                    isDark ? 0.15 : 0.1,
                  );
                  borderColor = Colors.green.withOpacity(0.3);
                  statusColor = Colors.green;
                } else {
                  bgColor = colorScheme.surfaceContainerHighest.withOpacity(0.3);
                  borderColor = colorScheme.outline.withOpacity(0.2);
                  statusColor = colorScheme.onSurface.withOpacity(0.6);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.producto?.nombre ?? 'Producto',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cantidad: ${reserva.cantidad}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estaVencida
                              ? 'Vencida'
                              : 'Expira en: ${reserva.tiempoRestanteFormateado}',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              parentContext,
                            ).fontSize!,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
