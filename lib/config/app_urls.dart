import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración centralizada de URLs de la aplicación
/// Maneja automáticamente cambios entre desarrollo y producción
class AppUrls {
  static late String _baseUrl;
  static late String _baseUrlImg;
  static late String _publicPricesUrl;
  static late String _publicStockUrl;

  /// Inicializar URLs desde .env (llamar en main.dart)
  static void initialize() {
    _baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.100.22:8000/api';
    _baseUrlImg = dotenv.env['BASE_URL_IMG'] ?? 'http://192.168.100.22:8000/storage/';
    _publicPricesUrl = dotenv.env['PUBLIC_PRICES_URL'] ?? 'http://192.168.100.22:8000/public/precios';
    _publicStockUrl = dotenv.env['PUBLIC_STOCK_URL'] ?? 'http://192.168.100.22:8000/public/precios-stock';

    debugPrintUrls();
  }

  /// URL base para la API
  static String get baseUrl => _baseUrl;

  /// URL base para imágenes
  static String get baseUrlImg => _baseUrlImg;

  /// URL para el catálogo de precios públicos
  static String get publicPricesUrl => _publicPricesUrl;

  /// URL para el catálogo de stock públicos
  static String get publicStockUrl => _publicStockUrl;

  /// Debug: Mostrar URLs configuradas (solo en desarrollo)
  static void debugPrintUrls() {
    debugPrint('🌐 ============= URLs Configuration =============');
    debugPrint('📍 Base URL: $_baseUrl');
    debugPrint('🖼️  Images URL: $_baseUrlImg');
    debugPrint('💰 Public Prices URL: $_publicPricesUrl');
    debugPrint('📦 Public Stock URL: $_publicStockUrl');
    debugPrint('🌐 ==========================================');
  }

  /// Construir URL completa para endpoints API
  /// Ejemplo: buildUrl('/productos') → 'http://localhost:8000/api/productos'
  static String buildUrl(String endpoint) {
    return '$_baseUrl$endpoint';
  }

  /// Construir URL completa para imágenes
  /// Ejemplo: buildImageUrl('productos/image.jpg') → 'http://localhost:8000/storage/productos/image.jpg'
  static String buildImageUrl(String imagePath) {
    return '$_baseUrlImg$imagePath';
  }
}
