import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../extensions/theme_extension.dart';
import 'producto_detalle_screen.dart' as producto;
import 'widgets/product_grid_view_builder.dart';
import 'widgets/product_list_view_builder.dart';
import 'widgets/product_floating_action_button.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isGridView = false; // ✅ MEJORADO: Abre en formato lista por defecto
  bool _isSearchFocused = false;
  bool _isLoadingMore = false; // Flag para prevenir race conditions en scroll
  late AnimationController _listAnimationController;
  // ✅ NUEVO: Control para mostrar categorías (true) o marcas (false)
  bool _mostrarCategorias = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Initialize list animation controller
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    Future.delayed(Duration.zero, () {
      // ✅ NUEVO: Cargar filtros disponibles
      final filtrosProvider = context.read<FiltrosProductoProvider>();
      filtrosProvider.loadFiltros();

      _loadProductsIfNeeded();
      // Trigger animation when products load
      _listAnimationController.forward(from: 0.0);
    });
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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final productProvider = context.read<ProductProvider>();

      debugPrint('📍 SCROLL LISTENER TRIGGERED');
      debugPrint('   isLoading: ${productProvider.isLoading}');
      debugPrint('   hasMorePages: ${productProvider.hasMorePages}');
      debugPrint(
        '   currentPage: ${productProvider.currentPage}/${productProvider.totalPages}',
      );
      debugPrint('   totalProducts: ${productProvider.products.length}');
      debugPrint('   _isLoadingMore flag: $_isLoadingMore');

      // Prevenir race conditions con flag local
      if (_isLoadingMore) {
        debugPrint('📍 ⚠️ YA ESTÁ CARGANDO - ignorando scroll');
        return;
      }

      if (!productProvider.isLoading && productProvider.hasMorePages) {
        _isLoadingMore = true;
        debugPrint('📍 ✅ Cargando más productos...');

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
              debugPrint('📍 ✅ Carga completada, flag reseteado');
            })
            .catchError((e) {
              _isLoadingMore = false;
              debugPrint('📍 ❌ Error en carga, flag reseteado');
            });
      } else if (!productProvider.hasMorePages) {
        debugPrint(
          '📍 ℹ️ No hay más productos. totalPages: ${productProvider.totalPages}, currentPage: ${productProvider.currentPage}',
        );
      } else if (productProvider.isLoading) {
        debugPrint('📍 ℹ️ Provider aún cargando...');
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
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    // ✅ NUEVO: Pasar filtros activos al loadProducts
    await productProvider.loadProducts(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
    );
  }

  /// Refresh: Limpia el input, limpia lista y recarga productos desde el inicio
  Future<void> _refreshProducts() async {
    final productProvider = context.read<ProductProvider>();
    final filtrosProvider = context.read<FiltrosProductoProvider>();
    // Limpiar campo de búsqueda
    _searchController.clear();
    // Limpiar lista y resetear paginador
    productProvider.clearProducts();
    // ✅ NUEVO: Recargar desde página 1 manteniendo filtros activos
    await productProvider.loadProducts(
      categoryId: filtrosProvider.categoriaIdSeleccionada,
      brandId: filtrosProvider.marcaIdSeleccionada,
    );
  }

  void _onSearchChanged(String value) {
    // La búsqueda ahora se hace al presionar Enter o al hacer clic en el botón
    // Esta función ya no se ejecuta automáticamente
  }

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
    // ✅ NUEVO: Limpiar búsqueda pero mantener filtros activos
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

    // ✅ NUEVO: Verificar si el usuario es preventista para mostrar AppBar
    bool isPreventista = false;
    try {
      final authProvider = context.read<AuthProvider>();
      final userRoles = authProvider.user?.roles ?? [];
      isPreventista = userRoles.any(
        (role) =>
            role.toLowerCase() == 'preventista' ||
            role.toLowerCase() == 'preventista',
      );
      debugPrint(
        '👤 [ProductListScreen] Roles del usuario: $userRoles, isPreventista: $isPreventista',
      );
    } catch (e) {
      debugPrint('❌ [ProductListScreen] Error al verificar rol: $e');
    }

    return Scaffold(
      appBar: isPreventista
          ? AppBar(
              title: const Text('Crear Pedido'),
              elevation: 0,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSearchFocused
                            ? colorScheme.primary.withAlpha(80)
                            : colorScheme.outline.withAlpha(30),
                        width: _isSearchFocused ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isSearchFocused
                              ? colorScheme.primary.withAlpha(20)
                              : Colors.black.withAlpha(6),
                          blurRadius: _isSearchFocused ? 16 : 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _performSearch(),
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
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de búsqueda - Premium style
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _performSearch,
                    icon: Icon(
                      Icons.search,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Buscar',
                  ),
                ),
                const SizedBox(width: 8),

                const SizedBox(width: 8),
                // Botón de recarga - Premium style
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _refreshProducts,
                    icon: Icon(
                      Icons.refresh,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Recargar',
                  ),
                ),
              ],
            ),
          ),

          // ✅ NUEVO: Chips de filtros horizontales para Categorías y Marcas
          Consumer<FiltrosProductoProvider>(
            builder: (context, filtrosProvider, _) {
              return Column(
                children: [
                  // ✅ NUEVO: Toggle para Categorías | Marcas
                  if ((filtrosProvider.categorias.isNotEmpty ||
                      filtrosProvider.marcas.isNotEmpty)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('CATEGORÍAS'),
                                ),
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('MARCAS'),
                                ),
                              ],
                              selected: {_mostrarCategorias},
                              onSelectionChanged: (value) {
                                setState(() {
                                  _mostrarCategorias = value.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mostrar solo categorías O marcas según toggle
                    if (_mostrarCategorias && filtrosProvider.categorias.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtrosProvider.categorias.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected =
                                  filtrosProvider.categoriaIdSeleccionada == null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: const Text('Todas'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    filtrosProvider.seleccionarCategoria(null);
                                    _loadProducts();
                                  },
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  selectedColor: colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
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
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(categoryName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    filtrosProvider.seleccionarCategoria(
                                      categoryId,
                                    );
                                    _loadProducts();
                                  }
                                },
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                selectedColor: colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (!_mostrarCategorias &&
                        filtrosProvider.marcas.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtrosProvider.marcas.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected =
                                  filtrosProvider.marcaIdSeleccionada == null;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: const Text('Todas'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    filtrosProvider.seleccionarMarca(null);
                                    _loadProducts();
                                  },
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  selectedColor: colorScheme.secondary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onSecondary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            final marca = filtrosProvider.marcas[index - 1];
                            final marcaId = marca['id'] as int?;
                            final marcaNombre = marca['nombre'] as String? ?? '';
                            final isSelected =
                                filtrosProvider.marcaIdSeleccionada == marcaId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(marcaNombre),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    filtrosProvider.seleccionarMarca(marcaId);
                                    _loadProducts();
                                  }
                                },
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                selectedColor: colorScheme.secondary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onSecondary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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

          // Lista de productos
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                debugPrint(
                  '🔍 Consumer rebuild - isLoading: ${productProvider.isLoading}, productos: ${productProvider.products.length}',
                );
                // Estado de carga - Mostrar simple loading
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

                // Estado de error
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
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.error,
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

                // Estado vacío
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
                          style: context.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                // Grid o Lista de productos
                debugPrint(
                  '✅ Construyendo ${_isGridView ? "GRID" : "LIST"} con ${productProvider.products.length} productos',
                );
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
