import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/providers.dart';

class VisitaEstadoFilter extends StatelessWidget {
  const VisitaEstadoFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer<VisitaProvider>(
        builder: (context, visitaProvider, _) {
          final filtroActual = visitaProvider.filtroVisitas;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Icon(
                    Icons.done_all,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estado de Visita:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chips de filtro
              Wrap(
                spacing: 8,
                children: [
                  // Todos
                  _buildFilterChip(
                    context: context,
                    label: 'Todos',
                    icon: Icons.list,
                    isSelected: filtroActual == 'all',
                    onTap: () => visitaProvider.filtrarPorEstadoVisita('all'),
                    color: Colors.grey,
                  ),

                  // Visitados
                  _buildFilterChip(
                    context: context,
                    label: 'Visitados',
                    icon: Icons.check_circle,
                    isSelected: filtroActual == 'visitados',
                    onTap: () => visitaProvider.filtrarPorEstadoVisita('visitados'),
                    color: Colors.green,
                  ),

                  // Pendientes
                  _buildFilterChip(
                    context: context,
                    label: 'Pendientes',
                    icon: Icons.schedule,
                    isSelected: filtroActual == 'pendientes',
                    onTap: () => visitaProvider.filtrarPorEstadoVisita('pendientes'),
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
