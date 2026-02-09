import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/entrega_estados_provider.dart';
import 'date_picker_field.dart';

class FiltrosModernos extends StatelessWidget {
  final String filtroEstado;
  final String busqueda;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool filtrosExpandidos;
  final bool isDarkMode;
  final TextEditingController searchController;
  final Function(String) onBusquedaChanged;
  final Function(String?) onFiltroEstadoChanged;
  final Function(DateTime) onFechaInicioChanged;
  final Function(DateTime) onFechaFinChanged;
  final Function(bool) onFiltrosExpandidosChanged;
  final VoidCallback onLimpiarFiltros;
  final Function() onCargarEntregas;

  const FiltrosModernos({
    Key? key,
    required this.filtroEstado,
    required this.busqueda,
    required this.fechaInicio,
    required this.fechaFin,
    required this.filtrosExpandidos,
    required this.isDarkMode,
    required this.searchController,
    required this.onBusquedaChanged,
    required this.onFiltroEstadoChanged,
    required this.onFechaInicioChanged,
    required this.onFechaFinChanged,
    required this.onFiltrosExpandidosChanged,
    required this.onLimpiarFiltros,
    required this.onCargarEntregas,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        busqueda.isNotEmpty ||
        filtroEstado != null ||
        fechaInicio != null ||
        fechaFin != null;

    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header colapsable
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (hasFilters) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Activo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      onFiltrosExpandidosChanged(!filtrosExpandidos);
                    },
                    child: Icon(
                      filtrosExpandidos
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido colapsable
            if (filtrosExpandidos) ...[
              // Barra de búsqueda mejorada
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: onBusquedaChanged,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar: ID, cliente, CI, teléfono, venta, fecha...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    suffixIcon: busqueda.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              searchController.clear();
                              onBusquedaChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // Filtros de estado y fechas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro de estados - DINÁMICO desde la BD
                    Consumer<EntregaEstadosProvider>(
                      builder: (context, estadosProvider, _) {
                        final estadosFiltro = estadosProvider
                            .getEstadosParaFiltrado();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                clipBehavior: Clip.hardEdge,
                                itemCount: estadosFiltro.length + 1,
                                itemBuilder: (context, index) {
                                  // Primera opción es "Todas"
                                  if (index == 0) {
                                    final isSelected = filtroEstado == null || filtroEstado.isEmpty;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 0,
                                        right: 8,
                                      ),
                                      child: FilterChip(
                                        label: Text(
                                          'Todas',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDarkMode
                                                      ? Colors.grey[300]
                                                      : Colors.grey[700]),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          onFiltroEstadoChanged(null);
                                          onCargarEntregas();
                                        },
                                        backgroundColor: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[200],
                                        selectedColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Estados dinámicos desde la BD
                                  final estado = estadosFiltro[index - 1];
                                  final isSelected =
                                      filtroEstado == estado.codigo;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        estado.nombre,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700]),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        onFiltroEstadoChanged(estado.codigo);
                                        onCargarEntregas();
                                      },
                                      backgroundColor: isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[200],
                                      selectedColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro de fechas
                    Text(
                      'Rango de fechas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DatePickerField(
                            label: 'Desde',
                            date: fechaInicio,
                            onDateSelected: onFechaInicioChanged,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DatePickerField(
                            label: 'Hasta',
                            date: fechaFin,
                            onDateSelected: onFechaFinChanged,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),

                    // Botón de limpiar filtros
                    if (hasFilters) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onLimpiarFiltros,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Limpiar filtros'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
