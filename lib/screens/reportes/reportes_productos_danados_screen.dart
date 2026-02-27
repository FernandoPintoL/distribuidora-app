import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../config/config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'nuevo_reporte_screen.dart';
import 'detalle_reporte_screen.dart';

class ReportesProductosDanadosScreen extends StatefulWidget {
  const ReportesProductosDanadosScreen({super.key});

  @override
  State<ReportesProductosDanadosScreen> createState() =>
      _ReportesProductosDanadosScreenState();
}

class _ReportesProductosDanadosScreenState
    extends State<ReportesProductosDanadosScreen> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String? _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // ✅ Posponer la carga después de la construcción para evitar setState durante build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _cargarReportes(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider =
          Provider.of<ReporteProductoDanadoProvider>(context, listen: false);
      if (provider.hasMorePages && !provider.isLoading) {
        provider.cargarReportes(estado: _estadoSeleccionado);
      }
    }
  }

  Future<void> _cargarReportes({bool refresh = false}) async {
    final provider =
        Provider.of<ReporteProductoDanadoProvider>(context, listen: false);
    await provider.cargarReportes(
      estado: _estadoSeleccionado,
      refresh: refresh,
    );
  }

  void _filtrarPorEstado(String? estado) {
    setState(() {
      _estadoSeleccionado = estado;
    });
    _cargarReportes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Defectos'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Tooltip(
              message: 'Nuevo reporte',
              child: ElevatedButton.icon(
                onPressed: () => _abrirNuevoReporte(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _cargarReportes(refresh: true),
        child: Consumer<ReporteProductoDanadoProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Filtros
                  _buildFiltrosSection(),

                  // Contenido principal
                  if (provider.isLoading && provider.reportes.isEmpty)
                    _buildLoadingState()
                  else if (provider.errorMessage != null &&
                      provider.reportes.isEmpty)
                    _buildErrorState(provider)
                  else if (provider.reportes.isEmpty)
                    _buildEmptyState()
                  else
                    _buildReportesList(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Seccion de filtros
  Widget _buildFiltrosSection() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titulo filtros
          Text(
            'Filtrar por estado',
            style: AppTextStyles.titleSmall(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Chips de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Todos
                _buildEstadoChip(
                  label: 'Todos',
                  estado: null,
                  isSelected: _estadoSeleccionado == null,
                ),
                // Pendiente
                _buildEstadoChip(
                  label: 'Pendientes',
                  estado: 'pendiente',
                  isSelected: _estadoSeleccionado == 'pendiente',
                  color: Colors.orange,
                ),
                // En revision
                _buildEstadoChip(
                  label: 'En Revision',
                  estado: 'en_revision',
                  isSelected: _estadoSeleccionado == 'en_revision',
                  color: Colors.blue,
                ),
                // Aprobado
                _buildEstadoChip(
                  label: 'Aprobados',
                  estado: 'aprobado',
                  isSelected: _estadoSeleccionado == 'aprobado',
                  color: Colors.green,
                ),
                // Rechazado
                _buildEstadoChip(
                  label: 'Rechazados',
                  estado: 'rechazado',
                  isSelected: _estadoSeleccionado == 'rechazado',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip para filtrar por estado
  Widget _buildEstadoChip({
    required String label,
    required String? estado,
    required bool isSelected,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _filtrarPorEstado(estado),
        backgroundColor: Colors.grey[200],
        selectedColor: (color ?? Colors.blue).withOpacity(0.3),
        side: BorderSide(
          color: isSelected ? (color ?? Colors.blue) : Colors.transparent,
          width: 2,
        ),
        showCheckmark: false,
      ),
    );
  }

  /// Lista de reportes
  Widget _buildReportesList(ReporteProductoDanadoProvider provider) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          controller: _scrollController,
          itemCount: provider.reportes.length,
          itemBuilder: (context, index) {
            final reporte = provider.reportes[index];
            return _buildReporteCard(reporte);
          },
        ),
        // Indicador de carga al final
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  /// Card de reporte
  Widget _buildReporteCard(ReporteProductoDanado reporte) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(reporte.estado);

    return GestureDetector(
      onTap: () => _abrirDetalle(reporte.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Numero venta y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${reporte.numeroVenta}',
                          style:
                              AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reporte.nombreCliente,
                          style: AppTextStyles.bodySmall(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      reporte.estadoDescripcion,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Observaciones (primeras lineas)
              Text(
                reporte.observaciones,
                style: AppTextStyles.bodySmall(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Info de imagenes y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Imagenes
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reporte.imagenes.length} imagen${reporte.imagenes.length != 1 ? 'es' : ''}',
                        style: AppTextStyles.labelSmall(context),
                      ),
                    ],
                  ),
                  // Fecha
                  Text(
                    _formatearFecha(reporte.createdAt),
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando reportes...'),
        ],
      ),
    );
  }

  /// Estado de error
  Widget _buildErrorState(ReporteProductoDanadoProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar reportes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _cargarReportes(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Estado vacio
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay reportes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _estadoSeleccionado != null
                ? 'No hay reportes con este estado'
                : 'Comienza reportando un producto danado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_estadoSeleccionado == null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _abrirNuevoReporte(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Reporte'),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtener color segun estado
  Color _getStatusColor(String estado) {
    return switch (estado) {
      'pendiente' => Colors.orange,
      'en_revision' => Colors.blue,
      'aprobado' => Colors.green,
      'rechazado' => Colors.red,
      _ => Colors.grey,
    };
  }

  /// Formatear fecha
  String _formatearFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final diferencia = hoy.difference(fecha).inDays;

    if (diferencia == 0) {
      return 'Hoy';
    } else if (diferencia == 1) {
      return 'Ayer';
    } else if (diferencia < 7) {
      return 'hace $diferencia dias';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  /// Abrir pantalla de nuevo reporte
  void _abrirNuevoReporte() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NuevoReporteScreen(),
      ),
    );
  }

  /// Abrir detalle de reporte
  void _abrirDetalle(int reporteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleReporteScreen(reporteId: reporteId),
      ),
    );
  }
}
