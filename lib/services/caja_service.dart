import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/caja.dart';
import '../models/movimiento_caja.dart';
import 'api_service.dart';

class CajaService {
  final ApiService _apiService = ApiService();

  /// Obtener el estado actual de la caja del chofer
  /// Si no hay caja abierta, retorna null en data
  Future<ApiResponse<Caja?>> obtenerEstadoCaja() async {
    try {
      final response = await _apiService.get('/chofer/cajas/estado');
      final data = response.data as Map<String, dynamic>;

      if (data['data'] == null) {
        return ApiResponse(
          success: true,
          data: null,
          message: 'No hay caja abierta',
        );
      }

      final caja = Caja.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      debugPrint(
        '📦 [CAJA_SERVICE] Caja obtenida: ${caja.estado} (ID: ${caja.id})',
      );

      return ApiResponse(
        success: true,
        data: caja,
        message: 'Estado de caja obtenido',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener estado de caja: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Abrir una caja nueva para el chofer
  /// Retorna la caja abierta
  Future<ApiResponse<Caja>> abrirCaja({
    double montoApertura = 0.0,
  }) async {
    try {
      final payload = {
        'monto_apertura': montoApertura,
      };

      final response = await _apiService.post(
        '/chofer/cajas/abrir',
        data: payload,
      );

      debugPrint(
        '📥 [CAJA_SERVICE] Respuesta abrirCaja completa: ${response.data}',
      );

      final data = response.data as Map<String, dynamic>;

      debugPrint(
        '📊 [CAJA_SERVICE] Estructura data: success=${data['success']}, data=${data['data']}',
      );

      if (data['data'] == null) {
        debugPrint(
          '❌ [CAJA_SERVICE] data["data"] es null',
        );
        return ApiResponse(
          success: false,
          message: 'Respuesta sin datos',
        );
      }

      final caja = Caja.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      debugPrint(
        '✅ [CAJA_SERVICE] Caja abierta: ID ${caja.id}',
      );

      return ApiResponse(
        success: true,
        data: caja,
        message: data['message'] as String? ?? 'Caja abierta exitosamente',
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ [CAJA_SERVICE] DioException: ${e.message}',
      );
      debugPrint(
        '📥 [CAJA_SERVICE] Respuesta error: ${e.response?.data}',
      );
      String errorMsg = 'Error al abrir caja';
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        errorMsg = errData['message'] as String? ?? errorMsg;
      }
      return ApiResponse(
        success: false,
        message: errorMsg,
      );
    } catch (e) {
      debugPrint(
        '❌ [CAJA_SERVICE] Error inesperado: ${e.toString()}',
      );
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Cerrar la caja abierta del chofer
  /// Retorna la caja cerrada
  Future<ApiResponse<Caja>> cerrarCaja({
    double? montosCierre,
    String? observaciones,
  }) async {
    try {
      final payload = {
        if (montosCierre != null) 'montos_cierre': montosCierre,
        if (observaciones != null) 'observaciones': observaciones,
      };

      final response = await _apiService.post(
        '/chofer/cajas/cerrar',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final caja = Caja.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      debugPrint(
        '🔐 [CAJA_SERVICE] Caja cerrada: ID ${caja.id}, Diferencia: ${caja.diferencia}',
      );

      return ApiResponse(
        success: true,
        data: caja,
        message: data['message'] as String? ?? 'Caja cerrada exitosamente',
      );
    } on DioException catch (e) {
      String errorMsg = 'Error al cerrar caja';
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

  /// Obtener todos los movimientos de la caja abierta actual
  Future<ApiResponse<List<MovimientoCaja>>> obtenerMovimientosCaja({
    int page = 1,
    String? fechaDesde,
    String? fechaHasta,
    String? tipo,
  }) async {
    try {
      final params = {
        'page': page,
        if (fechaDesde != null) 'fecha_desde': fechaDesde,
        if (fechaHasta != null) 'fecha_hasta': fechaHasta,
        if (tipo != null) 'tipo': tipo,
      };

      final response = await _apiService.get(
        '/chofer/cajas/movimientos',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final movimientos = (data['data'] as List)
          .map((mov) => MovimientoCaja.fromJson(mov as Map<String, dynamic>))
          .toList();

      debugPrint(
        '📋 [CAJA_SERVICE] Movimientos obtenidos: ${movimientos.length}',
      );

      return ApiResponse(
        success: true,
        data: movimientos,
        message: 'Movimientos obtenidos',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener movimientos: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener resumen financiero de la caja actual
  /// Retorna totales de ingresos, egresos y balance
  Future<ApiResponse<Map<String, dynamic>>> obtenerResumenCaja() async {
    try {
      final response = await _apiService.get(
        '/chofer/cajas/resumen',
      );

      final data = response.data as Map<String, dynamic>;
      final resumen = data['data'] as Map<String, dynamic>;

      debugPrint(
        '💰 [CAJA_SERVICE] Resumen caja - Ingresos: ${resumen['total_ingresos']}, Egresos: ${resumen['total_egresos']}',
      );

      return ApiResponse(
        success: true,
        data: resumen,
        message: 'Resumen obtenido',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener resumen: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }
}
