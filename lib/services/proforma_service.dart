import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

// ✅ NUEVO: Importar TimeOfDay para parámetros de proforma
// (ya incluido en flutter/material.dart)

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
  /// - Las reservas no han expirado (o necesitan renovación)
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma a confirmar
  /// - politicaPago: ANTICIPADO_100, MEDIO_MEDIO o CONTRA_ENTREGA (opcional, default: MEDIO_MEDIO)
  ///
  /// Retorna:
  /// - Success: La venta/pedido creado
  /// - Error RESERVAS_EXPIRADAS: Incluye información para renovación
  /// - Otros errores: Mensajes de validación
  Future<ApiResponse<Pedido>> confirmarProforma({
    required int proformaId,
    String politicaPago = 'MEDIO_MEDIO',
  }) async {
    try {
      debugPrint('📝 Confirmando proforma #$proformaId');

      final response = await _apiService.post(
        '/proformas/$proformaId/confirmar',
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
        // Crear ApiResponse con información de error enriquecida
        final apiResponse = ApiResponse<Pedido>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al confirmar proforma',
          data: null,
        );

        // Agregar código de error si está disponible
        if (responseData['code'] != null) {
          apiResponse.code = responseData['code'] as String;
        }

        // Agregar información adicional para RESERVAS_EXPIRADAS
        if (responseData['code'] == 'RESERVAS_EXPIRADAS' && responseData['data'] != null) {
          apiResponse.additionalData = responseData['data'] as Map<String, dynamic>;
        }

        return apiResponse;
      }
    } on DioException catch (e) {
      final apiResponse = ApiResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );

      // Intentar extraer código de error de la respuesta
      if (e.response?.data != null) {
        final Map<String, dynamic> errorData = e.response!.data as Map<String, dynamic>;
        if (errorData['code'] != null) {
          apiResponse.code = errorData['code'] as String;
        }
        if (errorData['data'] != null) {
          apiResponse.additionalData = errorData['data'] as Map<String, dynamic>;
        }
      }

      return apiResponse;
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
      final response = await _apiService.get('/proformas/$proformaId');

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
        '/proformas',
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

  /// ✅ NUEVO: Crear una nueva proforma con validación de combos
  ///
  /// Esta es la versión optimizada de PedidoService.crearPedido() enfocada en proformas.
  /// El backend valida automáticamente productos COMBO vs SIMPLE con su lógica de capacidad.
  ///
  /// Parámetros:
  /// - clienteId: ID del cliente
  /// - items: Lista de items con formato {producto_id, cantidad, precio_unitario}
  /// - tipoEntrega: DELIVERY o PICKUP
  /// - fechaProgramada: Fecha de entrega solicitada
  /// - direccionId: ID de dirección (requerido para DELIVERY)
  /// - horaInicio: Hora inicio preferida (opcional)
  /// - horaFin: Hora fin preferida (opcional)
  /// - observaciones: Observaciones (opcional)
  /// - politicaPago: CONTRA_ENTREGA, ANTICIPADO_100, MEDIO_MEDIO, CREDITO
  ///
  /// Retorna:
  /// - Success: La proforma creada (estado PENDIENTE)
  /// - Error: Mensajes de validación o error del servidor
  ///
  /// Ejemplos de validación:
  /// - COMBO: Valida capacidad (cuello de botella)
  /// - SIMPLE: Valida stock_disponible
  /// - Combos requieren al menos cantidad=1
  ///
  /// Cambios en 2026-02-19:
  /// - Backend ahora distingue entre COMBO (usa ComboStockService) y SIMPLE (usa stock_disponible)
  /// - Ya no hay errores SQLSTATE[42703] (columna indefinida)
  /// - Retorna detalles de error incluyendo cuello_de_botella para combos
  Future<ApiResponse<Pedido>> crearProforma({
    required int clienteId,
    required List<Map<String, dynamic>> items,
    required String tipoEntrega,
    required DateTime fechaProgramada,
    int? direccionId,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
    String? observaciones,
    String politicaPago = 'CONTRA_ENTREGA',
  }) async {
    try {
      // Preparar el cuerpo de la petición
      final Map<String, dynamic> requestBody = {
        'cliente_id': clienteId,
        'productos': items,
        'tipo_entrega': tipoEntrega,
        'fecha_programada': fechaProgramada.toIso8601String(),
        'politica_pago': politicaPago,
      };

      // Agregar dirección SOLO si es DELIVERY
      if (tipoEntrega == 'DELIVERY' && direccionId != null) {
        requestBody['direccion_entrega_solicitada_id'] = direccionId;
      }

      // Agregar campos opcionales si están presentes
      if (horaInicio != null) {
        requestBody['hora_inicio_preferida'] =
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
      }

      if (horaFin != null) {
        requestBody['hora_fin_preferida'] =
            '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}';
      }

      if (observaciones != null && observaciones.isNotEmpty) {
        requestBody['observaciones'] = observaciones;
      }

      debugPrint('📋 Creando PROFORMA con ${items.length} productos');
      debugPrint('   Cliente: $clienteId');
      debugPrint('   Tipo entrega: $tipoEntrega');
      debugPrint('   Política pago: $politicaPago');
      if (tipoEntrega == 'DELIVERY' && direccionId != null) {
        debugPrint('   Dirección: $direccionId');
      }

      final response = await _apiService.post(
        '/proformas',
        data: requestBody,
      );

      // Backend wraps proforma data inside data.proforma
      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final proformaData = responseData['data'] is Map<String, dynamic> &&
                (responseData['data'] as Map<String, dynamic>).containsKey('proforma')
            ? (responseData['data'] as Map<String, dynamic>)['proforma']
            : responseData['data'];

        final proforma = Pedido.fromJson(proformaData as Map<String, dynamic>);

        debugPrint('✅ PROFORMA creada: ${proforma.numero} - Estado: ${proforma.estadoCodigo}');
        return ApiResponse<Pedido>(
          success: true,
          message: 'Proforma creada exitosamente',
          data: proforma,
        );
      } else {
        // 🔴 Manejo mejorado de errores de stock insuficiente
        String errorMessage = responseData['message'] as String? ?? 'Error al crear proforma';

        if (responseData['tipo_error'] == 'STOCK_INSUFICIENTE') {
          final detallesError = responseData['detalles_error'] as Map<String, dynamic>?;
          if (detallesError != null) {
            final producto = detallesError['producto'] as Map<String, dynamic>?;
            final stockInfo = detallesError['stock_info'] as Map<String, dynamic>?;

            if (producto != null && stockInfo != null) {
              final nombreProducto = producto['nombre'] ?? 'Producto';
              final disponible = stockInfo['disponible'] ?? 0;
              final solicitado = stockInfo['solicitado'] ?? 0;

              errorMessage = '❌ Stock insuficiente para "$nombreProducto"\n'
                  'Disponible: $disponible unidades\n'
                  'Solicitado: $solicitado unidades\n\n'
                  '${responseData['sugerencia'] ?? 'Por favor, ajusta las cantidades.'}';

              debugPrint('⚠️  Error de stock: $errorMessage');
            }
          }
        }

        return ApiResponse<Pedido>(
          success: false,
          message: errorMessage,
          data: null,
        );
      }
    } on DioException catch (e) {
      // 🔴 Manejo mejorado de errores de stock durante la reserva
      String errorMessage = _getErrorMessage(e);

      if (e.response?.statusCode == 422 && e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;

        // Si es error de stock insuficiente
        if (responseData['tipo_error'] == 'STOCK_INSUFICIENTE') {
          final detallesError = responseData['detalles_error'] as Map<String, dynamic>?;
          if (detallesError != null) {
            final producto = detallesError['producto'] as Map<String, dynamic>?;
            final stockInfo = detallesError['stock_info'] as Map<String, dynamic>?;

            if (producto != null && stockInfo != null) {
              final nombreProducto = producto['nombre'] ?? 'Producto';
              final disponible = stockInfo['disponible'] ?? 0;
              final solicitado = stockInfo['solicitado'] ?? 0;

              errorMessage = '❌ Stock insuficiente para "$nombreProducto"\n'
                  'Disponible: $disponible unidades\n'
                  'Solicitado: $solicitado unidades\n\n'
                  '${responseData['sugerencia'] ?? 'Por favor, ajusta las cantidades.'}';

              debugPrint('⚠️  Error de stock: $errorMessage');
            }
          }
        }
      }

      debugPrint('❌ Error creando proforma: $errorMessage');
      return ApiResponse<Pedido>(
        success: false,
        message: errorMessage,
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado al crear proforma: $e');
      return ApiResponse<Pedido>(
        success: false,
        message: 'Error inesperado al crear proforma: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Renovar reservas expiradas de una proforma
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma cuyas reservas necesitan renovación
  ///
  /// Retorna:
  /// - Success: true si las reservas fueron renovadas (válidas por 7 días más)
  /// - Data: Información actualizada de las reservas
  ///
  /// Códigos de error:
  /// - NO_EXPIRED_RESERVATIONS: La proforma no tiene reservas expiradas
  /// - RESERVAS_EXPIRADAS: Error al renovar las reservas
  Future<ApiResponse<Map<String, dynamic>>> renovarReservas(int proformaId) async {
    try {
      debugPrint('🔄 Renovando reservas para proforma #$proformaId');

      final response = await _apiService.post(
        '/proformas/$proformaId/renovar-reservas',
        data: {},
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
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
        message: 'Error inesperado al renovar reservas: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Obtener estadísticas de proformas
  ///
  /// Retorna contadores y métricas agregadas sin cargar todas las proformas.
  /// Ideal para mostrar en dashboards y pantallas de inicio.
  ///
  /// Incluye:
  /// - Total de proformas
  /// - Cantidades por estado (pendiente, aprobada, rechazada, convertida, vencida)
  /// - Montos por estado
  /// - Distribución por canal
  /// - Alertas (vencidas y por vencer)
  /// - Monto total
  ///
  /// Este endpoint es mucho más rápido que cargar todas las proformas
  /// (~2KB vs ~500KB-2MB)
  Future<ApiResponse<ProformaStats>> getStats() async {
    try {
      debugPrint('📊 Obteniendo estadísticas de proformas');

      final response = await _apiService.get('/proformas/estadisticas');

      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final stats = ProformaStats.fromJson(responseData['data'] as Map<String, dynamic>);

        debugPrint('✅ Estadísticas obtenidas: ${stats.total} proformas totales');
        debugPrint('   Pendientes: ${stats.porEstado.pendiente}');
        debugPrint('   Aprobadas: ${stats.porEstado.aprobada}');
        debugPrint('   Vencidas: ${stats.alertas.vencidas}');

        return ApiResponse<ProformaStats>(
          success: true,
          message: 'Estadísticas obtenidas exitosamente',
          data: stats,
        );
      } else {
        return ApiResponse<ProformaStats>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al obtener estadísticas',
          data: null,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: ${_getErrorMessage(e)}');
      return ApiResponse<ProformaStats>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse<ProformaStats>(
        success: false,
        message: 'Error inesperado al obtener estadísticas: ${e.toString()}',
        data: null,
      );
    }
  }

  /// ✅ NUEVO: Actualizar una proforma pendiente
  ///
  /// Este endpoint actualiza una proforma PENDIENTE con nuevos items.
  /// Solo se puede actualizar si está en estado PENDIENTE.
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma a actualizar
  /// - items: Lista de items (productos con cantidades)
  /// - clienteId: ID del cliente (requerido)
  /// - observaciones: Observaciones adicionales (opcional)
  ///
  /// Retorna:
  /// - Success: La proforma actualizada
  /// - Otros errores: Mensajes de validación
  Future<ApiResponse<Pedido>> actualizarProforma({
    required int proformaId,
    required int clienteId,
    required List<Map<String, dynamic>> items,
    String? observaciones,
  }) async {
    try {
      debugPrint('📝 Actualizando proforma #$proformaId');

      final response = await _apiService.put(
        '/proformas/$proformaId',
        data: {
          'cliente_id': clienteId,
          'items': items,
          'observaciones': observaciones,
        },
      );

      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final proforma = Pedido.fromJson(responseData['data'] as Map<String, dynamic>);

        debugPrint('✅ Proforma actualizada: ${proforma.numero}');
        return ApiResponse<Pedido>(
          success: true,
          message: 'Proforma actualizada exitosamente',
          data: proforma,
        );
      } else {
        return ApiResponse<Pedido>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al actualizar proforma',
          data: null,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Error actualizando proforma: ${_getErrorMessage(e)}');
      return ApiResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse<Pedido>(
        success: false,
        message: 'Error inesperado al actualizar proforma: ${e.toString()}',
        data: null,
      );
    }
  }

  /// ✅ NUEVO: Anular una proforma
  ///
  /// Este endpoint anula una proforma PENDIENTE o APROBADA.
  /// No se pueden anular proformas que ya fueron convertidas a venta.
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma a anular
  /// - motivo: Motivo de la anulación (requerido)
  ///
  /// Retorna:
  /// - Success: La proforma anulada (con estado = 'ANULADA')
  /// - Otros errores: Mensajes de validación
  Future<ApiResponse<Pedido>> anularProforma({
    required int proformaId,
    required String motivo,
  }) async {
    try {
      debugPrint('🚫 Rechazando proforma #$proformaId - Motivo: $motivo');

      // ✅ CORREGIDO: Usar endpoint 'rechazar' en lugar de 'anular'
      // ✅ CORREGIDO: Usar parámetro 'comentario' en lugar de 'motivo_anulacion'
      final response = await _apiService.post(
        '/proformas/$proformaId/rechazar',
        data: {
          'comentario': motivo,
        },
      );

      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final proforma = Pedido.fromJson(responseData['data'] as Map<String, dynamic>);

        debugPrint('✅ Proforma anulada: ${proforma.numero}');
        return ApiResponse<Pedido>(
          success: true,
          message: 'Proforma anulada exitosamente',
          data: proforma,
        );
      } else {
        return ApiResponse<Pedido>(
          success: false,
          message: responseData['message'] as String? ?? 'Error al anular proforma',
          data: null,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Error anulando proforma: ${_getErrorMessage(e)}');
      return ApiResponse<Pedido>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return ApiResponse<Pedido>(
        success: false,
        message: 'Error inesperado al anular proforma: ${e.toString()}',
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
