import 'package:flutter/foundation.dart';
import '../models/estado_logistico.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class EstadoLogisticoService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<EstadoLogistico>>> obtenerEstadosPorCategoria(
    String categoria,
  ) async {
    try {
      debugPrint('📤 GET → /api/estados/$categoria');

      final response = await _apiService.get('/estados/$categoria');

      final data = response.data as Map<String, dynamic>;
      final estados = (data['data'] as List)
          .map((estado) => EstadoLogistico.fromJson(estado as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Estados obtenidos: ${estados.length}');

      return ApiResponse(
        success: true,
        data: estados,
        message: 'Estados obtenidos exitosamente',
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo estados: $e');
      return ApiResponse(
        success: false,
        data: [],
        message: 'Error al obtener estados: $e',
      );
    }
  }
}
