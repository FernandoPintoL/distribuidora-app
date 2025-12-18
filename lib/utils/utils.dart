import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  /// Construye la URL completa para una imagen desde el servidor
  /// Si el path es null o vacío, retorna null
  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    // Si ya es una URL completa, retornarla tal cual
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Obtener la URL base del servidor
    String baseUrl;
    if (dotenv.env.isNotEmpty) {
      final envUrl = dotenv.env['BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        // Remover '/api' del final si existe para construir la URL de storage
        baseUrl = envUrl.replaceAll('/api', '');
        debugPrint('🌐 Usando BASE_URL del .env: $envUrl -> $baseUrl');
      } else {
        // URL por defecto si no hay configuración
        baseUrl = 'http://192.168.5.44:9000';
        debugPrint(
          '⚠️ BASE_URL no encontrado en .env, usando default: $baseUrl',
        );
      }
    } else {
      // URL por defecto
      baseUrl = 'http://192.168.5.44:9000';
      debugPrint('⚠️ dotenv no cargado, usando default: $baseUrl');
    }

    // Construir la URL completa
    // Las imágenes pueden estar en diferentes paths según la configuración del servidor
    // Intentar primero con /storage/ (Laravel estándar)
    final storageUrl = '$baseUrl/storage/$imagePath';
    debugPrint('🔗 URL de imagen construida: $storageUrl');

    return storageUrl;
  }

  /// Construye la URL completa para una imagen de perfil de cliente
  static String? buildProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('📁 Path de imagen de perfil es null o vacío');
      return null;
    }

    debugPrint('📁 Path de imagen de perfil recibido: $imagePath');
    return buildImageUrl(imagePath);
  }

  /// Método alternativo que retorna múltiples URLs posibles para intentar
  static List<String> buildMultipleImageUrls(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('📁 Image path is null or empty');
      return [];
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      debugPrint('🌐 Image path is already a full URL: $imagePath');
      return [imagePath];
    }

    String baseUrl = 'http://192.168.5.44:9000';

    if (dotenv.env.isNotEmpty) {
      final envUrl = dotenv.env['BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        baseUrl = envUrl.replaceAll('/api', '');
        debugPrint('🌐 Using base URL from .env: $baseUrl');
      } else {
        debugPrint('⚠️ BASE_URL not found in .env, using default: $baseUrl');
      }
    } else {
      debugPrint('⚠️ dotenv not loaded, using default base URL: $baseUrl');
    }

    final urls = [
      '$baseUrl/storage/$imagePath', // Laravel storage:link
      '$baseUrl/uploads/$imagePath', // Common uploads folder
      '$baseUrl/images/$imagePath', // Simple images folder
      '$baseUrl/$imagePath', // Root path
    ];

    debugPrint('🔗 Generated URLs for image "$imagePath":');
    for (int i = 0; i < urls.length; i++) {
      debugPrint('  ${i + 1}. ${urls[i]}');
    }

    return urls;
  }
}
