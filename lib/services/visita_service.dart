import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/orden_del_dia.dart';
import 'api_service.dart';

class VisitaService {
  final ApiService _apiService = ApiService();

  /// Registrar nueva visita
  Future<ApiResponse<VisitaPreventistaCliente>> registrarVisita({
    required int clienteId,
    required DateTime fechaHoraVisita,
    required TipoVisitaPreventista tipoVisita,
    required EstadoVisitaPreventista estadoVisita,
    MotivoNoAtencionVisita? motivoNoAtencion,
    required double latitud,
    required double longitud,
    File? fotoLocal,
    String? observaciones,
  }) async {
    try {
      final formData = FormData();

      // Campos obligatorios
      formData.fields.add(MapEntry('cliente_id', clienteId.toString()));
      formData.fields.add(
        MapEntry(
          'fecha_hora_visita',
          fechaHoraVisita.toIso8601String(),
        ),
      );
      formData.fields.add(MapEntry('tipo_visita', tipoVisita.name));
      formData.fields.add(MapEntry('estado_visita', estadoVisita.name));
      formData.fields.add(MapEntry('latitud', latitud.toString()));
      formData.fields.add(MapEntry('longitud', longitud.toString()));

      // Campos opcionales
      if (motivoNoAtencion != null) {
        formData.fields.add(
          MapEntry('motivo_no_atencion', motivoNoAtencion.name),
        );
      }

      if (observaciones != null && observaciones.isNotEmpty) {
        formData.fields.add(MapEntry('observaciones', observaciones));
      }

      // Foto (si existe)
      if (fotoLocal != null) {
        formData.files.add(
          MapEntry(
            'foto_local',
            await MultipartFile.fromFile(
              fotoLocal.path,
              filename: 'visita_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ),
        );
      }

      final response = await _apiService.post(
        '/visitas',
        data: formData,
        isFormData: true,
      );

      debugPrint('✅ Visita registrada exitosamente');

      return ApiResponse<VisitaPreventistaCliente>.fromJson(
        response.data,
        (data) => VisitaPreventistaCliente.fromJson(data),
      );
    } on DioException catch (e) {
      debugPrint('❌ Error al registrar visita: ${_getErrorMessage(e)}');
      return ApiResponse<VisitaPreventistaCliente>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse<VisitaPreventistaCliente>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener mis visitas
  Future<PaginatedResponse<VisitaPreventistaCliente>> obtenerMisVisitas({
    int page = 1,
    int perPage = 20,
    String? fechaInicio,
    String? fechaFin,
    EstadoVisitaPreventista? estadoVisita,
    TipoVisitaPreventista? tipoVisita,
    int? clienteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (fechaInicio != null && fechaFin != null) {
        queryParams['fecha_inicio'] = fechaInicio;
        queryParams['fecha_fin'] = fechaFin;
      }

      if (estadoVisita != null) {
        queryParams['estado_visita'] = estadoVisita.name;
      }

      if (tipoVisita != null) {
        queryParams['tipo_visita'] = tipoVisita.name;
      }

      if (clienteId != null) {
        queryParams['cliente_id'] = clienteId;
      }

      final response = await _apiService.get(
        '/visitas',
        queryParameters: queryParams,
      );

      return PaginatedResponse<VisitaPreventistaCliente>.fromJson(
        response.data,
        (json) => VisitaPreventistaCliente.fromJson(json),
      );
    } on DioException catch (e) {
      return PaginatedResponse<VisitaPreventistaCliente>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return PaginatedResponse<VisitaPreventistaCliente>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener detalle de visita
  Future<ApiResponse<VisitaPreventistaCliente>> obtenerDetalleVisita(
    int visitaId,
  ) async {
    try {
      final response = await _apiService.get('/visitas/$visitaId');

      return ApiResponse<VisitaPreventistaCliente>.fromJson(
        response.data,
        (data) => VisitaPreventistaCliente.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<VisitaPreventistaCliente>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<VisitaPreventistaCliente>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener estadísticas de mis visitas
  Future<ApiResponse<Map<String, dynamic>>> obtenerEstadisticas({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (fechaInicio != null && fechaFin != null) {
        queryParams['fecha_inicio'] = fechaInicio;
        queryParams['fecha_fin'] = fechaFin;
      }

      final response = await _apiService.get(
        '/visitas/estadisticas',
        queryParameters: queryParams,
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
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Validar si cliente tiene horario disponible ahora
  Future<ApiResponse<Map<String, dynamic>>> validarHorario(
    int clienteId,
  ) async {
    try {
      final response = await _apiService.get(
        '/visitas/validar-horario',
        queryParameters: {'cliente_id': clienteId},
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
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  /// ✅ NUEVO: Obtener orden del día (clientes a visitar hoy)
  Future<ApiResponse<OrdenDelDia>> obtenerOrdenDelDia() async {
    try {
      final response = await _apiService.get('/visitas/orden-del-dia');

      return ApiResponse<OrdenDelDia>.fromJson(
        response.data,
        (data) => OrdenDelDia.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<OrdenDelDia>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error al obtener orden del día: $e');
      return ApiResponse<OrdenDelDia>(
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
