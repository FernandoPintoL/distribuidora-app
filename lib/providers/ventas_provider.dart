import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider para gestionar lista de ventas del cliente
class VentasProvider with ChangeNotifier {
  final VentaService _ventaService = VentaService();

  // Estado
  List<Venta> _ventas = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Paginación
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalItems = 0;
  final int _perPage = 20; // ✅ MODIFICADO: 20 registros por página para mejor UX

  // Filtros
  String? _filtroEstado;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String? _filtroBusqueda;

  // Getters
  List<Venta> get ventas => _ventas;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get totalItems => _totalItems;
  String? get filtroEstado => _filtroEstado;
  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;
  String? get filtroBusqueda => _filtroBusqueda;

  // ✅ NUEVO: Estado para detalle de venta
  Venta? _ventaDetalle;
  bool _isLoadingDetalle = false;

  // Getters para detalle de venta
  Venta? get ventaDetalle => _ventaDetalle;
  bool get isLoadingDetalle => _isLoadingDetalle;

  /// Cargar detalles de una venta específica
  Future<void> loadVentaDetalle(int ventaId) async {
    _isLoadingDetalle = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final response = await _ventaService.getVenta(ventaId);

      if (response.success && response.data != null) {
        _ventaDetalle = response.data;
        _isLoadingDetalle = false;
        _errorMessage = null;

        debugPrint('✅ Detalle de venta cargado: ${_ventaDetalle?.numero}');
      } else {
        _isLoadingDetalle = false;
        _errorMessage = response.message;
        debugPrint('❌ Error: ${response.message}');
      }
    } catch (e) {
      _isLoadingDetalle = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('Error loading venta detail: $e');
    } finally {
      Future.microtask(() => notifyListeners());
    }
  }

  /// Cargar lista de ventas (página 1)
  Future<void> loadVentas({
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _filtroEstado = estado;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroBusqueda = busqueda;

    if (!refresh) {
      Future.microtask(() => notifyListeners());
    }

    try {
      final response = await _ventaService.getVentas(
        page: _currentPage,
        perPage: _perPage,
        estado: estado,
        busqueda: busqueda,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      if (response.success && response.data != null) {
        final dataList = response.data!['data'] as List<dynamic>;
        _ventas = dataList.cast<Venta>();
        _hasMorePages = response.data!['has_more_pages'] ?? false;
        _totalItems = response.data!['total'] ?? 0;
        _errorMessage = null;

        debugPrint('✅ Ventas cargadas: ${_ventas.length} items');
      } else {
        _errorMessage = response.message;
        _ventas = [];
        debugPrint('❌ Error: ${response.message}');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _ventas = [];
      debugPrint('Error loading ventas: $e');
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Cargar más ventas (siguiente página)
  Future<void> loadMoreVentas() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    _isLoadingMore = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final nextPage = _currentPage + 1;

      final response = await _ventaService.getVentas(
        page: nextPage,
        perPage: _perPage,
        estado: _filtroEstado,
        busqueda: _filtroBusqueda,
        fechaDesde: _filtroFechaDesde,
        fechaHasta: _filtroFechaHasta,
      );

      if (response.success && response.data != null) {
        final dataList = response.data!['data'] as List<dynamic>;
        final nuevasVentas = dataList.cast<Venta>();

        _ventas.addAll(nuevasVentas);
        _hasMorePages = response.data!['has_more_pages'] ?? false;
        _currentPage = nextPage;
        _errorMessage = null;

        debugPrint('✅ Cargadas ${nuevasVentas.length} ventas más');
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('Error loading more ventas: $e');
    } finally {
      _isLoadingMore = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Aplicar filtro de estado
  Future<void> aplicarFiltroEstado(String? estadoCodigo) async {
    await loadVentas(
      estado: estadoCodigo,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: _filtroBusqueda,
    );
  }

  /// Aplicar filtro de fechas
  Future<void> aplicarFiltroFechas(DateTime? desde, DateTime? hasta) async {
    await loadVentas(
      estado: _filtroEstado,
      fechaDesde: desde,
      fechaHasta: hasta,
      busqueda: _filtroBusqueda,
    );
  }

  /// Aplicar búsqueda
  Future<void> aplicarBusqueda(String? busqueda) async {
    await loadVentas(
      estado: _filtroEstado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: busqueda,
    );
  }

  /// Limpiar filtros
  Future<void> limpiarFiltros() async {
    await loadVentas();
  }

  /// Filtrar ventas localmente por estado de pago
  List<Venta> getVentasPorEstado(String estadoPago) {
    return _ventas
        .where((v) => v.estadoPago.toUpperCase() == estadoPago.toUpperCase())
        .toList();
  }

  /// Obtener ventas pagadas
  List<Venta> get ventasPagadas => getVentasPorEstado('PAGADO');

  /// Obtener ventas con pago parcial
  List<Venta> get ventasParciales => getVentasPorEstado('PARCIAL');

  /// Obtener ventas pendientes de pago
  List<Venta> get ventasPendientes => getVentasPorEstado('PENDIENTE');

  /// Limpiar errores
  void limpiarErrores() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }

  /// Resetear provider
  void reset() {
    _ventas = [];
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = true;
    _totalItems = 0;
    _filtroEstado = null;
    _filtroFechaDesde = null;
    _filtroFechaHasta = null;
    _filtroBusqueda = null;
    Future.microtask(() => notifyListeners());
  }
}
