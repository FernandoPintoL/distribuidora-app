import 'package:flutter/material.dart';
import '../../../extensions/theme_extension.dart';
import '../../../config/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final bool tieneFilTros;
  final List<String> filtrosActivos;
  final VoidCallback? onVerProductos;

  const EmptyState({
    required this.tieneFilTros,
    required this.filtrosActivos,
    this.onVerProductos,
  });

  @override
  Widget build(BuildContext context) {
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
                    ? 'No se encontraron pedidos'
                    : 'No tienes pedidos aún',
                style: AppTextStyles.titleLarge(context)
                    .copyWith(color: colorScheme.onSurface),
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
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    if (tieneFilTros && filtrosActivos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.3),
                          border: Border.all(
                            color: colorScheme.error.withOpacity(0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros activos:',
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...filtrosActivos.map(
                              (filtro) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '•',
                                      style:
                                          AppTextStyles.bodyMedium(
                                            context,
                                          ).copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        filtro,
                                        style:
                                            AppTextStyles.bodyMedium(
                                              context,
                                            ).copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
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
                  label: const Text('Ver productos'),
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
}
