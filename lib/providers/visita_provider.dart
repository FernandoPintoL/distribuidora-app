import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/visita_service.dart';

class VisitaProvider with ChangeNotifier {
  final VisitaService _visitaService = VisitaService();

  List<VisitaPreventistaCliente> _visitas = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  Map<String, dynamic>? _estadisticas;

  // Getters
  List<VisitaPreventistaCliente> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  /// Registrar nueva visita
  Future<bool> registrarVisita({
    required int clienteId,
    required DateTime fechaHoraVisita,
    required TipoVisitaPreventista tipoVisita,
    required EstadoVisitaPreventista estadoVisita,
    MotivoNoAtencionVisita? motivoNoAtencion,
    required double latitud,
    required double longitud,
    File? fotoLocal,
    String? observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _visitaService.registrarVisita(
        clienteId: clienteId,
        fechaHoraVisita: fechaHoraVisita,
        tipoVisita: tipoVisita,
        estadoVisita: estadoVisita,
        motivoNoAtencion: motivoNoAtencion,
        latitud: latitud,
        longitud: longitud,
        fotoLocal: fotoLocal,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        // Agregar al inicio de la lista
        _visitas.insert(0, response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al registrar visita';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cargar visitas (con paginación)
  Future<void> cargarVisitas({
    bool refresh = false,
    String? fechaInicio,
    String? fechaFin,
    EstadoVisitaPreventista? estadoVisita,
    TipoVisitaPreventista? tipoVisita,
    int? clienteId,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _visitas.clear();
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _visitaService.obtenerMisVisitas(
        page: _currentPage,
        perPage: 20,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estadoVisita: estadoVisita,
        tipoVisita: tipoVisita,
        clienteId: clienteId,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          _visitas = response.data!.data;
        } else {
          _visitas.addAll(response.data!.data);
        }

        final currentPage = response.data!.currentPage ?? 1;
        final lastPage = response.data!.lastPage ?? 1;
        _currentPage = currentPage + 1;
        _hasMorePages = currentPage < lastPage;
      } else {
        _errorMessage = response.message ?? 'Error al cargar visitas';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar estadísticas
  Future<void> cargarEstadisticas({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await _visitaService.obtenerEstadisticas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (response.success && response.data != null) {
        _estadisticas = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
    }
  }

  /// Validar horario de cliente
  Future<Map<String, dynamic>?> validarHorarioCliente(int clienteId) async {
    try {
      final response = await _visitaService.validarHorario(clienteId);

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error al validar horario: $e');
      return null;
    }
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
