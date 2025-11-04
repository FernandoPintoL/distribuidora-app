import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Servicio para gestionar proformas (cotizaciones)
///
/// Una proforma es una cotización que el cliente solicita
/// y que debe ser aprobada antes de convertirse en venta.
class ProformaService {
  final ApiService _apiService = ApiService();

  /// Confirmar una proforma aprobada y convertirla en venta
  ///
  /// Este endpoint convierte una proforma APROBADA en una venta/pedido confirmado.
  /// Solo se puede confirmar si:
  /// - La proforma está en estado APROBADA
  /// - La proforma no ha vencido
  /// - El stock de productos está disponible
  /// - Tiene mínimo 5 productos diferentes
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma a confirmar
  /// - politicaPago: ANTICIPADO_100, MEDIO_MEDIO o CONTRA_ENTREGA (opcional, default: MEDIO_MEDIO)
  ///
  /// Retorna: La venta/pedido creado
  Future<ApiResponse<Pedido>> confirmarProforma({
    required int proformaId,
    String politicaPago = 'MEDIO_MEDIO',
  }) async {
    try {
      debugPrint('📝 Confirmando proforma #$proformaId');

      final response = await _apiService.post(
        '/app/proformas/$proformaId/confirmar',
        data: {
          'politica_pago': politicaPago,
        },
      );

      // El backend retorna la venta creada en response.data.venta
      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['venta'] != null) {
        final venta = Pedido.fromJson(responseData['venta'] as Map<String, dynamic>);

        return ApiResponse<Pedido>(
          success: true,
          message: responseData['message'] as String? ?? 'Pedido confirmado exitosamente',
          data: venta,
        );
      } else {
        return ApiResponse<Pedido>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al confirmar proforma',
          data: null,
        );
      }
    } on DioException catch (e) {
      return ApiResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Pedido>(
        success: false,
        message: 'Error inesperado al confirmar proforma: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener una proforma por ID
  Future<ApiResponse<Pedido>> getProforma(int proformaId) async {
    try {
      final response = await _apiService.get('/app/proformas/$proformaId');

      final apiResponse = ApiResponse<Pedido>.fromJson(
        response.data,
        (data) => Pedido.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Pedido>(
        success: false,
        message: 'Error inesperado al obtener proforma: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener proformas del cliente autenticado
  ///
  /// Retorna todas las proformas del cliente, filtradas por estado si se especifica
  Future<PaginatedResponse<Pedido>> getProformasCliente({
    int page = 1,
    int perPage = 15,
    String? estado, // PENDIENTE, APROBADA, RECHAZADA, CONVERTIDA, VENCIDA
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (estado != null) {
        queryParams['estado'] = estado;
      }

      final response = await _apiService.get(
        '/app/cliente/proformas',
        queryParameters: queryParams,
      );

      return PaginatedResponse<Pedido>.fromJson(
        response.data,
        (json) => Pedido.fromJson(json),
      );
    } on DioException catch (e) {
      return PaginatedResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return PaginatedResponse<Pedido>(
        success: false,
        message: 'Error inesperado al obtener proformas: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Registrar un pago para una venta
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta
  /// - monto: Monto del pago
  /// - tipoPago: EFECTIVO, TRANSFERENCIA, QR, etc.
  /// - numeroReferencia: Número de referencia del pago (opcional)
  Future<ApiResponse<Map<String, dynamic>>> registrarPago({
    required int ventaId,
    required double monto,
    required String tipoPago,
    String? numeroReferencia,
  }) async {
    try {
      debugPrint('💰 Registrando pago de Bs. $monto para venta #$ventaId');

      final Map<String, dynamic> requestBody = {
        'monto': monto,
        'tipo_pago': tipoPago,
      };

      if (numeroReferencia != null && numeroReferencia.isNotEmpty) {
        requestBody['numero_referencia'] = numeroReferencia;
      }

      final response = await _apiService.post(
        '/app/ventas/$ventaId/pagos',
        data: requestBody,
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
        message: 'Error inesperado al registrar pago: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener estado de pago de una venta
  Future<ApiResponse<Map<String, dynamic>>> getEstadoPago(int ventaId) async {
    try {
      final response = await _apiService.get('/app/ventas/$ventaId/estado-pago');

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
        message: 'Error inesperado al obtener estado de pago: ${e.toString()}',
        data: null,
      );
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
