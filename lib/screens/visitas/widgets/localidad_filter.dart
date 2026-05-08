import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/config.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';

/// Selector de localidades para filtrar clientes
class LocalidadFilter extends StatelessWidget {
  final List<Localidad> localidades;
  final List<ClienteOrdenDelDia> clientes;

  const LocalidadFilter({
    super.key,
    required this.localidades,
    required this.clientes,
  });

  /// Contar clientes por localidad
  int _contarClientesPorLocalidad(int localidadId) {
    return clientes.where((c) => c.localidad?.id == localidadId).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.grey.shade700
        : Theme.of(context).colorScheme.outlineVariant;

    return Consumer<VisitaProvider>(
      builder: (context, visitaProvider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: borderColor,
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
                        label: Text('Todas (${clientes.length})'),
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
                      final conteo = _contarClientesPorLocalidad(localidad.id);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${localidad.nombre} ($conteo)'),
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
