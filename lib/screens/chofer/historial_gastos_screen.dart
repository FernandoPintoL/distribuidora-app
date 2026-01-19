import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';

class HistorialGastosScreen extends StatefulWidget {
  const HistorialGastosScreen({Key? key}) : super(key: key);

  @override
  State<HistorialGastosScreen> createState() => _HistorialGastosScreenState();
}

class _HistorialGastosScreenState extends State<HistorialGastosScreen> {
  String _categoriaFiltro = 'TODOS';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    final gastoProvider = context.read<GastoProvider>();
    await gastoProvider.cargarGastos();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
        elevation: 0,
      ),
      body: Consumer<GastoProvider>(
        builder: (context, gastoProvider, _) {
          return Column(
            children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar gastos...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filtro por categoría
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFiltroChip(
                            'TODOS',
                            Icons.all_inclusive,
                            colorScheme,
                          ),
                          ...Gasto.categorias.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildFiltroChip(
                                cat,
                                _getIconoCategoria(cat),
                                colorScheme,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Estadísticas rápidas
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Total Gastos',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${gastoProvider.totalGastos.toStringAsFixed(2)} Bs',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Cantidad',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${gastoProvider.cantidadGastos}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Lista de gastos
              Expanded(
                child: _buildListaGastos(gastoProvider, colorScheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroChip(String categoria, IconData icono, ColorScheme colorScheme) {
    final isSelected = _categoriaFiltro == categoria;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _categoriaFiltro = categoria;
        });
      },
      avatar: Icon(icono, size: 18),
      label: Text(
        categoria == 'TODOS' ? 'Todo' : categoria,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: colorScheme.primaryContainer,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildListaGastos(
    GastoProvider gastoProvider,
    ColorScheme colorScheme,
  ) {
    if (gastoProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.primary,
          ),
        ),
      );
    }

    // Filtrar gastos
    List<Gasto> gastosFiltrados = gastoProvider.gastos;

    if (_categoriaFiltro != 'TODOS') {
      gastosFiltrados =
          gastosFiltrados.where((g) => g.categoria == _categoriaFiltro).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      gastosFiltrados = gastosFiltrados
          .where((g) =>
              g.descripcion.toLowerCase().contains(query) ||
              (g.numeroComprobante?.toLowerCase().contains(query) ?? false) ||
              (g.proveedor?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    if (gastosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sin gastos registrados',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarGastos,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: gastosFiltrados.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final gasto = gastosFiltrados[index];
          return _buildGastoTile(context, gasto, gastoProvider, colorScheme);
        },
      ),
    );
  }

  Widget _buildGastoTile(
    BuildContext context,
    Gasto gasto,
    GastoProvider gastoProvider,
    ColorScheme colorScheme,
  ) {
    return Dismissible(
      key: ValueKey(gasto.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        final exito = await gastoProvider.eliminarGasto(gasto.id);
        if (exito && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gasto eliminado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
          child: Icon(
            _getIconoCategoria(gasto.categoria),
            color: colorScheme.primary,
          ),
        ),
        title: Text(gasto.descripcion),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gasto.categoriaLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
            if (gasto.numeroComprobante != null)
              Text(
                'Comprobante: ${gasto.numeroComprobante}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-${gasto.montoFormato} Bs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            Text(
              _formatoFecha(gasto.fecha),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconoCategoria(String categoria) {
    switch (categoria) {
      case 'TRANSPORTE':
        return Icons.directions_car;
      case 'LIMPIEZA':
        return Icons.cleaning_services;
      case 'MANTENIMIENTO':
        return Icons.build;
      case 'SERVICIOS':
        return Icons.miscellaneous_services;
      case 'VARIOS':
        return Icons.category;
      default:
        return Icons.attach_money;
    }
  }

  String _formatoFecha(DateTime fecha) {
    final hoy = DateTime.now();
    if (fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day) {
      return 'Hoy ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    }
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
