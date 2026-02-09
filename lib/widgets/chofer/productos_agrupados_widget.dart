import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_agrupado.dart';
import '../../providers/productos_agrupados_provider.dart';

/// Widget que muestra productos agrupados de una entrega en formato tabla
///
/// Consolida productos de múltiples ventas, mostrando:
/// - Cantidad total de cada producto
/// - Ventas en las que aparece
/// - Información del cliente
class ProductosAgrupadsWidget extends StatefulWidget {
  final int entregaId;
  final bool mostrarDetalleVentas;

  const ProductosAgrupadsWidget({
    super.key,
    required this.entregaId,
    this.mostrarDetalleVentas = true,
  });

  @override
  State<ProductosAgrupadsWidget> createState() =>
      _ProductosAgrupadsWidgetState();
}

class _ProductosAgrupadsWidgetState extends State<ProductosAgrupadsWidget> {
  late Set<int> _expandedRows;

  @override
  void initState() {
    super.initState();
    _expandedRows = {};
    // Cargar productos cuando se crea el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosAgrupadsProvider>().cargarProductosAgrupados(
        widget.entregaId,
      );
    });
  }

  void _toggleExpanded(int productoId) {
    setState(() {
      if (_expandedRows.contains(productoId)) {
        _expandedRows.remove(productoId);
      } else {
        _expandedRows.add(productoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductosAgrupadsProvider>(
      builder: (context, provider, _) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        // Estado de carga
        if (provider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando productos...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Error
        if (provider.errorMessage != null &&
            provider.productosAgrupados == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((0.1 * 255).toInt()),
              border: Border.all(
                color: Colors.red.withAlpha((0.5 * 255).toInt()),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        final productos = provider.productos;

        if (productos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.withAlpha((0.1 * 255).toInt()),
              border: Border.all(
                color: Colors.yellow.withAlpha((0.5 * 255).toInt()),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                const Text('No hay productos en esta entrega'),
              ],
            ),
          );
        }

        // Calcular total general
        final totalGeneral = productos.fold<double>(
          0,
          (sum, p) => sum + double.parse(p.subtotal),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lista Generica #${widget.entregaId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Resumen cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Tipos de productos
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipos',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.totalProductos.toString(),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cantidad total
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cantidad',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.cantidadTotal.toInt()}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total general
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bs. ${totalGeneral.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tabla de productos
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: DataTable(
                    headingRowColor: MaterialStatePropertyAll(
                      isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Producto',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Cantidad',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Precio',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Subtotal',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (widget.mostrarDetalleVentas)
                        DataColumn(
                          label: Text(
                            '',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                    rows: [
                      ...productos.map((producto) {
                        final isExpanded = _expandedRows.contains(
                          producto.productoId,
                        );
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      producto.nombreProducto,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (producto.codigoProducto.isNotEmpty)
                                      Text(
                                        'Código: ${producto.codigoProducto}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${producto.cantidadTotal.toStringAsFixed(2)} ${producto.unidadMedida}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Bs. ${producto.precioUnitario.toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Bs. ${producto.subtotal}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                            if (widget.mostrarDetalleVentas)
                              DataCell(
                                producto.ventas.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 20,
                                        ),
                                        onPressed: () => _toggleExpanded(
                                          producto.productoId,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        );
                      }).toList(),
                      // Fila de total
                      DataRow(
                        color: MaterialStatePropertyAll(
                          isDarkMode
                              ? Colors.grey[800]?.withAlpha((0.5 * 255).toInt())
                              : Colors.grey[100],
                        ),
                        cells: [
                          DataCell(
                            Text(
                              'TOTAL',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${provider.cantidadTotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(const SizedBox.shrink()),
                          DataCell(
                            Text(
                              'Bs. ${totalGeneral.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                            ),
                          ),
                          if (widget.mostrarDetalleVentas)
                            DataCell(const SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Filas expandibles con detalles de ventas
              ...productos
                  .where((p) => _expandedRows.contains(p.productoId))
                  .map((producto) => _buildVentasDetalle(context, producto))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVentasDetalle(BuildContext context, ProductoAgrupado producto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.05 * 255).toInt()),
        border: Border(
          top: BorderSide(color: Colors.blue.withAlpha((0.3 * 255).toInt())),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas (${producto.ventas.length}):',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...producto.ventas.map((venta) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.numeroVenta,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            venta.nombreCliente,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${venta.cantidad.toStringAsFixed(2)} un.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
