import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:distribuidora/config/app_text_styles.dart';

/// Modelo simple para productos rechazados
class ProductoRechazado {
  final int detalleVentaId;
  final int? productoId;
  final String nombreProducto;
  final double cantidadOriginal;
  double cantidadRechazada;
  final double precioUnitario;
  final double subtotalOriginal;

  ProductoRechazado({
    required this.detalleVentaId,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidadOriginal,
    required this.cantidadRechazada,
    required this.precioUnitario,
    required this.subtotalOriginal,
  });

  double get cantidadEntregada => cantidadOriginal - cantidadRechazada;
  double get subtotalRechazado => cantidadRechazada * precioUnitario;
}

/// ✅ Widget Stateless para tabla de productos rechazados
class TablaProductosRechazadosWidget extends StatelessWidget {
  final List<dynamic> detalles;
  final List<ProductoRechazado> productosRechazados;
  final Map<int, TextEditingController> cantidadRechazadaControllers;
  final bool isDarkMode;
  final Function(int detalleId, ProductoRechazado producto) onMarcarRechazo;
  final Function(int detalleId) onDesmarcarRechazo;
  final Function(int detalleId, double cantidad) onCantidadRechazadaChanged;

  const TablaProductosRechazadosWidget({
    Key? key,
    required this.detalles,
    required this.productosRechazados,
    required this.cantidadRechazadaControllers,
    required this.isDarkMode,
    required this.onMarcarRechazo,
    required this.onDesmarcarRechazo,
    required this.onCantidadRechazadaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular totales
    double totalOriginal = detalles.fold(
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
        // Encabezado mejorado
        Text(
          '📦 Productos de la Venta',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
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

        // Tabla de productos mejorada
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
              rows: detalles.asMap().entries.map((entry) {
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
                    // Checkbox para marcar como rechazado
                    DataCell(
                      Checkbox(
                        value: isRechazado,
                        onChanged: (value) {
                          if (value == true) {
                            onMarcarRechazo(
                              detalle.id,
                              ProductoRechazado(
                                detalleVentaId: detalle.id,
                                productoId: detalle.producto?.id,
                                nombreProducto: detalle.producto?.nombre ??
                                    detalle.nombreProducto ??
                                    'Producto',
                                cantidadOriginal:
                                    detalle.cantidad.toDouble(),
                                cantidadRechazada: 1.0,
                                precioUnitario:
                                    detalle.precioUnitario.toDouble(),
                                subtotalOriginal:
                                    detalle.subtotal?.toDouble() ?? 0,
                              ),
                            );
                            if (!cantidadRechazadaControllers
                                .containsKey(detalle.id)) {
                              cantidadRechazadaControllers[detalle.id] =
                                  TextEditingController(text: '1.0');
                            }
                          } else {
                            onDesmarcarRechazo(detalle.id);
                            cantidadRechazadaControllers[detalle.id]
                                ?.dispose();
                            cantidadRechazadaControllers.remove(detalle.id);
                          }
                        },
                        activeColor: Colors.orange,
                      ),
                    ),
                    // Nombre del producto
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
                    // Cantidad original
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
                    // Input editable para cantidad rechazada
                    DataCell(
                      isRechazado
                          ? SizedBox(
                              width: 70,
                              child: TextField(
                                controller:
                                    cantidadRechazadaControllers[detalle.id],
                                keyboardType: TextInputType.numberWithOptions(
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
                                    onCantidadRechazadaChanged(
                                      detalle.id,
                                      detalle.cantidad.toDouble(),
                                    );
                                    cantidadRechazadaControllers[detalle.id]
                                            ?.text =
                                        detalle.cantidad.toStringAsFixed(1);
                                  } else if (cantidad >= 0) {
                                    onCantidadRechazadaChanged(
                                      detalle.id,
                                      cantidad,
                                    );
                                  }
                                },
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
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
                    // Cantidad entregada (calculada)
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
                    // Precio unitario
                    DataCell(
                      Text(
                        'Bs. ${detalle.precioUnitario.toStringAsFixed(2)}',
                      ),
                    ),
                    // Subtotal de rechazadas (calculado)
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

        // Resumen de montos basado en cantidades rechazadas
        if (productosRechazados.isNotEmpty)
          Container(
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
                // Desglose por producto rechazado
                Text(
                  '📋 Desglose de Rechazos Parciales:',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.blue[300]!
                        : Colors.blue[800]!,
                  ),
                ),
                const SizedBox(height: 8),
                ...productosRechazados.map(
                  (prod) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '  • ${prod.nombreProducto}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${prod.cantidadRechazada.toStringAsFixed(1)}/${prod.cantidadOriginal.toStringAsFixed(0)} rechazadas',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.labelSmall(context).fontSize!,
                            color: isDarkMode
                                ? Colors.orange[400]!
                                : Colors.orange[700]!,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color:
                      isDarkMode ? Colors.orange[600]! : Colors.orange[300]!,
                ),
                const SizedBox(height: 8),
                // Total Entregado
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
                // Total Rechazado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✗ Total Rechazado:',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? Colors.red[400]!
                            : Colors.red[700]!,
                      ),
                    ),
                    Text(
                      'Bs. ${montoRechazado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? Colors.red[400]!
                            : Colors.red[700]!,
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
                // Total Original
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
          ),
      ],
    );
  }
}
