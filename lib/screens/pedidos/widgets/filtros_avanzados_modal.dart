import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// ✅ NUEVO 2026-02-27: Modal de filtros avanzados en BottomSheet
void mostrarFiltrosAvanzadosModal(
  BuildContext context, {
  required DateTime? filtroFechaDesde,
  required DateTime? filtroFechaHasta,
  required DateTime? filtroFechaVencimientoDesde,
  required DateTime? filtroFechaVencimientoHasta,
  required DateTime? filtroFechaEntregaSolicitadaDesde,
  required DateTime? filtroFechaEntregaSolicitadaHasta,
  required Function(DateTime?) onFechaDesdeChanged,
  required Function(DateTime?) onFechaHastaChanged,
  required Function(DateTime?) onFechaVencDesdeChanged,
  required Function(DateTime?) onFechaVencHastaChanged,
  required Function(DateTime?) onFechaEntregaDesdeChanged,
  required Function(DateTime?) onFechaEntregaHastaChanged,
  required VoidCallback onLimpiar,
  required VoidCallback onAplicar,
  required Widget Function(BuildContext, String, IconData, DateTime?, DateTime?,
      Function(DateTime?), Function(DateTime?), VoidCallback, DateTime?, DateTime?,
      ColorScheme, bool) buildDateFilterGroup,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (modalContext) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============= HEADER =============
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros Avanzados',
                    style: Theme.of(modalContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(modalContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outline.withOpacity(0.2)),
              const SizedBox(height: 16),

              // ============= FILTRO FECHA DE CREACIÓN =============
              buildDateFilterGroup(
                context,
                'Fecha de Creación',
                Icons.event,
                filtroFechaDesde,
                filtroFechaHasta,
                onFechaDesdeChanged,
                onFechaHastaChanged,
                () {
                  onFechaDesdeChanged(null);
                  onFechaHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 16),

              // ============= FILTRO FECHA VENCIMIENTO =============
              buildDateFilterGroup(
                context,
                'Fecha Vencimiento',
                Icons.event_note,
                filtroFechaVencimientoDesde,
                filtroFechaVencimientoHasta,
                onFechaVencDesdeChanged,
                onFechaVencHastaChanged,
                () {
                  onFechaVencDesdeChanged(null);
                  onFechaVencHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 16),

              // ============= FILTRO FECHA ENTREGA SOLICITADA =============
              buildDateFilterGroup(
                context,
                'Fecha Entrega Solicitada',
                Icons.local_shipping,
                filtroFechaEntregaSolicitadaDesde,
                filtroFechaEntregaSolicitadaHasta,
                onFechaEntregaDesdeChanged,
                onFechaEntregaHastaChanged,
                () {
                  onFechaEntregaDesdeChanged(null);
                  onFechaEntregaHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 24),

              // ============= BOTONES ACCIONES =============
              Row(
                children: [
                  // Botón Limpiar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLimpiar,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Aplicar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAplicar();
                        Navigator.pop(modalContext);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
