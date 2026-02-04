import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Servicio para gestionar ventas (órdenes confirmadas)
///
/// Una venta es una proforma que ha sido confirmada y convertida,
/// con información completa de pagos, logística y seguimiento.
class VentaService {
  final ApiService _apiService = ApiService();

  /// Obtener una venta por su ID
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta a obtener
  ///
  /// Retorna:
  /// - Success: Datos completos de la venta con estado logístico y pago
  /// - Error: Mensaje de error descriptivo
  Future<ApiResponse<Venta>> getVenta(int ventaId) async {
    try {
      debugPrint('📦 Obteniendo venta #$ventaId');

      // ✅ CORREGIDO: Usar ruta correcta /ventas/{id} (no /app/ventas)
      final response = await _apiService.get('/ventas/$ventaId');

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final venta =
            Venta.fromJson(responseData['data'] as Map<String, dynamic>);

        return ApiResponse<Venta>(
          success: true,
          message: responseData['message'] as String? ?? 'Venta obtenida exitosamente',
          data: venta,
        );
      } else {
        return ApiResponse<Venta>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al obtener venta',
          data: null,
        );
      }
    } on DioException catch (e) {
      return ApiResponse<Venta>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Venta>(
        success: false,
        message: 'Error inesperado al obtener venta: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener una venta por ID de proforma
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma (que fue convertida a venta)
  ///
  /// Retorna:
  /// - Success: Venta asociada a la proforma
  /// - Error: Mensaje de error descriptivo
  Future<ApiResponse<Venta>> getVentaByProformaId(int proformaId) async {
    try {
      debugPrint('📦 Obteniendo venta para proforma #$proformaId');

      final response = await _apiService.get(
        '/ventas',
        queryParameters: {
          'proforma_id': proformaId,
        },
      );

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        // Backend retorna lista, tomar el primero
        final dataList = responseData['data'] as List<dynamic>?;
        if (dataList != null && dataList.isNotEmpty) {
          final venta = Venta.fromJson(dataList.first as Map<String, dynamic>);
          return ApiResponse<Venta>(
            success: true,
            message: responseData['message'] as String? ??
                'Venta obtenida exitosamente',
            data: venta,
          );
        } else {
          return ApiResponse<Venta>(
            success: false,
            message: 'No se encontró venta para esta proforma',
            data: null,
          );
        }
      } else {
        return ApiResponse<Venta>(
          success: false,
          message:
              responseData['message'] as String? ?? 'Error al obtener venta',
          data: null,
        );
      }
    } on DioException catch (e) {
      return ApiResponse<Venta>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Venta>(
        success: false,
        message: 'Error inesperado al obtener venta: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener estado de pago detallado de una venta
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta
  ///
  /// Retorna:
  /// - Success: Mapa con información de pago (estado, monto_pagado, monto_pendiente, etc.)
  /// - Error: Mensaje de error descriptivo
  Future<ApiResponse<Map<String, dynamic>>> getEstadoPago(int ventaId) async {
    try {
      debugPrint('💳 Obteniendo estado de pago para venta #$ventaId');

      final response =
          await _apiService.get('/app/ventas/$ventaId/estado-pago');

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: responseData['message'] as String? ??
              'Estado de pago obtenido exitosamente',
          data: responseData['data'] as Map<String, dynamic>,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] as String? ??
              'Error al obtener estado de pago',
          data: null,
        );
      }
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

  /// Registrar un pago para una venta
  ///
  /// Parámetros:
  /// - ventaId: ID de la venta
  /// - monto: Monto pagado
  /// - tipoPago: Tipo de pago (EFECTIVO, TRANSFERENCIA, QR, TARJETA, etc.)
  /// - numeroReferencia: Número de referencia opcional (para transferencias, cheques, etc.)
  /// - observaciones: Notas adicionales del pago
  ///
  /// Retorna:
  /// - Success: Datos de la venta actualizada
  /// - Error: Mensaje de error descriptivo
  Future<ApiResponse<Map<String, dynamic>>> registrarPago({
    required int ventaId,
    required double monto,
    required String tipoPago,
    String? numeroReferencia,
    String? observaciones,
  }) async {
    try {
      debugPrint(
          '💰 Registrando pago para venta #$ventaId: Bs. $monto ($tipoPago)');

      final response = await _apiService.post(
        '/app/ventas/$ventaId/pagos',
        data: {
          'monto': monto,
          'tipo_pago': tipoPago,
          if (numeroReferencia != null) 'numero_referencia': numeroReferencia,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: responseData['message'] as String? ??
              'Pago registrado exitosamente',
          data: responseData['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] as String? ??
              'Error al registrar pago',
          data: null,
        );
      }
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

  /// Obtener lista de ventas del cliente con paginación
  ///
  /// Parámetros:
  /// - page: Número de página (default: 1)
  /// - perPage: Items por página (default: 20)
  /// - estado: Filtrar por estado de pago (opcional): PAGADO, PARCIAL, PENDIENTE
  /// - estadoLogistico: Filtrar por estado logístico (opcional)
  /// - busqueda: Búsqueda por ID, número de venta o nombre de cliente (opcional)
  /// - fechaDesde: Filtrar por fecha desde (opcional)
  /// - fechaHasta: Filtrar por fecha hasta (opcional)
  ///
  /// Retorna:
  /// - Success: Map con 'data' (lista de ventas), 'total', 'per_page', 'current_page'
  /// - Error: Mensaje de error descriptivo
  Future<ApiResponse<Map<String, dynamic>>> getVentas({
    int page = 1,
    int perPage = 20, // ✅ MODIFICADO: 20 registros por página para mejor UX
    String? estado,
    String? estadoLogistico,
    String? busqueda,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      debugPrint('📋 Obteniendo ventas - página $page');

      final queryParams = {
        'page': page,
        'per_page': perPage,
        if (estado != null) 'estado_pago': estado,
        if (estadoLogistico != null) 'estado_logistico': estadoLogistico,
        if (busqueda != null) 'busqueda': busqueda,
        if (fechaDesde != null) 'fecha_desde': fechaDesde.toIso8601String(),
        if (fechaHasta != null) 'fecha_hasta': fechaHasta.toIso8601String(),
      };

      // Usar endpoint /api/ventas (filtra automáticamente por cliente autenticado)
      final response = await _apiService.get(
        '/ventas',
        queryParameters: queryParams,
      );

      final Map<String, dynamic> responseData =
          response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        // Parsear lista de ventas
        final dataList = responseData['data'] as List<dynamic>;
        final ventas = dataList
            .map((v) => Venta.fromJson(v as Map<String, dynamic>))
            .toList();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: responseData['message'] as String? ?? 'Ventas obtenidas',
          data: {
            'data': ventas,
            'total': responseData['total'] ?? dataList.length,
            'per_page': responseData['per_page'] ?? perPage,
            'current_page': responseData['current_page'] ?? page,
            'has_more_pages':
                (responseData['current_page'] ?? page) * (responseData['per_page'] ?? perPage) <
                    (responseData['total'] ?? dataList.length),
          },
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al obtener ventas',
          data: null,
        );
      }
    } on DioException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error inesperado al obtener ventas: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Helper para obtener mensaje de error desde DioException
  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return e.response?.data?['message'] ?? 'Error del servidor';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      case DioExceptionType.connectionError:
        return 'Error de conexión';
      case DioExceptionType.unknown:
        return 'Error desconocido: ${e.message}';
      default:
        return 'Error inesperado';
    }
  }
}
