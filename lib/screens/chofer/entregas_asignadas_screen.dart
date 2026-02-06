import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../models/estado.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/entrega_estados_provider.dart';
import '../../services/estados_helpers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/productos_agrupados_widget.dart';
import '../../config/config.dart';

class EntregasAsignadasScreen extends StatefulWidget {
  const EntregasAsignadasScreen({Key? key}) : super(key: key);

  @override
  State<EntregasAsignadasScreen> createState() =>
      _EntregasAsignadasScreenState();
}

class _EntregasAsignadasScreenState extends State<EntregasAsignadasScreen> {
  String? _filtroEstado;
  String _busqueda = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _filtrosExpandidos = false;
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  late Future<void> _cargarFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Cargar datos inmediatamente (sin addPostFrameCallback aquí)
    // El provider maneja addPostFrameCallback en su notifyListeners()
    _cargarFuture = _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Cargar estados de entrega desde la BD (dinámicos)
    final estadosProvider = context.read<EntregaEstadosProvider>();
    await estadosProvider.cargarEstados();

    // Cargar entregas asignadas
    final entregaProvider = context.read<EntregaProvider>();
    await entregaProvider.obtenerEntregasAsignadas(
      estado: _filtroEstado != 'Todas' && _filtroEstado != null
          ? _filtroEstado
          : null,
    );
  }

  Future<void> _cargarEntregas() async {
    final provider = context.read<EntregaProvider>();
    await provider.obtenerEntregasAsignadas(
      estado: _filtroEstado != 'Todas' && _filtroEstado != null
          ? _filtroEstado
          : null,
    );
  }

  /// Actualizar todos los datos desde el backend (pull-to-refresh)
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final estadosProvider = context.read<EntregaEstadosProvider>();
      final entregaProvider = context.read<EntregaProvider>();

      // Actualizar estados y entregas en paralelo
      await Future.wait([
        estadosProvider.cargarEstados(),
        entregaProvider.obtenerEntregasAsignadas(
          estado: _filtroEstado != 'Todas' && _filtroEstado != null
              ? _filtroEstado
              : null,
        ),
      ]);
    } catch (e) {
      debugPrint('❌ Error refrescando entregas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Búsqueda avanzada case-insensitive con múltiples campos
  List<Entrega> _getEntregasFiltradas(List<Entrega> entregas) {
    return entregas.where((entrega) {
      // Filtro por búsqueda (búsqueda avanzada)
      if (_busqueda.isNotEmpty) {
        final search = _busqueda.toLowerCase();
        bool coincide = false;

        // Búsqueda en Entrega
        if ((entrega.id.toString().contains(search)) ||
            (entrega.numero?.toLowerCase().contains(search) ?? false) ||
            (entrega.cliente?.toLowerCase().contains(search) ?? false) ||
            (entrega.direccion?.toLowerCase().contains(search) ?? false)) {
          coincide = true;
        }

        // Búsqueda en Ventas
        if (!coincide && entrega.ventas.isNotEmpty) {
          for (final venta in entrega.ventas) {
            if ((venta.id.toString().contains(search)) ||
                (venta.numero?.toLowerCase().contains(search) ?? false) ||
                (venta.clienteNombre?.toLowerCase().contains(search) ??
                    false) ||
                (venta.cliente?.toLowerCase().contains(search) ?? false)) {
              coincide = true;
              break;
            }
            // Búsqueda en datos del cliente dentro de la venta
            if (venta.cliente is Map) {
              final clienteMap = venta.cliente as Map;
              if ((clienteMap['nombre']?.toString().toLowerCase().contains(
                        search,
                      ) ??
                      false) ||
                  (clienteMap['ci']?.toString().toLowerCase().contains(
                        search,
                      ) ??
                      false) ||
                  (clienteMap['telefono']?.toString().toLowerCase().contains(
                        search,
                      ) ??
                      false)) {
                coincide = true;
                break;
              }
            }
          }
        }

        if (!coincide) {
          return false;
        }
      }

      // Filtro por fechas
      if (_fechaInicio != null || _fechaFin != null) {
        final fecha = entrega.fechaAsignacion;
        if (fecha != null) {
          if (_fechaInicio != null &&
              fecha.isBefore(
                _fechaInicio!.subtract(const Duration(hours: 1)),
              )) {
            return false;
          }
          if (_fechaFin != null &&
              fecha.isAfter(_fechaFin!.add(const Duration(days: 1)))) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = null;
      _busqueda = '';
      _fechaInicio = null;
      _fechaFin = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      // ✅ RefreshIndicator envuelve todo para pull-to-refresh desde cualquier estado
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 40,
        strokeWidth: 2.5,
        color: Colors.blue,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        child: FutureBuilder<void>(
          future: _cargarFuture,
          builder: (context, snapshot) {
            // Una vez que se completa (éxito o error), mostrar Consumer
            // El Consumer escuchará cambios posteriores del provider
            return Consumer<EntregaProvider>(
              builder: (context, provider, _) {
                // Mostrar loading solo si aún se está cargando
                if (snapshot.connectionState == ConnectionState.waiting &&
                    provider.entregas.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.blue : Colors.blue,
                      ),
                    ),
                  );
                }

                final entregasFiltradas = _getEntregasFiltradas(
                  provider.entregas,
                );

                return Column(
                  children: [
                    // Filtros y búsqueda mejorados
                    _buildFiltrosModernos(isDarkMode),
                    // Lista de entregas
                    Expanded(
                      child: _buildListado(
                        provider,
                        entregasFiltradas,
                        isDarkMode,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiltrosModernos(bool isDarkMode) {
    final hasFilters =
        _busqueda.isNotEmpty ||
        _filtroEstado != null ||
        _fechaInicio != null ||
        _fechaFin != null;

    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header colapsable
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (hasFilters) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Activo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtrosExpandidos = !_filtrosExpandidos;
                      });
                    },
                    child: Icon(
                      _filtrosExpandidos
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido colapsable
            if (_filtrosExpandidos) ...[
              // Barra de búsqueda mejorada
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _busqueda = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Buscar: ID, cliente, CI, teléfono, venta, fecha...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _busqueda = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // Filtros de estado y fechas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro de estados - DINÁMICO desde la BD
                    Consumer<EntregaEstadosProvider>(
                      builder: (context, estadosProvider, _) {
                        final estadosFiltro = estadosProvider
                            .getEstadosParaFiltrado();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                clipBehavior: Clip.hardEdge,
                                itemCount: estadosFiltro.length + 1,
                                itemBuilder: (context, index) {
                                  // Primera opción es "Todas"
                                  if (index == 0) {
                                    final isSelected = _filtroEstado == null;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 0,
                                        right: 8,
                                      ),
                                      child: FilterChip(
                                        label: Text(
                                          'Todas',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDarkMode
                                                      ? Colors.grey[300]
                                                      : Colors.grey[700]),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _filtroEstado = null;
                                          });
                                          _cargarEntregas();
                                        },
                                        backgroundColor: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[200],
                                        selectedColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Estados dinámicos desde la BD
                                  final estado = estadosFiltro[index - 1];
                                  final isSelected =
                                      _filtroEstado == estado.codigo;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        estado.nombre,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700]),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _filtroEstado = estado.codigo;
                                        });
                                        _cargarEntregas();
                                      },
                                      backgroundColor: isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[200],
                                      selectedColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro de fechas
                    Text(
                      'Rango de fechas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Desde',
                            date: _fechaInicio,
                            onDateSelected: (date) {
                              setState(() {
                                _fechaInicio = date;
                              });
                            },
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Hasta',
                            date: _fechaFin,
                            onDateSelected: (date) {
                              setState(() {
                                _fechaFin = date;
                              });
                            },
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),

                    // Botón de limpiar filtros
                    if (hasFilters) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _limpiarFiltros,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Limpiar filtros'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Seleccionar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? (date != null ? Colors.white : Colors.grey[400])
                        : (date != null ? Colors.black87 : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListado(
    EntregaProvider provider,
    List<Entrega> entregas,
    bool isDarkMode,
  ) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.blue : Colors.blue,
          ),
        ),
      );
    }

    if (entregas.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 64,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay entregas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _busqueda.isNotEmpty || _filtroEstado != null
                      ? 'No se encontraron resultados para los filtros seleccionados'
                      : 'Las entregas aparecerán aquí cuando se asignen',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entregas.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final entrega = entregas[index];
        return _EntregaCard(entrega: entrega, isDarkMode: isDarkMode);
      },
    );
  }

  String _getEtiquetaEstado(String estado) {
    const etiquetas = {
      'PROGRAMADO': 'Programado',
      'ASIGNADA': 'Asignada',
      'PREPARACION_CARGA': 'En Prep.',
      'EN_CARGA': 'En Carga',
      'LISTO_PARA_ENTREGA': 'Listo',
      'EN_CAMINO': 'En Camino',
      'EN_TRANSITO': 'En Tránsito',
      'LLEGO': 'Llegó',
      'ENTREGADO': 'Entregado',
      'NOVEDAD': 'Novedad',
      'RECHAZADO': 'Rechazado',
      'CANCELADA': 'Cancelada',
    };
    return etiquetas[estado] ?? estado;
  }
}

class _EntregaCard extends StatefulWidget {
  final Entrega entrega;
  final bool isDarkMode;

  const _EntregaCard({
    Key? key,
    required this.entrega,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<_EntregaCard> createState() => _EntregaCardState();
}

class _EntregaCardState extends State<_EntregaCard> {
  bool _ventasExpandidas = false;
  bool _productosExpandidos = false;

  Entrega get entrega => widget.entrega;
  bool get isDarkMode => widget.isDarkMode;

  @override
  Widget build(BuildContext context) {
    // debugPrint('Building EntregaCard for Entrega ID: ${entrega.id}');
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 4,
      color: cardColor,
      shadowColor: isDarkMode
          ? Colors.black.withAlpha((0.5 * 255).toInt())
          : Colors.grey.withAlpha((0.3 * 255).toInt()),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorEstado(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entrega.tipoWorkIcon,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getTituloTrabajo(entrega),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Entrega: ${entrega.numeroEntrega ?? '#${entrega.id}'}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entrega.id > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.orange[900]?.withAlpha((0.2 * 255).toInt())
                    : Colors.orange[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _productosExpandidos = !_productosExpandidos;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 Productos a Entregar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  'Ver resumen consolidado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.withAlpha(
                                      (0.7 * 255).toInt(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          _productosExpandidos
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  // Productos expandidos
                  if (_productosExpandidos) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    ProductosAgrupadsWidget(
                      entregaId: entrega.id,
                      mostrarDetalleVentas: true,
                    ),
                  ],
                ],
              ),
            ),
          // Ventas asignadas (expandible)
          if (entrega.ventas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue[900]?.withAlpha((0.3 * 255).toInt())
                    : Colors.blue[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _ventasExpandidas = !_ventasExpandidas;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 ${entrega.ventas.length} venta${entrega.ventas.length > 1 ? 's' : ''} asignada${entrega.ventas.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (entrega.ventas.isNotEmpty)
                                  Text(
                                    'Total: BS ${entrega.ventas.fold<double>(0, (sum, v) => sum + v.subtotal).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          _ventasExpandidas
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  // Ventas expandidas
                  if (_ventasExpandidas) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entrega.ventas.length,
                      itemBuilder: (context, index) {
                        final venta = entrega.ventas[index];
                        // print('[ENTREGA_CARD] Mostrando venta: ${venta.estadoLogistico}, cliente: ${venta.clienteNombre ?? venta.cliente}');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]?.withAlpha(
                                      (0.3 * 255).toInt(),
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado: número, cliente y estado logístico
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      venta.numero,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      venta.clienteNombre ??
                                                          venta.cliente ??
                                                          'Cliente desconocido',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Estado logístico badge
                                              _buildEstadoVentaBadge(
                                                venta.estadoLogisticoId,
                                                venta.estadoLogistico,
                                                venta.estadoLogisticoColor,
                                                venta.estadoLogisticoIcon,
                                                isDarkMode,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Fila de montos: Subtotal y Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Subtotal
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDarkMode
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Bs. ${venta.subtotal?.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.grey[300]
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Productos Agrupados (expandible)

          // Fecha y botones de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fecha asignada
                if (entrega.fechaAsignacion != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entrega.formatFecha(entrega.fechaAsignacion),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(), // Widget vacío sin conflictos de layout
                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ver Detalles
                    Tooltip(
                      message: 'Ver Detalles',
                      child: IconButton(
                        icon: const Icon(Icons.info_outline),
                        color: Colors.blue,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/chofer/entrega-detalle',
                            arguments: entrega.id,
                          );
                        },
                      ),
                    ),
                    // Cómo llegar
                    Tooltip(
                      message: 'Cómo llegar',
                      child: IconButton(
                        icon: const Icon(Icons.map),
                        color: Colors.orange,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _openInGoogleMaps(context),
                      ),
                    ),
                    // Iniciar Ruta (condicional)
                    if (entrega.puedeIniciarRuta)
                      Tooltip(
                        message: 'Iniciar Ruta',
                        child: IconButton(
                          icon: const Icon(Icons.navigation),
                          color: Colors.green,
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/chofer/iniciar-ruta',
                              arguments: entrega.id,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado() {
    // Usar primero el color del estado desde la BD (estado_entrega.color)
    final colorHex = entrega.estadoEntregaColor ?? entrega.estadoColor;

    // Validar que el color tenga el formato correcto
    if (colorHex.isEmpty || !colorHex.startsWith('#')) {
      return Colors.blue; // Color por defecto si hay error
    }

    try {
      return Color(int.parse('0xff${colorHex.substring(1)}'));
    } catch (e) {
      debugPrint('❌ Error parseando color: $colorHex - $e');
      return Colors.blue;
    }
  }

  String _getTituloTrabajo(Entrega entrega) {
    print('[ENTREGA_CARD] Tipo de trabajo: ${entrega.estadoEntregaCodigo}');
    if (entrega.trabajoType == 'entrega') {
      return 'Entrega #${entrega.id}';
    } else if (entrega.trabajoType == 'envio') {
      return 'Envío #${entrega.id}';
    }
    return 'Entrega #${entrega.id}';
  }

  Widget _buildEstadoVentaBadge(
    int? estadoLogisticoId,
    String? estadoLogisticoCodigo,
    String? estadoLogisticoColor,
    String? estadoLogisticoIcon,
    bool isDarkMode,
  ) {
    // Usar directamente los datos del backend si están disponibles
    String nombre = estadoLogisticoCodigo ?? 'Desconocido';
    String icono = estadoLogisticoIcon ?? '📦';
    String colorHex = estadoLogisticoColor ?? '#000000';

    // Si no tenemos color/icon del backend, intentar buscar en el caché
    if ((estadoLogisticoColor == null || estadoLogisticoIcon == null) &&
        estadoLogisticoId != null) {
      final estado = EstadosHelper.getEstadoPorId(
        'venta_logistica',
        estadoLogisticoId,
      );
      if (estado != null) {
        nombre = estado.nombre;
        icono = estado.icono ?? '📦';
        colorHex = estado.color;
      }
    }

    // Convertir color hex a Color
    final color = Color(EstadosHelper.colorHexToInt(colorHex));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icono, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            nombre,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final address = entrega.direccion ?? '';
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dirección no disponible')));
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/$address');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
