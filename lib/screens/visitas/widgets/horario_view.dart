import 'package:flutter/material.dart';
import '../../../config/config.dart';
import '../../../models/orden_del_dia.dart';

/// Timeline vertical mostrando clientes por horario (estilo Gantt)
class HorarioView extends StatelessWidget {
  final OrdenDelDia ordenDelDia;
  final Function(ClienteOrdenDelDia cliente) onClienteTap;

  const HorarioView({
    super.key,
    required this.ordenDelDia,
    required this.onClienteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Obtener rango de horas (de 6:00 AM a 8:00 PM)
    final startHour = 6;
    final endHour = 20;
    final horasDisponibles = List.generate(endHour - startHour + 1, (i) => startHour + i);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 📋 Header
          Container(
            decoration: BoxDecoration(gradient: AppGradients.teal),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronograma de Visitas',
                  style: AppTextStyles.headlineSmall(context).copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ordenDelDia.diaSemana} - ${ordenDelDia.fecha}',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 🕒 Timeline
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: horasDisponibles.map((hour) {
                final horaStr = '${hour.toString().padLeft(2, '0')}:00';
                final clientesEnHora = _getClientesEnHora(hour);
                final tieneClientes = clientesEnHora.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hora
                      Text(
                        horaStr,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Clientes en esta hora
                      if (tieneClientes)
                        Column(
                          children: clientesEnHora.map((cliente) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildClienteBloque(
                                context,
                                cliente,
                                colorScheme,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sin visitas programadas',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      // Divisor
                      const Divider(height: 24),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtener clientes cuya ventana de entrega incluye la hora indicada
  List<ClienteOrdenDelDia> _getClientesEnHora(int hour) {
    return ordenDelDia.clientes.where((cliente) {
      final horaInicio = cliente.ventanaHoraria.horaInicio;
      final horaFin = cliente.ventanaHoraria.horaFin;

      if (horaInicio == null || horaFin == null) return false;

      try {
        final partsInicio = horaInicio.split(':');
        final partsFin = horaFin.split(':');

        final hourInicio = int.parse(partsInicio[0]);
        final hourFin = int.parse(partsFin[0]);

        // Cliente está en esta hora si la ventana incluye esta hora
        return hour >= hourInicio && hour < hourFin;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Construir bloque visual del cliente con su ventana horaria
  Widget _buildClienteBloque(
    BuildContext context,
    ClienteOrdenDelDia cliente,
    ColorScheme colorScheme,
  ) {
    final esVisitado = cliente.visitado;
    final bgColor = esVisitado
        ? Colors.green.withOpacity(0.15)
        : Colors.orange.withOpacity(0.15);
    final borderColor = esVisitado ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => onClienteTap(cliente),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del cliente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cliente.nombre,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (esVisitado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '✓ Visitado',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Horario
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: borderColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${cliente.ventanaHoraria.horaInicio} - ${cliente.ventanaHoraria.horaFin}',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Código cliente y Localidad
            if (cliente.codigoCliente != null || cliente.localidad != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (cliente.codigoCliente != null) ...[
                    Expanded(
                      child: Text(
                        'Código: ${cliente.codigoCliente}',
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                  if (cliente.localidad != null) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cliente.localidad!.nombre,
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
