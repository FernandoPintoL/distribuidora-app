import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../config/config.dart';
import '../services/print_service.dart';
import '../utils/date_picker_utils.dart';

/// Pantalla de Reporte de Productos Vendidos
class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen>
    with TickerProviderStateMixin {
  late DateTime _fechaDesde;
  late DateTime _fechaHasta;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fechaHasta = ahora;
    _fechaDesde = DateTime(ahora.year, ahora.month, 1);

    _tabController = TabController(length: 2, vsync: this);

    // Cargar reporte con fechas por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteVentasProvider>().loadReporte(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaDesde(BuildContext context) async {
    final pickedDate = await DatePickerUtils.showThemedDatePicker(
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
    final pickedDate = await DatePickerUtils.showThemedDatePicker(
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
      final pdfBytes = await context
          .read<ReporteVentasProvider>()
          .descargarPdfReporte();

      if (pdfBytes != null && mounted) {
        await PrintService().abrirPdfDesdeBytes(
          pdfBytes: pdfBytes,
          nombreArchivo:
              'reporte-productos-vendidos-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.pdf',
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
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            // Fechas en una fila con 2 columnas responsivas
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectFechaDesde(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Desde'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_fechaDesde),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectFechaHasta(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Hasta'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(_fechaHasta),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Totales con botón Descargar PDF
                          _buildTotalesCardWithPdf(context, provider),
                          const SizedBox(height: 16),

                          // TabBar para Productos y Ventas
                          if (provider.productos.isNotEmpty ||
                              provider.ventas.isNotEmpty) ...[
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    tabs: [
                                      Tab(
                                        text:
                                            '📦 Productos (${provider.productos.length})',
                                      ),
                                      Tab(
                                        text:
                                            '📋 Ventas (${provider.ventas.length})',
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 400,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        // Tab de Productos
                                        provider.productos.isNotEmpty
                                            ? SingleChildScrollView(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: _buildProductosTable(
                                                  context,
                                                  provider,
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.inbox_outlined,
                                                      size: 48,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Sin productos',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        // Tab de Ventas
                                        provider.ventas.isNotEmpty
                                            ? SingleChildScrollView(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: _buildVentasTable(
                                                  context,
                                                  provider,
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.inbox_outlined,
                                                      size: 48,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Sin ventas',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
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

  Widget _buildTotalesCardWithPdf(
    BuildContext context,
    ReporteVentasProvider provider,
  ) {
    final totales = provider.totales;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📊 Resumen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isDownloadingPdf ? null : _descargarPdf,
                  icon: provider.isDownloadingPdf
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download, size: 18),
                  label: Text(
                    provider.isDownloadingPdf ? 'Descargando...' : 'PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
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
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosTable(
    BuildContext context,
    ReporteVentasProvider provider,
  ) {
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
                  DataCell(
                    Text(
                      (producto['nombre'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text((producto['codigo'] ?? '').toString())),
                  DataCell(
                    Text((producto['cantidad_total'] ?? 0).toStringAsFixed(2)),
                  ),
                  DataCell(
                    Text(
                      'Bs. ${(producto['precio_promedio'] ?? 0).toStringAsFixed(2)}',
                    ),
                  ),
                  DataCell(
                    Text(
                      'Bs. ${(producto['total_venta'] ?? 0).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildVentasTable(
    BuildContext context,
    ReporteVentasProvider provider,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Folio')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: provider.ventas
            .map(
              (venta) => DataRow(
                cells: [
                  DataCell(Text((venta['id'] ?? '').toString())),
                  DataCell(
                    Text(
                      (venta['cliente'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      venta['fecha'] != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(DateTime.parse(venta['fecha'].toString()))
                          : '',
                    ),
                  ),
                  DataCell(
                    Text('Bs. ${(venta['total'] ?? 0).toStringAsFixed(2)}'),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
