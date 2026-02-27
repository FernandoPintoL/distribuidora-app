import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FiltrosProductoService {
  final ApiService _apiService = ApiService();

  /// Obtiene los filtros disponibles (categorías y marcas) para la app
  ///
  /// Retorna un mapa con:
  /// - 'categorias': List de Map con {id, nombre}
  /// - 'marcas': List de Map con {id, nombre}
  Future<Map<String, dynamic>> getFiltros() async {
    try {
      final response = await _apiService.get('/app/productos/filtros');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final filtrosData = data['data'] as Map<String, dynamic>;
          return {
            'categorias': List<Map<String, dynamic>>.from(
              (filtrosData['categorias'] as List? ?? []).map(
                (cat) => Map<String, dynamic>.from(cat),
              ),
            ),
            'marcas': List<Map<String, dynamic>>.from(
              (filtrosData['marcas'] as List? ?? []).map(
                (marca) => Map<String, dynamic>.from(marca),
              ),
            ),
          };
        }
      }

      debugPrint('❌ [FiltrosProductoService] Error: respuesta inesperada');
      return {'categorias': [], 'marcas': []};
    } on DioException catch (e) {
      debugPrint('❌ [FiltrosProductoService] DioException: ${e.message}');
      return {'categorias': [], 'marcas': []};
    } catch (e) {
      debugPrint('❌ [FiltrosProductoService] Error inesperado: $e');
      return {'categorias': [], 'marcas': []};
    }
  }
}
