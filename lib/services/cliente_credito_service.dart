import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

class ClienteCreditoService {
  final ApiService _apiService = ApiService();

  /// ✅ NUEVO: Obtener detalles de crédito del cliente logueado
  Future<ApiResponse<DetallesCreditoCliente>> obtenerDetallesCreditoCliente(
    int clienteId,
  ) async {
    try {
      final response = await _apiService.get(
        '/clientes/$clienteId/credito-detalles',
      );

      return ApiResponse<DetallesCreditoCliente>.fromJson(
        response.data,
        (data) => DetallesCreditoCliente.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<DetallesCreditoCliente>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error al obtener detalles de crédito: $e');
      return ApiResponse<DetallesCreditoCliente>(
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
