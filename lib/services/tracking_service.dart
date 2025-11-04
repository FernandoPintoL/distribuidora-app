import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

class TrackingService {
  final ApiService _apiService = ApiService();

  /// Obtener ubicaciones de tracking de una entrega
  ///
  /// Devuelve el historial completo de ubicaciones y la ubicación actual
  Future<ApiResponse<Map<String, dynamic>>> getUbicacionesEntrega(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.get(
        '/tracking/entregas/$entregaId/ubicaciones',
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data,
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error inesperado al obtener ubicaciones: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener solo la última ubicación conocida (lightweight)
  ///
  /// Útil para polling rápido sin cargar todo el historial
  Future<ApiResponse<UbicacionTracking>> getUltimaUbicacion(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.get(
        '/tracking/entregas/$entregaId/ubicacion-actual',
      );

      final apiResponse = ApiResponse<UbicacionTracking>.fromJson(
        response.data,
        (data) => UbicacionTracking.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<UbicacionTracking>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<UbicacionTracking>(
        success: false,
        message: 'Error inesperado al obtener ubicación: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Calcular distancia estimada desde la ubicación actual del camión
  /// hasta la ubicación del cliente
  Future<ApiResponse<DistanciaEstimada>> calcularDistanciaLlegada(
    int entregaId,
    double latCliente,
    double lngCliente,
  ) async {
    try {
      final response = await _apiService.post(
        '/tracking/entregas/$entregaId/calcular-eta',
        data: {'lat_destino': latCliente, 'lng_destino': lngCliente},
      );

      final apiResponse = ApiResponse<DistanciaEstimada>.fromJson(
        response.data,
        (data) => DistanciaEstimada.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<DistanciaEstimada>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<DistanciaEstimada>(
        success: false,
        message: 'Error inesperado al calcular distancia: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener información de tracking de un pedido
  ///
  /// Incluye entrega, chofer, camión y última ubicación si existe
  Future<ApiResponse<Map<String, dynamic>>> getTrackingPedido(
    int pedidoId,
  ) async {
    try {
      final response = await _apiService.get('/app/pedidos/$pedidoId/tracking');

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data,
      );
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error inesperado al obtener tracking: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Verificar si un pedido tiene tracking activo
  Future<bool> tieneTrackingActivo(int pedidoId) async {
    try {
      final response = await getTrackingPedido(pedidoId);

      if (!response.success || response.data == null) {
        return false;
      }

      final data = response.data!;

      // Verificar que tenga entrega asignada y ubicación actual
      return data['entrega'] != null && data['ubicacion_actual'] != null;
    } catch (e) {
      debugPrint('Error verificando tracking activo: $e');
      return false;
    }
  }

  // Helper para extraer mensaje de error de DioException
  String _getErrorMessage(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('message')) {
          return data['message'] as String;
        } else if (data.containsKey('error')) {
          return data['error'] as String;
        } else if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first as String;
          }
          return 'Error de validación';
        }
      }

      return 'Error del servidor: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    } else {
      return 'Error de red: ${e.message}';
    }
  }
}
