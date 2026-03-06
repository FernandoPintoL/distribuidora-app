import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/entrega.dart';
import '../models/estadisticas_chofer.dart';
import '../models/ubicacion_tracking.dart';
import '../models/producto_agrupado.dart';
import 'api_service.dart';

class EntregaService {
  final ApiService _apiService = ApiService();

  // ✅ NUEVO: Obtener estadísticas rápidas del chofer (optimizado para dashboard)
  Future<ApiResponse<EstadisticasChofer>> obtenerEstadisticas() async {
    try {
      final response = await _apiService.get('/chofer/estadisticas');

      final data = response.data as Map<String, dynamic>;

      if (data['data'] == null) {
        return ApiResponse(
          success: false,
          message: 'Sin datos de estadísticas',
        );
      }

      final estadisticas = EstadisticasChofer.fromJson(
        data['data'] as Map<String, dynamic>,
      );

      debugPrint(
        '📊 [ENTREGA_SERVICE] Estadísticas obtenidas: ${estadisticas.totalEntregas} entregas',
      );

      return ApiResponse(
        success: true,
        data: estadisticas,
        message: 'Estadísticas obtenidas exitosamente',
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

  // ✅ ACTUALIZADO: Obtener entregas + envios asignados al chofer - Filtra por created_at (fecha de creación)
  Future<ApiResponse<List<Entrega>>> obtenerEntregasAsignadas({
    int page = 1,
    String? estado,
    String? createdDesde,  // ✅ ACTUALIZADO: Rango de fechas de creación (created_at)
    String? createdHasta,  // ✅ ACTUALIZADO: Rango de fechas de creación (created_at)
    String? search,  // ✅ NUEVO: búsqueda case-insensitive
    int? localidadId,  // ✅ NUEVO: filtro por localidad
  }) async {
    try {
      final params = {
        'page': page,
        if (estado != null) 'estado': estado,
        if (createdDesde != null) 'created_desde': createdDesde,  // ✅ ACTUALIZADO: Parámetro de created_at
        if (createdHasta != null) 'created_hasta': createdHasta,  // ✅ ACTUALIZADO: Parámetro de created_at
        if (search != null && search.isNotEmpty) 'search': search,  // ✅ NUEVO
        if (localidadId != null) 'localidad_id': localidadId,  // ✅ NUEVO
      };

      // Nuevo endpoint que devuelve entregas + envios
      final response = await _apiService.get(
        '/chofer/trabajos',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final trabajos = (data['data'] as List).map((trabajo) {
        // El backend envía directamente la entrega completa en el array
        final trabajoMap = trabajo as Map<String, dynamic>;

        debugPrint(
          '[ENTREGA_SERVICE] Parseando entrega: ${trabajoMap['numero_entrega']} con ${(trabajoMap['ventas'] as List?)?.length ?? 0} ventas',
        );

        return Entrega.fromJson(trabajoMap);
      }).toList();

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
      final response = await _apiService.get('/chofer/entregas/$entregaId');

      debugPrint(
        '📍 [ENTREGA_SERVICE] Respuesta obtenerEntrega: ${response.data}',
      );

      final responseData = response.data as Map<String, dynamic>;

      debugPrint(
        '📍 [ENTREGA_SERVICE] Claves en responseData: ${responseData.keys.toList()}',
      );

      try {
        // ✅ NUEVO: Obtener datos de entrega
        final entregaData = responseData['data'] as Map<String, dynamic>;

        // ✅ NUEVO: Agregar productos si vienen en la respuesta
        if (responseData['productos'] is List) {
          entregaData['productos'] = responseData['productos'];
          debugPrint(
            '🛍️ [ENTREGA_SERVICE] Productos agregados: ${(responseData['productos'] as List).length} items',
          );
        }

        // ✅ NUEVO: Agregar localidades si vienen en la respuesta
        if (responseData['localidades'] is Map<String, dynamic>) {
          entregaData['localidades'] = responseData['localidades'];
          debugPrint(
            '📍 [ENTREGA_SERVICE] Localidades agregadas: ${(responseData['localidades'] as Map)['cantidad_localidades']} localidades',
          );
        }

        final entrega = Entrega.fromJson(entregaData);

        debugPrint(
          '🛍️ [ENTREGA_SERVICE] Entrega parseada con ${entrega.productosGenerico.length} productos',
        );

        return ApiResponse(
          success: true,
          data: entrega,
          message: 'Entrega obtenida exitosamente',
        );
      } catch (parseError) {
        debugPrint('❌ Error parseando JSON de entrega: $parseError');
        debugPrint('📦 Datos recibidos: ${responseData['data']}');
        return ApiResponse(
          success: false,
          message:
              'Error al parsear datos de entrega: ${parseError.toString()}',
        );
      }
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
      final data = {'latitud': latitud, 'longitud': longitud};

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
      final data = {'latitud': latitud, 'longitud': longitud};

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/marcar-llegada',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;

      // Verificar si la respuesta contiene un mensaje de error del backend
      if (responseData['success'] == false) {
        return ApiResponse(
          success: false,
          message:
              responseData['message'] as String? ?? 'Error al marcar llegada',
        );
      }

      // Si no hay campo 'data', intentar recargar la entrega
      if (responseData['data'] == null) {
        debugPrint(
          '⚠️ Backend no retornó datos completos, recargando entrega...',
        );
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

      return ApiResponse(success: false, message: errorMessage);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // Confirmar entrega con firma y fotos
  // Si ventaId viene, confirma UNA VENTA específica
  // Si no viene, confirma TODA la entrega
  Future<ApiResponse<Entrega>> confirmarEntrega(
    int entregaId, {
    int? ventaId,
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
    // ✅ Estado de venta (ENTREGADA o CANCELADA)
    String? estadoVenta,
    // ✅ FASE 1: Confirmación de Pago
    String? estadoPago, // PAGADO, PARCIAL, NO_PAGADO
    double? montoRecibido, // Dinero recibido
    int? tipoPagoId, // FK a tipos_pago
    String? motivoNoPago, // Motivo si NO pagó
    // ✅ FASE 2: Foto de comprobante
    String? fotoComprobanteBase64, // Base64 foto del dinero o comprobante
  }) async {
    try {
      final data = {
        if (firmaBase64 != null) 'firma_digital_base64': firmaBase64,
        if (observaciones != null) 'observaciones': observaciones,
        if (fotosBase64 != null) 'fotos': fotosBase64,
        // ✅ Estado de venta
        if (estadoVenta != null) 'estado_venta': estadoVenta,
        // ✅ FASE 1: Pago
        if (estadoPago != null) 'estado_pago': estadoPago,
        if (montoRecibido != null) 'monto_recibido': montoRecibido,
        if (tipoPagoId != null) 'tipo_pago_id': tipoPagoId,
        if (motivoNoPago != null) 'motivo_no_pago': motivoNoPago,
        // ✅ FASE 2: Foto de comprobante
        if (fotoComprobanteBase64 != null)
          'foto_comprobante': fotoComprobanteBase64,
      };

      // Construir ruta dinámicamente según si es venta específica o entrega completa
      final endpoint = ventaId != null
          ? '/chofer/entregas/$entregaId/ventas/$ventaId/confirmar-entrega'
          : '/chofer/entregas/$entregaId/confirmar-entrega';

      final response = await _apiService.post(endpoint, data: data);

      final responseData = response.data as Map<String, dynamic>;
      debugPrint(
        '📍 [ENTREGA_SERVICE] Respuesta confirmarEntrega: $responseData',
      );

      // ✅ Verificar si el backend retornó error (success: false)
      final isSuccess = responseData['success'] as bool? ?? false;
      if (!isSuccess) {
        final errorMessage =
            responseData['message'] as String? ??
            (ventaId != null
                ? 'Error al confirmar venta'
                : 'Error al confirmar entrega');
        return ApiResponse(success: false, message: errorMessage);
      }

      // ✅ Solo parsear entrega si success es true
      final entrega = Entrega.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );

      return ApiResponse(
        success: true,
        data: entrega,
        message: ventaId != null
            ? 'Venta confirmada exitosamente'
            : 'Entrega confirmada exitosamente',
      );
    } on DioException catch (e) {
      // Intentar extraer el mensaje de error del backend
      String errorMessage = e.message ?? 'Error desconocido';

      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        errorMessage = responseData['message'] as String? ?? errorMessage;
      }

      return ApiResponse(success: false, message: errorMessage);
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
        '/chofer/entregas/$entregaId/ubicacion',
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
      final params = {'limite': limite};

      final response = await _apiService.get(
        '/tracking/ubicaciones/$entregaId',
        queryParameters: params,
      );

      // La respuesta de Dio tiene estructura: {success: true, data: {entrega_id, ubicaciones: []}}
      final responseData = response.data as Map<String, dynamic>? ?? {};
      final backendSuccess = responseData['success'] as bool? ?? false;
      final backendData = responseData['data'] as Map<String, dynamic>? ?? {};

      debugPrint('📍 [ENTREGA_SERVICE] Backend success: $backendSuccess');
      debugPrint(
        '📍 [ENTREGA_SERVICE] Backend data keys: ${backendData.keys.toList()}',
      );

      if (backendSuccess && backendData.isNotEmpty) {
        final ubicacionesList = backendData['ubicaciones'] as List? ?? [];
        debugPrint(
          '📍 [ENTREGA_SERVICE] Ubicaciones encontradas: ${ubicacionesList.length}',
        );

        final ubicaciones = ubicacionesList
            .map((u) => UbicacionTracking.fromJson(u as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: ubicaciones,
          message: 'Ubicaciones obtenidas exitosamente',
        );
      } else {
        debugPrint(
          '📍 [ENTREGA_SERVICE] Backend retornó sin datos o sin éxito',
        );
        return ApiResponse(
          success:
              true, // Devolvemos success=true aunque no hay datos (para no blocar el flujo)
          data: [],
          message: 'Sin ubicaciones disponibles',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ENTREGA_SERVICE] DioException: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al obtener ubicaciones: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [ENTREGA_SERVICE] Error general: $e');
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
          .map(
            (h) => EntregaEstadoHistorial.fromJson(h as Map<String, dynamic>),
          )
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
      final payload = {if (notas != null) 'notas': notas};

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
      final response = await _apiService.get('/entregas/$entregaId/progreso');

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
  Future<ApiResponse<Entrega>> confirmarCargoCompleto(int entregaId) async {
    try {
      final response = await _apiService.post(
        '/entregas/$entregaId/listo-para-entrega',
        data: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final entrega = Entrega.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
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

  /// Confirmar que una venta fue entregada (FASE 3: Entrega Individual)
  ///
  /// POST /api/chofer/entregas/{id}/ventas/{venta_id}/confirmar-entrega
  ///
  /// Parámetros:
  /// - fotos: List<String> (opcional) - Fotos en base64
  /// - observaciones: String (opcional) - Observaciones sobre la entrega (max 500 chars)
  ///
  /// Respuesta:
  /// - Venta actualizada con estado_logistico_id = ENTREGADA
  Future<ApiResponse<Map<String, dynamic>>> confirmarVentaEntregada(
    int entregaId,
    int ventaId, {
    List<String>? fotosBase64,
    String? observaciones,
    String? observacionesLogistica,  // ✅ NUEVO: Observaciones logísticas (estado entrega, incidentes)
    double? montoRecibido,  // ✅ NUEVO: Monto que pagó el cliente (backward compatible)
    int? tipoPagoId,  // ✅ NUEVO: ID del tipo de pago (backward compatible)
    // ✅ NUEVA 2026-02-12: Múltiples pagos
    List<Map<String, dynamic>>? pagos,  // Array de {tipo_pago_id, monto, referencia}
    bool? esCredito,  // ✅ CAMBIO: Si es promesa de pago (no dinero real)
    String? tipoConfirmacion,  // COMPLETA o CON_NOVEDAD
    // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
    List<Map<String, dynamic>>? productosRechazados,  // Array de {detalle_venta_id, nombre_producto, cantidad, precio_unitario, subtotal}
    // ✅ NUEVA 2026-03-05: Campos de novedad
    String? tipoNovedad,  // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADO, NO_CONTACTADO
    bool? tiendaAbierta,
    bool? clientePresente,
    String? motivoRechazo,
  }) async {
    try {
      final data = <String, dynamic>{
        if (fotosBase64 != null && fotosBase64.isNotEmpty) 'fotos': fotosBase64,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
        if (observacionesLogistica != null && observacionesLogistica.isNotEmpty)
          'observaciones_logistica': observacionesLogistica,  // ✅ NUEVO: Pasar al backend
        if (montoRecibido != null) 'monto_recibido': montoRecibido,  // ✅ NUEVO: Pasar monto (backward compatible)
        if (tipoPagoId != null) 'tipo_pago_id': tipoPagoId,  // ✅ NUEVO: Pasar tipo de pago (backward compatible)
        // ✅ NUEVA 2026-02-12: Múltiples pagos
        if (pagos != null && pagos.isNotEmpty) 'pagos': pagos,  // Array de pagos múltiples
        if (esCredito != null && esCredito) 'es_credito': esCredito,  // ✅ CAMBIO: Promesa de pago
        if (tipoConfirmacion != null) 'tipo_confirmacion': tipoConfirmacion,  // COMPLETA o CON_NOVEDAD
        // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
        if (productosRechazados != null && productosRechazados.isNotEmpty) 'productos_rechazados': productosRechazados,  // Array de productos rechazados
        // ✅ NUEVA 2026-03-05: Campos de novedad
        if (tipoNovedad != null) 'tipo_novedad': tipoNovedad,
        if (tiendaAbierta != null) 'tienda_abierta': tiendaAbierta,
        if (clientePresente != null) 'cliente_presente': clientePresente,
        if (motivoRechazo != null) 'motivo_rechazo': motivoRechazo,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/ventas/$ventaId/confirmar-entrega',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        return ApiResponse(
          success: true,
          data: responseData['data'] as Map<String, dynamic>?,
          message: responseData['message'] ??
              'Venta entregada correctamente',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ??
              'Error al confirmar entrega de venta',
        );
      }
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

  /// Finalizar entrega (marcar como ENTREGADA cuando todas las ventas están entregadas)
  ///
  /// POST /api/chofer/entregas/{id}/finalizar-entrega
  ///
  /// Parámetros (todos opcionales):
  /// - firma_digital_base64: String - Firma digital en base64
  /// - fotos: List<String> - Fotos en base64
  /// - observaciones: String - Observaciones finales
  /// - monto_recolectado: double - Dinero recolectado
  ///
  /// Respuesta:
  /// - Entrega actualizada con estado_entrega_id = ENTREGADO
  /// - Validación: Todas las ventas deben estar ENTREGADAS o CANCELADAS
  Future<ApiResponse<Entrega>> finalizarEntrega(
    int entregaId, {
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
    double? montoRecolectado,
  }) async {
    try {
      final data = <String, dynamic>{
        if (firmaBase64 != null && firmaBase64.isNotEmpty)
          'firma_digital_base64': firmaBase64,
        if (fotosBase64 != null && fotosBase64.isNotEmpty) 'fotos': fotosBase64,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
        if (montoRecolectado != null) 'monto_recolectado': montoRecolectado,
      };

      final response = await _apiService.post(
        '/chofer/entregas/$entregaId/finalizar-entrega',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final entrega = Entrega.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        return ApiResponse(
          success: true,
          data: entrega,
          message: response.data['message'] ?? 'Entrega finalizada correctamente',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Error al finalizar entrega',
        );
      }
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al finalizar entrega: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// Obtener resumen de pagos registrados en una entrega
  ///
  /// GET /api/chofer/entregas/{id}/resumen-pagos
  Future<ApiResponse<Map<String, dynamic>>> obtenerResumenPagos(int entregaId) async {
    try {
      final response = await _apiService.get('/chofer/entregas/$entregaId/resumen-pagos');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == false) {
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Error al obtener resumen',
        );
      }

      final resumen = data['data'] as Map<String, dynamic>;

      return ApiResponse(
        success: true,
        data: resumen,
        message: 'Resumen obtenido exitosamente',
      );
    } on DioException catch (e) {
      debugPrint('Error al obtener resumen de pagos: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al obtener resumen: ${e.message}',
      );
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // ✅ FASE 2: Obtener tipos de pago desde la API
  Future<ApiResponse<List<Map<String, dynamic>>>> obtenerTiposPago() async {
    try {
      final response = await _apiService.get('/tipos-pago');

      final responseData = response.data as Map<String, dynamic>;

      final isSuccess = responseData['success'] as bool? ?? false;
      if (!isSuccess) {
        final errorMessage =
            responseData['message'] as String? ??
            'Error al obtener tipos de pago';
        return ApiResponse(success: false, message: errorMessage);
      }

      // Parsear respuesta esperada: { success: true, data: [{id, codigo, nombre}, ...] }
      final tiposPagoData = responseData['data'] as List? ?? [];
      final tiposPago = tiposPagoData
          .map(
            (item) => {
              'id': item['id'],
              'codigo': item['codigo'],
              'nombre': item['nombre'],
            },
          )
          .toList();

      return ApiResponse(
        success: true,
        message: 'Tipos de pago obtenidos',
        data: tiposPago,
      );
    } on DioException catch (e) {
      debugPrint('Error en obtenerTiposPago: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al obtener tipos de pago: ${e.message}',
      );
    } catch (e) {
      debugPrint('Error inesperado en obtenerTiposPago: $e');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  /// 📦 Obtener productos agrupados de una entrega
  ///
  /// Consolida productos de múltiples ventas, sumando cantidades
  /// EJEMPLO:
  /// - Venta A: 2x ProductoA, 1x ProductoB
  /// - Venta B: 2x ProductoA, 2x ProductoB
  /// RESULTADO: 4x ProductoA, 3x ProductoB
  ///
  /// GET /api/entregas/{id}/productos-agrupados
  Future<ApiResponse<ProductosAgrupados>> obtenerProductosAgrupados(int entregaId) async {
    try {
      debugPrint('📦 [ENTREGA_SERVICE] Obteniendo productos agrupados para entrega #$entregaId');

      final response = await _apiService.get(
        '/entregas/$entregaId/productos-agrupados',
      );

      final data = response.data as Map<String, dynamic>;

      if (!data['success'] as bool) {
        return ApiResponse(
          success: false,
          message: data['message'] as String? ?? 'Error al obtener productos',
        );
      }

      final productosJson = data['data'] as Map<String, dynamic>;
      final productosAgrupados = ProductosAgrupados.fromJson(productosJson);

      debugPrint(
        '✅ [ENTREGA_SERVICE] Productos obtenidos: ${productosAgrupados.totalItems} tipos, ${productosAgrupados.cantidadTotal.toInt()} unidades',
      );

      return ApiResponse(
        success: true,
        data: productosAgrupados,
        message: 'Productos obtenidos exitosamente',
      );
    } on DioException catch (e) {
      debugPrint('❌ Error obteniendo productos agrupados: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al obtener productos: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // ✅ NUEVO 2026-02-15: Corregir pagos de una venta en una entrega
  Future<ApiResponse<Map<String, dynamic>>> corregirPagoVenta({
    required int entregaId,
    required int ventaId,
    required List<Map<String, dynamic>> desglosePagos,
  }) async {
    try {
      debugPrint(
        '💳 [ENTREGA_SERVICE] Corrigiendo pagos - Entrega #$entregaId, Venta #$ventaId',
      );

      final response = await _apiService.patch(
        '/entregas/$entregaId/ventas/$ventaId/corregir-pago',
        data: {
          'desglose_pagos': desglosePagos,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final isSuccess = responseData['success'] as bool? ?? false;

      if (isSuccess) {
        debugPrint('✅ [ENTREGA_SERVICE] Pagos corregidos exitosamente');
        return ApiResponse(
          success: true,
          data: responseData['data'] as Map<String, dynamic>? ?? {},
          message: responseData['message'] as String? ?? 'Pagos corregidos exitosamente',
        );
      } else {
        final errorMessage = responseData['message'] as String? ?? 'Error al corregir pagos';
        debugPrint('❌ [ENTREGA_SERVICE] Error: $errorMessage');
        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Error en corregirPagoVenta: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al corregir pagos: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Error inesperado en corregirPagoVenta: $e');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  // ✅ NUEVO 2026-02-21: Cambiar tipo de entrega de una venta
  Future<ApiResponse<Map<String, dynamic>>> cambiarTipoEntrega({
    required int entregaId,
    required int ventaId,
    required String tipoEntrega, // COMPLETA o CON_NOVEDAD
    String? tipoNovedad, // DEVOLUCION_PARCIAL, RECHAZADA, etc (requerido si tipoEntrega es CON_NOVEDAD)
  }) async {
    try {
      debugPrint(
        '📦 [ENTREGA_SERVICE] Cambiando tipo de entrega - Entrega #$entregaId, Venta #$ventaId a $tipoEntrega',
      );

      final data = {
        'tipo_entrega': tipoEntrega,
      };

      if (tipoEntrega == 'CON_NOVEDAD' && tipoNovedad != null) {
        data['tipo_novedad'] = tipoNovedad;
      }

      final response = await _apiService.patch(
        '/entregas/$entregaId/ventas/$ventaId/cambiar-tipo-entrega',
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      final isSuccess = responseData['success'] as bool? ?? false;

      if (isSuccess) {
        debugPrint('✅ [ENTREGA_SERVICE] Tipo de entrega cambiado exitosamente');
        return ApiResponse(
          success: true,
          data: responseData['data'] as Map<String, dynamic>? ?? {},
          message: responseData['message'] as String? ?? 'Tipo de entrega actualizado',
        );
      } else {
        final errorMessage = responseData['message'] as String? ?? 'Error al cambiar tipo de entrega';
        debugPrint('❌ [ENTREGA_SERVICE] Error: $errorMessage');
        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Error en cambiarTipoEntrega: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al cambiar tipo de entrega: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Error inesperado en cambiarTipoEntrega: $e');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }
}
