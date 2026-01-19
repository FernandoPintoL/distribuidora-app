import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/gasto.dart';
import 'api_service.dart';

class GastoService {
  final ApiService _apiService = ApiService();

  /// Registrar un nuevo gasto en la caja abierta
  Future<ApiResponse<Gasto>> registrarGasto({
    required double monto,
    required String descripcion,
    required String categoria,
    String? numeroComprobante,
    String? proveedor,
    String? observaciones,
  }) async {
    try {
      final payload = {
        'monto': monto,
        'descripcion': descripcion,
        'categoria': categoria,
        if (numeroComprobante != null) 'numero_comprobante': numeroComprobante,
        if (proveedor != null) 'proveedor': proveedor,
        if (observaciones != null) 'observaciones': observaciones,
      };

      final response = await _apiService.post(
        '/cajas/gastos',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final gasto = Gasto.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      debugPrint(
        '✅ [GASTO_SERVICE] Gasto registrado: ${gasto.categoria} - ${gasto.monto} Bs',
      );

      return ApiResponse(
        success: true,
        data: gasto,
        message: data['message'] as String? ?? 'Gasto registrado exitosamente',
      );
    } on DioException catch (e) {
      String errorMsg = 'Error al registrar gasto';
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        errorMsg = errData['message'] as String? ?? errorMsg;
      }
      return ApiResponse(
        success: false,
        message: errorMsg,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener listado de gastos registrados
  Future<ApiResponse<List<Gasto>>> obtenerGastos({
    int page = 1,
    String? fechaDesde,
    String? fechaHasta,
    String? categoria,
    String? q, // búsqueda por descripción o comprobante
  }) async {
    try {
      final params = {
        'page': page,
        if (fechaDesde != null) 'fecha_desde': fechaDesde,
        if (fechaHasta != null) 'fecha_hasta': fechaHasta,
        if (categoria != null) 'categoria': categoria,
        if (q != null) 'q': q,
      };

      final response = await _apiService.get(
        '/cajas/gastos',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final gastos = (data['data'] as List)
          .map((gasto) => Gasto.fromJson(gasto as Map<String, dynamic>))
          .toList();

      debugPrint(
        '📋 [GASTO_SERVICE] Gastos obtenidos: ${gastos.length}',
      );

      return ApiResponse(
        success: true,
        data: gastos,
        message: 'Gastos obtenidos',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener gastos: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener un gasto específico por ID
  Future<ApiResponse<Gasto>> obtenerGasto(int gastoId) async {
    try {
      final response = await _apiService.get(
        '/cajas/gastos/$gastoId',
      );

      final data = response.data as Map<String, dynamic>;
      final gasto = Gasto.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: gasto,
        message: 'Gasto obtenido',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener gasto: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Eliminar un gasto registrado
  Future<ApiResponse<void>> eliminarGasto(int gastoId) async {
    try {
      await _apiService.delete(
        '/cajas/gastos/$gastoId',
      );

      debugPrint(
        '🗑️ [GASTO_SERVICE] Gasto eliminado: ID $gastoId',
      );

      return ApiResponse(
        success: true,
        message: 'Gasto eliminado exitosamente',
      );
    } on DioException catch (e) {
      String errorMsg = 'Error al eliminar gasto';
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        errorMsg = errData['message'] as String? ?? errorMsg;
      }
      return ApiResponse(
        success: false,
        message: errorMsg,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener estadísticas de gastos (total del mes, cantidad, etc)
  Future<ApiResponse<Map<String, dynamic>>> obtenerEstadisticasGastos({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      final params = {
        if (fechaDesde != null) 'fecha_desde': fechaDesde,
        if (fechaHasta != null) 'fecha_hasta': fechaHasta,
      };

      final response = await _apiService.get(
        '/cajas/gastos/estadisticas',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final estadisticas = data['data'] as Map<String, dynamic>;

      debugPrint(
        '📊 [GASTO_SERVICE] Estadísticas - Total: ${estadisticas['total_gasto']}, Cantidad: ${estadisticas['cantidad_gastos']}',
      );

      return ApiResponse(
        success: true,
        data: estadisticas,
        message: 'Estadísticas obtenidas',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener estadísticas: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }
}
