import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/banner_publicitario.dart';
import 'api_service.dart';

class BannerPublicitarioService {
  final ApiService _apiService = ApiService();

  /// Obtener banners publicitarios vigentes y activos
  /// Retorna una lista de banners para mostrar en la app
  Future<ApiResponse<List<BannerPublicitario>>> obtenerBannersActivos() async {
    try {
      final response = await _apiService.get('/banners-publicitarios');
      final data = response.data as Map<String, dynamic>;

      debugPrint('[BANNER_SERVICE] Respuesta API: ${data.toString()}');

      if (data['success'] == true && data['data'] is List) {
        final banners = (data['data'] as List)
            .map((item) {
              final banner = BannerPublicitario.fromJson(item as Map<String, dynamic>);
              // Completar la URL de la imagen con la baseUrl del API
              _completarUrlImagen(banner);
              return banner;
            })
            .toList();

        debugPrint(
          '🎯 [BANNER_SERVICE] Banners cargados: ${banners.length}',
        );

        return ApiResponse(
          success: true,
          data: banners,
          message: 'Banners cargados correctamente',
        );
      }

      return ApiResponse(
        success: false,
        message: 'Formato de respuesta inválido',
        data: [],
      );
    } on DioException catch (e) {
      debugPrint('❌ [BANNER_SERVICE] Error DIO: ${e.message}');
      return ApiResponse(
        success: false,
        message: 'Error al cargar banners: ${e.message}',
        data: [],
      );
    } catch (e) {
      debugPrint('❌ [BANNER_SERVICE] Error inesperado: ${e.toString()}');
      return ApiResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: [],
      );
    }
  }

  /// Completar la URL de la imagen del banner
  /// Convierte rutas relativas a URLs absolutas
  void _completarUrlImagen(BannerPublicitario banner) {
    if (banner.imagen.startsWith('http')) {
      // Ya es una URL completa
      return;
    }

    // Obtener baseUrl del ApiService (removiendo /api al final)
    final baseUrl = _apiService.baseUrl.replaceAll('/api', '');

    // Construir URL completa
    if (banner.imagen.startsWith('/')) {
      banner.imagen = '$baseUrl${banner.imagen}';
    } else {
      banner.imagen = '$baseUrl/storage/${banner.imagen}';
    }

    debugPrint('🖼️  [BANNER_SERVICE] URL completada: ${banner.imagen}');
  }
}
