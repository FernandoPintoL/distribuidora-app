import 'package:flutter/material.dart';
import 'models.dart';
import 'package:flutter/services.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/venta.dart';

// ✅ WIDGET: Tabla de Productos Rechazados en Devolución Parcial
class TablaProductosWidget extends StatelessWidget {
  final Venta venta;
  final bool isDarkMode;
  final List<ProductoRechazado> productosRechazados;
  final Map<int, TextEditingController> cantidadRechazadaControllers;
  final Function(int detalleVentaId, ProductoRechazado nuevoProducto) onProductoRechazadoAgregado;
  final Function(int detalleVentaId) onProductoRechazadoRemovido;
  final Function(ProductoRechazado producto, double nuevaCantidad) onCantidadRechazadaChanged;
  final VoidCallback onStateChanged;

  const TablaProductosWidget({
    Key? key,
    required this.venta,
    required this.isDarkMode,
    required this.productosRechazados,
    required this.cantidadRechazadaControllers,
    required this.onProductoRechazadoAgregado,
    required this.onProductoRechazadoRemovido,
    required this.onCantidadRechazadaChanged,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (venta.detalles == null || venta.detalles!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular totales
    double totalOriginal = venta.detalles!.fold(
      0.0,
      (sum, det) => sum + (det.subtotal ?? 0),
    );
    double montoRechazado = productosRechazados.fold(
      0.0,
      (sum, prod) => sum + prod.subtotalRechazado,
    );
    double montoEntregado = totalOriginal - montoRechazado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📦 Productos de la Venta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Marca productos con rechazo parcial e ingresa cantidad rechazada',
          style: TextStyle(
            fontSize: AppTextStyles.bodySmall(context).fontSize!,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.orange.withOpacity(0.1),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    '✗',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Producto',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Orig',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Rech',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty Entre',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Precio',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Subtotal Rech',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: venta.detalles!.asMap().entries.map((entry) {
                final detalle = entry.value;
                ProductoRechazado? productoRechazado;
                try {
                  productoRechazado = productosRechazados.firstWhere(
                    (p) => p.detalleVentaId == detalle.id,
                  );
                } catch (e) {
                  productoRechazado = null;
                }
                final isRechazado = productoRechazado != null;

                return DataRow(
                  color: MaterialStateColor.resolveWith((states) {
                    if (isRechazado) {
                      return Colors.orange.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  }),
                  cells: [
                    DataCell(
                      Checkbox(
                        value: isRechazado,
                        onChanged: (value) {
                          if (value == true) {
                            final nuevoProducto = ProductoRechazado(
                              detalleVentaId: detalle.id,
                              productoId: detalle.producto?.id,
                              nombreProducto: detalle.producto?.nombre ??
                                  detalle.nombreProducto ??
                                  'Producto',
                              cantidadOriginal: detalle.cantidad.toDouble(),
                              cantidadRechazada: 1.0,
                              precioUnitario: detalle.precioUnitario.toDouble(),
                              subtotalOriginal:
                                  detalle.subtotal?.toDouble() ?? 0,
                            );
                            onProductoRechazadoAgregado(
                              detalle.id,
                              nuevoProducto,
                            );
                            if (!cantidadRechazadaControllers
                                .containsKey(detalle.id)) {
                              cantidadRechazadaControllers[detalle.id] =
                                  TextEditingController(text: '1.0');
                            }
                          } else {
                            onProductoRechazadoRemovido(detalle.id);
                            cantidadRechazadaControllers[detalle.id]?.dispose();
                            cantidadRechazadaControllers.remove(detalle.id);
                          }
                          onStateChanged();
                        },
                        activeColor: Colors.orange,
                      ),
                    ),
                    DataCell(
                      Text(
                        detalle.producto?.nombre ??
                            detalle.nombreProducto ??
                            'Sin nombre',
                        style: TextStyle(
                          fontWeight: isRechazado
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isRechazado ? Colors.orange[700] : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${detalle.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.orange[700] : null,
                        ),
                      ),
                    ),
                    DataCell(
                      isRechazado
                          ? SizedBox(
                              width: 70,
                              child: Builder(
                                builder: (context) {
                                  if (!cantidadRechazadaControllers
                                      .containsKey(detalle.id)) {
                                    cantidadRechazadaControllers[detalle.id] =
                                        TextEditingController(
                                      text:
                                          '${productoRechazado?.cantidadRechazada ?? 0}',
                                    );
                                  }
                                  final controller =
                                      cantidadRechazadaControllers[detalle.id]!;

                                  return TextField(
                                    controller: controller,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d*'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      final cantidad =
                                          double.tryParse(value) ?? 0;
                                      if (cantidad > detalle.cantidad) {
                                        productoRechazado?.cantidadRechazada =
                                            detalle.cantidad.toDouble();
                                        controller.text = detalle.cantidad
                                            .toStringAsFixed(1);
                                      } else if (cantidad >= 0) {
                                        productoRechazado?.cantidadRechazada =
                                            cantidad;
                                      }
                                      onStateChanged();
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                    ),
                    DataCell(
                      Text(
                        isRechazado
                            ? '${productoRechazado?.cantidadEntregada.toStringAsFixed(1)}'
                            : '${detalle.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.green[700] : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Text('Bs. ${detalle.precioUnitario.toStringAsFixed(2)}'),
                    ),
                    DataCell(
                      Text(
                        isRechazado
                            ? 'Bs. ${productoRechazado?.subtotalRechazado.toStringAsFixed(2)}'
                            : '-',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isRechazado ? Colors.red[700] : null,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (productosRechazados.isNotEmpty)
          _buildResumenRechazos(context, isDarkMode, totalOriginal,
              montoRechazado, montoEntregado),
      ],
    );
  }

  Widget _buildResumenRechazos(
    BuildContext context,
    bool isDarkMode,
    double totalOriginal,
    double montoRechazado,
    double montoEntregado,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.green[50]!, Colors.orange[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.orange[700]! : Colors.green[300]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            '📋 Desglose de Rechazos Parciales:',
            style: TextStyle(
              fontSize: AppTextStyles.bodySmall(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.blue[300]! : Colors.blue[800]!,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildProductosRechazadosList(context),
          const SizedBox(height: 12),
          Divider(
            color:
                isDarkMode ? Colors.orange[600]! : Colors.orange[300]!,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✓ Total Entregado:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? Colors.green[400]!
                      : Colors.green[700]!,
                ),
              ),
              Text(
                'Bs. ${montoEntregado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? Colors.green[400]!
                      : Colors.green[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✗ Total Rechazado:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.red[400]! : Colors.red[700]!,
                ),
              ),
              Text(
                'Bs. ${montoRechazado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.red[400]! : Colors.red[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            color:
                isDarkMode ? Colors.orange[600]! : Colors.orange[300]!,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Original:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? Colors.grey[400]!
                      : Colors.grey[700]!,
                ),
              ),
              Text(
                'Bs. ${totalOriginal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? Colors.grey[400]!
                      : Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductosRechazadosList(BuildContext context) {
    return productosRechazados.map(
      (prod) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '  • ${prod.nombreProducto}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${prod.cantidadRechazada.toStringAsFixed(1)}/${prod.cantidadOriginal.toStringAsFixed(0)} rechazadas',
              style: TextStyle(
                fontSize: AppTextStyles.labelSmall(context).fontSize!,
                color: isDarkMode
                    ? Colors.orange[400]!
                    : Colors.orange[700]!,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).toList();
  }
}

// ✅ Clase auxiliar para productos rechazados
class ProductoRechazado {
  int detalleVentaId;
  int? productoId;
  String nombreProducto;
  double cantidadOriginal;
  double cantidadRechazada;
  double precioUnitario;
  double subtotalOriginal;

  ProductoRechazado({
    required this.detalleVentaId,
    this.productoId,
    required this.nombreProducto,
    required this.cantidadOriginal,
    required this.cantidadRechazada,
    required this.precioUnitario,
    required this.subtotalOriginal,
  });

  double get subtotalRechazado => cantidadRechazada * precioUnitario;
  double get cantidadEntregada => cantidadOriginal - cantidadRechazada;
}
