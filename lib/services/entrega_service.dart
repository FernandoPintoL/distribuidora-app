import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/entrega.dart';
import '../models/ubicacion_tracking.dart';
import 'api_service.dart';

class EntregaService {
  final ApiService _apiService = ApiService();

  // Obtener entregas asignadas al chofer actual
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

      final response = await _apiService.get(
        '/chofer/entregas',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final entregas = (data['data'] as List)
          .map((e) => Entrega.fromJson(e as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        success: true,
        data: entregas,
        message: 'Entregas obtenidas exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al obtener entregas: ${e.message}',
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

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
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

  // Iniciar ruta (cambiar estado a EN_CAMINO)
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

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
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

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
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

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: 'Llegada marcada exitosamente',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al marcar llegada: ${e.message}',
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
    required String firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
  }) async {
    try {
      final data = {
        'firma_digital': firmaBase64,
        'observaciones': observaciones,
        if (fotosBase64 != null) 'fotos': fotosBase64,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/confirmar-entrega',
        data: data,
      );

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
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

      final entrega = Entrega.fromJson(
        response.data as Map<String, dynamic>,
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

      final ubicacion = UbicacionTracking.fromJson(
        response.data as Map<String, dynamic>,
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

      final ubicacion = UbicacionTracking.fromJson(
        response.data as Map<String, dynamic>,
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
}
