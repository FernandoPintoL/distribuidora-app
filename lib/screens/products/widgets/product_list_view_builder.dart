import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../widgets/product/product_list_item.dart';

/// Widget que construye la vista de lista de productos
class ProductListViewBuilder extends StatelessWidget {
  final ProductProvider productProvider;
  final ScrollController scrollController;
  final Function(Product) onProductTap;
  final Future<void> Function() onRefresh;

  const ProductListViewBuilder({
    super.key,
    required this.productProvider,
    required this.scrollController,
    required this.onProductTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ NUEVO: Separar combos de productos normales
    final combos = productProvider.products
        .where((p) => p.esCombo == true)
        .toList();
    final productosNormales = productProvider.products
        .where((p) => p.esCombo != true)
        .toList();
    final tieneCombosSeparados =
        combos.isNotEmpty && productosNormales.isNotEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Stack(
        children: [
          ListView.builder(
            controller: scrollController,
            itemCount:
                combos.length +
                productosNormales.length +
                (tieneCombosSeparados ? 1 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            itemBuilder: (context, index) {
              // Sección de Combos
              if (index < combos.length) {
                final product = combos[index];
                return ProductListItem(
                  product: product,
                  onTap: () => onProductTap(product),
                );
              }

              // Separador entre combos y productos normales (solo si hay ambos)
              if (tieneCombosSeparados && index == combos.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Divider(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(50),
                        height: 1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Productos Regulares',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                );
              }

              // Sección de Productos Normales
              final productIndex =
                  index - combos.length - (tieneCombosSeparados ? 1 : 0);
              if (productIndex < productosNormales.length) {
                final product = productosNormales[productIndex];
                return ProductListItem(
                  product: product,
                  onTap: () => onProductTap(product),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          // Loading indicator at bottom when fetching more products
          if (productProvider.isLoading && productProvider.products.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
