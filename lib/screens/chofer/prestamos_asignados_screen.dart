import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_urls.dart';
import 'prestamo_detalle_screen.dart';

/// Pantalla que muestra los 3 tipos de préstamos asignados al chofer
class PrestamosAsignadosScreen extends StatefulWidget {
  final bool showAppBar;

  const PrestamosAsignadosScreen({super.key, this.showAppBar = false});

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
        debugPrint('📦 Cargando préstamos para: ${authProvider.user!.name}');
        // ✅ REFACTORIZADO: Pasar 0 para que el backend obtenga del token JWT
        prestamosProvider.cargarPrestamosDelChofer(0);
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
              return TabBar(
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
                    text:
                        'Proveedores (${provider.prestamosProveedores.length})',
                    icon: const Icon(Icons.business),
                  ),
                ],
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
          final totalPrestamos =
              prestamosProvider.prestamosClientes.length +
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
                Icon(_getIconForType(tipo), size: 64),
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
        subtitulo = '$estado';
        break;
      case 'evento':
        nombre = prestamo.nombreEvento ?? 'Evento desconocido';
        estado = prestamo.estado ?? '';
        subtitulo = estado.isNotEmpty
            ? 'Estado: $estado'
            : 'Encargado: ${prestamo.encargadoEvento ?? 'N/A'}';
        break;
      case 'proveedor':
        nombre = prestamo.proveedor?.nombre ?? 'Proveedor desconocido';
        estado = prestamo.estado ?? '';
        subtitulo = 'Estado: $estado';
        debugPrint(
          '🔧 [PROVEEDOR] ID=$id, Estado=$estado, Objeto Estado=${prestamo.estado}',
        );
        break;
    }

    final cardColor = _getColorByEstado(context, estado);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      // color: cardColor,
      shadowColor: cardColor,
      surfaceTintColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor, width: 2),
      ),
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
              _buildProfileWidget(context, tipo, prestamo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cardColor,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Folio: #$id',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ✅ MEJORADO: Mostrar todas las ubicaciones del préstamo
                    if (prestamo.ubicaciones != null &&
                        prestamo.ubicaciones!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ..._buildUbicacionesWidgets(
                        context,
                        prestamo.ubicaciones!,
                      ),
                    ],
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
      return Color(0xFF1B5E20);
    }

    // ACTIVO y PARCIALMENTE_DEVUELTO
    if (estado == 'ACTIVO' || estado == 'PARCIALMENTE_DEVUELTO') {
      return Color(0xFF503CBD);
    }

    //CANCELADO
    if (estado == 'CANCELADO') {
      return Color(0xFFB71C1C);
    }

    return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
  }

  /// Construir widget de perfil del cliente o icono genérico
  Widget _buildProfileWidget(
    BuildContext context,
    String tipo,
    dynamic prestamo,
  ) {
    // Si es cliente y tiene foto de perfil, mostrar imagen
    if (tipo == 'cliente' && prestamo.cliente?.fotoPerfil != null) {
      return _buildClienteImageWidget(prestamo.cliente!.fotoPerfil!);
    }

    // Si es cliente pero sin foto, mostrar avatar con iniciales
    if (tipo == 'cliente') {
      return _buildClienteAvatarWidget(prestamo.cliente?.nombre ?? 'C');
    }

    // Para evento y proveedor, mostrar icono genérico
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Icon(_getIconForType(tipo)),
    );
  }

  /// Widget para mostrar imagen de cliente
  Widget _buildClienteImageWidget(String fotoPerfil) {
    final imageUrl = AppUrls.buildImageUrl(fotoPerfil);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: Theme.of(context).primaryColor.withAlpha(50),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error cargando imagen: $imageUrl - $error');
            return Container(
              color: Theme.of(context).primaryColor.withAlpha(50),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Widget para mostrar avatar con iniciales
  Widget _buildClienteAvatarWidget(String nombre) {
    final iniciales = nombre
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          iniciales.isNotEmpty ? iniciales : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String tipo) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              _buildEstadoChip(tipo, 'ACTIVOS'),
              _buildEstadoChip(tipo, 'COMPLETAMENTE_DEVUELTO'),
              if (_estadosFiltrados[tipo]!.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _estadosFiltrados[tipo]!.clear();
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    size: 16,
                    color: context.colorScheme.secondary,
                  ),
                  label: Text(
                    'Limpiar filtros',
                    style: TextStyle(color: context.colorScheme.secondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String tipo, String estado) {
    final isSelected = _estadosFiltrados[tipo]!.contains(estado);
    final colorInfo = _getEstadoColorAndIcon(estado);

    // Cambiar label para COMPLETAMENTE_DEVUELTO
    final label = estado == 'COMPLETAMENTE_DEVUELTO' ? 'TERMINADO' : estado.replaceAll('_', ' ');

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            colorInfo['icon'] as IconData,
            size: 16,
            color: isSelected ? Colors.white : colorInfo['color'] as Color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: colorInfo['color'] as Color,
      backgroundColor: (colorInfo['color'] as Color).withOpacity(0.1),
      side: BorderSide(
        color: colorInfo['color'] as Color,
        width: isSelected ? 2 : 1,
      ),
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

  Map<String, dynamic> _getEstadoColorAndIcon(String estado) {
    switch (estado) {
      case 'ACTIVOS':
        return {
          'color': Colors.orange.shade600,
          'icon': Icons.hourglass_bottom_outlined,
        };
      case 'COMPLETAMENTE_DEVUELTO':
        return {
          'color': Colors.green.shade600,
          'icon': Icons.check_circle_outline,
        };
      default:
        return {'color': Colors.grey, 'icon': Icons.help_outline};
    }
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

        // Si seleccionó "ACTIVOS", incluye tanto ACTIVO como PARCIALMENTE_DEVUELTO
        if (estadosFiltrados.contains('ACTIVOS')) {
          cumpleEstado = estado == 'ACTIVO' || estado == 'PARCIALMENTE_DEVUELTO';
        } else {
          cumpleEstado = estadosFiltrados.contains(estado);
        }
      }

      return cumpleBusqueda && cumpleEstado;
    }).toList();
  }

  Future<void> _refreshPrestamos(BuildContext context, String tipo) async {
    final provider = context.read<PrestamosProvider>();
    // Aquí se podría recargar solo el tipo específico si fuera necesario
    // Por ahora, vuelve a cargar todo
  }

  /// Construir widgets para mostrar múltiples ubicaciones
  List<Widget> _buildUbicacionesWidgets(
    BuildContext context,
    List<dynamic> ubicaciones,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < ubicaciones.length; i++) {
      final ubicacion = ubicaciones[i];

      // Mostrar número de ubicación si hay más de una
      if (ubicaciones.length > 1) {
        widgets.add(
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ubicación ${i + 1}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }

      // Dirección
      /*if (ubicacion.direccion != null) {
        widgets.add(
          Row(
            children: [
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ubicacion.direccion!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }*/

      // Observaciones
      if (ubicacion.observaciones != null &&
          ubicacion.observaciones!.isNotEmpty) {
        widgets.add(const SizedBox(height: 4));
        widgets.add(
          Text(
            '📝 ${ubicacion.observaciones!}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }

      //localidad
      if (ubicacion.localidad != null) {
        widgets.add(const SizedBox(height: 4));
        widgets.add(
          Text(
            '📍 ${ubicacion.localidad!.nombre}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }

      // Espaciador entre ubicaciones
      if (i < ubicaciones.length - 1) {
        widgets.add(const SizedBox(height: 6));
      }
    }

    return widgets;
  }
}
