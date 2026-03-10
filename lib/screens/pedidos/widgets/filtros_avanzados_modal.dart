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

  // ✅ Estado local para el modal que persiste durante su ciclo de vida
  DateTime? _localFechaDesde = filtroFechaDesde;
  DateTime? _localFechaHasta = filtroFechaHasta;
  DateTime? _localFechaVencDesde = filtroFechaVencimientoDesde;
  DateTime? _localFechaVencHasta = filtroFechaVencimientoHasta;
  DateTime? _localFechaEntregaDesde = filtroFechaEntregaSolicitadaDesde;
  DateTime? _localFechaEntregaHasta = filtroFechaEntregaSolicitadaHasta;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (modalContext, setModalState) {
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
                _localFechaDesde,
                _localFechaHasta,
                (fecha) {
                  setModalState(() => _localFechaDesde = fecha);
                  onFechaDesdeChanged(fecha);
                },
                (fecha) {
                  setModalState(() => _localFechaHasta = fecha);
                  onFechaHastaChanged(fecha);
                },
                () {
                  setModalState(() {
                    _localFechaDesde = null;
                    _localFechaHasta = null;
                  });
                  onFechaDesdeChanged(null);
                  onFechaHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 12),

              // ✅ NUEVO: Botones rápidos específicos para Creación
              Text(
                '⚡ Aplicar rápidamente a Creación:',
                style: Theme.of(modalContext).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final ayer = DateTime.now().subtract(const Duration(days: 1));
                        setModalState(() {
                          _localFechaDesde = ayer;
                          _localFechaHasta = ayer;
                        });
                        onFechaDesdeChanged(ayer);
                        onFechaHastaChanged(ayer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Ayer', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        setModalState(() {
                          _localFechaDesde = hoy;
                          _localFechaHasta = hoy;
                        });
                        onFechaDesdeChanged(hoy);
                        onFechaHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Hoy', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final manana = DateTime.now().add(const Duration(days: 1));
                        setModalState(() {
                          _localFechaDesde = manana;
                          _localFechaHasta = manana;
                        });
                        onFechaDesdeChanged(manana);
                        onFechaHastaChanged(manana);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Mañana', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        final hace7Dias = hoy.subtract(const Duration(days: 7));
                        setModalState(() {
                          _localFechaDesde = hace7Dias;
                          _localFechaHasta = hoy;
                        });
                        onFechaDesdeChanged(hace7Dias);
                        onFechaHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Últimos 7', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ============= FILTRO FECHA VENCIMIENTO =============
              buildDateFilterGroup(
                context,
                'Fecha Vencimiento',
                Icons.event_note,
                _localFechaVencDesde,
                _localFechaVencHasta,
                (fecha) {
                  setModalState(() => _localFechaVencDesde = fecha);
                  onFechaVencDesdeChanged(fecha);
                },
                (fecha) {
                  setModalState(() => _localFechaVencHasta = fecha);
                  onFechaVencHastaChanged(fecha);
                },
                () {
                  setModalState(() {
                    _localFechaVencDesde = null;
                    _localFechaVencHasta = null;
                  });
                  onFechaVencDesdeChanged(null);
                  onFechaVencHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 12),

              // ✅ NUEVO: Botones rápidos específicos para Vencimiento
              Text(
                '⚡ Aplicar rápidamente a Vencimiento:',
                style: Theme.of(modalContext).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final ayer = DateTime.now().subtract(const Duration(days: 1));
                        setModalState(() {
                          _localFechaVencDesde = ayer;
                          _localFechaVencHasta = ayer;
                        });
                        onFechaVencDesdeChanged(ayer);
                        onFechaVencHastaChanged(ayer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Ayer', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        setModalState(() {
                          _localFechaVencDesde = hoy;
                          _localFechaVencHasta = hoy;
                        });
                        onFechaVencDesdeChanged(hoy);
                        onFechaVencHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Hoy', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final manana = DateTime.now().add(const Duration(days: 1));
                        setModalState(() {
                          _localFechaVencDesde = manana;
                          _localFechaVencHasta = manana;
                        });
                        onFechaVencDesdeChanged(manana);
                        onFechaVencHastaChanged(manana);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Mañana', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        final hace7Dias = hoy.subtract(const Duration(days: 7));
                        setModalState(() {
                          _localFechaVencDesde = hace7Dias;
                          _localFechaVencHasta = hoy;
                        });
                        onFechaVencDesdeChanged(hace7Dias);
                        onFechaVencHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Últimos 7', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ============= FILTRO FECHA ENTREGA SOLICITADA =============
              buildDateFilterGroup(
                context,
                'Fecha Entrega Solicitada',
                Icons.local_shipping,
                _localFechaEntregaDesde,
                _localFechaEntregaHasta,
                (fecha) {
                  setModalState(() => _localFechaEntregaDesde = fecha);
                  onFechaEntregaDesdeChanged(fecha);
                },
                (fecha) {
                  setModalState(() => _localFechaEntregaHasta = fecha);
                  onFechaEntregaHastaChanged(fecha);
                },
                () {
                  setModalState(() {
                    _localFechaEntregaDesde = null;
                    _localFechaEntregaHasta = null;
                  });
                  onFechaEntregaDesdeChanged(null);
                  onFechaEntregaHastaChanged(null);
                },
                DateTime(2020),
                DateTime(2100),
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 12),

              // ✅ NUEVO: Botones rápidos específicos para Entrega Solicitada
              Text(
                '⚡ Aplicar rápidamente a Entrega:',
                style: Theme.of(modalContext).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final ayer = DateTime.now().subtract(const Duration(days: 1));
                        setModalState(() {
                          _localFechaEntregaDesde = ayer;
                          _localFechaEntregaHasta = ayer;
                        });
                        onFechaEntregaDesdeChanged(ayer);
                        onFechaEntregaHastaChanged(ayer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Ayer', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        setModalState(() {
                          _localFechaEntregaDesde = hoy;
                          _localFechaEntregaHasta = hoy;
                        });
                        onFechaEntregaDesdeChanged(hoy);
                        onFechaEntregaHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Hoy', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final manana = DateTime.now().add(const Duration(days: 1));
                        setModalState(() {
                          _localFechaEntregaDesde = manana;
                          _localFechaEntregaHasta = manana;
                        });
                        onFechaEntregaDesdeChanged(manana);
                        onFechaEntregaHastaChanged(manana);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Mañana', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final hoy = DateTime.now();
                        final hace7Dias = hoy.subtract(const Duration(days: 7));
                        setModalState(() {
                          _localFechaEntregaDesde = hace7Dias;
                          _localFechaEntregaHasta = hoy;
                        });
                        onFechaEntregaDesdeChanged(hace7Dias);
                        onFechaEntregaHastaChanged(hoy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Últimos 7', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
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
    },
  );
}
