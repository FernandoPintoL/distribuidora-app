import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/product/index.dart';
import '../../widgets/product/product_grid_item.dart';
import '../../widgets/product/product_list_item.dart';
import '../../extensions/theme_extension.dart';
import 'producto_detalle_screen.dart' as producto;

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, () {
      _loadProductsIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final productProvider = context.read<ProductProvider>();
      if (!productProvider.isLoading && productProvider.hasMorePages) {
        productProvider.loadMoreProducts(search: _searchController.text);
      }
    }
  }

  Future<void> _loadProductsIfNeeded() async {
    final productProvider = context.read<ProductProvider>();
    if (productProvider.products.isEmpty && !productProvider.isLoading) {
      await productProvider.loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadProducts(search: _searchController.text);
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final productProvider = context.read<ProductProvider>();
      productProvider.loadProducts(search: value.isEmpty ? null : value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final productProvider = context.read<ProductProvider>();
    productProvider.loadProducts();
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda moderna
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      hintStyle: TextStyle(
                        color: context.textTheme.bodySmall?.color,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerHighest.withAlpha(100),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de cambio de vista
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _toggleView,
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: colorScheme.primary,
                    ),
                    tooltip: _isGridView
                        ? 'Vista de lista'
                        : 'Vista de cuadrícula',
                  ),
                ),
              ],
            ),
          ),

          // Chips de categoría (placeholder - necesitarías cargar categorías)
          /* Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('Todas', null),
                // Agregar más categorías dinámicamente
              ],
            ),
          ), */

          // Lista de productos
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                // Estado de carga inicial con skeleton
                if (productProvider.isLoading &&
                    productProvider.products.isEmpty) {
                  return _buildSkeletonLoading();
                }

                // Estado de error
                if (productProvider.errorMessage != null &&
                    productProvider.products.isEmpty) {
                  return _buildErrorState(
                    productProvider.errorMessage!,
                    colorScheme,
                  );
                }

                // Estado vacío
                if (productProvider.products.isEmpty) {
                  return _buildEmptyState(colorScheme, isDark);
                }

                // Grid o Lista de productos
                return RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: colorScheme.primary,
                  child: _isGridView
                      ? _buildGridView(productProvider)
                      : _buildListView(productProvider),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.canCreateProducts) {
            return FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create product screen
              },
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) =>
                const ProductSkeletonWidget(isGridView: true),
          )
        : ListView.builder(
            itemCount: 6,
            itemBuilder: (context, index) =>
                const ProductSkeletonWidget(isGridView: false),
          );
  }

  Widget _buildGridView(ProductProvider productProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount:
          productProvider.products.length + (productProvider.isLoading ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return const ProductSkeletonWidget(isGridView: true);
        }
        final product = productProvider.products[index];
        return ProductGridItem(
          product: product,
          onTap: () => _onProductTap(product),
        );
      },
    );
  }

  Widget _buildListView(ProductProvider productProvider) {
    return ListView.builder(
      controller: _scrollController,
      itemCount:
          productProvider.products.length + (productProvider.isLoading ? 1 : 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return const ProductSkeletonWidget(isGridView: false);
        }
        final product = productProvider.products[index];
        return ProductListItem(
          product: product,
          onTap: () => _onProductTap(product),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 120,
            color: isDark
                ? colorScheme.onSurface.withAlpha(80)
                : colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron productos'
                : 'No hay productos disponibles',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Los productos aparecerán aquí cuando estén disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: colorScheme.error),
          const SizedBox(height: 24),
          Text(
            'Error al cargar productos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _onProductTap(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => producto.ProductoDetalleScreen(producto: product),
      ),
    );
  }
}
