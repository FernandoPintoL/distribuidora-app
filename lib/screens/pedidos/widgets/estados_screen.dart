import 'package:flutter/material.dart';
import '../../../extensions/theme_extension.dart';

/// ✅ Widgets para estados vacío y error
class EstadosScreen {
  /// Widget de estado vacío (sin pedidos)
  static Widget buildEmptyState(
    BuildContext context, {
    required bool tieneFilTros,
    required List<String> filtrosActivos,
    VoidCallback? onVerProductos,
  }) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tieneFilTros ? Icons.search_off : Icons.receipt_long_outlined,
                size: 80,
                color: isDark
                    ? colorScheme.onSurface.withOpacity(0.3)
                    : colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                tieneFilTros
                    ? '😔 No se encontraron pedidos'
                    : '📭 No tienes pedidos aún',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      tieneFilTros
                          ? 'Intenta ajustar tus filtros de búsqueda'
                          : 'Crea tu primer pedido desde el catálogo',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Mostrar filtros activos
                    if (tieneFilTros && filtrosActivos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros activos:',
                              style: context.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...filtrosActivos.map(
                              (filtro) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $filtro',
                                  style: context.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!tieneFilTros) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onVerProductos,
                  icon: const Icon(Icons.shopping_bag, size: 18),
                  label: const Text('Ver Productos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Widget de estado error
  static Widget buildErrorState(
    BuildContext context, {
    required String errorMessage,
    VoidCallback? onReintentar,
  }) {
    final colorScheme = context.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 70,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar pedidos',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
