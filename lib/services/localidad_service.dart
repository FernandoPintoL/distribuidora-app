import 'package:flutter/foundation.dart';
import '../models/localidad.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class LocalidadService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<Localidad>>> obtenerLocalidades() async {
    try {
      debugPrint('📤 GET → /api/localidades');

      final response = await _apiService.get('/localidades');

      final data = response.data as Map<String, dynamic>;
      final localidades = (data['data'] as List)
          .map((loc) => Localidad.fromJson(loc as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Localidades obtenidas: ${localidades.length}');

      return ApiResponse(
        success: true,
        data: localidades,
        message: 'Localidades obtenidas exitosamente',
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo localidades: $e');
      return ApiResponse(
        success: false,
        data: [],
        message: 'Error al obtener localidades: $e',
      );
    }
  }
}
