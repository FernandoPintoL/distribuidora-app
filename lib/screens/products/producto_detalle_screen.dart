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
  int _cantidad = 1;
  bool _agregandoAlCarrito = false;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: '1');
    _observacionesController = TextEditingController();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _incrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.producto.id);
    final stock = (widget.producto.stockPrincipal?.cantidadDisponible ?? 0 as num).toInt();

    if (cantidadActual < stock) {
      // Agregar 1 unidad al carrito
      carritoProvider.agregarProducto(widget.producto, cantidad: 1);
    }
  }

  void _decrementarCantidad() {
    final carritoProvider = context.read<CarritoProvider>();
    final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.producto.id);

    if (cantidadActual > 0) {
      // Decrementar 1 unidad del carrito
      carritoProvider.decrementarCantidad(widget.producto.id);
    }
  }

  void _actualizarCantidad(String valor) {
    // Ya no se usa, pero lo dejamos por compatibilidad
  }

  Future<void> _agregarAlCarrito() async {
    final carritoProvider = context.read<CarritoProvider>();

    // Validar cantidad
    if (_cantidad <= 0) {
      _mostrarError('La cantidad debe ser mayor a 0');
      return;
    }

    setState(() => _agregandoAlCarrito = true);

    try {
      // Simular delay de procesamiento
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ NUEVO: Agregar al carrito (esto dispara notifyListeners() automáticamente)
      carritoProvider.agregarProducto(
        widget.producto,
        cantidad: _cantidad,
        observaciones: _observacionesController.text.isNotEmpty
            ? _observacionesController.text
            : null,
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
      setState(() => _cantidad = 1);
    } catch (e) {
      _mostrarError('Error al agregar al carrito: $e');
    } finally {
      if (mounted) {
        setState(() => _agregandoAlCarrito = false);
      }
    }
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
                          onPressed: _incrementarCantidad,
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
                      // Mostrar controles +/- si ya está en carrito
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
                            Text(
                              '$cantidadEnCarrito',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: brownColor,
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
            ],
          ),
        );
      },
    );
  }
}
