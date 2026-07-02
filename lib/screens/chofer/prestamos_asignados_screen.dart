import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_text_styles.dart';
import 'prestamo_detalle_screen.dart';

/// Pantalla que muestra los 3 tipos de préstamos asignados al chofer
class PrestamosAsignadosScreen extends StatefulWidget {
  final bool showAppBar;

  const PrestamosAsignadosScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  State<PrestamosAsignadosScreen> createState() =>
      _PrestamosAsignadosScreenState();
}

class _PrestamosAsignadosScreenState extends State<PrestamosAsignadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Búsqueda y filtrado
  final Map<String, TextEditingController> _searchControllers = {
    'cliente': TextEditingController(),
    'evento': TextEditingController(),
    'proveedor': TextEditingController(),
  };

  final Map<String, Set<String>> _estadosFiltrados = {
    'cliente': {},
    'evento': {},
    'proveedor': {},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ Cargar préstamos cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPrestamos();
    });
  }

  /// Cargar préstamos del chofer actual
  void _cargarPrestamos() {
    try {
      final authProvider = context.read<AuthProvider>();
      final prestamosProvider = context.read<PrestamosProvider>();

      if (authProvider.user != null) {
        debugPrint(
          '📦 Cargando préstamos para chofer: ${authProvider.user!.id}',
        );
        prestamosProvider.cargarPrestamosDelChofer(authProvider.user!.id);
      } else {
        debugPrint('❌ Usuario no autenticado');
      }
    } catch (e) {
      debugPrint('❌ Error cargando préstamos: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar() : null,
      body: Column(
        children: [
          // Tabs con conteo de préstamos
          Consumer<PrestamosProvider>(
            builder: (context, provider, _) {
              return Container(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.secondary,
                  indicatorColor: Theme.of(context).colorScheme.secondary,
                  tabs: [
                    Tab(
                      text: 'Clientes (${provider.prestamosClientes.length})',
                      icon: const Icon(Icons.person),
                    ),
                    Tab(
                      text: 'Eventos (${provider.prestamosEventos.length})',
                      icon: const Icon(Icons.event),
                    ),
                    Tab(
                      text: 'Proveedores (${provider.prestamosProveedores.length})',
                      icon: const Icon(Icons.business),
                    ),
                  ],
                ),
              );
            },
          ),
          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrestamosList('cliente'),
                _buildPrestamosList('evento'),
                _buildPrestamosList('proveedor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer2<AuthProvider, PrestamosProvider>(
        builder: (context, authProvider, prestamosProvider, _) {
          final totalPrestamos = prestamosProvider.prestamosClientes.length +
              prestamosProvider.prestamosEventos.length +
              prestamosProvider.prestamosProveedores.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Préstamos Asignados'),
              Text(
                'Total: $totalPrestamos',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
      elevation: 0,
    );
  }

  Widget _buildPrestamosList(String tipo) {
    return Consumer<PrestamosProvider>(
      builder: (context, provider, _) {
        List<dynamic> prestamos = [];
        bool loading = false;

        switch (tipo) {
          case 'cliente':
            prestamos = provider.prestamosClientes;
            loading = provider.loadingClientes;
            break;
          case 'evento':
            prestamos = provider.prestamosEventos;
            loading = provider.loadingEventos;
            break;
          case 'proveedor':
            prestamos = provider.prestamosProveedores;
            loading = provider.loadingProveedores;
            break;
        }

        debugPrint(
          '🔍 [PRESTAMOS_$tipo] loading=$loading, count=${prestamos.length}',
        );

        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar prestamos
        final prestamosFiltrados = _filtrarPrestamos(prestamos, tipo);

        if (prestamos.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForType(tipo),
                  size: 64,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text('No hay préstamos asignados'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshPrestamos(context, tipo),
          child: Column(
            children: [
              _buildFilterSection(tipo),
              Expanded(
                child: prestamosFiltrados.isEmpty
                    ? Center(
                        child: Text(
                          'No hay resultados con los filtros aplicados',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: prestamosFiltrados.length,
                        itemBuilder: (context, index) {
                          final prestamo = prestamosFiltrados[index];
                          return _buildPrestamoCard(context, prestamo, tipo);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrestamoCard(
    BuildContext context,
    dynamic prestamo,
    String tipo,
  ) {
    String nombre = '';
    String subtitulo = '';
    String estado = '';
    String id = prestamo.id?.toString() ?? 'N/A';

    switch (tipo) {
      case 'cliente':
        nombre = prestamo.cliente?.nombre ?? 'Cliente desconocido';
        estado = prestamo.estado ?? '';
        subtitulo = 'Estado: $estado';
        break;
      case 'evento':
        nombre = prestamo.nombreEvento ?? 'Evento desconocido';
        estado = prestamo.estado ?? '';
        subtitulo = estado.isNotEmpty ? 'Estado: $estado' : 'Encargado: ${prestamo.encargadoEvento ?? 'N/A'}';
        break;
      case 'proveedor':
        nombre = prestamo.proveedor?.nombre ?? 'Proveedor desconocido';
        estado = prestamo.estado ?? '';
        subtitulo = 'Estado: $estado';
        debugPrint('🔧 [PROVEEDOR] ID=$id, Estado=$estado, Objeto Estado=${prestamo.estado}');
        break;
    }

    final cardColor = _getColorByEstado(context, estado);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      color: cardColor,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PrestamoDetalleScreen(prestamo: prestamo, tipo: tipo),
            ),
          );
          // ✅ Refrescar después de regresar de la navegación
          _cargarPrestamos();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_getIconForType(tipo)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: #$id',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'cliente':
        return Icons.person;
      case 'evento':
        return Icons.event;
      case 'proveedor':
        return Icons.business;
      default:
        return Icons.inventory; // ✅ CORREGIDO: Icons.package no existe
    }
  }

  Color _getColorByEstado(BuildContext context, String estado) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (estado.isEmpty) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    }

    if (estado == 'COMPLETAMENTE_DEVUELTO') {
      return isDark ? const Color(0xFF1B5E20) : Colors.green.shade200;
    }

    // ACTIVO y PARCIALMENTE_DEVUELTO
    if (estado == 'ACTIVO' || estado == 'PARCIALMENTE_DEVUELTO') {
      return isDark ? const Color(0xFF0D47A1) : Colors.blue.shade200;
    }

    return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
  }

  Widget _buildFilterSection(String tipo) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchControllers[tipo],
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchControllers[tipo]!.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchControllers[tipo]!.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              isDense: true,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildEstadoChip(tipo, 'ACTIVO'),
              _buildEstadoChip(tipo, 'PARCIALMENTE_DEVUELTO'),
              _buildEstadoChip(tipo, 'COMPLETAMENTE_DEVUELTO'),
              if (_estadosFiltrados[tipo]!.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _estadosFiltrados[tipo]!.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String tipo, String estado) {
    final isSelected = _estadosFiltrados[tipo]!.contains(estado);
    return FilterChip(
      label: Text(estado.replaceAll('_', ' ')),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _estadosFiltrados[tipo]!.add(estado);
          } else {
            _estadosFiltrados[tipo]!.remove(estado);
          }
        });
      },
    );
  }

  List<dynamic> _filtrarPrestamos(List<dynamic> prestamos, String tipo) {
    final searchText = _searchControllers[tipo]!.text.toLowerCase();
    final estadosFiltrados = _estadosFiltrados[tipo]!;

    return prestamos.where((prestamo) {
      // Filtro por búsqueda de nombre
      bool cumpleBusqueda = true;
      if (searchText.isNotEmpty) {
        String nombre = '';
        switch (tipo) {
          case 'cliente':
            nombre = prestamo.cliente?.nombre ?? '';
            break;
          case 'evento':
            nombre = prestamo.nombreEvento ?? '';
            break;
          case 'proveedor':
            nombre = prestamo.proveedor?.nombre ?? '';
            break;
        }
        cumpleBusqueda = nombre.toLowerCase().contains(searchText);
      }

      // Filtro por estado
      bool cumpleEstado = true;
      if (estadosFiltrados.isNotEmpty) {
        final estado = prestamo.estado ?? '';
        cumpleEstado = estadosFiltrados.contains(estado);
      }

      return cumpleBusqueda && cumpleEstado;
    }).toList();
  }

  Future<void> _refreshPrestamos(BuildContext context, String tipo) async {
    final provider = context.read<PrestamosProvider>();
    // Aquí se podría recargar solo el tipo específico si fuera necesario
    // Por ahora, vuelve a cargar todo
  }
}
