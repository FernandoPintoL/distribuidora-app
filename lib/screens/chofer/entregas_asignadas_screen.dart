import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_text_styles.dart';
import '../../providers/entrega_provider.dart';
import '../../providers/estado_logistico_provider.dart';
import '../../providers/localidad_provider.dart';
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
  DateTime? _fechaDesde = DateTime.now(); // Por defecto: hoy
  DateTime? _fechaHasta = DateTime.now(); // Por defecto: hoy
  String? _searchQuery; // ✅ NUEVO: búsqueda
  String _searchInput =
      ''; // ✅ NUEVO: input temporal de búsqueda (antes de confirmar)
  int? _localidadFiltro; // ✅ NUEVO: localidad
  bool _mostrarFiltros =
      false; // ✅ NUEVO: control de visibilidad de filtros (inicia OCULTO)
  bool _isRefreshing = false; // ✅ NUEVO: Estado para recarga manual
  final TextEditingController _searchController =
      TextEditingController(); // ✅ NUEVO: controller para el campo
  String? _entregaIdBusqueda; // ✅ NUEVO: búsqueda por ID de entrega
  String? _ventaBusqueda; // ✅ NUEVO: búsqueda por venta (ID o nombre)
  final TextEditingController _entregaIdController =
      TextEditingController(); // ✅ NUEVO: controller para entrega ID
  final TextEditingController _ventaBusquedaController =
      TextEditingController(); // ✅ NUEVO: controller para venta

  // ✅ CRÍTICO: Future estable que NO se recrea en cada rebuild
  Future<bool>? _futureEntregas;

  Future<void> _onCambiarFiltro(String? nuevoEstado) async {
    setState(() => _filtroEstado = nuevoEstado);
  }

  @override
  void initState() {
    super.initState();
    // ✅ Cargar estados logísticos y localidades DESPUÉS del frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EstadoLogisticoProvider>().obtenerEstados('entrega');
        context.read<LocalidadProvider>().obtenerLocalidades();
        // ✅ CRÍTICO: Crear el Future UNA SOLA VEZ en initState TAMBIÉN DESPUÉS del frame
        _cargarEntregas();
      }
    });
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
      entregaId: _entregaIdBusqueda,
      searchVenta: _ventaBusqueda,
    );
  }

  // ✅ NUEVO: Ejecutar búsqueda manualmente (por Enter o botón)
  Future<void> _ejecutarBusqueda() async {
    setState(() {
      _searchQuery = _searchInput.isEmpty ? null : _searchInput;
      _mostrarFiltros = !_mostrarFiltros;
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
    _entregaIdController.dispose();
    _ventaBusquedaController.dispose();
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
    }
  }

  void _limpiarFechas() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FutureBuilder<bool>(
        // ✅ CRÍTICO: Usar _futureEntregas que NO se recrea en cada rebuild
        future: _futureEntregas ?? Future.value(true),
        builder: (context, snapshot) {
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
                          color: Theme.of(context).cardColor,
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
                child: ListView(
                  children: [
                    // ✅ NUEVO: Panel colapsable de filtros (scrolleable)
                    Container(
                      child: Column(
                        children: [
                          // Header con icono para expandir/contraer
                          InkWell(
                            onTap: () {
                              setState(
                                () => _mostrarFiltros = !_mostrarFiltros,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.filter_alt),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Filtros',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // ✅ Mostrar cantidad de filtros activos (solo los confirmados)
                                      if (_searchQuery != null ||
                                          _localidadFiltro != null ||
                                          _filtroEstado != null ||
                                          (_fechaDesde != null ||
                                              _fechaHasta != null) ||
                                          _entregaIdBusqueda != null ||
                                          _ventaBusqueda != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
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
                                              '${(_searchQuery != null ? 1 : 0) + (_localidadFiltro != null ? 1 : 0) + (_filtroEstado != null ? 1 : 0) + (_fechaDesde != null || _fechaHasta != null ? 1 : 0) + (_entregaIdBusqueda != null ? 1 : 0) + (_ventaBusqueda != null ? 1 : 0)}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // ✅ Botón Actualizar + Ícono expand/collapse
                                  Row(
                                    children: [
                                      Consumer<EntregaProvider>(
                                        builder: (context, provider, _) {
                                          return IconButton(
                                            icon: AnimatedRotation(
                                              turns: _isRefreshing ? 1.0 : 0.0,
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              child: const Icon(Icons.refresh),
                                            ),
                                            tooltip: _isRefreshing
                                                ? 'Recargando...'
                                                : 'Actualizar entregas',
                                            onPressed: _isRefreshing
                                                ? null
                                                : _refrescarEntregas,
                                          );
                                        },
                                      ),
                                      Icon(
                                        _mostrarFiltros
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                    ],
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
                                  /*Row(
                                    spacing: 8,
                                    children: [
                                      // TextField
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            setState(
                                              () => _searchInput = value,
                                            );
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                '🔍 Buscar (ID, número, cliente, NIT, teléfono)',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
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
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: _ejecutarBusqueda,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                  ),*/
                                  // ✅ NUEVO: Input para búsqueda por ID de entrega
                                  TextField(
                                    controller: _entregaIdController,
                                    onChanged: (value) {
                                      setState(
                                        () => _entregaIdBusqueda = value.isEmpty
                                            ? null
                                            : value,
                                      );
                                    },
                                    decoration: InputDecoration(
                                      hintText: '🎫 Buscar por ID de Entrega',
                                      prefixIcon: const Icon(Icons.receipt),
                                      suffixIcon:
                                          _entregaIdController.text.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                _entregaIdController.clear();
                                                setState(
                                                  () =>
                                                      _entregaIdBusqueda = null,
                                                );
                                              },
                                              child: Icon(
                                                Icons.close,
                                                size: 20,
                                                color: Colors.red[400],
                                              ),
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                  // ✅ NUEVO: Input para búsqueda de venta (ID o nombre cliente)
                                  TextField(
                                    controller: _ventaBusquedaController,
                                    onChanged: (value) {
                                      setState(
                                        () => _ventaBusqueda = value.isEmpty
                                            ? null
                                            : value,
                                      );
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          '🛍️ Buscar Venta (ID o Nombre Cliente)',
                                      prefixIcon: const Icon(
                                        Icons.shopping_cart,
                                      ),
                                      suffixIcon:
                                          _ventaBusquedaController
                                              .text
                                              .isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                _ventaBusquedaController
                                                    .clear();
                                                setState(
                                                  () => _ventaBusqueda = null,
                                                );
                                              },
                                              child: Icon(
                                                Icons.close,
                                                size: 20,
                                                color: Colors.red[400],
                                              ),
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                    ),
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
                                              vertical: 4,
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
                                                Text('Desde'),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _fechaDesde != null
                                                      ? '📅 ${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                                                      : 'Todas las fechas',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                              vertical: 4,
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
                                                Text('Hasta'),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _fechaHasta != null
                                                      ? '📅 ${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                                                      : 'Todas las fechas',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                  Consumer<LocalidadProvider>(
                                    builder: (context, localidadProvider, _) {
                                      return DropdownButton<int?>(
                                        value: _localidadFiltro,
                                        isExpanded: true,
                                        hint: const Text(
                                          '🏘️ Todas las localidades',
                                        ),
                                        onChanged: (value) {
                                          setState(
                                            () => _localidadFiltro = value,
                                          );
                                        },
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                              '🏘️ Todas las localidades',
                                            ),
                                          ),
                                          ...localidadProvider.localidades.map((
                                            loc,
                                          ) {
                                            return DropdownMenuItem(
                                              value: loc.id,
                                              child: Text(
                                                '📍 ${loc.nombre} (${loc.codigo})',
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  ),
                                  // Dropdown de estado (dinámico)
                                  Consumer<EstadoLogisticoProvider>(
                                    builder: (context, estadoProvider, _) {
                                      // ✅ NUEVO: Obtener estados de ENTREGAS del caché centralizado
                                      final estados = estadoProvider
                                          .obtenerEstadosPorCategoria(
                                            'entrega',
                                          );
                                      return DropdownButton<String?>(
                                        value: _filtroEstado,
                                        isExpanded: true,
                                        hint: const Text('Todos los estados'),
                                        onChanged: _onCambiarFiltro,
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text('Todos los estados'),
                                          ),
                                          ...estados.map((estado) {
                                            return DropdownMenuItem(
                                              value: estado.codigo,
                                              child: Text(
                                                '${estado.icono} ${estado.nombre}',
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  ),
                                  // ✅ Botón Limpiar Todos
                                  // ✅ Botones de búsqueda y limpiar
                                  Row(
                                    spacing: 8,
                                    children: [
                                      // Botón Buscar
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _ejecutarBusqueda,
                                          icon: const Icon(Icons.search),
                                          label: const Text('Buscar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // Botón Limpiar Todos
                                      if (_searchQuery != null ||
                                          _localidadFiltro != null ||
                                          _filtroEstado != null ||
                                          (_fechaDesde != null ||
                                              _fechaHasta != null) ||
                                          _entregaIdBusqueda != null ||
                                          _ventaBusqueda != null)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = null;
                                                _searchInput = '';
                                                _searchController.clear();
                                                _localidadFiltro = null;
                                                _filtroEstado = null;
                                                _fechaDesde = null;
                                                _fechaHasta = null;
                                                _entregaIdBusqueda = null;
                                                _ventaBusqueda = null;
                                                _entregaIdController.clear();
                                                _ventaBusquedaController
                                                    .clear();
                                              });
                                              _cargarEntregas();
                                            },
                                            icon: const Icon(Icons.clear_all),
                                            label: const Text('Limpiar Todos'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange[600],
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ✅ NUEVO 2026-03-12: Panel de estadísticas (cantidad de entregas y ventas)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Tarjeta de entregas
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.blue[900]
                                    : Colors.blue[50],
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.blue[700]!
                                      : Colors.blue[200]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entregas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entregas.length}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.blue[100]
                                          : Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tarjeta de ventas totales
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.green[900]
                                    : Colors.green[50],
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.green[700]!
                                      : Colors.green[200]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ventas Totales',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode
                                          ? Colors.green[300]
                                          : Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entregas.fold<int>(0, (sum, e) => sum + ((e.ventas?.length ?? 0) as int))}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.green[100]
                                          : Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entregas.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No hay entregas',
                                style: TextStyle(
                                  fontSize: AppTextStyles.headlineSmall(
                                    context,
                                  ).fontSize!,
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
                    if (entregas.isNotEmpty)
                      ...entregas.map((entrega) {
                        return EntregaCard(
                          key: ValueKey(
                            'entrega_${entrega.id}_${entrega.estado}',
                          ),
                          entrega: entrega,
                          isDarkMode: isDarkMode,
                        );
                      }),
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
              fontSize: AppTextStyles.bodyLarge(context).fontSize!,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
