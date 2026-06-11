import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/config.dart';
import '../../../extensions/theme_extension.dart';
import '../../../providers/providers.dart';
import '../../../services/datetime_util_service.dart';

class FechaHoraWidget extends StatelessWidget {
  final BuildContext parentContext;
  final DateTime? fechaProgramada;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFin;
  final String observaciones;
  final String turnoSeleccionado;
  final int? horaEspecificaSeleccionada;
  final Function(DateTime) onFechaProgramadaChanged;
  final Function(String, int?) onTurnoChanged;
  final Function(int) onHoraEspecificaChanged;
  final Function(String) onObservacionesChanged;
  final Function() onSeleccionarFechaPersonalizada;

  static const String TURNO_MORNING = 'MORNING';
  static const String TURNO_AFTERNOON = 'AFTERNOON';

  const FechaHoraWidget({
    super.key,
    required this.parentContext,
    required this.fechaProgramada,
    required this.horaInicio,
    required this.horaFin,
    required this.observaciones,
    required this.turnoSeleccionado,
    required this.horaEspecificaSeleccionada,
    required this.onFechaProgramadaChanged,
    required this.onTurnoChanged,
    required this.onHoraEspecificaChanged,
    required this.onObservacionesChanged,
    required this.onSeleccionarFechaPersonalizada,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;
    final authProvider = parentContext.read<AuthProvider>();
    final user = authProvider.user;
    final esPreventista = user?.roles?.contains('preventista') ?? false;
    final fechasDisponibles = DateTimeUtilService.obtenerFechasDisponibles();

    bool usarFechaPersonalizada = false;
    if (fechaProgramada != null) {
      usarFechaPersonalizada = !DateTimeUtilService.esFechaEstandar(fechaProgramada!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Fecha y Hora de Entrega',
                style: TextStyle(
                  fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (esPreventista)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Otra fecha',
                      style: parentContext.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: usarFechaPersonalizada,
                      onChanged: (value) {
                        if (value) {
                          onSeleccionarFechaPersonalizada();
                        } else {
                          final now = DateTime.now();
                          onFechaProgramadaChanged(
                            DateTime(now.year, now.month, now.day),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // SECCIÓN 1: Fechas estándar
        if (!usarFechaPersonalizada) ...[
          Text(
            'Selecciona una fecha',
            style: parentContext.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: fechasDisponibles.entries.toList().asMap().entries.map((
              indexedEntry,
            ) {
              final index = indexedEntry.key;
              final entry = indexedEntry.value;
              final isLast = index == fechasDisponibles.length - 1;

              final nombreFecha = entry.key;
              final fecha = entry.value;
              final isSelected = fechaProgramada?.year == fecha.year &&
                  fechaProgramada?.month == fecha.month &&
                  fechaProgramada?.day == fecha.day;

              final diasSemana = [
                'Lunes',
                'Martes',
                'Miércoles',
                'Jueves',
                'Viernes',
                'Sábado',
                'Domingo',
              ];
              final nombreDia = diasSemana[fecha.weekday - 1];
              final fechaFormato = '${fecha.day}/${fecha.month}';

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: ElevatedButton(
                    onPressed: () {
                      onFechaProgramadaChanged(fecha);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombreFecha,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$nombreDia\n$fechaFormato',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Sección de Turno
          Text(
            'Selecciona un turno',
            style: parentContext.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final turnosDisponibles = DateTimeUtilService.obtenerTurnosDisponibles(fechaProgramada);
                    final morningDisponible =
                        turnosDisponibles[TURNO_MORNING] ?? false;

                    return Opacity(
                      opacity: morningDisponible ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: morningDisponible
                            ? () => onTurnoChanged(TURNO_MORNING, 8)
                            : null,
                        icon: const Icon(Icons.sunny),
                        label: const Text('Mañana\n8:00 - 12:00'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turnoSeleccionado == TURNO_MORNING
                              ? Colors.orange.shade500
                              : colorScheme.surfaceVariant,
                          foregroundColor: turnoSeleccionado == TURNO_MORNING
                              ? Colors.white
                              : colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final turnosDisponibles = DateTimeUtilService.obtenerTurnosDisponibles(fechaProgramada);
                    final tardeDisponible =
                        turnosDisponibles[TURNO_AFTERNOON] ?? false;

                    return Opacity(
                      opacity: tardeDisponible ? 1.0 : 0.5,
                      child: ElevatedButton.icon(
                        onPressed: tardeDisponible
                            ? () => onTurnoChanged(TURNO_AFTERNOON, 14)
                            : null,
                        icon: const Icon(Icons.wb_twilight),
                        label: const Text('Tarde\n14:00 - 18:00'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: turnoSeleccionado == TURNO_AFTERNOON
                              ? Colors.purple.shade500
                              : colorScheme.surfaceVariant,
                          foregroundColor: turnoSeleccionado == TURNO_AFTERNOON
                              ? Colors.white
                              : colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Aviso si no hay turnos disponibles
          Builder(
            builder: (context) {
              final turnosDisponibles = DateTimeUtilService.obtenerTurnosDisponibles(fechaProgramada);
              final esHoy = fechaProgramada?.year == DateTime.now().year &&
                  fechaProgramada?.month == DateTime.now().month &&
                  fechaProgramada?.day == DateTime.now().day;
              final hayAlgunDisponible =
                  turnosDisponibles.values.any((v) => v);

              if (esHoy && !hayAlgunDisponible) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Es muy tarde para hoy. Por favor, selecciona mañana o una fecha posterior.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: AppTextStyles.bodySmall(parentContext)
                                .fontSize!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (esHoy && !turnosDisponibles[TURNO_MORNING]!) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El turno matutino ya no está disponible. Solo puedes elegir el turno de la tarde.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: AppTextStyles.bodySmall(parentContext)
                                .fontSize!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
        ] else ...[
          // SECCIÓN 2: Fecha personalizada
          Text(
            'Fecha seleccionada',
            style: parentContext.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onSeleccionarFechaPersonalizada,
            child: Card(
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fechaProgramada != null
                            ? DateTimeUtilService.formatearFecha(fechaProgramada!)
                            : 'Seleccionar fecha',
                        style: parentContext.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.edit, color: colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // SECCIÓN 3: Seleccionar Hora Específica
        Text(
          'Selecciona la hora',
          style: parentContext.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DateTimeUtilService.obtenerHorasDisponibles(turnoSeleccionado).map((hora) {
            final isSelected = horaEspecificaSeleccionada == hora;
            return ElevatedButton(
              onPressed: () {
                onHoraEspecificaChanged(hora);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                foregroundColor: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                '$hora:00',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // SECCIÓN 4: Observaciones
        Text(
          'Observaciones (Opcional)',
          style: parentContext.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Ej: Entregar entre semana, no sábado...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 2,
          onChanged: onObservacionesChanged,
          controller: TextEditingController(text: observaciones),
        ),
      ],
    );
  }
}
