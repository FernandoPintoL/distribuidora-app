import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/carrito.dart';
import '../models/carrito_item.dart';
import 'api_service.dart';

/// Servicio para gestionar persistencia de carritos en la base de datos
class CarritoService {
  final ApiService _apiService;

  CarritoService(this._apiService);

  /// Guardar carrito en la base de datos
  /// POST /api/carritos/guardar
  Future<Carrito?> guardarCarrito(Carrito carrito, int usuarioId) async {
    try {
      debugPrint('💾 Guardando carrito en base de datos...');
      debugPrint('   Usuario ID: $usuarioId');
      debugPrint('   Items en carrito: ${carrito.items.length}');
      debugPrint('   Subtotal: ${carrito.subtotal.toStringAsFixed(2)} Bs');

      final response = await _apiService.post(
        '/carritos/guardar',
        data: {
          'usuario_id': usuarioId,
          'items': carrito.items.map((item) => {
            'producto_id': item.producto.id,
            'cantidad': item.cantidad,
            'precio_unitario': item.precioUnitario,
            'observaciones': item.observaciones,
          }).toList(),
          'estado': 'guardado',
          'subtotal': carrito.subtotal,
          'impuesto': carrito.impuesto,
          'total': carrito.total,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final carritoGuardado = Carrito.fromJson(response.data['data']);
        debugPrint('✅ Carrito guardado exitosamente');
        debugPrint('   ID generado: ${carritoGuardado.id}');
        return carritoGuardado;
      }

      debugPrint('❌ Error: Status ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error al guardar carrito: ${_getErrorMessage(e)}');
      return null;
    } catch (e) {
      debugPrint('❌ Error al guardar carrito: $e');
      return null;
    }
  }

  /// Recuperar último carrito guardado del usuario
  /// GET /carritos/usuario/{usuarioId}/ultimo
  /// Retorna null si no hay carrito guardado (404 es válido, no es error)
  Future<Carrito?> recuperarUltimoCarrito(int usuarioId) async {
    try {
      debugPrint('📂 Recuperando último carrito guardado...');
      debugPrint('   Usuario ID: $usuarioId');

      final response = await _apiService.get(
        '/carritos/usuario/$usuarioId/ultimo',
      );

      // 200 OK - Carrito encontrado
      if (response.statusCode == 200 && response.data['data'] != null) {
        final carrito = Carrito.fromJson(response.data['data']);
        debugPrint('✅ Carrito recuperado exitosamente');
        debugPrint('   Items: ${carrito.items.length}');
        debugPrint('   Subtotal: ${carrito.subtotal.toStringAsFixed(2)} Bs');
        return carrito;
      }

      // 404 Not Found - No hay carrito guardado (respuesta válida, no error)
      if (response.statusCode == 404) {
        debugPrint('ℹ️  No hay carrito guardado para este usuario (404)');
        return null;
      }

      // Otro status code
      debugPrint('ℹ️  No hay carrito guardado para este usuario (Status: ${response.statusCode})');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error crítico al recuperar carrito: ${_getErrorMessage(e)}');
      return null;
    } catch (e) {
      debugPrint('❌ Error inesperado al recuperar carrito: $e');
      return null;
    }
  }

  /// Obtener historial de carritos abandonados del usuario
  /// GET /carritos/usuario/{usuarioId}/abandonados
  /// Retorna lista vacía si no hay carritos abandonados (404 es válido, no es error)
  Future<List<Carrito>> obtenerCarritosAbandonados(int usuarioId) async {
    try {
      debugPrint('📜 Obteniendo carritos abandonados...');
      debugPrint('   Usuario ID: $usuarioId');

      final response = await _apiService.get(
        '/carritos/usuario/$usuarioId/abandonados',
      );

      // 200 OK - Carritos encontrados
      if (response.statusCode == 200 && response.data['data'] is List) {
        final carritos = (response.data['data'] as List)
            .map((item) => Carrito.fromJson(item))
            .toList();

        debugPrint('✅ ${carritos.length} carritos abandonados encontrados');
        return carritos;
      }

      // 404 Not Found - No hay carritos abandonados (respuesta válida, no error)
      if (response.statusCode == 404) {
        debugPrint('ℹ️  No hay carritos abandonados (404)');
        return [];
      }

      // Otro status code - retornar lista vacía
      debugPrint('ℹ️  No hay carritos abandonados (Status: ${response.statusCode})');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ Error crítico al obtener carritos abandonados: ${_getErrorMessage(e)}');
      return [];
    } catch (e) {
      debugPrint('❌ Error inesperado al obtener carritos abandonados: $e');
      return [];
    }
  }

  /// Eliminar carrito (marcarlo como eliminado)
  /// DELETE /api/carritos/{carritoId}
  Future<bool> eliminarCarrito(int carritoId) async {
    try {
      debugPrint('🗑️  Eliminando carrito...');
      debugPrint('   Carrito ID: $carritoId');

      final response = await _apiService.delete(
        '/carritos/$carritoId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Carrito eliminado exitosamente');
        return true;
      }

      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error al eliminar carrito: ${_getErrorMessage(e)}');
      return false;
    } catch (e) {
      debugPrint('❌ Error al eliminar carrito: $e');
      return false;
    }
  }

  /// Convertir carrito a proforma (pedido cotizado)
  /// POST /api/proformas
  Future<Map<String, dynamic>?> convertirAProforma(
    int carritoId,
    int clienteId,
    List<CarritoItem> items,
  ) async {
    try {
      debugPrint('📋 Convirtiendo carrito a proforma...');
      debugPrint('   Carrito ID: $carritoId');
      debugPrint('   Cliente ID: $clienteId');
      debugPrint('   Items: ${items.length}');

      final response = await _apiService.post(
        '/proformas',
        data: {
          'cliente_id': clienteId,
          'carrito_id': carritoId,
          'productos': items.map((item) => {
            'producto_id': item.producto.id,
            'cantidad': item.cantidad,
            'precio_unitario': item.precioUnitario,
          }).toList(),
        },
      );

      if (response.statusCode == 201) {
        final proforma = response.data['data'] as Map<String, dynamic>;

        debugPrint('✅ Proforma creada exitosamente');
        debugPrint('   ID: ${proforma['id']}');
        debugPrint('   Número: ${proforma['numero']}');
        debugPrint('   Estado: ${proforma['estado']}');

        return proforma;
      }

      debugPrint('❌ Error: Status ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error al convertir a proforma: ${_getErrorMessage(e)}');
      return null;
    } catch (e) {
      debugPrint('❌ Error al convertir a proforma: $e');
      return null;
    }
  }

  /// Actualizar estado del carrito
  /// PATCH /api/carritos/{carritoId}
  Future<bool> actualizarEstadoCarrito(
    int carritoId,
    String nuevoEstado,
  ) async {
    try {
      debugPrint('🔄 Actualizando estado del carrito...');
      debugPrint('   Carrito ID: $carritoId');
      debugPrint('   Nuevo estado: $nuevoEstado');

      final response = await _apiService.patch(
        '/carritos/$carritoId',
        data: {'estado': nuevoEstado},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Estado actualizado a: $nuevoEstado');
        return true;
      }

      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error al actualizar estado: ${_getErrorMessage(e)}');
      return false;
    } catch (e) {
      debugPrint('❌ Error al actualizar estado: $e');
      return false;
    }
  }

  /// Obtener estadísticas de carritos del usuario
  /// GET /api/carritos/usuario/{usuarioId}/estadisticas
  Future<Map<String, dynamic>> obtenerEstadisticasCarritos(int usuarioId) async {
    try {
      debugPrint('📊 Obteniendo estadísticas de carritos...');
      debugPrint('   Usuario ID: $usuarioId');

      final response = await _apiService.get(
        '/carritos/usuario/$usuarioId/estadisticas',
      );

      if (response.statusCode == 200 && response.data['data'] is Map) {
        final estadisticas = response.data['data'] as Map<String, dynamic>;

        debugPrint('✅ Estadísticas obtenidas:');
        debugPrint('   Total: ${estadisticas['carritos_totales']}');
        debugPrint('   Completados: ${estadisticas['carritos_completados']}');
        debugPrint('   Abandonados: ${estadisticas['carritos_abandonados']}');
        return estadisticas;
      }

      return {};
    } on DioException catch (e) {
      debugPrint('❌ Error al obtener estadísticas: ${_getErrorMessage(e)}');
      return {};
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Helper para extraer mensaje de error de DioException
  String _getErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('message')) {
        return data['message'];
      }
      if (data.containsKey('error')) {
        return data['error'];
      }
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
