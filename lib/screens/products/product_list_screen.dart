import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_text_styles.dart';
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
    _performSearch();
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  // ✅ NUEVO: Mostrar filtros avanzados
  void _showAdvancedFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    final filtrosProvider = context.read<FiltrosProductoProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer<FiltrosProductoProvider>(
        builder: (context, filtros, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros Avanzados',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sección de Categorías
                  Text(
                    'Categorías',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtros.isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  else if (filtros.categorias.isEmpty)
                    Text(
                      'Sin categorías disponibles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    )
                  else
                    Column(
                      children: [
                        RadioListTile<int?>(
                          value: null,
                          groupValue: filtros.categoriaIdSeleccionada,
                          onChanged: (value) {
                            filtros.seleccionarCategoria(value);
                            Navigator.pop(context);
                            _loadProducts();
                          },
                          title: const Text('Todas las categorías'),
                          dense: true,
                        ),
                        ...filtros.categorias.map((cat) {
                          final id = cat['id'] as int?;
                          final nombre = cat['nombre'] as String?;
                          return RadioListTile<int?>(
                            value: id,
                            groupValue: filtros.categoriaIdSeleccionada,
                            onChanged: (value) {
                              filtros.seleccionarCategoria(value);
                              Navigator.pop(context);
                              _loadProducts();
                            },
                            title: Text(nombre ?? 'Sin nombre'),
                            dense: true,
                          );
                        }).toList(),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Sección de Marcas
                  Text(
                    'Marcas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtros.marcas.isEmpty)
                    Text(
                      'Sin marcas disponibles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    )
                  else
                    Column(
                      children: [
                        RadioListTile<int?>(
                          value: null,
                          groupValue: filtros.marcaIdSeleccionada,
                          onChanged: (value) {
                            filtros.seleccionarMarca(value);
                            Navigator.pop(context);
                            _loadProducts();
                          },
                          title: const Text('Todas las marcas'),
                          dense: true,
                        ),
                        ...filtros.marcas.map((marca) {
                          final id = marca['id'] as int?;
                          final nombre = marca['nombre'] as String?;
                          return RadioListTile<int?>(
                            value: id,
                            groupValue: filtros.marcaIdSeleccionada,
                            onChanged: (value) {
                              filtros.seleccionarMarca(value);
                              Navigator.pop(context);
                              _loadProducts();
                            },
                            title: Text(nombre ?? 'Sin nombre'),
                            dense: true,
                          );
                        }).toList(),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            filtros.limpiarFiltros();
                            Navigator.pop(context);
                            _loadProducts();
                          },
                          child: const Text('Limpiar filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
                // ✅ NUEVO: Botón de filtros con badge - Premium style
                Consumer<FiltrosProductoProvider>(
                  builder: (context, filtrosProvider, _) {
                    final hayFiltros = filtrosProvider.hayFiltrosActivos;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerHighest.withAlpha(
                                    100,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hayFiltros
                                  ? colorScheme.primary.withAlpha(80)
                                  : colorScheme.outline.withAlpha(30),
                              width: hayFiltros ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: hayFiltros
                                    ? colorScheme.primary.withAlpha(20)
                                    : Colors.black.withAlpha(6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showAdvancedFilters,
                            icon: Icon(
                              Icons.tune,
                              color: hayFiltros
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                              size: 24,
                            ),
                            tooltip: 'Filtros avanzados',
                          ),
                        ),
                        if (hayFiltros)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${filtrosProvider.conteoFiltrosActivos}',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
      onRefresh: _refreshProducts,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
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
                        onTap: () => _onProductTap(product),
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
                        onTap: () => _onProductTap(product),
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

  Widget _buildListView(ProductProvider productProvider) {
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
      onRefresh: _refreshProducts,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
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
                  onTap: () => _onProductTap(product),
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
                  onTap: () => _onProductTap(product),
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
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
