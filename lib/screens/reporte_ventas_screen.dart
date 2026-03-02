import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../config/config.dart';
import '../services/print_service.dart';

/// Pantalla de Reporte de Productos Vendidos
class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  late DateTime _fechaDesde;
  late DateTime _fechaHasta;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fechaHasta = ahora;
    _fechaDesde = ahora.subtract(const Duration(days: 30));

    // Cargar reporte con fechas por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteVentasProvider>().loadReporte(
            fechaDesde: _fechaDesde,
            fechaHasta: _fechaHasta,
          );
    });
  }

  Future<void> _selectFechaDesde(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaDesde,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _fechaDesde = pickedDate);
    }
  }

  Future<void> _selectFechaHasta(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaHasta,
      firstDate: _fechaDesde,
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _fechaHasta = pickedDate);
    }
  }

  void _aplicarFiltros() {
    context.read<ReporteVentasProvider>().loadReporte(
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        );
  }

  Future<void> _descargarPdf() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando PDF...'),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final pdfBytes =
          await context.read<ReporteVentasProvider>().descargarPdfReporte();

      if (pdfBytes != null && mounted) {
        await PrintService().abrirPdfDesdeBytes(
          pdfBytes: pdfBytes,
          nombreArchivo: 'reporte-productos-vendidos-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.pdf',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PDF descargado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Productos Vendidos'),
        elevation: 0,
      ),
      body: Consumer<ReporteVentasProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              _aplicarFiltros();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de Filtros
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔍 Filtros',
                              style: TextStyle(
                                fontSize:
                                    AppTextStyles.bodyLarge(context).fontSize!,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Fecha Desde
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Desde'),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(_fechaDesde),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectFechaDesde(context),
                            ),
                            const SizedBox(height: 8),
                            // Fecha Hasta
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Hasta'),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(_fechaHasta),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectFechaHasta(context),
                            ),
                            const SizedBox(height: 16),
                            // Botones de acción
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _aplicarFiltros,
                                    icon: const Icon(Icons.search),
                                    label: const Text('Buscar'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      context
                                          .read<ReporteVentasProvider>()
                                          .clearFiltros();
                                      _aplicarFiltros();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Limpiar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estado de carga
                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize:
                                      AppTextStyles.bodySmall(context).fontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Totales
                          _buildTotalesCard(context, provider),
                          const SizedBox(height: 16),

                          // Botón descargar PDF
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: provider.isDownloadingPdf
                                  ? null
                                  : _descargarPdf,
                              icon: provider.isDownloadingPdf
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.file_download),
                              label: Text(provider.isDownloadingPdf
                                  ? 'Descargando...'
                                  : 'Descargar PDF'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tabla de Productos
                          if (provider.productos.isNotEmpty) ...[
                            Text(
                              '📦 Productos Vendidos (${provider.productos.length})',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodyLarge(context)
                                    .fontSize!,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildProductosTable(context, provider),
                            const SizedBox(height: 16),
                          ],

                          // Tabla de Ventas
                          if (provider.ventas.isNotEmpty) ...[
                            Text(
                              '📋 Ventas Aprobadas (${provider.ventas.length})',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodyLarge(context)
                                    .fontSize!,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildVentasTable(context, provider),
                          ] else if (provider.productos.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sin datos para mostrar',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.bodyLarge(
                                          context,
                                        ).fontSize!,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalesCard(
      BuildContext context, ReporteVentasProvider provider) {
    final totales = provider.totales;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Resumen',
              style: TextStyle(
                fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Productos',
                    value: (totales['cantidad_productos'] ?? 0).toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    label: 'Cantidad Total',
                    value: (totales['cantidad_total_vendida'] ?? 0)
                        .toStringAsFixed(2),
                    icon: Icons.inventory_2,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Total Venta',
                    value:
                        'Bs. ${(totales['total_venta_general'] ?? 0).toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    label: 'Precio Promedio',
                    value:
                        'Bs. ${(totales['precio_promedio_general'] ?? 0).toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySmall(context).fontSize,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTextStyles.bodyLarge(context).fontSize!,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosTable(
      BuildContext context, ReporteVentasProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Cantidad'), numeric: true),
          DataColumn(label: Text('Precio Promedio'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: provider.productos
            .map(
              (producto) => DataRow(
                cells: [
                  DataCell(Text(
                    (producto['nombre'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(Text((producto['codigo'] ?? '').toString())),
                  DataCell(Text(
                    (producto['cantidad_total'] ?? 0).toStringAsFixed(2),
                  )),
                  DataCell(Text(
                    'Bs. ${(producto['precio_promedio'] ?? 0).toStringAsFixed(2)}',
                  )),
                  DataCell(Text(
                    'Bs. ${(producto['total_venta'] ?? 0).toStringAsFixed(2)}',
                  )),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildVentasTable(
      BuildContext context, ReporteVentasProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Venta')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: provider.ventas
            .map(
              (venta) => DataRow(
                cells: [
                  DataCell(Text((venta['numero'] ?? '').toString())),
                  DataCell(Text(
                    (venta['cliente'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(Text(
                    venta['fecha'] != null
                        ? DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(venta['fecha'].toString()))
                        : '',
                  )),
                  DataCell(Text(
                    'Bs. ${(venta['total'] ?? 0).toStringAsFixed(2)}',
                  )),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
