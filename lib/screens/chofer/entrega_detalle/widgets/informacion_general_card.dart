import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import 'compact_info_chip.dart';
import 'compact_date_chip.dart';

class InformacionGeneralCard extends StatefulWidget {
  final Entrega entrega;

  const InformacionGeneralCard({Key? key, required this.entrega})
    : super(key: key);

  @override
  State<InformacionGeneralCard> createState() =>
      _InformacionGeneralCardState();
}

class _InformacionGeneralCardState extends State<InformacionGeneralCard> {
  bool _expandirDetalles = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado compacto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles de Entrega',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (widget.entrega.observaciones != null &&
                    widget.entrega.observaciones!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandirDetalles = !_expandirDetalles;
                      });
                    },
                    child: Icon(
                      _expandirDetalles ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de información compacta
            LayoutBuilder(
              builder: (context, constraints) {
                final numCols = constraints.maxWidth > 500 ? 3 : 2;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CompactInfoChip(
                      icon: Icons.confirmation_number,
                      label: '#${widget.entrega.id}',
                      value: widget.entrega.numeroEntrega ?? 'N/A',
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),
                    if (widget.entrega.chofer != null)
                      CompactInfoChip(
                        icon: Icons.person,
                        label: 'Chofer',
                        value: widget.entrega.chofer!.nombreCompleto,
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      )
                    else
                      CompactInfoChip(
                        icon: Icons.person_off,
                        label: 'Chofer',
                        value: 'No asignado',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),
                    if (widget.entrega.vehiculo != null)
                      CompactInfoChip(
                        icon: Icons.directions_car,
                        label: 'Auto',
                        value: widget.entrega.vehiculo!.placaFormato,
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      )
                    else
                      CompactInfoChip(
                        icon: Icons.directions_car,
                        label: 'Auto',
                        value: 'No asignado',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),
                    if (widget.entrega.vehiculo != null &&
                        widget.entrega.vehiculo!.capacidadKg != null)
                      CompactInfoChip(
                        icon: Icons.balance,
                        label: 'Capacidad',
                        value: '${widget.entrega.vehiculo!.capacidadKg.toString()} kg',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),
                    if (widget.entrega.chofer != null &&
                        widget.entrega.chofer!.telefono != null &&
                        widget.entrega.chofer!.telefono!.isNotEmpty)
                      CompactInfoChip(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: widget.entrega.chofer!.telefono ?? 'N/A',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),
                  ],
                );
              },
            ),

            // Sección de Fechas y Tiempos
            if (widget.entrega.fechaAsignacion != null ||
                widget.entrega.fechaInicio != null ||
                widget.entrega.fechaEntrega != null) ...[
              const SizedBox(height: 16),
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              Text(
                'Cronograma',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.entrega.fechaAsignacion != null)
                    CompactDateChip(
                      icon: Icons.calendar_today,
                      label: 'Asignada',
                      date: widget.entrega.fechaAsignacion!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),
                  if (widget.entrega.fechaInicio != null)
                    CompactDateChip(
                      icon: Icons.play_circle,
                      label: 'Inicio',
                      date: widget.entrega.fechaInicio!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),
                  if (widget.entrega.fechaEntrega != null)
                    CompactDateChip(
                      icon: Icons.check_circle,
                      label: 'Entregada',
                      date: widget.entrega.fechaEntrega!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                      isSuccess: true,
                    ),
                ],
              ),
            ],

            // Observaciones expandibles
            if (widget.entrega.observaciones != null &&
                widget.entrega.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandirDetalles = !_expandirDetalles;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.notes,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Observaciones',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expandirDetalles
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (_expandirDetalles) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.primaryContainer
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    widget.entrega.observaciones!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
