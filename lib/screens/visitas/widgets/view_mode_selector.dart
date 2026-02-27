import 'package:flutter/material.dart';
import '../../../config/config.dart';
import '../../../providers/providers.dart';
import 'package:provider/provider.dart';

/// Selector de modo de vista: Día / Semana
class ViewModeSelector extends StatelessWidget {
  const ViewModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitaProvider>(
      builder: (context, visitaProvider, _) {
        final isDay = visitaProvider.viewMode == ViewMode.day;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Tooltip(
            message: 'Cambiar vista',
            child: PopupMenuButton<ViewMode>(
              initialValue: visitaProvider.viewMode,
              onSelected: (ViewMode modo) {
                visitaProvider.cambiarModoVista(modo);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<ViewMode>(
                  value: ViewMode.day,
                  child: Row(
                    children: [
                      Icon(
                        Icons.today,
                        size: 20,
                        color: isDay
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text('Día'),
                    ],
                  ),
                ),
                PopupMenuItem<ViewMode>(
                  value: ViewMode.week,
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 20,
                        color: visitaProvider.viewMode == ViewMode.week
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text('Semana'),
                    ],
                  ),
                ),
                PopupMenuItem<ViewMode>(
                  value: ViewMode.horarios,
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 20,
                        color: visitaProvider.viewMode == ViewMode.horarios
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text('Horarios'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      visitaProvider.viewMode == ViewMode.day
                          ? Icons.today
                          : visitaProvider.viewMode == ViewMode.week
                              ? Icons.date_range
                              : Icons.schedule,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      visitaProvider.viewMode == ViewMode.day
                          ? 'Día'
                          : visitaProvider.viewMode == ViewMode.week
                              ? 'Semana'
                              : 'Horarios',
                      style: AppTextStyles.labelLarge(context).copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
