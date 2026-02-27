import 'package:flutter/foundation.dart';
import '../models/reporte_producto_danado.dart';
import '../services/reporte_producto_danado_service.dart';

class ReporteProductoDanadoProvider with ChangeNotifier {
  final ReporteProductoDanadoService _service = ReporteProductoDanadoService();

  // Estado
  List<ReporteProductoDanado> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  ReporteProductoDanado? _reporteSeleccionado;

  // Filtros
  String? _estadoFiltro;
  int? _clienteIdFiltro;
  int? _ventaIdFiltro;

  // Getters
  List<ReporteProductoDanado> get reportes => _reportes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  ReporteProductoDanado? get reporteSeleccionado => _reporteSeleccionado;

  String? get estadoFiltro => _estadoFiltro;
  int? get clienteIdFiltro => _clienteIdFiltro;
  int? get ventaIdFiltro => _ventaIdFiltro;

  /// Cargar reportes con filtros y paginacion
  Future<void> cargarReportes({
    String? estado,
    int? clienteId,
    int? ventaId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _reportes.clear();
      _estadoFiltro = estado;
      _clienteIdFiltro = clienteId;
      _ventaIdFiltro = ventaId;
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.obtenerReportes(
        estado: _estadoFiltro ?? estado,
        clienteId: _clienteIdFiltro ?? clienteId,
        ventaId: _ventaIdFiltro ?? ventaId,
        page: _currentPage,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final reportesData = response.data!['data'] as List;
        final nuevoReportes = reportesData
            .map((r) => ReporteProductoDanado.fromJson(r))
            .toList();

        if (refresh) {
          _reportes = nuevoReportes;
        } else {
          _reportes.addAll(nuevoReportes);
        }

        final currentPageNum = response.data!['current_page'] ?? 1;
        final lastPageNum = response.data!['last_page'] ?? 1;
        _currentPage = currentPageNum + 1;
        _hasMorePages = currentPageNum < lastPageNum;
      } else {
        _errorMessage = response.message ?? 'Error al cargar reportes';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('Error al cargar reportes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener detalles de un reporte especifico
  Future<bool> cargarReporte(int reporteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.obtenerReporte(reporteId);

      if (response.success && response.data != null) {
        _reporteSeleccionado = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al cargar reporte';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al cargar reporte: $e');
      return false;
    }
  }

  /// Crear un nuevo reporte
  Future<bool> crearReporte({
    required int ventaId,
    required String observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.crearReporte(
        ventaId: ventaId,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        _reportes.insert(0, response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al crear reporte';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al crear reporte: $e');
      return false;
    }
  }

  /// Actualizar estado de un reporte
  Future<bool> actualizarReporte({
    required int reporteId,
    required String estado,
    String? notasRespuesta,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.actualizarReporte(
        reporteId: reporteId,
        estado: estado,
        notasRespuesta: notasRespuesta,
      );

      if (response.success && response.data != null) {
        final index = _reportes.indexWhere((r) => r.id == reporteId);
        if (index != -1) {
          _reportes[index] = response.data!;
        }
        if (_reporteSeleccionado?.id == reporteId) {
          _reporteSeleccionado = response.data;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al actualizar reporte';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al actualizar reporte: $e');
      return false;
    }
  }

  /// Subir imagen para un reporte
  Future<bool> subirImagen({
    required int reporteId,
    required String rutaArchivo,
    String? descripcion,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.subirImagen(
        reporteId: reporteId,
        rutaArchivo: rutaArchivo,
        descripcion: descripcion,
      );

      if (response.success) {
        // Recargar el reporte para obtener las imagenes actualizadas
        await cargarReporte(reporteId);
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al subir imagen';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al subir imagen: $e');
      return false;
    }
  }

  /// Eliminar una imagen
  Future<bool> eliminarImagen(int imagenId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.eliminarImagen(imagenId);

      if (response.success) {
        if (_reporteSeleccionado != null) {
          _reporteSeleccionado!.imagenes
              .removeWhere((img) => img.id == imagenId);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al eliminar imagen';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Eliminar un reporte
  Future<bool> eliminarReporte(int reporteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.eliminarReporte(reporteId);

      if (response.success) {
        _reportes.removeWhere((r) => r.id == reporteId);
        if (_reporteSeleccionado?.id == reporteId) {
          _reporteSeleccionado = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al eliminar reporte';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al eliminar reporte: $e');
      return false;
    }
  }

  /// Obtener reportes de una venta
  Future<List<ReporteProductoDanado>> obtenerReportesPorVenta(int ventaId) async {
    try {
      final response = await _service.obtenerReportesPorVenta(ventaId);
      return response.data ?? [];
    } catch (e) {
      debugPrint('Error al obtener reportes por venta: $e');
      return [];
    }
  }

  /// Limpiar error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar seleccion
  void limpiarSeleccion() {
    _reporteSeleccionado = null;
    notifyListeners();
  }

  /// Limpiar filtros
  void limpiarFiltros() {
    _estadoFiltro = null;
    _clienteIdFiltro = null;
    _ventaIdFiltro = null;
    notifyListeners();
  }
}
