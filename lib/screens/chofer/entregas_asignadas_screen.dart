import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/entrega_estados_provider.dart';
import 'entregas_asignadas/entregas_asignadas_exports.dart';

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
    // Inicializar con un future completado para evitar LateInitializationError
    _cargarFuture = Future.value();

    // Retrasar la carga de datos hasta después del build para evitar
    // "setState() called during build" error cuando el provider notifica listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _cargarFuture = _cargarDatos();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final estadosProvider = context.read<EntregaEstadosProvider>();
    await estadosProvider.cargarEstados();

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

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final estadosProvider = context.read<EntregaEstadosProvider>();
      final entregaProvider = context.read<EntregaProvider>();

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

  List<Entrega> _getEntregasFiltradas(List<Entrega> entregas) {
    return entregas.where((entrega) {
      // Filtro por búsqueda
      if (_busqueda.isNotEmpty) {
        final search = _busqueda.toLowerCase();
        bool coincide = false;

        if ((entrega.id.toString().contains(search)) ||
            (entrega.numero?.toLowerCase().contains(search) ?? false) ||
            (entrega.cliente?.toLowerCase().contains(search) ?? false) ||
            (entrega.direccion?.toLowerCase().contains(search) ?? false)) {
          coincide = true;
        }

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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 40,
        strokeWidth: 2.5,
        color: Colors.blue,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        child: FutureBuilder<void>(
          future: _cargarFuture,
          builder: (context, snapshot) {
            return Consumer<EntregaProvider>(
              builder: (context, provider, _) {
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
                    FiltrosModernos(
                      filtroEstado: _filtroEstado ?? '',
                      busqueda: _busqueda,
                      fechaInicio: _fechaInicio,
                      fechaFin: _fechaFin,
                      filtrosExpandidos: _filtrosExpandidos,
                      isDarkMode: isDarkMode,
                      searchController: _searchController,
                      onBusquedaChanged: (value) {
                        setState(() => _busqueda = value);
                      },
                      onFiltroEstadoChanged: (estado) {
                        setState(() => _filtroEstado = estado);
                      },
                      onFechaInicioChanged: (date) {
                        setState(() => _fechaInicio = date);
                      },
                      onFechaFinChanged: (date) {
                        setState(() => _fechaFin = date);
                      },
                      onFiltrosExpandidosChanged: (expanded) {
                        setState(() => _filtrosExpandidos = expanded);
                      },
                      onLimpiarFiltros: _limpiarFiltros,
                      onCargarEntregas: _cargarEntregas,
                    ),
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
        return EntregaCard(entrega: entrega, isDarkMode: isDarkMode);
      },
    );
  }
}
