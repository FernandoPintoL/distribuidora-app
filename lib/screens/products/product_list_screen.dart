import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

        productProvider
            .loadMoreProducts(search: _searchController.text)
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
    await productProvider.loadProducts(search: _searchController.text);
  }

  /// Refresh: Limpia y recarga los productos desde el inicio
  Future<void> _refreshProducts() async {
    final productProvider = context.read<ProductProvider>();
    // Limpiar lista y resetear paginador
    productProvider.clearProducts();
    // Recargar desde página 1
    await productProvider.loadProducts(search: _searchController.text.isEmpty ? null : _searchController.text);
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

  Future<void> _openBarcodeScanner() async {
    try {
      // Abre directamente el diálogo del scanner
      // Si no hay permisos o hay error, el MobileScanner lo maneja
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => _buildBarcodeScannerDialog(),
      );
    } catch (e) {
      debugPrint('Error al abrir scanner: $e');
      // Si hay cualquier error, muestra entrada manual
      if (mounted) {
        _showManualBarcodeInput();
      }
    }
  }

  void _showManualBarcodeInput() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController manualController = TextEditingController();
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Ingresar código de barras',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          content: TextField(
            controller: manualController,
            autofocus: true,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Escanea o ingresa el código',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.qr_code, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.pop(context);
                _searchByBarcode(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (manualController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _searchByBarcode(manualController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarcodeScannerDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Escanear código de barras',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: colorScheme.outline.withAlpha(30)),
          // Scanner
          SizedBox(height: 300, child: _buildScannerContent()),
          Divider(height: 0, color: colorScheme.outline.withAlpha(30)),
          // Pie de página con opción manual
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Apunta la cámara al código de barras',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showManualBarcodeInput();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Ingresar manualmente'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent() {
    // Crear un nuevo controlador cada vez para evitar problemas de lifecycle
    final scannerController = MobileScannerController();

    return MobileScanner(
      controller: scannerController,
      onDetect: (capture) {
        try {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final scannedCode = barcodes.first.rawValue ?? '';
            if (scannedCode.isNotEmpty && mounted) {
              // Detener el scanner y cerrar el diálogo
              try {
                scannerController.stop();
              } catch (e) {
                debugPrint('Error al detener scanner: $e');
              }
              Navigator.pop(context);
              _searchByBarcode(scannedCode);
            }
          }
        } catch (e) {
          debugPrint('Error al detectar código: $e');
        }
      },
      errorBuilder: (context, error) {
        final colorScheme = Theme.of(context).colorScheme;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Error con la cámara',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Permiso denegado o dispositivo sin cámara',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showManualBarcodeInput();
                },
                icon: const Icon(Icons.edit),
                label: const Text('Entrada manual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchByBarcode(String barcode) {
    _searchController.text = barcode;
    _onSearchChanged(barcode);
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
                // Botón de scanner de código de barras - Premium style
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
                    onPressed: _openBarcodeScanner,
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Escanear código de barras',
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de cambio de vista - Premium style
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
                    onPressed: _toggleView,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween<double>(
                            begin: 0.0,
                            end: 0.5,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: colorScheme.primary,
                        size: 24,
                        key: ValueKey(_isGridView),
                      ),
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
                  return RefreshIndicator(
                    onRefresh: _loadProducts,
                    color: colorScheme.primary,
                    child: _isGridView
                        ? _buildGridView(productProvider)
                        : _buildListView(productProvider),
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
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  Widget _buildSkeletonLoading() {
    return _isGridView
        ? _buildResponsiveGridWithSkeletons()
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: 6,
            itemBuilder: (context, index) =>
                const ProductSkeletonWidget(isGridView: false),
          );
  }

  Widget _buildResponsiveGridWithSkeletons() {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    // Responsive grid configuration (same as _buildGridView)
    final crossAxisCount = isLandscape ? 3 : 2;
    final spacing = 16.0;
    final padding = 16.0;
    final availableWidth =
        screenSize.width - (padding * 2) - (spacing * (crossAxisCount - 1));
    final itemWidth = availableWidth / crossAxisCount;
    final mainAxisExtent = itemWidth * 1.4;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: 6,
      itemBuilder: (context, index) =>
          const ProductSkeletonWidget(isGridView: true),
    );
  }

  Widget _buildGridView(ProductProvider productProvider) {
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

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: Stack(
        children: [
          GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: mainAxisExtent,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return ProductGridItem(
                product: product,
                onTap: () => _onProductTap(product),
              );
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

  Widget _buildListView(ProductProvider productProvider) {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: productProvider.products.length,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return ProductListItem(
                product: product,
                onTap: () => _onProductTap(product),
              );
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

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return Consumer2<AuthProvider, CarritoProvider>(
      builder: (context, authProvider, carritoProvider, child) {
        // Si hay items en el carrito, mostrar botón para ir al carrito
        if (carritoProvider.items.isNotEmpty) {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/carrito');
            },
            elevation: 6,
            highlightElevation: 8,
            backgroundColor: colorScheme.primary,
            icon: const Icon(Icons.shopping_cart),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            label: Text(
              'Carrito (${carritoProvider.items.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        // Si el usuario puede crear productos, mostrar botón de agregar
        if (authProvider.canCreateProducts) {
          return FloatingActionButton(
            onPressed: () {
              // TODO: Navigate to create product screen
            },
            elevation: 6,
            highlightElevation: 8,
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
