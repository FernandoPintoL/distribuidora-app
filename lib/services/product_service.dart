import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  /// Obtiene lista de productos disponibles para venta
  ///
  /// ✅ IMPORTANTE: El almacén se obtiene AUTOMÁTICAMENTE del servidor
  /// NO enviar 'almacen_id' en el request
  ///
  /// El servidor valida que:
  /// 1. Usuario tenga rol permitido (Preventista, Cliente, Chofer, Super Admin)
  /// 2. Usuario tenga empresa asignada
  /// 3. Empresa tenga almacén de venta asignado
  /// 4. Solo lista productos con:
  ///    - Stock disponible > 0 en el almacén de la empresa
  ///    - Precio de venta válido (tipo_precio_id = 2, precio > 0)
  ///    - Producto activo
  Future<PaginatedResponse<Product>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    int? brandId,
    int? supplierId,
    bool? active,
    // ❌ REMOVIDO: int? almacenId - El almacén se obtiene del servidor
    // ❌ REMOVIDO: bool withStock - Siempre se filtra por stock
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      // ✅ Parámetros opcionales de búsqueda y filtro
      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (categoryId != null) {
        queryParams['categoria_id'] = categoryId;
      }
      if (brandId != null) {
        queryParams['marca_id'] = brandId;
      }
      if (supplierId != null) {
        queryParams['proveedor_id'] = supplierId;
      }
      if (active != null) {
        queryParams['activo'] = active;
      }
      // ❌ NO ENVIAR: almacen_id
      // ❌ NO ENVIAR: con_stock
      // El servidor maneja esto automáticamente basado en auth()->user()->empresa->almacen_id

      final response = await _apiService.get(
        '/productos',
        queryParameters: queryParams,
      );

      return PaginatedResponse<Product>.fromJson(
        response.data,
        (json) => Product.fromJson(json),
      );
    } on DioException catch (e) {
      return PaginatedResponse<Product>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return PaginatedResponse<Product>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<List<Product>>> searchProducts(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/productos/buscar',
        queryParameters: {'q': query, 'limite': limit},
      );

      final apiResponse = ApiResponse<List<Product>>.fromJson(
        response.data,
        (data) => (data as List).map((item) => Product.fromJson(item)).toList(),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<List<Product>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<Product>>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Product>> getProduct(int id) async {
    try {
      final response = await _apiService.get('/productos/$id');

      return ApiResponse<Product>.fromJson(
        response.data,
        (data) => Product.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Product>> createProduct({
    required String nombre,
    required String codigo,
    String? descripcion,
    int? categoriaId,
    int? marcaId,
    int? proveedorId,
    int? unidadMedidaId,
    double? precioCompra,
    double? precioVenta,
    int? stockMinimo,
    int? stockMaximo,
    bool activo = true,
  }) async {
    try {
      final data = {
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'categoria_id': categoriaId,
        'marca_id': marcaId,
        'proveedor_id': proveedorId,
        'unidad_medida_id': unidadMedidaId,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'stock_minimo': stockMinimo,
        'stock_maximo': stockMaximo,
        'activo': activo,
      };

      final response = await _apiService.post('/productos', data: data);

      return ApiResponse<Product>.fromJson(
        response.data,
        (data) => Product.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Product>> updateProduct(
    int id, {
    String? nombre,
    String? codigo,
    String? descripcion,
    int? categoriaId,
    int? marcaId,
    int? proveedorId,
    int? unidadMedidaId,
    double? precioCompra,
    double? precioVenta,
    int? stockMinimo,
    int? stockMaximo,
    bool? activo,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (nombre != null) data['nombre'] = nombre;
      if (codigo != null) data['codigo'] = codigo;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (categoriaId != null) data['categoria_id'] = categoriaId;
      if (marcaId != null) data['marca_id'] = marcaId;
      if (proveedorId != null) data['proveedor_id'] = proveedorId;
      if (unidadMedidaId != null) data['unidad_medida_id'] = unidadMedidaId;
      if (precioCompra != null) data['precio_compra'] = precioCompra;
      if (precioVenta != null) data['precio_venta'] = precioVenta;
      if (stockMinimo != null) data['stock_minimo'] = stockMinimo;
      if (stockMaximo != null) data['stock_maximo'] = stockMaximo;
      if (activo != null) data['activo'] = activo;

      final response = await _apiService.put('/productos/$id', data: data);

      return ApiResponse<Product>.fromJson(
        response.data,
        (data) => Product.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Null>> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete('/productos/$id');

      return ApiResponse<Null>.fromJson(response.data);
    } on DioException catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Null>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.data != null) {
      try {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            return errorData['message'];
          }
          if (errorData.containsKey('error')) {
            return errorData['error'];
          }
        }
      } catch (_) {}
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return 'Error del servidor: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        return 'Error de conexión';
    }
  }
}
