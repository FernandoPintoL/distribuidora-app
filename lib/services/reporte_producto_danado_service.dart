import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/reporte_producto_danado.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ReporteProductoDanadoService {
  final ApiService _apiService = ApiService();
  final String baseUrl = '/reportes-productos-danados';

  /// Listar todos los reportes con filtros opcionales
  Future<ApiResponse<Map<String, dynamic>>> obtenerReportes({
    String? estado,
    int? clienteId,
    int? ventaId,
    String? desde,
    String? hasta,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };

      if (estado != null) queryParameters['estado'] = estado;
      if (clienteId != null) queryParameters['cliente_id'] = clienteId;
      if (ventaId != null) queryParameters['venta_id'] = ventaId;
      if (desde != null) queryParameters['desde'] = desde;
      if (hasta != null) queryParameters['hasta'] = hasta;

      final response = await _apiService.dio.get(
        '${_apiService.baseUrl}$baseUrl',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: response.data['data'],
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al obtener reportes',
      );
    } catch (e) {
      debugPrint('Error al obtener reportes: $e');
      return ApiResponse(
        success: false,
        message: 'Error al obtener reportes: ${e.toString()}',
      );
    }
  }

  /// Obtener detalles de un reporte especifico
  Future<ApiResponse<ReporteProductoDanado?>> obtenerReporte(int reporteId) async {
    try {
      final response = await _apiService.dio.get('${_apiService.baseUrl}$baseUrl/$reporteId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final reporte = ReporteProductoDanado.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          data: reporte,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al obtener reporte',
      );
    } catch (e) {
      debugPrint('Error al obtener reporte: $e');
      return ApiResponse(
        success: false,
        message: 'Error al obtener reporte: ${e.toString()}',
      );
    }
  }

  /// Crear un nuevo reporte
  Future<ApiResponse<ReporteProductoDanado?>> crearReporte({
    required int ventaId,
    required String observaciones,
  }) async {
    try {
      final formData = FormData.fromMap({
        'venta_id': ventaId,
        'observaciones': observaciones,
      });

      final response = await _apiService.dio.post(
        '${_apiService.baseUrl}$baseUrl',
        data: formData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final reporte = ReporteProductoDanado.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          data: reporte,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al crear reporte',
      );
    } catch (e) {
      debugPrint('Error al crear reporte: $e');
      return ApiResponse(
        success: false,
        message: 'Error al crear reporte: ${e.toString()}',
      );
    }
  }

  /// Actualizar estado del reporte
  Future<ApiResponse<ReporteProductoDanado?>> actualizarReporte({
    required int reporteId,
    required String estado,
    String? notasRespuesta,
  }) async {
    try {
      final data = {
        'estado': estado,
      };
      if (notasRespuesta != null) {
        data['notas_respuesta'] = notasRespuesta;
      }

      final response = await _apiService.dio.patch(
        '${_apiService.baseUrl}$baseUrl/$reporteId',
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final reporte = ReporteProductoDanado.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          data: reporte,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al actualizar reporte',
      );
    } catch (e) {
      debugPrint('Error al actualizar reporte: $e');
      return ApiResponse(
        success: false,
        message: 'Error al actualizar reporte: ${e.toString()}',
      );
    }
  }

  /// Subir imagen para un reporte
  Future<ApiResponse<Map<String, dynamic>?>> subirImagen({
    required int reporteId,
    required String rutaArchivo,
    String? descripcion,
  }) async {
    try {
      final formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(rutaArchivo),
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _apiService.dio.post(
        '${_apiService.baseUrl}$baseUrl/$reporteId/imagenes',
        data: formData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: response.data['data'],
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al subir imagen',
      );
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      return ApiResponse(
        success: false,
        message: 'Error al subir imagen: ${e.toString()}',
      );
    }
  }

  /// Eliminar una imagen
  Future<ApiResponse<void>> eliminarImagen(int imagenId) async {
    try {
      final response = await _apiService.dio.delete('${_apiService.baseUrl}$baseUrl/imagenes/$imagenId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al eliminar imagen',
      );
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
      return ApiResponse(
        success: false,
        message: 'Error al eliminar imagen: ${e.toString()}',
      );
    }
  }

  /// Eliminar un reporte
  Future<ApiResponse<void>> eliminarReporte(int reporteId) async {
    try {
      final response = await _apiService.dio.delete('${_apiService.baseUrl}$baseUrl/$reporteId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al eliminar reporte',
      );
    } catch (e) {
      debugPrint('Error al eliminar reporte: $e');
      return ApiResponse(
        success: false,
        message: 'Error al eliminar reporte: ${e.toString()}',
      );
    }
  }

  /// Obtener reportes de una venta especifica
  Future<ApiResponse<List<ReporteProductoDanado>>> obtenerReportesPorVenta(
    int ventaId,
  ) async {
    try {
      final response = await _apiService.dio.get('${_apiService.baseUrl}$baseUrl/venta/$ventaId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final reportes = (response.data['data'] as List)
            .map((r) => ReporteProductoDanado.fromJson(r))
            .toList();

        return ApiResponse(
          success: true,
          data: reportes,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Error al obtener reportes',
      );
    } catch (e) {
      debugPrint('Error al obtener reportes por venta: $e');
      return ApiResponse(
        success: false,
        message: 'Error al obtener reportes: ${e.toString()}',
      );
    }
  }
}
