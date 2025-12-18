import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

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
  double _cantidad = 1.0;
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
    setState(() {
      _cantidad += 1;
      _cantidadController.text = _cantidad.toStringAsFixed(0);
    });
  }

  void _decrementarCantidad() {
    if (_cantidad > 1) {
      setState(() {
        _cantidad -= 1;
        _cantidadController.text = _cantidad.toStringAsFixed(0);
      });
    }
  }

  void _actualizarCantidad(String valor) {
    if (valor.isEmpty) {
      _cantidad = 0;
      return;
    }

    final nuevaCantidad = double.tryParse(valor) ?? 0;
    if (nuevaCantidad > 0) {
      setState(() {
        _cantidad = nuevaCantidad;
      });
    }
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
      setState(() => _cantidad = 1.0);
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
    final stockDisponible =
        widget.producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();
    final tieneStock = stockDispDouble > 0;
    final cantidadMinima = (widget.producto.cantidadMinima ?? 1).toDouble();

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
                    _buildStockInfo(tieneStock, stockDispDouble),
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
                stockDisponible: stockDispDouble,
              ),
              SizedBox(height: 16,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final imagenes = widget.producto.imagenes;

    if (imagenes == null || imagenes.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey.shade100,
      child: PageView.builder(
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          return Image.network(
            imagenes[index].url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 80),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNombreYPrecio() {
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
                  color: Colors.grey.shade600,
                ),
          ),
        const SizedBox(height: 12),
        Text(
          'Bs ${(widget.producto.precioVenta ?? 0).toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
        ),
      ],
    );
  }

  Widget _buildStockInfo(bool tieneStock, double stockDisponible) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tieneStock ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: tieneStock ? Colors.green.shade300 : Colors.red.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            tieneStock ? Icons.check_circle : Icons.cancel,
            color: tieneStock ? Colors.green.shade700 : Colors.red.shade700,
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
                    color:
                        tieneStock ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (tieneStock)
                  Text(
                    '${stockDisponible.toStringAsFixed(0)} ${widget.producto.unidadMedida?.nombre ?? 'unidades'} disponibles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
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
                          color: Colors.grey.shade600,
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
    required double cantidadMinima,
    required double stockDisponible,
  }) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de cantidad
          Text(
            'Cantidad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Información de cantidad mínima
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Cantidad mínima: ${cantidadMinima.toStringAsFixed(0)} ${widget.producto.unidadMedida?.nombre ?? 'unidades'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Input de cantidad con botones
          Row(
            children: [
              IconButton(
                onPressed: _decrementarCantidad,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _cantidadController,
                  onChanged: _actualizarCantidad,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                onPressed: _incrementarCantidad,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de observaciones
          /*Text(
            'Observaciones (opcional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _observacionesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ej: Sin conservante, lo más fresco posible...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),*/

          // Botón agregar al carrito
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tieneStock && !_agregandoAlCarrito
                  ? _agregarAlCarrito
                  : null,
              icon: _agregandoAlCarrito
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout, color: Colors.white,),
              label: Text(
                _agregandoAlCarrito
                    ? 'Agregando...'
                    : tieneStock
                        ? 'Agregar al Carrito'
                        : 'Producto sin Stock',
                  style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade700,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
