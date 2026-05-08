import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/config.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';

/// Widget de filtros avanzados para orden del día
/// Permite filtrar por: cliente, horario fijo, rango de horarios
class FiltrosAvanzados extends StatefulWidget {
  final List<ClienteOrdenDelDia> clientes;

  const FiltrosAvanzados({
    super.key,
    required this.clientes,
  });

  @override
  State<FiltrosAvanzados> createState() => _FiltrosAvanzadosState();
}

class _FiltrosAvanzadosState extends State<FiltrosAvanzados> {
  late TextEditingController _searchController;
  bool _mostrarFiltros = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Recargar orden del día con los filtros actuales
  void _recargarOrdenDelDia(BuildContext context) {
    final visitaProvider = context.read<VisitaProvider>();
    visitaProvider.invalidarCache();
    // Fuerza rebuild del FutureBuilder padre
    if (context.mounted) {
      context.read<VisitaProvider>().notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<VisitaProvider>(
      builder: (context, visitaProvider, _) {
        final tieneActivos = visitaProvider.clienteSeleccionado != null ||
            visitaProvider.horarioInicio != null ||
            visitaProvider.horarioFin != null;

        return Column(
          children: [
            // 🔍 Barra de búsqueda de cliente
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  visitaProvider.filtrarPorCliente(value);
                  // ✅ Recargar datos cuando cambia la búsqueda
                  _recargarOrdenDelDia(context);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: Icon(Icons.person_search,
                      color: colorScheme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            visitaProvider.filtrarPorCliente('');
                            _recargarOrdenDelDia(context);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                ),
              ),
            ),

            // ⏰ Botón para mostrar/ocultar filtros avanzados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros Avanzados',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tieneActivos)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Activo',
                            style:
                                AppTextStyles.labelSmall(context).copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _mostrarFiltros
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarFiltros = !_mostrarFiltros;
                      });
                    },
                  ),
                ],
              ),
            ),

            // 📊 Panel de filtros avanzados (expandible)
            if (_mostrarFiltros)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horario Fijo
                    Text(
                      'Horario Fijo',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildHorarioChip(
                            context,
                            'Todos',
                            null,
                            visitaProvider.horarioInicio == null,
                            () {
                              visitaProvider.filtrarPorHorario(null, null);
                              _recargarOrdenDelDia(context);
                            },
                          ),
                          ..._getHorariosUnicos().map((horario) {
                            return _buildHorarioChip(
                              context,
                              horario,
                              horario,
                              visitaProvider.horarioInicio == horario,
                              () {
                                visitaProvider.filtrarPorHorario(
                                  horario,
                                  horario,
                                );
                                _recargarOrdenDelDia(context);
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rango de Horarios
                    Text(
                      'Rango de Horarios',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerField(
                            context,
                            'Desde',
                            visitaProvider.horarioInicio,
                            (hora) {
                              visitaProvider.filtrarPorHorario(
                                hora,
                                visitaProvider.horarioFin,
                              );
                              _recargarOrdenDelDia(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('—'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTimePickerField(
                            context,
                            'Hasta',
                            visitaProvider.horarioFin,
                            (hora) {
                              visitaProvider.filtrarPorHorario(
                                visitaProvider.horarioInicio,
                                hora,
                              );
                              _recargarOrdenDelDia(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botón Limpiar Filtros
                    if (tieneActivos)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            visitaProvider.limpiarFiltros();
                            _recargarOrdenDelDia(context);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Limpiar Filtros'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Construir chip de horario
  Widget _buildHorarioChip(
    BuildContext context,
    String label,
    String? value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor:
            Theme.of(context).colorScheme.surface,
        selectedColor:
            Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  /// Construir campo time picker
  Widget _buildTimePickerField(
    BuildContext context,
    String label,
    String? selectedTime,
    Function(String?) onTimeSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTimeOfDay(selectedTime) ?? TimeOfDay.now(),
        );
        if (picked != null) {
          final hora = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeSelected(hora);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  selectedTime ?? '--:--',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener horas únicas de las ventanas de entrega
  List<String> _getHorariosUnicos() {
    final horas = <String>{};
    for (var cliente in widget.clientes) {
      if (cliente.ventanaHoraria.horaInicio != null) {
        horas.add(cliente.ventanaHoraria.horaInicio!);
      }
    }
    return horas.toList()..sort();
  }

  /// Parsear string de hora a TimeOfDay
  TimeOfDay? _parseTimeOfDay(String? time) {
    if (time == null) return null;
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }
}
