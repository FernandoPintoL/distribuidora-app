import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../extensions/theme_extension.dart';

/// ✅ Widgets para contenedores de filtros (fechas y estados)
class FilterContainers {
  /// Construir contenedor de filtro de fechas con botones rápidos
  static Widget buildDateFilterContainer(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    bool isFilterDateExpanded,
    Function(bool) onExpandedChanged,
    DateTime? filtroFechaDesde,
    DateTime? filtroFechaHasta,
    DateTime? filtroFechaVencimientoDesde,
    DateTime? filtroFechaVencimientoHasta,
    DateTime? filtroFechaEntregaSolicitadaDesde,
    DateTime? filtroFechaEntregaSolicitadaHasta,
    Function(DateTime?) onFechaDesdeChanged,
    Function(DateTime?) onFechaHastaChanged,
    Function(DateTime?) onFechaVencimientoDesdeChanged,
    Function(DateTime?) onFechaVencimientoHastaChanged,
    Function(DateTime?) onFechaEntregaSolicitadaDesdeChanged,
    Function(DateTime?) onFechaEntregaSolicitadaHastaChanged,
    VoidCallback onResetFechaCreacion,
    VoidCallback onResetFechaVencimiento,
    VoidCallback onResetFechaEntregaSolicitada,
    VoidCallback onBuscar,
    VoidCallback onLimpiarTodo,
    String? filtroEstadoSeleccionado,
    String? searchText,
  ) {
    final tieneFiltrosActivos =
        filtroFechaDesde != null ||
        filtroFechaHasta != null ||
        filtroFechaVencimientoDesde != null ||
        filtroFechaVencimientoHasta != null ||
        filtroFechaEntregaSolicitadaDesde != null ||
        filtroFechaEntregaSolicitadaHasta != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ HEADER: Toggle para mostrar/ocultar filtros
          InkWell(
            onTap: () => onExpandedChanged(!isFilterDateExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isFilterDateExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.date_range, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrar por Fechas',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Badge de filtros activos
                  if (tieneFiltrosActivos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Activo',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO EXPANDIBLE
          if (isFilterDateExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // ✅ BOTONES RÁPIDOS
                    _buildQuickDateButtons(
                      context,
                      colorScheme,
                      isDark,
                      onFechaDesdeChanged,
                      onFechaHastaChanged,
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),

                    // ✅ FILTRO DE CREACIÓN
                    buildDateFilterGroupWithReset(
                      context,
                      'Fecha Creación',
                      Icons.calendar_today,
                      filtroFechaDesde,
                      filtroFechaHasta,
                      onFechaDesdeChanged,
                      onFechaHastaChanged,
                      onResetFechaCreacion,
                      DateTime(2020),
                      DateTime.now(),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 12),

                    // ✅ FILTRO DE VENCIMIENTO
                    buildDateFilterGroupWithReset(
                      context,
                      'Fecha Vencimiento',
                      Icons.event_note,
                      filtroFechaVencimientoDesde,
                      filtroFechaVencimientoHasta,
                      onFechaVencimientoDesdeChanged,
                      onFechaVencimientoHastaChanged,
                      onResetFechaVencimiento,
                      DateTime(2020),
                      DateTime(2100),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 12),

                    // ✅ FILTRO DE ENTREGA SOLICITADA
                    buildDateFilterGroupWithReset(
                      context,
                      'Entrega Solicitada',
                      Icons.local_shipping,
                      filtroFechaEntregaSolicitadaDesde,
                      filtroFechaEntregaSolicitadaHasta,
                      onFechaEntregaSolicitadaDesdeChanged,
                      onFechaEntregaSolicitadaHastaChanged,
                      onResetFechaEntregaSolicitada,
                      DateTime(2020),
                      DateTime(2100),
                      colorScheme,
                      isDark,
                    ),
                    const SizedBox(height: 16),

                    // ✅ BOTONES DE ACCIÓN
                    Row(
                      children: [
                        if (tieneFiltrosActivos)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onBuscar,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Buscar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        if (tieneFiltrosActivos) const SizedBox(width: 8),
                        if (tieneFiltrosActivos)
                          OutlinedButton.icon(
                            onPressed: onLimpiarTodo,
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Limpiar todo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Botones rápidos para rangos comunes de fechas
  static Widget _buildQuickDateButtons(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Function(DateTime?) onFechaDesdeChanged,
    Function(DateTime?) onFechaHastaChanged,
  ) {
    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 7));
    final hace30Dias = hoy.subtract(const Duration(days: 30));
    final primerDiaDelMes = DateTime(hoy.year, hoy.month, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Accesos rápidos de fechas',
          style: context.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateButton(
              context,
              'Hoy',
              hoy,
              hoy,
              colorScheme,
              isDark,
              onFechaDesdeChanged,
              onFechaHastaChanged,
            ),
            _buildQuickDateButton(
              context,
              'Últimos 7 días',
              hace7Dias,
              hoy,
              colorScheme,
              isDark,
              onFechaDesdeChanged,
              onFechaHastaChanged,
            ),
            _buildQuickDateButton(
              context,
              'Últimos 30 días',
              hace30Dias,
              hoy,
              colorScheme,
              isDark,
              onFechaDesdeChanged,
              onFechaHastaChanged,
            ),
            _buildQuickDateButton(
              context,
              'Este mes',
              primerDiaDelMes,
              hoy,
              colorScheme,
              isDark,
              onFechaDesdeChanged,
              onFechaHastaChanged,
            ),
          ],
        ),
      ],
    );
  }

  /// Botón individual para rango rápido
  static Widget _buildQuickDateButton(
    BuildContext context,
    String label,
    DateTime desde,
    DateTime hasta,
    ColorScheme colorScheme,
    bool isDark,
    Function(DateTime?) onFechaDesdeChanged,
    Function(DateTime?) onFechaHastaChanged,
  ) {
    return ElevatedButton(
      onPressed: () {
        onFechaDesdeChanged(desde);
        onFechaHastaChanged(hasta);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }

  /// Grupo de filtro de fechas con botón de reset individual
  /// ✅ PÚBLICO: Accesible para uso en modales
  static Widget buildDateFilterGroupWithReset(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? desde,
    DateTime? hasta,
    Function(DateTime?) onDesdeChanged,
    Function(DateTime?) onHastaChanged,
    VoidCallback onReset,
    DateTime? minDate,
    DateTime? maxDate,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final tieneFiltros = desde != null || hasta != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tieneFiltros
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label con reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTextStyles.labelSmall(context).fontSize!,
                    ),
                  ),
                  if (tieneFiltros) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Activo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (tieneFiltros)
                InkWell(
                  onTap: onReset,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Botones desde/hasta
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Desde
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: desde ?? DateTime.now(),
                    firstDate: minDate ?? DateTime(2020),
                    lastDate: maxDate ?? DateTime(2100),
                  );
                  if (fecha != null) {
                    onDesdeChanged(fecha);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: desde != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Desde',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desde != null
                            ? DateFormat('dd/MM').format(desde)
                            : '--',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: AppTextStyles.labelSmall(context).fontSize!,
                          fontWeight: FontWeight.w600,
                          color: desde != null
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Separador
              Text(
                '→',
                style: TextStyle(
                  color: colorScheme.outline.withOpacity(0.4),
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                ),
              ),
              const SizedBox(width: 6),
              // Botón Hasta
              InkWell(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: hasta ?? DateTime.now(),
                    firstDate: desde ?? minDate ?? DateTime(2020),
                    lastDate: maxDate ?? DateTime(2100),
                  );
                  if (fecha != null) {
                    onHastaChanged(fecha);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasta != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hasta',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasta != null
                            ? DateFormat('dd/MM').format(hasta)
                            : '--',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: AppTextStyles.labelSmall(context).fontSize!,
                          fontWeight: FontWeight.w600,
                          color: hasta != null
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Info de rango
              if (desde != null && hasta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${hasta!.difference(desde!).inDays + 1} días',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir contenedor de filtros dinámicos cargados desde EstadosProvider
  static Widget buildDynamicFilterContainer(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    String? filtroEstadoSeleccionado,
    Function(String?) onEstadoChanged,
  ) {
    return Consumer<EstadosProvider>(
      builder: (context, estadosProvider, _) {
        if (estadosProvider.isLoading && estadosProvider.estados.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            child: SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        final states = estadosProvider.estados;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDynamicFilterChip(
                  context: context,
                  label: 'Todos',
                  codigo: null,
                  contador: estadosProvider.stats?.total ?? 0,
                  isSelected: filtroEstadoSeleccionado == null,
                  onTap: () => onEstadoChanged(null),
                  icon: Icons.list_alt,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                ...states.map((estado) {
                  final contador = estadosProvider.getContadorEstado(
                    estado.codigo,
                  );
                  final color = _hexToColor(estado.color);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDynamicFilterChip(
                      context: context,
                      label: estado.nombre,
                      codigo: estado.codigo,
                      contador: contador,
                      isSelected: filtroEstadoSeleccionado == estado.codigo,
                      onTap: () => onEstadoChanged(estado.codigo),
                      icon: _getIconoParaEstado(estado.codigo),
                      color: color,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Obtener ícono según código de estado
  static IconData _getIconoParaEstado(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'PENDIENTE':
        return Icons.hourglass_empty;
      case 'APROBADA':
        return Icons.check_circle_outline;
      case 'CONVERTIDA':
        return Icons.loop;
      case 'VENCIDA':
        return Icons.schedule;
      case 'RECHAZADA':
        return Icons.cancel;
      case 'PENDIENTE_ENVIO':
      case 'PENDIENTE_RETIRO':
        return Icons.inventory_2_outlined;
      case 'EN_TRANSITO':
        return Icons.local_shipping;
      case 'ENTREGADO':
      case 'ENTREGADA':
        return Icons.done_all;
      case 'PAGADO':
        return Icons.paid_outlined;
      default:
        return Icons.circle;
    }
  }

  /// Construir chip de filtro dinámico con contador
  static Widget _buildDynamicFilterChip({
    required BuildContext context,
    required String label,
    required String? codigo,
    required int contador,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final chipColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor
                : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.3),
                      blurRadius: 8,
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
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : colorScheme.onSurface),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$contador',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convertir hex string (#RRGGBB o RRGGBB) a Color
  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey;
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
