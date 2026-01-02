/// Estado Filter Widget
///
/// Componente reutilizable para filtrar por estado.
/// Proporciona dropdown, chips o botones para seleccionar estados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/estados_provider.dart';
import '../services/estados_helpers.dart';

/// Dropdown para filtrar por estado
///
/// Ejemplo:
/// ```dart
/// EstadoFilterDropdown(
///   categoria: 'entrega',
///   onChanged: (estadoCodigo) {
///     setState(() => filtro = estadoCodigo);
///   },
/// )
/// ```
class EstadoFilterDropdown extends ConsumerWidget {
  final String categoria;
  final String? selectedEstadoCodigo;
  final ValueChanged<String?> onChanged;
  final bool incluyeTodos;

  const EstadoFilterDropdown({
    required this.categoria,
    this.selectedEstadoCodigo,
    required this.onChanged,
    this.incluyeTodos = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadosAsync = ref.watch(estadosPorCategoriaProvider(categoria));

    return estadosAsync.when(
      data: (estados) {
        final items = <DropdownMenuItem<String?>>[];

        // Agregar opción "Todos" si está habilitado
        if (incluyeTodos) {
          items.add(
            DropdownMenuItem<String?>(
              value: null,
              child: const Text('Todos'),
            ),
          );
        }

        // Agregar cada estado
        for (final estado in estados.where((e) => e.activo)) {
          items.add(
            DropdownMenuItem<String?>(
              value: estado.codigo,
              child: Row(
                children: [
                  Text(estado.icono ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(estado.nombre),
                ],
              ),
            ),
          );
        }

        return DropdownButton<String?>(
          value: selectedEstadoCodigo,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          hint: const Text('Selecciona un estado'),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => _buildErrorFallback(err),
    );
  }

  Widget _buildErrorFallback(Object error) {
    print('[EstadoFilterDropdown] Error: $error, using fallback');
    final fallbackEstados = EstadosHelper.getEstados(categoria);

    final items = <DropdownMenuItem<String?>>[];

    if (incluyeTodos) {
      items.add(
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todos'),
        ),
      );
    }

    for (final estado in fallbackEstados.where((e) => e.activo)) {
      items.add(
        DropdownMenuItem<String?>(
          value: estado.codigo,
          child: Row(
            children: [
              Text(estado.icono ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(estado.nombre),
            ],
          ),
        ),
      );
    }

    return DropdownButton<String?>(
      value: selectedEstadoCodigo,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

/// Chips para filtrar por estado
///
/// Muestra múltiples chips seleccionables
class EstadoFilterChips extends ConsumerWidget {
  final String categoria;
  final Set<String> selectedEstadoCodigos;
  final ValueChanged<Set<String>> onChanged;
  final Axis direction;

  const EstadoFilterChips({
    required this.categoria,
    required this.selectedEstadoCodigos,
    required this.onChanged,
    this.direction = Axis.horizontal,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadosAsync = ref.watch(estadosPorCategoriaProvider(categoria));

    return estadosAsync.when(
      data: (estados) {
        final activos = estados.where((e) => e.activo).toList();

        final chips = activos.map((estado) {
          final isSelected = selectedEstadoCodigos.contains(estado.codigo);
          final colorInt = EstadosHelper.colorHexToInt(estado.color);
          final bgColor = Color(colorInt);

          return FilterChip(
            selected: isSelected,
            label: Text(
              '${estado.icono ?? ''} ${estado.nombre}',
              style: TextStyle(
                color: isSelected ? bgColor : null,
              ),
            ),
            backgroundColor: bgColor.withValues(alpha: 0.1),
            selectedColor: bgColor.withValues(alpha: 0.3),
            side: BorderSide(
              color: bgColor,
              width: isSelected ? 2 : 1,
            ),
            onSelected: (selected) {
              final newSet = Set<String>.from(selectedEstadoCodigos);
              if (selected) {
                newSet.add(estado.codigo);
              } else {
                newSet.remove(estado.codigo);
              }
              onChanged(newSet);
            },
          );
        }).toList();

        if (direction == Axis.horizontal) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(spacing: 8, children: chips),
          );
        } else {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorFallback(err),
    );
  }

  Widget _buildErrorFallback(Object error) {
    print('[EstadoFilterChips] Error: $error, using fallback');
    final fallbackEstados =
        EstadosHelper.getEstados(categoria).where((e) => e.activo).toList();

    final chips = fallbackEstados.map((estado) {
      final isSelected = selectedEstadoCodigos.contains(estado.codigo);
      final colorInt = EstadosHelper.colorHexToInt(estado.color);
      final bgColor = Color(colorInt);

      return FilterChip(
        selected: isSelected,
        label: Text(
          '${estado.icono ?? ''} ${estado.nombre}',
          style: TextStyle(
            color: isSelected ? bgColor : null,
          ),
        ),
        backgroundColor: bgColor.withValues(alpha: 0.1),
        selectedColor: bgColor.withValues(alpha: 0.3),
        side: BorderSide(
          color: bgColor,
          width: isSelected ? 2 : 1,
        ),
        onSelected: (selected) {
          final newSet = Set<String>.from(selectedEstadoCodigos);
          if (selected) {
            newSet.add(estado.codigo);
          } else {
            newSet.remove(estado.codigo);
          }
          onChanged(newSet);
        },
      );
    }).toList();

    if (direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(spacing: 8, children: chips),
      );
    } else {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }
  }
}

/// Botones para filtrar por estado
///
/// Botones grandes para interfaz más visual
class EstadoFilterButtons extends ConsumerWidget {
  final String categoria;
  final String? selectedEstadoCodigo;
  final ValueChanged<String?> onChanged;

  const EstadoFilterButtons({
    required this.categoria,
    this.selectedEstadoCodigo,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadosAsync = ref.watch(estadosPorCategoriaProvider(categoria));

    return estadosAsync.when(
      data: (estados) {
        final activos = estados.where((e) => e.activo).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Botón "Todos"
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () => onChanged(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedEstadoCodigo == null
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                  child: const Text('Todos'),
                ),
              ),
              // Botones por estado
              ...activos.map((estado) {
                final isSelected =
                    selectedEstadoCodigo == estado.codigo;
                final colorInt = EstadosHelper.colorHexToInt(estado.color);
                final bgColor = Color(colorInt);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () => onChanged(estado.codigo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? bgColor
                          : bgColor.withValues(alpha: 0.2),
                      foregroundColor: isSelected ? Colors.white : bgColor,
                    ),
                    child: Row(
                      children: [
                        Text(estado.icono ?? '', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(estado.nombre),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildErrorFallback(err, context),
    );
  }

  Widget _buildErrorFallback(Object error, BuildContext context) {
    print('[EstadoFilterButtons] Error: $error, using fallback');
    final fallbackEstados =
        EstadosHelper.getEstados(categoria).where((e) => e.activo).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => onChanged(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedEstadoCodigo == null
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
              ),
              child: const Text('Todos'),
            ),
          ),
          ...fallbackEstados.map((estado) {
            final isSelected = selectedEstadoCodigo == estado.codigo;
            final colorInt = EstadosHelper.colorHexToInt(estado.color);
            final bgColor = Color(colorInt);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () => onChanged(estado.codigo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? bgColor
                      : bgColor.withValues(alpha: 0.2),
                  foregroundColor: isSelected ? Colors.white : bgColor,
                ),
                child: Row(
                  children: [
                    Text(estado.icono ?? '', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(estado.nombre),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
