import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';
import 'entregas_asignadas/widgets/entrega_card.dart';

class EntregasAsignadasScreen extends StatefulWidget {
  const EntregasAsignadasScreen({Key? key}) : super(key: key);

  @override
  State<EntregasAsignadasScreen> createState() =>
      _EntregasAsignadasScreenState();
}

class _EntregasAsignadasScreenState extends State<EntregasAsignadasScreen> {
  String? _filtroEstado;
  // ✅ CAMBIO: Rango de fechas de CREACIÓN (created_at)
  DateTime? _fechaDesde = DateTime.now();  // Por defecto: hoy
  DateTime? _fechaHasta = DateTime.now();  // Por defecto: hoy
  String? _searchQuery;  // ✅ NUEVO: búsqueda
  String _searchInput = '';  // ✅ NUEVO: input temporal de búsqueda (antes de confirmar)
  int? _localidadFiltro;  // ✅ NUEVO: localidad
  bool _mostrarFiltros = false;  // ✅ NUEVO: control de visibilidad de filtros (inicia OCULTO)
  bool _isRefreshing = false;  // ✅ NUEVO: Estado para recarga manual
  final TextEditingController _searchController = TextEditingController();  // ✅ NUEVO: controller para el campo

  // ✅ CRÍTICO: Future estable que NO se recrea en cada rebuild
  late Future<bool> _futureEntregas;

  Future<void> _onCambiarFiltro(String? nuevoEstado) async {
    setState(() => _filtroEstado = nuevoEstado);
    _cargarEntregas();  // ✅ NUEVO: Recargar entregas después de cambiar filtro
  }

  @override
  void initState() {
    super.initState();
    // ✅ CRÍTICO: Crear el Future UNA SOLA VEZ en initState
    _cargarEntregas();
  }

  // ✅ NUEVO: Método para (re)cargar entregas sin recrear el Future
  void _cargarEntregas() {
    _futureEntregas = context.read<EntregaProvider>().obtenerEntregasAsignadas(
          estado: _filtroEstado,
          createdDesde: _fechaDesde != null
              ? _fechaDesde!.toIso8601String().split('T')[0]
              : null,
          createdHasta: _fechaHasta != null
              ? _fechaHasta!.toIso8601String().split('T')[0]
              : null,
          search: _searchQuery,
          localidadId: _localidadFiltro,
        );
  }

  // ✅ NUEVO: Ejecutar búsqueda manualmente (por Enter o botón)
  Future<void> _ejecutarBusqueda() async {
    setState(() {
      _searchQuery = _searchInput.isEmpty ? null : _searchInput;
    });
    _cargarEntregas();
    debugPrint('🔍 Búsqueda ejecutada: $_searchQuery');
  }

  // ✅ NUEVO: Limpiar campo de búsqueda
  void _limpiarBusqueda() {
    _searchController.clear();
    setState(() {
      _searchInput = '';
      _searchQuery = null;
    });
    _cargarEntregas();
  }

  // ✅ NUEVO: Refrescar entregas con feedback visual
  Future<void> _refrescarEntregas() async {
    if (_isRefreshing) {
      debugPrint('⏳ Ya está recargando...');
      return;
    }

    debugPrint('🔄 [REFRESCAR] Recargar entregas asignadas...');

    if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      _cargarEntregas();
      // Esperar a que se resuelva el futuro
      await _futureEntregas;

      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entregas actualizadas'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error recargando entregas: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Cambiar fecha DESDE del rango
  Future<void> _onCambiarFechaDesde() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _fechaHasta ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaDesde = fecha);
      _cargarEntregas();  // ✅ NUEVO: Recargar entregas después de cambiar fecha
    }
  }

  // ✅ NUEVO: Cambiar fecha HASTA del rango
  Future<void> _onCambiarFechaHasta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? DateTime.now(),
      firstDate: _fechaDesde ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaHasta = fecha);
      _cargarEntregas();  // ✅ NUEVO: Recargar entregas después de cambiar fecha
    }
  }

  void _limpiarFechas() {
    setState(() {
      _fechaDesde = DateTime.now();
      _fechaHasta = DateTime.now();
    });
    _cargarEntregas();  // ✅ NUEVO: Recargar entregas después de limpiar fechas
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Entregas Asignadas'),
        backgroundColor: isDarkMode ? Colors.grey[800] : const Color.fromARGB(255, 84, 79, 79),
        elevation: 1,
        actions: [
          // ✅ NUEVO: Botón para actualizar/recargar la pantalla
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer<EntregaProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: AnimatedRotation(
                    turns: _isRefreshing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(Icons.refresh),
                  ),
                  tooltip: _isRefreshing ? 'Recargando...' : 'Actualizar entregas',
                  onPressed: _isRefreshing ? null : _refrescarEntregas,
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        // ✅ CRÍTICO: Usar _futureEntregas que NO se recrea en cada rebuild
        future: _futureEntregas,
        builder: (context, snapshot) {
          debugPrint(
            '🏗️ [FUTUREBUILDER] connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}',
          );

          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Stack(
              children: [
                Container(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Cargando entregas...',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Por favor espera',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Si hay error o la carga falló
          if (snapshot.hasError || snapshot.data == false) {
            final provider = context.read<EntregaProvider>();
            return _buildErrorContent(provider, isDarkMode);
          }

          // Datos cargados correctamente
          // ✅ Usar Selector para escuchar específicamente cambios en entregas
          return Selector<EntregaProvider, List>(
            selector: (context, provider) => provider.entregas,
            builder: (context, entregas, _) {
              debugPrint(
                '🏗️ [CONSUMER_BUILD] entregas.length=${entregas.length}',
              );
              final provider = context.read<EntregaProvider>();

              return RefreshIndicator(
                onRefresh: () async {
                  debugPrint('🔄 Actualizando entregas...');
                  // ✅ CRÍTICO: Recargar usando el método que actualiza _futureEntregas
                  _cargarEntregas();
                  // Esperar a que se resuelva el futuro
                  await _futureEntregas;
                  debugPrint('✅ Entregas actualizadas');
                },
                child: Column(
                  children: [
                    // ✅ NUEVO: Panel colapsable de filtros
                    Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      child: Column(
                        children: [
                          // Header con icono para expandir/contraer
                          InkWell(
                            onTap: () {
                              setState(() => _mostrarFiltros = !_mostrarFiltros);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.filter_alt,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Filtros',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // ✅ Mostrar cantidad de filtros activos (solo los confirmados)
                                      if (_searchQuery != null ||
                                          _localidadFiltro != null ||
                                          _filtroEstado != null ||
                                          (_fechaDesde != DateTime.now() || _fechaHasta != DateTime.now()))
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[600],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${(_searchQuery != null ? 1 : 0) + (_localidadFiltro != null ? 1 : 0) + (_filtroEstado != null ? 1 : 0) + (_fechaDesde != DateTime.now() || _fechaHasta != DateTime.now() ? 1 : 0)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Icon(
                                    _mostrarFiltros
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Contenido de filtros (expandible)
                          if (_mostrarFiltros)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                spacing: 12,
                                children: [
                                  // ✅ NUEVO: Campo de búsqueda + botón (Row)
                                  Row(
                                    spacing: 8,
                                    children: [
                                      // TextField
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            setState(() => _searchInput = value);
                                          },
                                          onSubmitted: (_) {
                                            _ejecutarBusqueda();
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                '🔍 Buscar (ID, número, cliente, NIT, teléfono)',
                                            prefixIcon: const Icon(Icons.search),
                                            suffixIcon: _searchInput.isNotEmpty
                                                ? GestureDetector(
                                                    onTap: _limpiarBusqueda,
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 20,
                                                      color: Colors.red[400],
                                                    ),
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // ✅ Botón Buscar
                                      Material(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: _ejecutarBusqueda,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            child: const Icon(
                                              Icons.search,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // ✅ NUEVO: Selectores de rango de fechas (Desde y Hasta)
                                  Row(
                                    spacing: 8,
                                    children: [
                                      // Fecha DESDE
                                      Expanded(
                                        child: InkWell(
                                          onTap: _onCambiarFechaDesde,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isDarkMode
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Desde',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '📅 ${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Fecha HASTA
                                      Expanded(
                                        child: InkWell(
                                          onTap: _onCambiarFechaHasta,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isDarkMode
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hasta',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '📅 ${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Botón limpiar fechas
                                      GestureDetector(
                                        onTap: _limpiarFechas,
                                        child: Icon(
                                          Icons.close,
                                          size: 24,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // ✅ NUEVO: Dropdown de localidad (dinámico)
                                  Consumer<EntregaProvider>(
                                    builder: (context, provider, _) {
                                      final localidades =
                                          provider.obtenerLocalidadesUnicas();

                                      return DropdownButton<int?>(
                                        value: _localidadFiltro,
                                        isExpanded: true,
                                        hint: const Text(
                                            '🏘️ Todas las localidades'),
                                        onChanged: (value) {
                                          setState(
                                              () => _localidadFiltro = value);
                                          _cargarEntregas();
                                        },
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                                '🏘️ Todas las localidades'),
                                          ),
                                          ...localidades.map((loc) {
                                            return DropdownMenuItem(
                                              value: loc['id'] as int,
                                              child: Text(
                                                  '📍 ${loc['nombre']} (${loc['codigo'] ?? 'N/A'})'),
                                            );
                                          }).toList(),
                                        ],
                                      );
                                    },
                                  ),
                                  // Dropdown de estado
                                  DropdownButton<String?>(
                                    value: _filtroEstado,
                                    isExpanded: true,
                                    hint: const Text('Todos los estados'),
                                    onChanged: _onCambiarFiltro,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos los estados'),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'PREPARACION_CARGA',
                                        child: Text('📦 Preparación de Carga'),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'LISTO_PARA_ENTREGA',
                                        child: Text('✅ Listo para Entrega'),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'EN_TRANSITO',
                                        child: Text('🚗 En Tránsito'),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'ENTREGADO',
                                        child: Text('✓ Entregado'),
                                      ),
                                    ],
                                  ),
                                  // ✅ NUEVO: Botón para limpiar todos
                                  if (_searchQuery != null ||
                                      _localidadFiltro != null ||
                                      _filtroEstado != null ||
                                      (_fechaDesde != DateTime.now() || _fechaHasta != DateTime.now()))
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = null;
                                          _searchInput = '';
                                          _searchController.clear();
                                          _localidadFiltro = null;
                                          _filtroEstado = null;
                                          _fechaDesde = DateTime.now();
                                          _fechaHasta = DateTime.now();
                                        });
                                        _cargarEntregas();  // ✅ NUEVO: Recargar entregas después de limpiar
                                      },
                                      icon: const Icon(Icons.clear_all),
                                      label: const Text('Limpiar Todos'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[600],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Listado
                    Expanded(
                      child: entregas.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        size: 64,
                                        color: isDarkMode
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay entregas',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _filtroEstado != null
                                            ? 'No hay entregas en estado "$_filtroEstado"'
                                            : 'Las entregas aparecerán aquí cuando se asignen',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: entregas.length,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final entrega = entregas[index];
                                // ✅ CRÍTICO: Key único permite que Flutter reconstruya cuando los datos cambian
                                return EntregaCard(
                                  key: ValueKey('entrega_${entrega.id}_${entrega.estado}'),
                                  entrega: entrega,
                                  isDarkMode: isDarkMode,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorContent(EntregaProvider provider, bool isDarkMode) {
    debugPrint('❌ [BUILD_ERROR] Error cargando entregas');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDarkMode ? Colors.red[400] : Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar entregas',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _filtroEstado = null; // Reiniciar filtro
              });
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
