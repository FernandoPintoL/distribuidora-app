import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/config.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';

/// Selector de localidades para filtrar clientes
class LocalidadFilter extends StatelessWidget {
  final List<Localidad> localidades;

  const LocalidadFilter({
    super.key,
    required this.localidades,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitaProvider>(
      builder: (context, visitaProvider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por Localidad',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Botón "Todas"
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: visitaProvider.localidadSeleccionada == null,
                        onSelected: (selected) {
                          visitaProvider.cambiarLocalidad(null);
                        },
                        showCheckmark: false,
                        backgroundColor:
                            Theme.of(context).colorScheme.surface,
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        side: BorderSide(
                          color: visitaProvider.localidadSeleccionada == null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    // Localidades
                    ...localidades.map((localidad) {
                      final isSelected =
                          visitaProvider.localidadSeleccionada == localidad.id;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(localidad.nombre),
                          selected: isSelected,
                          onSelected: (selected) {
                            visitaProvider.cambiarLocalidad(
                              selected ? localidad.id : null,
                            );
                          },
                          showCheckmark: false,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
