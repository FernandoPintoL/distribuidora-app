import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/product/product_card_base.dart';
import '../../widgets/product/product_card_quantity_controls.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';

/// Pantalla de detalle de producto
/// Muestra informaciÃ³n completa del producto y permite agregar al carrito
class ProductoDetalleScreen extends StatefulWidget {
  final Product producto;

  const ProductoDetalleScreen({super.key, required this.producto});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  late TextEditingController _cantidadController;
  late TextEditingController _observacionesController;
  late FocusNode _cantidadFocusNode;
  int _cantidad = 1;
  bool _agregandoAlCarrito = false;

  // âœ… NUEVO: Estado para items opcionales de combos (mÃºltiples selecciones)
  final List<ComboItem> _itemsOpcionalesSeleccionados = [];
  final Map<int, int> _cantidadesOpcionales = {};

  @override
  void initState() {
    super.initState();
    _cantidadFocusNode = FocusNode();
    _observacionesController = TextEditingController();

    // âœ… Inicializar controller con valor por defecto
    _cantidadController = TextEditingController(text: '1');

    // âœ… NUEVO: Actualizar con la cantidad actual en el carrito + cargar combo items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final carritoProvider = context.read<CarritoProvider>();
        final cantidadEnCarrito = carritoProvider.obtenerCantidadProducto(
          widget.producto.id,
        );
        if (cantidadEnCarrito > 0) {
          _cantidad = cantidadEnCarrito;
          _cantidadController.text = _cantidad.toString();

          // âœ… NUEVO: Cargar items opcionales seleccionados desde el carrito
          _cargarItemsOpcionalesDelCarrito(carritoProvider);
        }

        // âœ… NUEVO: Agregar listener para detectar pÃ©rdida de foco
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

  // âœ… NUEVO: Cargar items opcionales seleccionados desde el carrito
  void _cargarItemsOpcionalesDelCarrito(CarritoProvider carritoProvider) {
    try {
      final item = carritoProvider.carrito.items.firstWhere(
        (i) => i.producto.id == widget.producto.id,
      );

      // Si el item tiene comboItemsSeleccionados, cargarlos
      if (item.comboItemsSeleccionados != null &&
          item.comboItemsSeleccionados!.isNotEmpty) {
        _itemsOpcionalesSeleccionados.clear();
        _cantidadesOpcionales.clear();

        final comboItems = widget.producto.comboItems ?? [];
        final itemsOpcionales = comboItems
            .where((c) => !c.esObligatorio)
            .toList();

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
            debugPrint('âš ï¸ No se encontrÃ³ combo item con id $comboItemId');
          }
        }

        setState(() {});
        debugPrint(
          'âœ… Items opcionales cargados: ${_itemsOpcionalesSeleccionados.length}',
        );
      }
    } catch (e) {
      // No hay item en el carrito para este producto
      debugPrint('â„¹ï¸ No hay item en carrito para este producto');
    }
  }

  // âœ… NUEVO: Construir combo items (obligatorios + opcionales seleccionados)
  List<Map<String, dynamic>>? _construirComboItems() {
    if (!widget.producto.esCombo) return null;

    final items = widget.producto.comboItems ?? [];
    if (items.isEmpty) return null;

    return [
      // Obligatorios (cantidad fija del combo)
      ...items
          .where((i) => i.esObligatorio)
          .map(
            (i) => {
              'combo_item_id': i.id,
              'producto_id': i.productoId,
              'cantidad': i.cantidad,
            },
          ),
      // Opcionales seleccionados (cantidad modificable)
      ..._itemsOpcionalesSeleccionados.map(
        (item) => {
          'combo_item_id': item.id,
          'producto_id': item.productoId,
          'cantidad': _cantidadesOpcionales[item.id] ?? item.cantidad,
        },
      ),
    ];
  }

  void _incrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(
      widget.producto.id,
    );
    final stock =
        (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num)
            .toInt();

    if (cantidadActual < stock) {
      // âœ… ACTUALIZADO: Agregar combo con items obligatorios pre-incluidos
      carritoProvider.agregarProducto(
        widget.producto,
        cantidad: 1,
        comboItemsSeleccionados: _construirComboItems(),
      );

      // âœ… NUEVO: Recalcular con rangos despuÃ©s de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();

      // âœ… NUEVO: Sincronizar el input
      setState(() {
        _cantidad = cantidadActual + 1;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  void _decrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(
      widget.producto.id,
    );

    if (cantidadActual > 0) {
      // Decrementar 1 unidad del carrito
      carritoProvider.decrementarCantidad(widget.producto.id);

      // âœ… NUEVO: Recalcular con rangos despuÃ©s de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();

      // âœ… NUEVO: Sincronizar el input
      setState(() {
        _cantidad = cantidadActual - 1;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  void _actualizarCantidad(String valor) {
    final carritoProvider = context.read<CarritoProvider>();
    final stock =
        (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num)
            .toInt();

    // âœ… NUEVO: Si estÃ¡ vacÃ­o mientras escribe, ignorar (no eliminar)
    if (valor.isEmpty) {
      return;
    }

    final cantidadIngresada = int.tryParse(valor) ?? 0;

    // âœ… NUEVO: Si es 0 o negativo, ignorar (no eliminar automÃ¡ticamente)
    if (cantidadIngresada <= 0) {
      return;
    }

    if (cantidadIngresada > stock) {
      // Si excede stock, ajustar al mÃ¡ximo disponible
      _mostrarError(
        'La cantidad no puede exceder el stock disponible ($stock)',
      );
      _cantidadController.text = stock.toString();
      carritoProvider.actualizarCantidad(widget.producto.id, stock);
      // âœ… NUEVO: Recalcular con rangos despuÃ©s de cambiar cantidad
      carritoProvider.calcularCarritoConRangos();
      setState(() => _cantidad = stock);
      return;
    }

    // âœ… Actualizar cantidad directamente en el carrito
    carritoProvider.actualizarCantidad(widget.producto.id, cantidadIngresada);
    // âœ… NUEVO: Recalcular con rangos despuÃ©s de cambiar cantidad
    carritoProvider.calcularCarritoConRangos();
    setState(() => _cantidad = cantidadIngresada);
  }

  void _onFocusLostCantidad() {
    if (_cantidad <= 0) {
      final carritoProvider = context.read<CarritoProvider>();
      carritoProvider.eliminarProducto(widget.producto.id);
      setState(() => _cantidad = 1);
    }
  }

  /// âœ… ACTUALIZADO: Actualizar items opcionales del combo en el carrito automÃ¡ticamente
  void _actualizarComboEnCarrito() {
    if (!widget.producto.esCombo) return;

    final carritoProvider = context.read<CarritoProvider>();

    // âœ… ACTUALIZADO: Usar mÃ©todo auxiliar para construir combo items
    final comboItemsSeleccionados = _construirComboItems();

    // Guardar en CarritoProvider
    carritoProvider.actualizarComboItems(
      widget.producto.id,
      comboItemsSeleccionados,
    );

    debugPrint(
      'ðŸ’¾ [ProductoDetalle] Combo items guardados en carrito automÃ¡ticamente: ${comboItemsSeleccionados?.length ?? 0} items',
    );
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<CarritoProvider, ProductProvider>(
      builder: (context, carritoProvider, productProvider, _) {
        final stockDisponible =
            widget.producto.stockPrincipal?.cantidadDisponible ?? 0;
        final stockDispInt = (stockDisponible as num).toInt();
        final tieneStock = stockDispInt > 0;
        final cantidadMinima = widget.producto.cantidadMinima ?? 1;

        // Obtener detalles de rango de precio
        final detalleConRango = carritoProvider.obtenerDetalleConRango(
          widget.producto.id,
        );

        return Scaffold(
          appBar: CustomGradientAppBar(title: widget.producto.nombre),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del producto
                  _buildImageGallery(),
                  // InformaciÃ³n de stock
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildStockInfo(tieneStock, stockDispInt),
                  ),
                  // InformaciÃ³n bÃ¡sica usando ProductCardBase
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Usar ProductCardBase para mostrar producto, precio y combo items
                        ProductCardBase(
                          product: widget.producto,
                          quantity: _cantidad,
                          detalleConRango: detalleConRango,
                          showDeleteButton: false,
                          showQuantityControls: false,
                          showImage: false,
                          isPreventista: true,
                          cantidadDisponible: stockDispInt,
                          unidadMedida: widget.producto.unidadMedida?.nombre,
                        ),
                        const SizedBox(height: 16),

                        // Productos del combo si aplica (solo para seleccionar opcionales)
                        if (widget.producto.esCombo &&
                            widget.producto.comboItems != null &&
                            widget.producto.comboItems!.isNotEmpty) ...[
                          _buildProductosCombo(),
                        ],
                        // AquÃ­ va el widget VolumeDiscountDisplay cuando se integre con descuentos
                      ],
                    ),
                  ),

                  // SecciÃ³n de agregar al carrito
                  _buildSeccionAgregarAlCarrito(
                    tieneStock: tieneStock,
                    cantidadMinima: cantidadMinima,
                    stockDisponible: stockDispInt,
                  ),
                  SizedBox(height: 16),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildStockInfo(bool tieneStock, int stockDisponible) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final backgroundColor = tieneStock
        ? (isDark
              ? Colors.green.shade900.withOpacity(0.2)
              : Colors.green.shade50)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildSeccionAgregarAlCarrito({
    required bool tieneStock,
    required int cantidadMinima,
    required int stockDisponible,
  }) {
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, _) {
        final cantidadEnCarrito = carritoProvider.obtenerCantidadProducto(
          widget.producto.id,
        );

        // âœ… ACTUALIZADO: Los combos se pueden agregar solo con items obligatorios
        // Items opcionales son realmente opcionales
        final necesitaSeleccionOpcional = false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Controles de cantidad
              if (tieneStock)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cantidadEnCarrito == 0)
                      // Mostrar botÃ³n + si no estÃ¡ en carrito
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          // âœ… NUEVO: Deshabilitar si falta seleccionar opcional
                          onPressed: necesitaSeleccionOpcional
                              ? null
                              : _incrementarCantidad,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Agregar al Carrito'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                      )
                    else
                      ProductCardQuantityControls(
                        quantity: _cantidad,
                        maxQuantity:
                            (widget
                                        .producto
                                        .stockPrincipal
                                        ?.cantidadDisponible ??
                                    0 as num)
                                .toInt(),
                        onIncrement: _incrementarCantidad,
                        onDecrement: _decrementarCantidad,
                        onChanged: _actualizarCantidad,
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
                    'Producto sin stock disponible',
                    style: TextStyle(
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

    debugPrint(
      'ðŸ” [_buildProductosCombo] comboItems.length: ${comboItems.length}',
    );

    if (comboItems.isEmpty) {
      debugPrint('âš ï¸ [_buildProductosCombo] comboItems estÃ¡ vacÃ­o');
      return const SizedBox.shrink();
    }

    // Separar solo items opcionales (obligatorios ya se muestran en ProductCardBase)
    final itemsOpcionales = comboItems
        .where((item) => !item.esObligatorio)
        .toList();

    if (itemsOpcionales.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TÃ­tulo: Items Opcionales
        Row(
          children: [
            Icon(Icons.check_box, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Grupo Opcional - Elige uno o mÃ¡s (${_itemsOpcionalesSeleccionados.length} seleccionados)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
              ...itemsOpcionales.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == itemsOpcionales.length - 1;
                final estaSeleccionado = _itemsOpcionalesSeleccionados.any(
                  (i) => i.id == item.id,
                );

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (estaSeleccionado) {
                          _itemsOpcionalesSeleccionados.removeWhere(
                            (i) => i.id == item.id,
                          );
                          _cantidadesOpcionales.remove(item.id);
                        } else {
                          _itemsOpcionalesSeleccionados.add(item);
                          _cantidadesOpcionales.putIfAbsent(
                            item.id,
                            () => item.cantidad.toInt(),
                          );
                        }
                      });
                      _actualizarComboEnCarrito();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: _buildComboItemCard(
                      item,
                      colorScheme,
                      isDark,
                      esSeleccionable: true,
                      estaSeleccionado: estaSeleccionado,
                      cantidadModificable: estaSeleccionado
                          ? _cantidadesOpcionales[item.id] ??
                                item.cantidad.toInt()
                          : null,
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

        // InformaciÃ³n de capacidad
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
              Icon(Icons.info, color: colorScheme.secondary, size: 18),
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
    final stockColor = tieneStock ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface.withOpacity(0.5) : Colors.white,
        border: Border.all(
          // âœ… NUEVO: Borde azul si estÃ¡ seleccionado
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
          // âœ… NUEVO: Nombre del producto con checkbox si es seleccionable
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // âœ… NUEVO: Checkbox para items opcionales (mÃºltiple selecciÃ³n)
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                    'âš ï¸ LÃ­mite',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.red.shade700,
                      fontSize: AppTextStyles.labelSmall(context).fontSize!,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cantidad: ${item.cantidad.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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
              color: tieneStock ? Colors.green.shade50 : Colors.red.shade50,
              border: Border.all(
                color: tieneStock ? Colors.green.shade300 : Colors.red.shade300,
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

          // InformaciÃ³n de combos posibles
          const SizedBox(height: 8),
          Text(
            'Se pueden hacer ${item.combosPosibles ?? 0} combos con este producto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),

          // âœ… NUEVO: Controles de cantidad para items opcionales seleccionados
          if (esSeleccionable &&
              estaSeleccionado &&
              cantidadModificable != null &&
              onCantidadChanged != null) ...[
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            onCantidadChanged(cantidadModificable + 1),
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
