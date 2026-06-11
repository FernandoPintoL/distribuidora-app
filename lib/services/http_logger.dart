import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Servicio de logging mejorado para peticiones HTTP
/// Muestra en consola de forma clara y formateada:
/// - URL y método HTTP
/// - Headers (sin información sensible)
/// - Body/Data enviado (pretty-printed si es JSON)
/// - Status code y response data
/// - Errores detallados
class HttpLogger {
  static const String _requestPrefix = '📤 REQUEST';
  static const String _responsePrefix = '✅ RESPONSE';
  static const String _errorPrefix = '❌ ERROR';

  /// Log de petición HTTP (SIMPLIFICADO)
  static void logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    debugPrint('📤 ${options.method.toUpperCase()} → ${options.uri}');

    // Mostrar body si existe
    if (options.data != null) {
      String bodyDisplay = '';

      if (options.data is String) {
        bodyDisplay = options.data;
      } else if (options.data is Map || options.data is List) {
        bodyDisplay = _prettyPrintJson(options.data);
      } else {
        bodyDisplay = options.data.toString();
      }

      debugPrint('   📦 Body: $bodyDisplay');
    }
  }

  /// Log de respuesta HTTP exitosa (SIMPLIFICADO)
  static void logResponse(Response response) {
    if (!kDebugMode) return;

    // Solo mostrar status y URL
    final uri = response.requestOptions.uri.toString();
    final method = response.requestOptions.method.toUpperCase();

    debugPrint('✅ $method ${response.statusCode} → $uri');
  }

  /// Log de error HTTP (SIMPLIFICADO)
  static void logError(DioException error) {
    if (!kDebugMode) return;

    // Solo mostrar error, status y URL
    final status = error.response?.statusCode ?? 'unknown';
    debugPrint('❌ Error $status: ${error.message} → ${error.requestOptions.uri}');
  }

  /// Enmascarar headers sensibles
  static String _maskSensitiveHeader(String key, dynamic value) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('authorization') ||
        lowerKey.contains('token') ||
        lowerKey.contains('password') ||
        lowerKey.contains('secret')) {
      return '***REDACTED***';
    }
    return value.toString();
  }

  /// Pretty print JSON
  static String _prettyPrintJson(dynamic json, {int indent = 0}) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  /// Obtener Content-Type de los headers
  static String _getContentType(Headers headers) {
    final contentType = headers.value('content-type') ?? 'unknown';
    return contentType.split(';').first.trim();
  }

  /// Detectar si el Content-Type es binario
  static bool _isBinaryContentType(String contentType) {
    final binaryTypes = [
      'image/',
      'application/pdf',
      'application/zip',
      'application/octet-stream',
      'video/',
      'audio/',
      'application/msword',
      'application/vnd.openxmlformats',
    ];
    return binaryTypes.any((type) => contentType.toLowerCase().contains(type));
  }

  /// Obtener tamaño de la respuesta
  static int _getResponseSize(dynamic data) {
    if (data is List<int>) {
      return data.length;
    } else if (data is String) {
      return data.length;
    } else if (data is Uint8List) {
      return data.length;
    }
    return 0;
  }
}
