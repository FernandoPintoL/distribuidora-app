import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider para gestionar lista de cuentas por cobrar
class CuentasPorCobrarProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado
  List<CuentaPorCobrar> _cuentas = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Paginación
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalItems = 0;
  final int _perPage = 20;

  // Filtros
  String? _filtroEstado;
  int? _filtroClienteId;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String? _filtroBusqueda;
  bool _filtroSoloVencidas = false;

  // Estadísticas
  Map<String, dynamic>? _estadisticas;

  // Getters
  List<CuentaPorCobrar> get cuentas => _cuentas;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get totalItems => _totalItems;
  String? get filtroEstado => _filtroEstado;
  int? get filtroClienteId => _filtroClienteId;
  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;
  String? get filtroBusqueda => _filtroBusqueda;
  bool get filtroSoloVencidas => _filtroSoloVencidas;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  // Getters para estadísticas
  int get totalCuentas => _estadisticas?['total'] as int? ?? 0;
  int get cuentasPendientes => _estadisticas?['pendientes'] as int? ?? 0;
  double get montoTotalPendiente => (_estadisticas?['monto_total_pendiente'] as num?)?.toDouble() ?? 0.0;
  int get cuentasVencidas => _estadisticas?['cuentas_vencidas'] as int? ?? 0;
  double get montoTotalVencido => (_estadisticas?['monto_total_vencido'] as num?)?.toDouble() ?? 0.0;

  /// Cargar lista de cuentas (página 1)
  Future<void> loadCuentas({
    String? estado,
    int? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
    bool soloVencidas = false,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _filtroEstado = estado;
    _filtroClienteId = clienteId;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroBusqueda = busqueda;
    _filtroSoloVencidas = soloVencidas;

    if (!refresh) {
      Future.microtask(() => notifyListeners());
    }

    try {
      final params = <String, dynamic>{
        'per_page': _perPage,
        'page': _currentPage,
        if (estado != null) 'estado': estado,
        if (clienteId != null) 'cliente_id': clienteId,
        if (busqueda != null) 'q': busqueda,
        if (fechaDesde != null) 'fecha_desde': fechaDesde.toString().split(' ')[0],
        if (fechaHasta != null) 'fecha_hasta': fechaHasta.toString().split(' ')[0],
        if (soloVencidas) 'solo_vencidas': 'true',
      };

      final response = await _apiService.get('/cuentas-por-cobrar', queryParameters: params);

      if (response.statusCode == 200 && response.data != null) {
        final responseBody = response.data as Map<String, dynamic>;

        if (responseBody['success'] == true && responseBody['data'] != null) {
          final dataList = responseBody['data'] as List<dynamic>;
          _cuentas = dataList.map((item) => CuentaPorCobrar.fromJson(item as Map<String, dynamic>)).toList();

          // Parsear estadísticas
          if (responseBody['estadisticas'] != null) {
            _estadisticas = responseBody['estadisticas'] as Map<String, dynamic>;
          }

          // Parsear paginación
          if (responseBody['pagination'] != null) {
            final pag = responseBody['pagination'] as Map<String, dynamic>;
            _hasMorePages = pag['has_more_pages'] as bool? ?? false;
            _totalItems = pag['total'] as int? ?? 0;
          }

          _errorMessage = null;
          debugPrint('✅ Cuentas por cobrar cargadas: ${_cuentas.length} items');
        } else {
          _errorMessage = responseBody['message'] as String?;
          _cuentas = [];
          debugPrint('❌ Error: ${responseBody['message']}');
        }
      } else {
        _errorMessage = 'Error en la solicitud: ${response.statusCode}';
        _cuentas = [];
        debugPrint('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _cuentas = [];
      debugPrint('Error loading cuentas: $e');
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Cargar más cuentas (siguiente página)
  Future<void> loadMoreCuentas() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    _isLoadingMore = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final nextPage = _currentPage + 1;

      final params = <String, dynamic>{
        'per_page': _perPage,
        'page': nextPage,
        if (_filtroEstado != null) 'estado': _filtroEstado,
        if (_filtroClienteId != null) 'cliente_id': _filtroClienteId,
        if (_filtroBusqueda != null) 'q': _filtroBusqueda,
        if (_filtroFechaDesde != null) 'fecha_desde': _filtroFechaDesde.toString().split(' ')[0],
        if (_filtroFechaHasta != null) 'fecha_hasta': _filtroFechaHasta.toString().split(' ')[0],
        if (_filtroSoloVencidas) 'solo_vencidas': 'true',
      };

      final response = await _apiService.get('/cuentas-por-cobrar', queryParameters: params);

      if (response.statusCode == 200 && response.data != null) {
        final responseBody = response.data as Map<String, dynamic>;

        if (responseBody['success'] == true && responseBody['data'] != null) {
          final dataList = responseBody['data'] as List<dynamic>;
          final nuevasCuentas = dataList.map((item) => CuentaPorCobrar.fromJson(item as Map<String, dynamic>)).toList();

          _cuentas.addAll(nuevasCuentas);

          // Actualizar paginación
          if (responseBody['pagination'] != null) {
            final pag = responseBody['pagination'] as Map<String, dynamic>;
            _hasMorePages = pag['has_more_pages'] as bool? ?? false;
            _currentPage = nextPage;
          }

          _errorMessage = null;
          debugPrint('✅ Cargadas ${nuevasCuentas.length} cuentas más');
        } else {
          _errorMessage = responseBody['message'] as String?;
        }
      } else {
        _errorMessage = 'Error en la solicitud: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('Error loading more cuentas: $e');
    } finally {
      _isLoadingMore = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Aplicar filtro de estado
  Future<void> aplicarFiltroEstado(String? estadoCodigo) async {
    await loadCuentas(
      estado: estadoCodigo,
      clienteId: _filtroClienteId,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: _filtroBusqueda,
      soloVencidas: _filtroSoloVencidas,
    );
  }

  /// Aplicar filtro de fechas
  Future<void> aplicarFiltroFechas(DateTime? desde, DateTime? hasta) async {
    await loadCuentas(
      estado: _filtroEstado,
      clienteId: _filtroClienteId,
      fechaDesde: desde,
      fechaHasta: hasta,
      busqueda: _filtroBusqueda,
      soloVencidas: _filtroSoloVencidas,
    );
  }

  /// Aplicar búsqueda
  Future<void> aplicarBusqueda(String? busqueda) async {
    await loadCuentas(
      estado: _filtroEstado,
      clienteId: _filtroClienteId,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: busqueda,
      soloVencidas: _filtroSoloVencidas,
    );
  }

  /// Filtrar solo vencidas
  Future<void> aplicarFiltroVencidas(bool soloVencidas) async {
    await loadCuentas(
      estado: _filtroEstado,
      clienteId: _filtroClienteId,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: _filtroBusqueda,
      soloVencidas: soloVencidas,
    );
  }

  /// Limpiar filtros
  Future<void> limpiarFiltros() async {
    await loadCuentas();
  }

  /// Limpiar errores
  void limpiarErrores() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }

  /// Resetear provider
  void reset() {
    _cuentas = [];
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = true;
    _totalItems = 0;
    _filtroEstado = null;
    _filtroClienteId = null;
    _filtroFechaDesde = null;
    _filtroFechaHasta = null;
    _filtroBusqueda = null;
    _filtroSoloVencidas = false;
    _estadisticas = null;
    Future.microtask(() => notifyListeners());
  }
}
