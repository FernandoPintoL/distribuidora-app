import 'package:flutter/foundation.dart';
import '../models/estado_logistico.dart';
import '../services/estado_logistico_service.dart';

class EstadoLogisticoProvider extends ChangeNotifier {
  final EstadoLogisticoService _estadoService = EstadoLogisticoService();

  // ✅ NUEVO: Cachear estados por categoría para evitar múltiples requests
  final Map<String, List<EstadoLogistico>> _estadosPorCategoria = {};
  final Set<String> _categoriascargadas = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtener estados por categoría (con caché)
  Future<bool> obtenerEstados(String categoria) async {
    // ✅ Si ya está cacheado, no hacer request nuevamente
    if (_categoriascargadas.contains(categoria)) {
      debugPrint('📦 [ESTADO_PROVIDER] Estados de "$categoria" obtenidos del caché');
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    debugPrint('🔍 [ESTADO_PROVIDER] Cargando estados de categoría: $categoria');
    notifyListeners();

    try {
      final response = await _estadoService.obtenerEstadosPorCategoria(categoria);

      if (response.success && response.data != null) {
        _estadosPorCategoria[categoria] = response.data!;
        _categoriascargadas.add(categoria);
        debugPrint('✅ [ESTADO_PROVIDER] Estados de "$categoria" cargados: ${response.data!.length}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error desconocido';
        debugPrint('❌ [ESTADO_PROVIDER] Error: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ [ESTADO_PROVIDER] Excepción: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cargar múltiples categorías de una vez (útil en app startup)
  Future<bool> obtenerTodosLosEstados() async {
    const categorias = ['entrega', 'venta_logistica', 'proforma'];
    bool todoOk = true;

    for (final categoria in categorias) {
      final ok = await obtenerEstados(categoria);
      if (!ok) todoOk = false;
    }

    return todoOk;
  }

  /// Obtener todos los estados de una categoría
  List<EstadoLogistico> obtenerEstadosPorCategoria(String categoria) {
    return _estadosPorCategoria[categoria] ?? [];
  }

  /// ✅ NUEVO: Obtener un estado específico por código (búsqueda rápida)
  EstadoLogistico? obtenerEstadoPorCodigo(String categoria, String codigo) {
    final estados = _estadosPorCategoria[categoria] ?? [];
    try {
      return estados.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      debugPrint('⚠️ [ESTADO_PROVIDER] Estado "$codigo" no encontrado en "$categoria"');
      return null;
    }
  }

  /// ✅ NUEVO: Obtener estado por ID
  EstadoLogistico? obtenerEstadoPorId(String categoria, int id) {
    final estados = _estadosPorCategoria[categoria] ?? [];
    try {
      return estados.firstWhere((e) => e.id == id);
    } catch (e) {
      debugPrint('⚠️ [ESTADO_PROVIDER] Estado con ID $id no encontrado en "$categoria"');
      return null;
    }
  }

  /// Verificar si una categoría ya está cacheada
  bool estaCacheado(String categoria) => _categoriascargadas.contains(categoria);

  /// Limpiar caché si es necesario (útil para refresh manual)
  void limpiarCache([String? categoria]) {
    if (categoria != null) {
      _estadosPorCategoria.remove(categoria);
      _categoriascargadas.remove(categoria);
      debugPrint('🗑️ [ESTADO_PROVIDER] Caché de "$categoria" eliminado');
    } else {
      _estadosPorCategoria.clear();
      _categoriascargadas.clear();
      debugPrint('🗑️ [ESTADO_PROVIDER] Caché completo eliminado');
    }
    notifyListeners();
  }

  /// ✅ NUEVO: Método helper para comparar estados sin hardcodear
  /// Ejemplo: esEstadoVenta('EN_TRANSITO') → valida contra el código del estado
  bool esEstado(String categoria, String? codigo, String codigoComparar) {
    if (codigo == null) return false;
    return codigo == codigoComparar;
  }

  /// ✅ NUEVO: Validar si un estado es de cierta tipo (FINAL, PENDIENTE, etc)
  bool esEstadoFinal(String categoria, String? codigoOId) {
    if (codigoOId == null) return false;
    final estado = obtenerEstadoPorCodigo(categoria, codigoOId) ??
        obtenerEstadoPorId(categoria, int.tryParse(codigoOId) ?? -1);
    return estado?.esEstadoFinal ?? false;
  }
}
