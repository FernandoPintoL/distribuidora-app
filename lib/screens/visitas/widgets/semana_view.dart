import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/config.dart';
import '../../../models/orden_del_dia.dart';
import '../../../providers/providers.dart';
import 'week_calendar_mini.dart';

/// Vista de semana: Mini calendario + Lista de días con resúmenes
class SemanaView extends StatelessWidget {
  final SemanaOrdenDelDia semana;
  final void Function(DateTime fecha) onSelectFecha;

  const SemanaView({
    super.key,
    required this.semana,
    required this.onSelectFecha,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<VisitaProvider>(
      builder: (context, visitaProvider, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // ✅ NUEVO: Mini calendario de 7 días
              WeekCalendarMini(
                semana: semana,
                fechaSeleccionada: visitaProvider.fechaSeleccionada,
                onSelectFecha: onSelectFecha,
              ),

              // Encabezado
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Orden del Día de la Semana',
                  style: AppTextStyles.headlineSmall(context),
                ),
              ),

              // Lista de días
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: semana.dias.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final dia = semana.dias[index];
                    final esHoy = dia.esHoy;

                    return _buildDiaCard(
                      context,
                      dia,
                      esHoy,
                      colorScheme,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Construir tarjeta de un día
  Widget _buildDiaCard(
    BuildContext context,
    DiaSemanaResumen dia,
    bool esHoy,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: esHoy ? 4 : 2,
      color: esHoy ? colorScheme.primaryContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esHoy
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          final fecha = DateTime.parse(dia.fecha);
          onSelectFecha(fecha);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Día y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dia.diaSemana,
                            style: AppTextStyles.titleLarge(context).copyWith(
                              fontWeight: FontWeight.bold,
                              color: esHoy
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                          if (esHoy)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Hoy',
                                  style: AppTextStyles.labelSmall(context).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(dia.fecha),
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: esHoy
                              ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  // Ícono indicador
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esHoy
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: esHoy
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Información de clientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    context,
                    '${dia.totalClientes}',
                    'Clientes',
                    colorScheme.onSurface,
                  ),
                  _buildStatColumn(
                    context,
                    '${dia.visitados}',
                    'Visitados',
                    Colors.green,
                  ),
                  _buildStatColumn(
                    context,
                    '${dia.pendientes}',
                    'Pendientes',
                    Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: dia.totalClientes > 0
                      ? dia.porcentajeCompletado / 100
                      : 0,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    dia.porcentajeCompletado == 100
                        ? Colors.green
                        : colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Porcentaje
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${dia.porcentajeCompletado.toStringAsFixed(0)}% completado',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Columna de estadística
  Widget _buildStatColumn(
    BuildContext context,
    String valor,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          valor,
          style: AppTextStyles.titleMedium(context).copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall(context),
        ),
      ],
    );
  }

  /// Formatear fecha como "24 de Febrero"
  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      final meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      return '${fecha.day} de ${meses[fecha.month - 1]}';
    } catch (e) {
      return fechaStr;
    }
  }
}
