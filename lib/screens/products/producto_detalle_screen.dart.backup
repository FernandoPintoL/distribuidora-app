import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';

/// Pantalla de detalle de producto
/// Muestra información completa del producto y permite agregar al carrito
class ProductoDetalleScreen extends StatefulWidget {
  final Product producto;

  const ProductoDetalleScreen({
    super.key,
    required this.producto,
  });

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late TextEditingController _cantidadController;
  late TextEditingController _observacionesController;
  late FocusNode _cantidadFocusNode;
  int _cantidad = 1;
  bool _agregandoAlCarrito = false;

  // ✅ NUEVO: Estado para items opcionales de combos (múltiples selecciones)
  final List<ComboItem> _itemsOpcionalesSeleccionados = [];
  final Map<int, int> _cantidadesOpcionales = {};

  @override
  void initState() {
    super.initState();
    _cantidadFocusNode = FocusNode();
    _observacionesController = TextEditingController();

    // ✅ Inicializar controller con valor por defecto
    _cantidadController = TextEditingController(text: '1');

    // ✅ NUEVO: Actualizar con la cantidad actual en el carrito + cargar combo items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final carritoProvider = context.read<CarritoProvider>();
        final cantidadEnCarrito = carritoProvider.obtenerCantidadProducto(widget.producto.id);
        if (cantidadEnCarrito > 0) {
          _cantidad = cantidadEnCarrito;
          _cantidadController.text = _cantidad.toString();

          // ✅ NUEVO: Cargar items opcionales seleccionados desde el carrito
          _cargarItemsOpcionalesDelCarrito(carritoProvider);
        }

        // ✅ NUEVO: Agregar listener para detectar pérdida de foco
        _cantidadFocusNode.addListener(() {
          if (!_cantidadFocusNode.hasFocus && mounted) {
            _onFocusLostCantidad();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
    _cantidadFocusNode.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Cargar items opcionales seleccionados desde el carrito
  void _cargarItemsOpcionalesDelCarrito(CarritoProvider carritoProvider) {
    try {
      final item = carritoProvider.carrito.items.firstWhere(
        (i) => i.producto.id == widget.producto.id,
      );

      // Si el item tiene comboItemsSeleccionados, cargarlos
      if (item.comboItemsSeleccionados != null && item.comboItemsSeleccionados!.isNotEmpty) {
        _itemsOpcionalesSeleccionados.clear();
        _cantidadesOpcionales.clear();

        final comboItems = widget.producto.comboItems ?? [];
        final itemsOpcionales = comboItems.where((c) => !c.esObligatorio).toList();

        for (final selectedItem in item.comboItemsSeleccionados!) {
          final comboItemId = selectedItem['combo_item_id'];
          final cantidad = selectedItem['cantidad'] ?? 1;

          // Buscar el ComboItem correspondiente
          try {
            final comboItem = itemsOpcionales.firstWhere(
              (c) => c.id == comboItemId,
            );
            _itemsOpcionalesSeleccionados.add(comboItem);
            _cantidadesOpcionales[comboItemId] = cantidad;
          } catch (e) {
            debugPrint('⚠️ No se encontró combo item con id $comboItemId');
          }
        }

        setState(() {});
        debugPrint('✅ Items opcionales cargados: ${_itemsOpcionalesSeleccionados.length}');
      }
    } catch (e) {
      // No hay item en el carrito para este producto
      debugPrint('ℹ️ No hay item en carrito para este producto');
    }
  }

  // ✅ NUEVO: Construir combo items (obligatorios + opcionales seleccionados)
  List<Map<String, dynamic>>? _construirComboItems() {
    if (!widget.producto.esCombo) return null;

    final items = widget.producto.comboItems ?? [];
    if (items.isEmpty) return null;

    return [
      // Obligatorios (cantidad fija del combo)
      ...items.where((i) => i.esObligatorio).map((i) => {
        'combo_item_id': i.id,
        'producto_id': i.productoId,
        'cantidad': i.cantidad,
      }),
      // Opcionales seleccionados (cantidad modificable)
      ..._itemsOpcionalesSeleccionados.map((item) => {
        'combo_item_id': item.id,
        'producto_id': item.productoId,
        'cantidad': _cantidadesOpcionales[item.id] ?? item.cantidad,
      }),
    ];
  }

  void _incrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.producto.id);
    final stock = (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num).toInt();

    if (cantidadActual < stock) {
      // ✅ ACTUALIZADO: Agregar combo con items obligatorios pre-incluidos
      carritoProvider.agregarProducto(
        widget.producto,
        cantidad: 1,
        comboItemsSeleccionados: _construirComboItems(),
      );

      // ✅ NUEVO: Sincronizar el input
      setState(() {
        _cantidad = cantidadActual + 1;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  void _decrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.producto.id);

    if (cantidadActual > 0) {
      // Decrementar 1 unidad del carrito
      carritoProvider.decrementarCantidad(widget.producto.id);

      // ✅ NUEVO: Sincronizar el input
      setState(() {
        _cantidad = cantidadActual - 1;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  void _actualizarCantidad(String valor) {
    final carritoProvider = context.read<CarritoProvider>();
    final stock =
        (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num).toInt();

    // ✅ NUEVO: Si está vacío mientras escribe, ignorar (no eliminar)
    if (valor.isEmpty) {
      return;
    }

    final cantidadIngresada = int.tryParse(valor) ?? 0;

    // ✅ NUEVO: Si es 0 o negativo, ignorar (no eliminar automáticamente)
    if (cantidadIngresada <= 0) {
      return;
    }

    if (cantidadIngresada > stock) {
      // Si excede stock, ajustar al máximo disponible
      _mostrarError('La cantidad no puede exceder el stock disponible ($stock)');
      _cantidadController.text = stock.toString();
      carritoProvider.actualizarCantidad(widget.producto.id, stock);
      setState(() => _cantidad = stock);
      return;
    }

    // ✅ Actualizar cantidad directamente en el carrito
    carritoProvider.actualizarCantidad(widget.producto.id, cantidadIngresada);
    setState(() => _cantidad = cantidadIngresada);
  }

  // ✅ NUEVO: Manejar cuando el usuario pierde el foco del input
  void _onFocusLostCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final stock =
        (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num).toInt();
    final valor = _cantidadController.text.trim();

    // Si dejó el campo vacío o con 0, eliminar del carrito
    if (valor.isEmpty || int.tryParse(valor) == null || int.tryParse(valor)! <= 0) {
      carritoProvider.eliminarProducto(widget.producto.id);
      setState(() {
        _cantidad = 1;
        _cantidadController.text = '1';
      });
      return;
    }

    final cantidadIngresada = int.tryParse(valor) ?? 1;

    // Ajustar si excede stock
    if (cantidadIngresada > stock) {
      _cantidadController.text = stock.toString();
      carritoProvider.actualizarCantidad(widget.producto.id, stock);
      setState(() => _cantidad = stock);
      return;
    }

    // Actualizar con el valor final
    carritoProvider.actualizarCantidad(widget.producto.id, cantidadIngresada);
    setState(() => _cantidad = cantidadIngresada);
  }

  Future<void> _agregarAlCarrito() async {
    final carritoProvider = context.read<CarritoProvider>();

    // Validar cantidad
    if (_cantidad <= 0) {
      _mostrarError('La cantidad debe ser mayor a 0');
      return;
    }

    // ✅ ACTUALIZADO: Los combos se pueden agregar solo con items obligatorios
    // Los items opcionales son... opcionales. No es obligatorio seleccionar ninguno.

    setState(() => _agregandoAlCarrito = true);

    try {
      // Simular delay de procesamiento
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ ACTUALIZADO: Usar método auxiliar para construir combo items
      final comboItemsSeleccionados = _construirComboItems();

      if (widget.producto.esCombo) {
        debugPrint('🔍 [_agregarAlCarrito] Items opcionales seleccionados: ${_itemsOpcionalesSeleccionados.length}');
        debugPrint('📦 [ProductoDetalle] Combo items construidos: $comboItemsSeleccionados');
      }

      // ✅ Agregar al carrito con comboItemsSeleccionados
      carritoProvider.agregarProducto(
        widget.producto,
        cantidad: _cantidad,
        observaciones: _observacionesController.text.isNotEmpty
            ? _observacionesController.text
            : null,
        comboItemsSeleccionados: comboItemsSeleccionados,
      );

      if (!mounted) return;

      // Verificar si hay error en el provider
      if (carritoProvider.errorMessage != null) {
        _mostrarError(carritoProvider.errorMessage!);
        return;
      }

      // Éxito
      _mostrarExito('${widget.producto.nombre} agregado al carrito');

      // Limpiar formulario
      _cantidadController.text = '1';
      _observacionesController.clear();
      setState(() {
        _cantidad = 1;
        _itemsOpcionalesSeleccionados.clear();
        _cantidadesOpcionales.clear();
      });
    } catch (e) {
      _mostrarError('Error al agregar al carrito: $e');
    } finally {
      if (mounted) {
        setState(() => _agregandoAlCarrito = false);
      }
    }
  }

  /// ✅ ACTUALIZADO: Actualizar items opcionales del combo en el carrito automáticamente
  void _actualizarComboEnCarrito() {
    if (!widget.producto.esCombo) return;

    final carritoProvider = context.read<CarritoProvider>();

    // ✅ ACTUALIZADO: Usar método auxiliar para construir combo items
    final comboItemsSeleccionados = _construirComboItems();

    // Guardar en CarritoProvider
    carritoProvider.actualizarComboItems(
      widget.producto.id,
      comboItemsSeleccionados,
    );

    debugPrint('💾 [ProductoDetalle] Combo items guardados en carrito automáticamente: ${comboItemsSeleccionados?.length ?? 0} items');
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CarritoProvider, ProductProvider>(
      builder: (context, carritoProvider, productProvider, _) {
        final stockDisponible =
            widget.producto.stockPrincipal?.cantidadDisponible ?? 0;
        final stockDispInt = (stockDisponible as num).toInt();
        final tieneStock = stockDispInt > 0;
        final cantidadMinima = widget.producto.cantidadMinima ?? 1;

        return Scaffold(
          appBar: CustomGradientAppBar(
            title: widget.producto.nombre,
            customGradient: AppGradients.blue,
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del producto
                  _buildImageGallery(),

                  // Información básica
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre y precio
                        _buildNombreYPrecio(),
                        const SizedBox(height: 16),

                        // Información de stock
                        _buildStockInfo(tieneStock, stockDispInt),
                        const SizedBox(height: 16),

                        // Descripción
                        if (widget.producto.descripcion != null &&
                            widget.producto.descripcion!.isNotEmpty)
                          _buildDescripcion(),

                        // Detalles adicionales
                        const SizedBox(height: 16),
                        _buildDetallesAdicionales(),

                        // Productos del combo si aplica
                        if (widget.producto.esCombo &&
                            widget.producto.comboItems != null &&
                            widget.producto.comboItems!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildProductosCombo(),

                          // ✅ NUEVO: Componentes requeridos basado en cantidad seleccionada
                          _buildComponentesRequeridos(),
                        ],

                        // Volume discounts si existen
                        const SizedBox(height: 16),
                        // Aquí va el widget VolumeDiscountDisplay cuando se integre con descuentos
                      ],
                    ),
                  ),

                  // Sección de agregar al carrito
                  _buildSeccionAgregarAlCarrito(
                    tieneStock: tieneStock,
                    cantidadMinima: cantidadMinima,
                    stockDisponible: stockDispInt,
                  ),
                  SizedBox(height: 16,)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery() {
    final imagenes = widget.producto.imagenes;
    final colorScheme = context.colorScheme;

    if (imagenes == null || imagenes.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: colorScheme.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      color: colorScheme.surfaceVariant,
      child: PageView.builder(
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          return Image.network(
            imagenes[index].url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.broken_image,
                  size: 80,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNombreYPrecio() {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.producto.nombre,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (widget.producto.codigo.isNotEmpty)
          Text(
            'Código: ${widget.producto.codigo}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        const SizedBox(height: 12),
        Text(
          'Bs ${(widget.producto.precioVenta ?? 0).toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade400,
              ),
        ),
      ],
    );
  }

  Widget _buildStockInfo(bool tieneStock, int stockDisponible) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final backgroundColor = tieneStock
        ? (isDark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50)
        : (isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50);

    final borderColor = tieneStock
        ? (isDark ? Colors.green.shade700 : Colors.green.shade300)
        : (isDark ? Colors.red.shade700 : Colors.red.shade300);

    final iconColor = tieneStock
        ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
        : (isDark ? Colors.red.shade400 : Colors.red.shade700);

    final textColor = tieneStock
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.red.shade300 : Colors.red.shade700);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            tieneStock ? Icons.check_circle : Icons.cancel,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tieneStock ? 'Disponible en stock' : 'Sin stock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (tieneStock)
                  Text(
                    '${stockDisponible.toStringAsFixed(0)} ${widget.producto.unidadMedida?.nombre ?? 'unidades'} disponibles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.producto.descripcion!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDetallesAdicionales() {
    final detalles = <MapEntry<String, String?>>[];

    if (widget.producto.marca != null) {
      detalles.add(MapEntry('Marca', widget.producto.marca!.nombre));
    }

    if (widget.producto.categoria != null) {
      detalles.add(MapEntry('Categoría', widget.producto.categoria!.nombre));
    }

    if (widget.producto.unidadMedida != null) {
      detalles.add(MapEntry('Unidad', widget.producto.unidadMedida!.nombre));
    }

    /*if (widget.producto.proveedor != null) {
      detalles.add(MapEntry('Proveedor', widget.producto.proveedor!.nombre));
    }*/

    if (widget.producto.sku != null) {
      detalles.add(MapEntry('SKU', widget.producto.sku!));
    }

    if (widget.producto.codigosBarra != null &&
        widget.producto.codigosBarra!.isNotEmpty) {
      detalles.add(
        MapEntry('Código de Barra', widget.producto.codigosBarra!.join(', ')),
      );
    }

    if (detalles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...detalles.asMap().entries.map((entry) {
          final index = entry.key;
          final detalle = entry.value;
          final isLast = index == detalles.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    detalle.key,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    detalle.value ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSeccionAgregarAlCarrito({
    required bool tieneStock,
    required int cantidadMinima,
    required int stockDisponible,
  }) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final cantidadEnCarrito = carritoProvider.obtenerCantidadProducto(widget.producto.id);
        const brownColor = Color(0xFF795548);
        final brownColorLight = brownColor.withAlpha(isDark ? 100 : 40);

        // ✅ ACTUALIZADO: Los combos se pueden agregar solo con items obligatorios
        // Items opcionales son realmente opcionales
        final necesitaSeleccionOpcional = false;

        return Container(
          color: cantidadEnCarrito > 0 ? brownColorLight : colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar cantidad en carrito
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cantidadEnCarrito > 0
                      ? '🛒 Cantidad en carrito: $cantidadEnCarrito ${widget.producto.unidadMedida?.nombre ?? 'unidades'}'
                      : '📦 Este producto no está en el carrito',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Controles de cantidad
              if (tieneStock)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ NUEVO: Mostrar advertencia si falta seleccionar opcional
                    if (necesitaSeleccionOpcional)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠️ Debes seleccionar al menos un item del grupo opcional arriba',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      'Cantidad',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (cantidadEnCarrito == 0)
                      // Mostrar botón + si no está en carrito
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          // ✅ NUEVO: Deshabilitar si falta seleccionar opcional
                          onPressed: necesitaSeleccionOpcional ? null : _incrementarCantidad,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Agregar al Carrito'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      // Mostrar controles +/- + TextField si ya está en carrito
                      Container(
                        decoration: BoxDecoration(
                          color: brownColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: brownColor, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: _decrementarCantidad,
                                icon: const Icon(Icons.remove, size: 20),
                                style: IconButton.styleFrom(
                                  foregroundColor: brownColor,
                                ),
                              ),
                            ),
                            // ✅ NUEVO: TextField para entrada directa de cantidad
                            Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: brownColor.withAlpha(40),
                                  ),
                                ),
                                child: TextField(
                                  controller: _cantidadController,
                                  focusNode: _cantidadFocusNode,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  onChanged: _actualizarCantidad,
                                  // ✅ NUEVO: Validar cuando el usuario pierde el foco
                                  onSubmitted: (_) {
                                    _onFocusLostCantidad();
                                  },
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: brownColor,
                                      ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                    hintText: '1',
                                    hintStyle: TextStyle(
                                      color: brownColor.withAlpha(50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: _incrementarCantidad,
                                icon: const Icon(Icons.add, size: 20),
                                style: IconButton.styleFrom(
                                  foregroundColor: brownColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              else
                // Mostrar mensaje si no hay stock
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '❌ Producto sin stock disponible',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductosCombo() {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final comboItems = widget.producto.comboItems ?? [];

    debugPrint('🔍 [_buildProductosCombo] comboItems.length: ${comboItems.length}');

    if (comboItems.isEmpty) {
      debugPrint('⚠️ [_buildProductosCombo] comboItems está vacío');
      return const SizedBox.shrink();
    }

    // Separar items obligatorios y opcionales
    final itemsObligatorios = comboItems.where((item) => item.esObligatorio).toList();
    final itemsOpcionales = comboItems.where((item) => !item.esObligatorio).toList();

    debugPrint('📦 [_buildProductosCombo] Items obligatorios: ${itemsObligatorios.length}');
    debugPrint('📦 [_buildProductosCombo] Items opcionales: ${itemsOpcionales.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            Icon(
              Icons.card_giftcard,
              color: Colors.amber.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Productos del Combo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Items obligatorios
        if (itemsObligatorios.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Productos Incluidos (${itemsObligatorios.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...itemsObligatorios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == itemsObligatorios.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: _buildComboItemCard(item, colorScheme, isDark),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        // Items opcionales (grupo opcional)
        if (itemsOpcionales.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_box,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Grupo Opcional - Elige uno o más (${_itemsOpcionalesSeleccionados.length} seleccionados)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...itemsOpcionales.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == itemsOpcionales.length - 1;
                  final estaSeleccionado = _itemsOpcionalesSeleccionados.any((i) => i.id == item.id);

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    // ✅ NUEVO: Hacer el item interactivo con InkWell
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (estaSeleccionado) {
                            // Remover si ya está seleccionado
                            _itemsOpcionalesSeleccionados.removeWhere((i) => i.id == item.id);
                            _cantidadesOpcionales.remove(item.id);
                          } else {
                            // Agregar si no está seleccionado
                            _itemsOpcionalesSeleccionados.add(item);
                            _cantidadesOpcionales.putIfAbsent(
                              item.id,
                              () => item.cantidad.toInt(),
                            );
                          }
                        });

                        // ✅ NUEVO: Guardar automáticamente en CarritoProvider
                        _actualizarComboEnCarrito();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: _buildComboItemCard(
                        item,
                        colorScheme,
                        isDark,
                        esSeleccionable: true,
                        estaSeleccionado: estaSeleccionado,
                        cantidadModificable:
                            estaSeleccionado ? _cantidadesOpcionales[item.id] ?? item.cantidad.toInt() : null,
                        onCantidadChanged: estaSeleccionado
                            ? (nuevaCantidad) {
                                setState(() {
                                  _cantidadesOpcionales[item.id] = nuevaCantidad;
                                });
                              }
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        // Información de capacidad
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: colorScheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacidad del Combo',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se pueden preparar hasta ${widget.producto.capacidad ?? 0} combos con el stock actual',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ NUEVO: Mostrar componentes requeridos del combo basado en cantidad seleccionada
  Widget _buildComponentesRequeridos() {
    if (!widget.producto.esCombo || _cantidad <= 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = context.colorScheme;
    final comboItems = widget.producto.comboItems ?? [];

    // Filtrar solo obligatorios + opcionales seleccionados
    final itemsObligatorios = comboItems.where((item) => item.esObligatorio).toList();
    final itemsOpcionalesSeleccionados = _itemsOpcionalesSeleccionados;

    if (itemsObligatorios.isEmpty && itemsOpcionalesSeleccionados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Título
        Row(
          children: [
            Icon(
              Icons.shopping_cart_checkout,
              color: Colors.blue.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Componentes Requeridos para ${ _cantidad > 1 ? '$_cantidad combos' : '1 combo'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabla de componentes
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Encabezados
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Componente',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Cant/Combo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Total',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items obligatorios
              ...itemsObligatorios.asMap().entries.map((entry) {
                final item = entry.value;
                final cantidadTotal = (item.cantidad * _cantidad).toInt();
                return _buildComponenteRow(item, item.cantidad.toInt(), cantidadTotal, 'Obligatorio');
              }),

              // Items opcionales seleccionados
              ...itemsOpcionalesSeleccionados.asMap().entries.map((entry) {
                final item = entry.value;
                final cantidadPorCombo = _cantidadesOpcionales[item.id] ?? item.cantidad.toInt();
                final cantidadTotal = cantidadPorCombo * _cantidad;
                return _buildComponenteRow(item, cantidadPorCombo, cantidadTotal, 'Opcional');
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Helper para mostrar una fila de componente
  Widget _buildComponenteRow(
    ComboItem item,
    int cantidadPorCombo,
    int cantidadTotal,
    String tipo,
  ) {
    final colorScheme = context.colorScheme;
    final bgColor = tipo == 'Obligatorio' ? Colors.blue.shade50 : Colors.orange.shade50;
    final borderColor = tipo == 'Obligatorio' ? Colors.blue.shade200 : Colors.orange.shade200;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
        color: bgColor.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productoNombre ?? 'Producto',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tipo == 'Obligatorio' ? Colors.blue : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tipo,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              cantidadPorCombo.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cantidadTotal.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboItemCard(
    ComboItem item,
    ColorScheme colorScheme,
    bool isDark, {
    bool esSeleccionable = false,
    bool estaSeleccionado = false,
    int? cantidadModificable,
    Function(int)? onCantidadChanged,
  }) {
    final esObligatorio = item.esObligatorio;
    final tieneStock = (item.stockDisponible ?? 0) > 0;
    final stockColor = tieneStock
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.5)
            : Colors.white,
        border: Border.all(
          // ✅ NUEVO: Borde azul si está seleccionado
          color: estaSeleccionado
              ? Colors.blue.shade400
              : colorScheme.outline.withOpacity(0.2),
          width: estaSeleccionado ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NUEVO: Nombre del producto con checkbox si es seleccionable
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ NUEVO: Checkbox para items opcionales (múltiple selección)
              if (esSeleccionable)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: estaSeleccionado,
                      onChanged: null, // Controlado por InkWell
                      activeColor: Colors.orange.shade700,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  item.productoNombre ?? 'Producto',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Badge de cuello de botella
              if (item.esCuelloBotella ?? false)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⚠️ Límite',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.red.shade700,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // SKU y cantidad
          Row(
            children: [
              Expanded(
                child: Text(
                  'SKU: ${item.productoSku ?? '-'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cantidad: ${item.cantidad.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Precio y unidad de medida
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio Unitario',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      'Bs ${(item.precioUnitario ?? 0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unidad',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      item.unidadMedidaNombre ?? '-',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stock disponible
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tieneStock
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              border: Border.all(
                color: tieneStock
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Disponible',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${(item.stockDisponible ?? 0).toStringAsFixed(0)} unidades',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Información de combos posibles
          const SizedBox(height: 8),
          Text(
            'Se pueden hacer ${item.combosPosibles ?? 0} combos con este producto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),

          // ✅ NUEVO: Controles de cantidad para items opcionales seleccionados
          if (esSeleccionable && estaSeleccionado && cantidadModificable != null && onCantidadChanged != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cantidad:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: cantidadModificable > 1
                            ? () => onCantidadChanged(cantidadModificable - 1)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          disabledBackgroundColor: Colors.grey.shade100,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          cantidadModificable.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onCantidadChanged(cantidadModificable + 1),
                        icon: const Icon(Icons.add, size: 18),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
