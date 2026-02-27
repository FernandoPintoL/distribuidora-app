import 'package:flutter/material.dart';
import '../../../config/config.dart';
import '../../../models/orden_del_dia.dart';

/// Mini calendario de 7 días (L-D)
/// Muestra cada día con contador de clientes pendientes
class WeekCalendarMini extends StatelessWidget {
  final SemanaOrdenDelDia semana;
  final DateTime fechaSeleccionada;
  final Function(DateTime fecha) onSelectFecha;

  const WeekCalendarMini({
    super.key,
    required this.semana,
    required this.fechaSeleccionada,
    required this.onSelectFecha,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezados de días (L, M, X, J, V, S, D)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _buildDayHeaders(context),
            ),
          ),
          const SizedBox(height: 12),

          // Grilla de 7 días
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: semana.dias.map((dia) {
              final fecha = DateTime.parse(dia.fecha);
              final esHoy = _esHoy(fecha);
              final esSeleccionado = _esSeleccionado(fecha);

              return _buildDayCell(
                context,
                dia,
                esHoy,
                esSeleccionado,
              );
            }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Encabezados de días de la semana
  List<Widget> _buildDayHeaders(BuildContext context) {
    const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return dias.map((dia) {
      return SizedBox(
        width: 50,
        child: Text(
          dia,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall(context).copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }).toList();
  }

  /// Celda individual de día
  Widget _buildDayCell(
    BuildContext context,
    DiaSemanaResumen dia,
    bool esHoy,
    bool esSeleccionado,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fecha = DateTime.parse(dia.fecha);
    final tieneClientes = dia.totalClientes > 0;
    final todosVisitados = dia.visitados == dia.totalClientes && tieneClientes;

    // Color de fondo
    Color bgColor;
    Color textColor;
    Color borderColor;
    double elevation = 0;

    if (esSeleccionado) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      borderColor = colorScheme.primary;
      elevation = 4;
    } else if (esHoy) {
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      borderColor = colorScheme.primary;
      elevation = 2;
    } else {
      bgColor = Colors.transparent;
      textColor = colorScheme.onSurface;
      borderColor = colorScheme.outlineVariant;
    }

    return GestureDetector(
      onTap: () {
        onSelectFecha(fecha);
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: esSeleccionado || esHoy ? 2 : 1,
            ),
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: elevation,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              onSelectFecha(fecha);
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Número del día
                  Text(
                    '${fecha.day}',
                    style: AppTextStyles.labelLarge(context).copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Indicador de estado
                  if (tieneClientes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildStatusIndicator(
                        context,
                        dia,
                        textColor,
                        todosVisitados,
                      ),
                    )
                  else
                    Text(
                      '-',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: textColor.withOpacity(0.5),
                      ),
                    ),

                  // Badge "Hoy"
                  if (esHoy)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'HOY',
                          style: AppTextStyles.labelSmall(context).copyWith(
                            fontSize: 8,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Indicador de estado de clientes
  Widget _buildStatusIndicator(
    BuildContext context,
    DiaSemanaResumen dia,
    Color textColor,
    bool todosVisitados,
  ) {
    // Si todos visitados: verde
    if (todosVisitados) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: Colors.green,
          ),
          const SizedBox(width: 2),
          Text(
            '${dia.totalClientes}',
            style: AppTextStyles.labelSmall(context).copyWith(
              fontSize: 9,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Si algunos visitados: naranja
    if (dia.visitados > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            '${dia.pendientes}',
            style: AppTextStyles.labelSmall(context).copyWith(
              fontSize: 9,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // Todos pendientes: rojo
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error,
          size: 12,
          color: Colors.red,
        ),
        const SizedBox(width: 2),
        Text(
          '${dia.totalClientes}',
          style: AppTextStyles.labelSmall(context).copyWith(
            fontSize: 9,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Helper: ¿Es hoy?
  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  /// Helper: ¿Es la fecha seleccionada?
  bool _esSeleccionado(DateTime fecha) {
    return fecha.year == fechaSeleccionada.year &&
        fecha.month == fechaSeleccionada.month &&
        fecha.day == fechaSeleccionada.day;
  }
}
