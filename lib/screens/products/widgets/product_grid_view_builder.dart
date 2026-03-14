import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../widgets/product/product_grid_item.dart';

/// Widget que construye la vista de grid de productos
class ProductGridViewBuilder extends StatelessWidget {
  final ProductProvider productProvider;
  final ScrollController scrollController;
  final Function(Product) onProductTap;
  final Future<void> Function() onRefresh;

  const ProductGridViewBuilder({
    super.key,
    required this.productProvider,
    required this.scrollController,
    required this.onProductTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    // Responsive grid configuration
    final crossAxisCount = isLandscape ? 3 : 2;
    final spacing = 16.0;
    final padding = 16.0;
    final availableWidth =
        screenSize.width - (padding * 2) - (spacing * (crossAxisCount - 1));
    final maxItemWidth = availableWidth / crossAxisCount;
    // Altura compacta: ajustada al contenido
    final mainAxisExtent = maxItemWidth * 1.0;

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
          CustomScrollView(
            controller: scrollController,
            slivers: [
              // Sección de Combos
              if (combos.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '🎁 Combos Especiales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: mainAxisExtent,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = combos[index];
                      return ProductGridItem(
                        product: product,
                        onTap: () => onProductTap(product),
                      );
                    }, childCount: combos.length),
                  ),
                ),
              ],

              // Separador
              if (tieneCombosSeparados)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(50),
                    ),
                  ),
                ),

              // Sección de Productos Normales
              if (productosNormales.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Productos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: mainAxisExtent,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = productosNormales[index];
                      return ProductGridItem(
                        product: product,
                        onTap: () => onProductTap(product),
                      );
                    }, childCount: productosNormales.length),
                  ),
                ),
              ],
            ],
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
