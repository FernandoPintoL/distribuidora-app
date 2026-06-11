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
        }).catchError((e) {
          _isLoadingMore = false;
        });
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
          Consumer<FiltrosProductoProvider>(
            builder: (context, filtrosProvider, _) {
              return Column(
                children: [
                  if ((filtrosProvider.categorias.isNotEmpty ||
                      filtrosProvider.marcas.isNotEmpty)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer.withAlpha(120),
                              colorScheme.primaryContainer.withAlpha(80),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withAlpha(100),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: _mostrarCategorias
                                          ? LinearGradient(
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme.primary
                                                    .withAlpha(200),
                                              ],
                                            )
                                          : null,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 18,
                                          color: _mostrarCategorias
                                              ? colorScheme.onPrimary
                                              : colorScheme.onPrimaryContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'CATEGORÍAS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _mostrarCategorias
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: _mostrarCategorias
                                                ? colorScheme.onPrimary
                                                : colorScheme
                                                    .onPrimaryContainer,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _mostrarCategorias = false);
                                  },
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: !_mostrarCategorias
                                          ? LinearGradient(
                                              colors: [
                                                colorScheme.secondary,
                                                colorScheme.secondary
                                                    .withAlpha(200),
                                              ],
                                            )
                                          : null,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_offer,
                                          size: 18,
                                          color: !_mostrarCategorias
                                              ? colorScheme.onSecondary
                                              : colorScheme
                                                  .onSecondaryContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'MARCAS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: !_mostrarCategorias
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: !_mostrarCategorias
                                                ? colorScheme.onSecondary
                                                : colorScheme
                                                    .onSecondaryContainer,
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
                    ),
                    const SizedBox(height: 12),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.primary
                                                  .withAlpha(180),
                                            ],
                                          )
                                        : null,
                                    color: !isSelected
                                        ? colorScheme.surfaceContainerHighest
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline
                                              .withAlpha(40),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withAlpha(30),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        filtrosProvider
                                            .seleccionarCategoria(null);
                                        _loadProducts();
                                      },
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Todas',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? colorScheme.onPrimary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final category = filtrosProvider
                                .categorias[index - 1];
                            final categoryId = category['id'] as int?;
                            final categoryName =
                                category['nombre'] as String? ?? '';
                            final isSelected =
                                filtrosProvider.categoriaIdSeleccionada ==
                                    categoryId;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.primary
                                                .withAlpha(180),
                                          ],
                                        )
                                      : null,
                                  color: !isSelected
                                      ? colorScheme.surfaceContainerHighest
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline
                                            .withAlpha(40),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withAlpha(30),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      filtrosProvider
                                          .seleccionarCategoria(
                                        categoryId,
                                      );
                                      _loadProducts();
                                    },
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: colorScheme.onPrimary,
                                            ),
                                          if (isSelected)
                                            const SizedBox(width: 6),
                                          Text(
                                            categoryName,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? colorScheme.onPrimary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13,
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              colorScheme.secondary,
                                              colorScheme.secondary
                                                  .withAlpha(180),
                                            ],
                                          )
                                        : null,
                                    color: !isSelected
                                        ? colorScheme.surfaceContainerHighest
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.secondary
                                          : colorScheme.outline
                                              .withAlpha(40),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colorScheme.secondary
                                                  .withAlpha(30),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        filtrosProvider
                                            .seleccionarMarca(null);
                                        _loadProducts();
                                      },
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Todas',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? colorScheme.onSecondary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final marca =
                                filtrosProvider.marcas[index - 1];
                            final marcaId = marca['id'] as int?;
                            final marcaNombre =
                                marca['nombre'] as String? ?? '';
                            final isSelected =
                                filtrosProvider.marcaIdSeleccionada ==
                                    marcaId;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            colorScheme.secondary,
                                            colorScheme.secondary
                                                .withAlpha(180),
                                          ],
                                        )
                                      : null,
                                  color: !isSelected
                                      ? colorScheme.surfaceContainerHighest
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.secondary
                                        : colorScheme.outline
                                            .withAlpha(40),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: colorScheme.secondary
                                                .withAlpha(30),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      filtrosProvider
                                          .seleccionarMarca(marcaId);
                                      _loadProducts();
                                    },
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color:
                                                  colorScheme.onSecondary,
                                            ),
                                          if (isSelected)
                                            const SizedBox(width: 6),
                                          Text(
                                            marcaNombre,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? colorScheme.onSecondary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13,
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
