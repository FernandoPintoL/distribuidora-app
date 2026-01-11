import 'package:flutter/foundation.dart';
import '../models/estado.dart';
import '../services/estados_helpers.dart';

/// Provider para gestionar estados de entregas dinámicamente
///
/// Carga los estados desde el backend a través de EstadosHelper
/// que maneja caché y fallbacks automáticamente
class EntregaEstadosProvider with ChangeNotifier {
  List<Estado> _estadosFiltro = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Estado> get estadosFiltro => _estadosFiltro;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene solo los estados activos y disponibles para filtrado
  List<Estado> getEstadosParaFiltrado() {
    return _estadosFiltro.where((e) => e.activo).toList();
  }

  /// Obtiene el nombre (label) de un estado por código
  String getEstadoNombre(String codigo) {
    try {
      final estado = _estadosFiltro.firstWhere((e) => e.codigo == codigo);
      return estado.nombre;
    } catch (e) {
      return EstadosHelper.getEstadoLabel('entrega', codigo);
    }
  }

  /// Obtiene el color de un estado por código
  String getEstadoColor(String codigo) {
    try {
      final estado = _estadosFiltro.firstWhere((e) => e.codigo == codigo);
      return estado.color;
    } catch (e) {
      return EstadosHelper.getEstadoColor('entrega', codigo);
    }
  }

  /// Obtiene el ícono de un estado por código
  String getEstadoIcon(String codigo) {
    try {
      final estado = _estadosFiltro.firstWhere((e) => e.codigo == codigo);
      return estado.icono ?? '❓';
    } catch (e) {
      return EstadosHelper.getEstadoIcon('entrega', codigo);
    }
  }

  /// Cargar estados de entrega desde el backend
  /// Usa EstadosHelper que maneja caché y fallbacks
  Future<void> cargarEstados({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtener estados activos desde EstadosHelper
      // Esto usa el caché si está disponible, sino carga fallback
      _estadosFiltro = EstadosHelper.getEstadosActivos('entrega');

      if (_estadosFiltro.isEmpty) {
        _errorMessage = 'No hay estados disponibles';
        debugPrint('⚠️ No hay estados disponibles para entregas');
      } else {
        // Ordenar por orden
        _estadosFiltro.sort((a, b) => a.orden.compareTo(b.orden));
        debugPrint('✅ Estados de entrega cargados: ${_estadosFiltro.length}');
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar estados: ${e.toString()}';
      debugPrint('❌ Error cargando estados de entrega: $e');
      // Fallback a lista vacía (EstadosHelper usará sus defaults)
      _estadosFiltro = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene un estado específico por código
  Estado? getEstadoPorCodigo(String codigo) {
    try {
      return _estadosFiltro.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }
}
