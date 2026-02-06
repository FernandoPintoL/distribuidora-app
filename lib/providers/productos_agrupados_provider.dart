import 'package:flutter/material.dart';
import '../models/producto_agrupado.dart';
import '../services/entrega_service.dart';

/// Provider para gestionar productos agrupados de una entrega
///
/// Consolida productos de múltiples ventas en una sola entrega
class ProductosAgrupadsProvider with ChangeNotifier {
  final EntregaService _entregaService = EntregaService();

  ProductosAgrupados? _productosAgrupados;
  bool _isLoading = false;
  String? _errorMessage;
  int? _entregaIdActual;

  // Getters
  ProductosAgrupados? get productosAgrupados => _productosAgrupados;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get entregaIdActual => _entregaIdActual;

  // Propiedades derivadas
  int get totalProductos => _productosAgrupados?.totalItems ?? 0;
  double get cantidadTotal => _productosAgrupados?.cantidadTotal ?? 0.0;
  List<ProductoAgrupado> get productos => _productosAgrupados?.productos ?? [];

  /// Cargar productos agrupados para una entrega
  Future<bool> cargarProductosAgrupados(int entregaId) async {
    // Si ya tenemos cargada esta entrega, retornar rápido
    if (_entregaIdActual == entregaId && _productosAgrupados != null) {
      debugPrint('📦 [PRODUCTOS_AGRUPADOS] Usando cache de entrega #$entregaId');
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    _entregaIdActual = entregaId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📦 [PRODUCTOS_AGRUPADOS] Cargando productos para entrega #$entregaId');

      final response = await _entregaService.obtenerProductosAgrupados(entregaId);

      if (!response.success) {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _productosAgrupados = response.data;
      _isLoading = false;

      debugPrint(
        '✅ [PRODUCTOS_AGRUPADOS] Cargados: ${_productosAgrupados?.totalItems} tipos de productos',
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      debugPrint('❌ [PRODUCTOS_AGRUPADOS] Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Limpiar datos
  void limpiar() {
    _productosAgrupados = null;
    _entregaIdActual = null;
    _errorMessage = null;
    notifyListeners();
  }
}
