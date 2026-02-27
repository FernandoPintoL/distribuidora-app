import 'package:flutter/foundation.dart';
import '../services/filtros_producto_service.dart';

class FiltrosProductoProvider with ChangeNotifier {
  final FiltrosProductoService _filtrosService = FiltrosProductoService();

  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _marcas = [];
  int? _categoriaIdSeleccionada;
  int? _marcaIdSeleccionada;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get categorias => _categorias;
  List<Map<String, dynamic>> get marcas => _marcas;
  int? get categoriaIdSeleccionada => _categoriaIdSeleccionada;
  int? get marcaIdSeleccionada => _marcaIdSeleccionada;
  bool get isLoading => _isLoading;

  bool get hayFiltrosActivos =>
      _categoriaIdSeleccionada != null || _marcaIdSeleccionada != null;

  int get conteoFiltrosActivos {
    int count = 0;
    if (_categoriaIdSeleccionada != null) count++;
    if (_marcaIdSeleccionada != null) count++;
    return count;
  }

  /// Carga los filtros disponibles del backend
  Future<void> loadFiltros() async {
    debugPrint('📥 FiltrosProductoProvider.loadFiltros() - Cargando filtros...');
    _isLoading = true;
    notifyListeners();

    final result = await _filtrosService.getFiltros();

    _categorias = result['categorias'] ?? [];
    _marcas = result['marcas'] ?? [];
    _isLoading = false;

    debugPrint('✅ FiltrosProductoProvider.loadFiltros() - Completado');
    debugPrint('   Categorías: ${_categorias.length}');
    debugPrint('   Marcas: ${_marcas.length}');
    notifyListeners();
  }

  /// Selecciona una categoría (null = todas)
  void seleccionarCategoria(int? id) {
    debugPrint('🔹 FiltrosProductoProvider.seleccionarCategoria($id)');
    _categoriaIdSeleccionada = id;
    notifyListeners();
  }

  /// Selecciona una marca (null = todas)
  void seleccionarMarca(int? id) {
    debugPrint('🔹 FiltrosProductoProvider.seleccionarMarca($id)');
    _marcaIdSeleccionada = id;
    notifyListeners();
  }

  /// Limpia todos los filtros
  void limpiarFiltros() {
    debugPrint('🧹 FiltrosProductoProvider.limpiarFiltros()');
    _categoriaIdSeleccionada = null;
    _marcaIdSeleccionada = null;
    notifyListeners();
  }

  /// Resetea filtros y recarga desde el backend
  Future<void> resetFiltros() async {
    limpiarFiltros();
    await loadFiltros();
  }
}
