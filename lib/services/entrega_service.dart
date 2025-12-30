import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/entrega.dart';
import '../models/ubicacion_tracking.dart';
import 'api_service.dart';

class EntregaService {
  final ApiService _apiService = ApiService();

  // Obtener entregas + envios asignados al chofer (combinados)
  Future<ApiResponse<List<Entrega>>> obtenerEntregasAsignadas({
    int page = 1,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      final params = {
        'page': page,
        if (estado != null) 'estado': estado,
        if (fechaDesde != null) 'fecha_desde': fechaDesde,
        if (fechaHasta != null) 'fecha_hasta': fechaHasta,
      };

      // Nuevo endpoint que devuelve entregas + envios
      final response = await _apiService.get(
        '/chofer/trabajos',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final trabajos = (data['data'] as List)
          .map((trabajo) {
            // Convertir trabajos (entregas + envios) a modelo Entrega
            // El nuevo endpoint incluye 'type' para distinguir entre 'entrega' y 'envio'
            final trabajoMap = trabajo as Map<String, dynamic>;

            // Normalizar para el modelo Entrega
            trabajoMap['trabajoType'] = trabajoMap['type']; // Guardar el tipo original

            return Entrega.fromJson(trabajoMap);
          })
          .toList();

      return ApiResponse(
        success: true,
        data: trabajos,
        message: 'Trabajos obtenidos exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener trabajos: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Obtener una entrega por ID
  Future<ApiResponse<Entrega>> obtenerEntrega(int entregaId) async {
    try {
      final response = await _apiService.get(
        '/chofer/entregas/$entregaId',
      );

      final responseData = response.data as Map<String, dynamic>;
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Entrega obtenida exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener entrega: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Iniciar ruta (cambiar estado a EN_RUTA)
  Future<ApiResponse<Entrega>> iniciarRuta(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    try {
      final data = {
        'latitud': latitud,
        'longitud': longitud,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/iniciar-ruta',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Ruta iniciada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al iniciar ruta: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Actualizar estado de entrega
  Future<ApiResponse<Entrega>> actualizarEstado(
    int entregaId, {
    required String estado,
    String? comentario,
  }) async {
    try {
      final data = {
        'estado': estado,
        if (comentario != null) 'comentario': comentario,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/actualizar-estado',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Estado actualizado exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al actualizar estado: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Marcar llegada a destino
  Future<ApiResponse<Entrega>> marcarLlegada(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    try {
      final data = {
        'latitud': latitud,
        'longitud': longitud,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/marcar-llegada',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;

      // Verificar si la respuesta contiene un mensaje de error del backend
      if (responseData['success'] == false) {
        return ApiResponse(
          success: false,
          message: responseData['message'] as String? ?? 'Error al marcar llegada',
        );
      }

      // Si no hay campo 'data', intentar recargar la entrega
      if (responseData['data'] == null) {
        debugPrint('⚠️ Backend no retornó datos completos, recargando entrega...');
        final entregaResponse = await obtenerEntrega(entregaId);
        return entregaResponse;
      }

      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Llegada marcada exitosamente',
      );
    } on DioException catch (e) {
      // Intentar extraer mensaje de error del backend
      String errorMessage = 'Error al marcar llegada: ${e.message}';

      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response?.data as Map<String, dynamic>;
        errorMessage = errorData['message'] as String? ?? errorMessage;
      }

      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Confirmar entrega con firma y fotos
  Future<ApiResponse<Entrega>> confirmarEntrega(
    int entregaId, {
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
  }) async {
    try {
      final data = {
        if (firmaBase64 != null) 'firma_digital': firmaBase64,
        if (observaciones != null) 'observaciones': observaciones,
        if (fotosBase64 != null) 'fotos': fotosBase64,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/confirmar-entrega',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Entrega confirmada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al confirmar entrega: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Reportar novedad
  Future<ApiResponse<Entrega>> reportarNovedad(
    int entregaId, {
    required String motivo,
    String? descripcion,
    String? fotoBase64,
  }) async {
    try {
      final data = {
        'motivo': motivo,
        if (descripcion != null) 'descripcion': descripcion,
        if (fotoBase64 != null) 'foto': fotoBase64,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/reportar-novedad',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Novedad reportada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al reportar novedad: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Registrar ubicación
  Future<ApiResponse<UbicacionTracking>> registrarUbicacion(
    int entregaId, {
    required double latitud,
    required double longitud,
    double? velocidad,
    double? rumbo,
    double? altitud,
    double? precision,
    String? evento,
  }) async {
    try {
      final data = {
        'latitud': latitud,
        'longitud': longitud,
        if (velocidad != null) 'velocidad': velocidad,
        if (rumbo != null) 'rumbo': rumbo,
        if (altitud != null) 'altitud': altitud,
        if (precision != null) 'precision': precision,
        if (evento != null) 'evento': evento,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/registrar-ubicacion',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final ubicacion = UbicacionTracking.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: ubicacion,
        message: 'Ubicación registrada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al registrar ubicación: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Obtener historial de ubicaciones de una entrega
  Future<ApiResponse<List<UbicacionTracking>>> obtenerUbicaciones(
    int entregaId, {
    int limite = 50,
  }) async {
    try {
      final params = {
        'limite': limite,
      };

      final response = await _apiService.get(
        '/tracking/ubicaciones/$entregaId',
        queryParameters: params,
      );

      final ubicaciones = (response.data['ubicaciones'] as List)
          .map((u) => UbicacionTracking.fromJson(u as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        success: true,
        data: ubicaciones,
        message: 'Ubicaciones obtenidas exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener ubicaciones: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Obtener última ubicación
  Future<ApiResponse<UbicacionTracking>> obtenerUltimaUbicacion(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.get(
        '/tracking/ultima-ubicacion/$entregaId',
      );

      final responseData = response.data as Map<String, dynamic>;
      final ubicacion = UbicacionTracking.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: ubicacion,
        message: 'Última ubicación obtenida',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener última ubicación: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Calcular ETA
  Future<ApiResponse<Map<String, dynamic>>> calcularETA(
    int entregaId, {
    required double latDestino,
    required double lngDestino,
    double velocidadPromedio = 40,
  }) async {
    try {
      final params = {
        'entrega_id': entregaId,
        'lat_destino': latDestino,
        'lng_destino': lngDestino,
        'velocidad_promedio': velocidadPromedio,
      };

      final response = await _apiService.get(
        '/tracking/calcular-eta',
        queryParameters: params,
      );

      return ApiResponse(
        success: true,
        data: response.data as Map<String, dynamic>,
        message: 'ETA calculada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al calcular ETA: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Obtener historial de estados
  Future<ApiResponse<List<EntregaEstadoHistorial>>> obtenerHistorialEstados(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.get(
        '/chofer/entregas/$entregaId/historial-estados',
      );

      final historial = (response.data['data'] as List)
          .map((h) => EntregaEstadoHistorial.fromJson(h as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        success: true,
        data: historial,
        message: 'Historial obtenido exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener historial: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // ========== MÉTODOS DE CARGA/CONFIRMACIÓN ==========

  /// Confirmar que una venta ha sido cargada en la entrega
  /// Usado en el flujo PREPARACION_CARGA o EN_CARGA
  Future<ApiResponse<Entrega>> confirmarVentaCargada(
    int entregaId,
    int ventaId, {
    String? notas,
  }) async {
    try {
      final payload = {
        if (notas != null) 'notas': notas,
      };

      final response = await _apiService.post(
        '/entregas/$entregaId/confirmar-venta/$ventaId',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend devolvió éxito, aunque puede que no devuelva la entrega completa
        // En ese caso, obtenemos la entrega actualizada con una llamada adicional
        try {
          final entregaCompleta = await obtenerEntrega(entregaId);
          if (entregaCompleta.success && entregaCompleta.data != null) {
            return ApiResponse(
              success: true,
              data: entregaCompleta.data,
              message: 'Venta confirmada como cargada',
            );
          }
        } catch (_) {
          // Si no podemos obtener la entrega, retornamos éxito de todas formas
        }

        // Fallback: retornar éxito aunque no tengamos la entrega completa
        return ApiResponse(
          success: true,
          data: null,
          message: 'Venta confirmada como cargada',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Error al confirmar venta',
        );
      }
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al confirmar venta: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener progreso de carga de una entrega
  /// Devuelve { confirmadas, total, pendientes, porcentaje, completado }
  Future<ApiResponse<Map<String, dynamic>>> obtenerProgresoEntrega(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.get(
        '/entregas/$entregaId/progreso',
      );

      final progreso = response.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: progreso,
        message: 'Progreso obtenido exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener progreso: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Confirmar que la carga está lista (transición de EN_CARGA a LISTO_PARA_ENTREGA)
  Future<ApiResponse<Entrega>> confirmarCargoCompleto(
    int entregaId,
  ) async {
    try {
      final response = await _apiService.post(
        '/entregas/$entregaId/listo-para-entrega',
        data: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final entrega = Entrega.fromJson(response.data['data'] as Map<String, dynamic>);
        return ApiResponse(
          success: true,
          data: entrega,
          message: 'Carga confirmada - Entrega lista para entrega',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Error al confirmar carga',
        );
      }
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al confirmar carga: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Desmarcar una venta como cargada (en caso de error)
  Future<ApiResponse<Entrega>> desmarcarVentaCargada(
    int entregaId,
    int ventaId,
  ) async {
    try {
      final response = await _apiService.delete(
        '/entregas/$entregaId/confirmar-venta/$ventaId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Backend devolvió éxito, aunque puede que no devuelva la entrega completa
        // En ese caso, obtenemos la entrega actualizada con una llamada adicional
        try {
          final entregaCompleta = await obtenerEntrega(entregaId);
          if (entregaCompleta.success && entregaCompleta.data != null) {
            return ApiResponse(
              success: true,
              data: entregaCompleta.data,
              message: 'Venta desmarcada correctamente',
            );
          }
        } catch (_) {
          // Si no podemos obtener la entrega, retornamos éxito de todas formas
        }

        // Fallback: retornar éxito aunque no tengamos la entrega completa
        return ApiResponse(
          success: true,
          data: null,
          message: 'Venta desmarcada correctamente',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Error al desmarcar venta',
        );
      }
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al desmarcar venta: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }
}
