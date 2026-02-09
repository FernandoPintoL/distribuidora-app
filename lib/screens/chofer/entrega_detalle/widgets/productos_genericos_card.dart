import 'package:flutter/material.dart';
import '../../../../services/print_service.dart';

class ProductosGenericosCard extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  final int entregaId;

  const ProductosGenericosCard({
    Key? key,
    required this.productos,
    required this.entregaId,
  }) : super(key: key);

  @override
  State<ProductosGenericosCard> createState() =>
      _ProductosGenericosCardState();
}

class _ProductosGenericosCardState extends State<ProductosGenericosCard> {
  bool _isDownloading = false;

  Future<void> _descargarTicket58() async {
    setState(() => _isDownloading = true);
    try {
      final printService = PrintService();
      final success = await printService.downloadDocument(
        documentoId: widget.entregaId,
        documentType: PrintDocumentType.entrega,
        format: PrintFormat.ticket58,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo descargar el ticket'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo PDF...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final productosAgrupados = <String, List<Map<String, dynamic>>>{};
    for (final producto in widget.productos) {
      final ventaNumero = producto['venta_numero'] as String? ?? 'Sin venta';
      if (!productosAgrupados.containsKey(ventaNumero)) {
        productosAgrupados[ventaNumero] = [];
      }
      productosAgrupados[ventaNumero]!.add(producto);
    }

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos Consolidados',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.productos.length} articulos',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _descargarTicket58,
                  icon: Icon(
                    _isDownloading ? Icons.hourglass_bottom : Icons.download,
                    size: 16,
                  ),
                  label: Text(
                    _isDownloading ? 'Descargando...' : 'PDF 58mm',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    disabledBackgroundColor: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: productosAgrupados.entries.map((entry) {
                final ventaNumero = entry.key;
                final productosVenta = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Venta: $ventaNumero',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${productosVenta.length} articulos',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...productosVenta.asMap().entries.map((pEntry) {
                      final idx = pEntry.key;
                      final p = pEntry.value;
                      final isLast = idx == productosVenta.length - 1;

                      final nombre = p['producto_nombre'] as String? ??
                          'Producto desconocido';
                      final cantidad = double.tryParse(
                            (p['cantidad'] is num
                                    ? p['cantidad']
                                    : p['cantidad'])
                                .toString(),
                          ) ??
                          0;
                      final unitario = double.tryParse(
                            (p['precio_unitario'] is num
                                    ? p['precio_unitario']
                                    : p['precio_unitario'])
                                .toString(),
                          ) ??
                          0;
                      final subtotal = double.tryParse(
                            (p['subtotal'] is num
                                    ? p['subtotal']
                                    : p['subtotal'])
                                .toString(),
                          ) ??
                          0;

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.blue[900]
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${cantidad % 1 == 0 ? cantidad.toInt() : cantidad}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.grey[100]
                                            : Colors.grey[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Bs. ${subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey[100]
                                          : Colors.grey[900],
                                    ),
                                  ),
                                  Text(
                                    'Bs. ${unitario.toStringAsFixed(2)} c/u',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
