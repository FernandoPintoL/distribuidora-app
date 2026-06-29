import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../extensions/theme_extension.dart';
import 'producto_detalle_screen.dart' as producto;
import 'widgets/product_list_view_builder.dart';
import 'widgets/product_floating_action_button.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchFocused = false;
  bool _isLoadingMore = false;
  late AnimationController _listAnimationController;
  bool _mostrarCategorias = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(Duration.zero, () {
      final filtrosProvider = context.read<FiltrosProductoProvider>();
      filtrosProvider.loadFiltros();

      _reloadProducts();
      _listAnimationController.forward(from: 0.0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadProducts();
    }
  }

  void _reloadProducts() {
    final productProvider = context.read<ProductProvider>();
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    productProvider.clearProducts();
    productProvider.loadProducts(
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
    );
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _listAnimationController.dispose();
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final productProvider = context.read<ProductProvider>();

      if (_isLoadingMore) {
        return;
      }

      if (!productProvider.isLoading && productProvider.hasMorePages) {
        _isLoadingMore = true;

        final filtrosProvider = context.read<FiltrosProductoProvider>();
        productProvider
            .loadMoreProducts(
              search: _searchController.text.isEmpty
                  ? null
                  : _searchController.text,
              categoryId: filtrosProvider.categoriaIdSeleccionada,
              brandId: filtrosProvider.marcaIdSeleccionada,
            )
            .then((_) {
              _isLoadingMore = false;
            })
            .catchError((e) {
              _isLoadingMore = false;
            });
      }
    }
  }

  Future<void> _loadProducts() async {
    final productProvider = context.read<ProductProvider>();
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    await productProvider.loadProducts(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
    );
  }

  Future<void> _refreshProducts() async {
    final productProvider = context.read<ProductProvider>();
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    _searchController.clear();
    productProvider.clearProducts();
    await productProvider.loadProducts(
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
    );
  }

  void _onSearchChanged(String value) {}

  void _performSearch() {
    final productProvider = context.read<ProductProvider>();
    final searchText = _searchController.text;
    productProvider.loadProducts(
      search: searchText.isEmpty ? null : searchText,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    final productProvider = context.read<ProductProvider>();
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    productProvider.loadProducts(
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    bool isPreventista = false;
    try {
      final authProvider = context.read<AuthProvider>();
      final userRoles = authProvider.user?.roles ?? [];
      isPreventista = userRoles.any(
        (role) =>
            role.toLowerCase() == 'preventista' ||
            role.toLowerCase() == 'preventista',
      );
    } catch (e) {
      debugPrint('❌ Error al verificar rol: $e');
    }

    return Scaffold(
      appBar: isPreventista
          ? AppBar(
              title: const Text('Crear Pedido'),
              // backgroundColor: colorScheme.surface,
              // foregroundColor: colorScheme.onSurface,
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: _refreshProducts,
                  icon: Icon(Icons.refresh, size: 24),
                  tooltip: 'Recargar',
                ),
              ],
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                // prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? SizedBox(
                        width: 96,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _performSearch,
                              icon: const Icon(Icons.search, size: 20),
                              tooltip: 'Buscar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 40,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSearch,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 40,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Consumer<FiltrosProductoProvider>(
            builder: (context, filtrosProvider, _) {
              return Column(
                children: [
                  if ((filtrosProvider.categorias.isNotEmpty ||
                      filtrosProvider.marcas.isNotEmpty)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _mostrarCategorias = true);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _mostrarCategorias
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _mostrarCategorias
                                          ? const Color(0xFFFFB800)
                                          : colorScheme.outline.withAlpha(50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.category, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CATEGORÍAS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _mostrarCategorias
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _mostrarCategorias = false);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_mostrarCategorias
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !_mostrarCategorias
                                          ? const Color(0xFFFFB800)
                                          : colorScheme.outline.withAlpha(50),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_offer, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'MARCAS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: !_mostrarCategorias
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_mostrarCategorias &&
                        filtrosProvider.categorias.isNotEmpty)
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtrosProvider.categorias.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected =
                                  filtrosProvider.categoriaIdSeleccionada ==
                                  null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFB800)
                                          : colorScheme.outline.withAlpha(40),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        filtrosProvider.seleccionarCategoria(
                                          null,
                                        );
                                        _loadProducts();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Todas',
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final category =
                                filtrosProvider.categorias[index - 1];
                            final categoryId = category['id'] as int?;
                            final categoryName =
                                category['nombre'] as String? ?? '';
                            final isSelected =
                                filtrosProvider.categoriaIdSeleccionada ==
                                categoryId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFB800)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.outline.withAlpha(40),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      filtrosProvider.seleccionarCategoria(
                                        categoryId,
                                      );
                                      _loadProducts();
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            Icon(Icons.check_circle, size: 14),
                                          if (isSelected)
                                            const SizedBox(width: 6),
                                          Text(
                                            categoryName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (!_mostrarCategorias &&
                        filtrosProvider.marcas.isNotEmpty)
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtrosProvider.marcas.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected =
                                  filtrosProvider.marcaIdSeleccionada == null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFB800)
                                          : colorScheme.outline.withAlpha(40),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        filtrosProvider.seleccionarMarca(null);
                                        _loadProducts();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Todas',
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final marca = filtrosProvider.marcas[index - 1];
                            final marcaId = marca['id'] as int?;
                            final marcaNombre =
                                marca['nombre'] as String? ?? '';
                            final isSelected =
                                filtrosProvider.marcaIdSeleccionada == marcaId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFB800)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFB800)
                                        : colorScheme.outline.withAlpha(40),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      filtrosProvider.seleccionarMarca(marcaId);
                                      _loadProducts();
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            Icon(Icons.check_circle, size: 14),
                                          if (isSelected)
                                            const SizedBox(width: 6),
                                          Text(
                                            marcaNombre,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ],
              );
            },
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando productos...',
                          style: context.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                if (productProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${productProvider.errorMessage}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos disponibles',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                try {
                  return ProductListViewBuilder(
                    productProvider: productProvider,
                    scrollController: _scrollController,
                    onProductTap: _onProductTap,
                    onRefresh: _loadProducts,
                  );
                } catch (e) {
                  debugPrint('❌ ERROR construyendo lista/grid: $e');
                  return Center(child: Text('Error: $e'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const ProductFloatingActionButton(),
    );
  }
}
