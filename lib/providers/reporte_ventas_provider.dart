import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class ReporteVentasProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado del reporte
  List<dynamic> _productos = [];
  List<dynamic> _ventas = [];
  Map<String, dynamic> _totales = {
    'cantidad_productos': 0,
    'cantidad_total_vendida': 0.0,
    'total_venta_general': 0.0,
    'precio_promedio_general': 0.0,
  };

  bool _isLoading = false;
  bool _isDownloadingPdf = false;
  String? _errorMessage;

  // Filtros
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  int? _filtroUsuarioCreadorId;
  int? _filtroClienteId;

  // Getters
  List<dynamic> get productos => _productos;
  List<dynamic> get ventas => _ventas;
  Map<String, dynamic> get totales => _totales;
  bool get isLoading => _isLoading;
  bool get isDownloadingPdf => _isDownloadingPdf;
  String? get errorMessage => _errorMessage;

  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;
  int? get filtroUsuarioCreadorId => _filtroUsuarioCreadorId;
  int? get filtroClienteId => _filtroClienteId;

  /// Cargar reporte de productos vendidos
  Future<void> loadReporte({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? usuarioCreadorId,
    int? clienteId,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroUsuarioCreadorId = usuarioCreadorId;
    _filtroClienteId = clienteId;

    try {
      final data = await _apiService.getReporteProductosVendidos(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        usuarioCreadorId: usuarioCreadorId,
        clienteId: clienteId,
      );

      if (data['success'] == true) {
        _productos = data['productos'] as List<dynamic>? ?? [];
        _ventas = data['ventas'] as List<dynamic>? ?? [];
        _totales = data['totales'] as Map<String, dynamic>? ?? {};
        _errorMessage = null;
      } else {
        _errorMessage = data['error'] ?? 'Error desconocido';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar reporte: $e';
      debugPrint('❌ Error en loadReporte: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Descargar PDF del reporte
  Future<List<int>?> descargarPdfReporte() async {
    if (_isDownloadingPdf) return null;

    _isDownloadingPdf = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pdfBytes = await _apiService.descargarReporteProductosVendidosPdf(
        fechaDesde: _filtroFechaDesde,
        fechaHasta: _filtroFechaHasta,
        usuarioCreadorId: _filtroUsuarioCreadorId,
        clienteId: _filtroClienteId,
      );

      _errorMessage = null;
      return pdfBytes;
    } catch (e) {
      _errorMessage = 'Error al descargar PDF: $e';
      debugPrint('❌ Error descargando PDF: $e');
      return null;
    } finally {
      _isDownloadingPdf = false;
      notifyListeners();
    }
  }

  /// Limpiar filtros y reporte
  void clearFiltros() {
    _filtroFechaDesde = null;
    _filtroFechaHasta = null;
    _filtroUsuarioCreadorId = null;
    _filtroClienteId = null;
    _productos = [];
    _ventas = [];
    _totales = {
      'cantidad_productos': 0,
      'cantidad_total_vendida': 0.0,
      'total_venta_general': 0.0,
      'precio_promedio_general': 0.0,
    };
    _errorMessage = null;
    notifyListeners();
  }

  /// Establecer fechas predeterminadas (últimos 30 días)
  void setFechasDefault() {
    final ahora = DateTime.now();
    _filtroFechaHasta = ahora;
    _filtroFechaDesde = ahora.subtract(const Duration(days: 30));
    notifyListeners();
  }
}
