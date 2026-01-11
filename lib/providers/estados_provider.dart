import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/estados_helpers.dart';

/// Provider para gestionar estados de proformas dinámicamente
///
/// Carga los estados desde el backend y mantiene contadores actualizados
class EstadosProvider with ChangeNotifier {
  final ProformaService _proformaService = ProformaService();

  // Estado
  List<Estado> _estados = [];
  ProformaStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Estado> get estados => _estados;
  ProformaStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtener el contador de un estado específico
  int getContadorEstado(String codigo) {
    if (_stats == null) return 0;

    switch (codigo.toUpperCase()) {
      case 'PENDIENTE':
        return _stats!.porEstado.pendiente;
      case 'APROBADA':
        return _stats!.porEstado.aprobada;
      case 'RECHAZADA':
        return _stats!.porEstado.rechazada;
      case 'CONVERTIDA':
        return _stats!.porEstado.convertida;
      case 'VENCIDA':
        return _stats!.porEstado.vencida;
      default:
        return 0;
    }
  }

  /// Obtener el monto de un estado específico
  double getMontoEstado(String codigo) {
    if (_stats == null) return 0;

    switch (codigo.toUpperCase()) {
      case 'PENDIENTE':
        return _stats!.montosPorEstado.pendiente;
      case 'APROBADA':
        return _stats!.montosPorEstado.aprobada;
      case 'RECHAZADA':
        return _stats!.montosPorEstado.rechazada;
      case 'CONVERTIDA':
        return _stats!.montosPorEstado.convertida;
      case 'VENCIDA':
        return _stats!.montosPorEstado.vencida;
      default:
        return 0;
    }
  }

  /// Obtener estado por código
  Estado? getEstado(String codigo) {
    try {
      return EstadosHelper.getEstadoPorCodigo('proforma', codigo);
    } catch (e) {
      return null;
    }
  }

  /// Cargar estados y estadísticas dinámicamente
  Future<void> loadEstadosYEstadisticas({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar estadísticas que incluye contador por estado
      final statsResponse = await _proformaService.getStats();

      if (statsResponse.success && statsResponse.data != null) {
        _stats = statsResponse.data;

        // Obtener los estados activos desde EstadosHelper
        _estados = EstadosHelper.getEstadosActivos('proforma');

        debugPrint('✅ Estados cargados: ${_estados.length}');
        debugPrint('✅ Estadísticas cargadas: Total=${_stats!.total}');
        _errorMessage = null;
      } else {
        _errorMessage = statsResponse.message ?? 'Error al cargar estados';
        _stats = null;
        _estados = [];
        debugPrint('❌ Error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _stats = null;
      _estados = [];
      debugPrint('❌ Error loading estados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refrescar solo las estadísticas (más rápido que recargar todo)
  Future<void> refreshEstadisticas() async {
    try {
      final statsResponse = await _proformaService.getStats();

      if (statsResponse.success && statsResponse.data != null) {
        _stats = statsResponse.data;
        debugPrint('✅ Estadísticas actualizadas');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing stats: $e');
    }
  }
}
