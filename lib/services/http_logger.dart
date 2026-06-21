import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Servicio de logging mejorado para peticiones HTTP
/// Muestra en consola de forma clara y formateada:
/// - URL y método HTTP
/// - Headers importantes
/// - Body/Data enviado (pretty-printed si es JSON)
/// - Status code y response data
/// - Errores detallados con body de error
class HttpLogger {
  static const String _requestPrefix = '📤 REQUEST';
  static const String _responsePrefix = '✅ RESPONSE';
  static const String _errorPrefix = '❌ ERROR';

  /// Log de petición HTTP
  static void logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    final method = options.method.toUpperCase();
    final uri = options.uri.toString();

    debugPrint('═' * 80);
    debugPrint('📤 $method → $uri');
    debugPrint('');

    // Mostrar headers importantes (sin sensibles)
    if (options.headers.isNotEmpty) {
      debugPrint('Headers:');
      options.headers.forEach((key, value) {
        if (!_isSensitiveHeader(key)) {
          debugPrint('  $key: $value');
        }
      });
      debugPrint('');
    }

    // Mostrar body/data enviado
    if (options.data != null) {
      debugPrint('Request Body:');
      String bodyDisplay = '';
      if (options.data is String) {
        bodyDisplay = options.data;
      } else if (options.data is Map) {
        bodyDisplay = _prettyPrintJson(options.data);
        // ✅ NUEVO 2026-06-14: Destacar campos importantes (con validación segura)
        try {
          if (options.data is Map<String, dynamic>) {
            _highlightDeliveryFields(options.data as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('⚠️ Error al destacar campos: $e');
        }
      } else if (options.data is List) {
        bodyDisplay = _prettyPrintJson(options.data);
      } else {
        bodyDisplay = options.data.toString();
      }
      debugPrint(bodyDisplay);
    }
    debugPrint('═' * 80);
  }

  /// Log de respuesta HTTP exitosa
  static void logResponse(Response response) {
    if (!kDebugMode) return;

    final uri = response.requestOptions.uri.toString();
    final method = response.requestOptions.method.toUpperCase();
    final statusCode = response.statusCode ?? 200;

    debugPrint('═' * 80);
    debugPrint('✅ $method $statusCode → $uri');
    debugPrint('');

    // Mostrar response body si existe
    if (response.data != null) {
      debugPrint('Response Body:');
      String bodyDisplay = '';
      if (response.data is String) {
        bodyDisplay = response.data;
      } else if (response.data is Map || response.data is List) {
        bodyDisplay = _prettyPrintJson(response.data);
      } else {
        bodyDisplay = response.data.toString();
      }
      debugPrint(bodyDisplay);
    }
    debugPrint('═' * 80);
  }

  /// Log de error HTTP
  static void logError(DioException error) {
    if (!kDebugMode) return;

    final status = error.response?.statusCode ?? 'unknown';
    final method = error.requestOptions.method.toUpperCase();
    final uri = error.requestOptions.uri.toString();

    debugPrint('═' * 80);
    debugPrint('❌ ERROR $status: ${error.message}');
    debugPrint('$method → $uri');
    debugPrint('');

    // Mostrar request data que generó el error
    if (error.requestOptions.data != null) {
      debugPrint('Request Data (que causó error):');
      String bodyDisplay = '';
      if (error.requestOptions.data is String) {
        bodyDisplay = error.requestOptions.data;
      } else if (error.requestOptions.data is Map || error.requestOptions.data is List) {
        bodyDisplay = _prettyPrintJson(error.requestOptions.data);
      } else {
        bodyDisplay = error.requestOptions.data.toString();
      }
      debugPrint(bodyDisplay);
      debugPrint('');
    }

    // Mostrar error response si existe
    if (error.response?.data != null) {
      debugPrint('Error Response:');
      String bodyDisplay = '';
      if (error.response!.data is String) {
        bodyDisplay = error.response!.data;
      } else if (error.response!.data is Map || error.response!.data is List) {
        bodyDisplay = _prettyPrintJson(error.response!.data);
      } else {
        bodyDisplay = error.response!.data.toString();
      }
      debugPrint(bodyDisplay);
    }

    debugPrint('═' * 80);
  }

  /// ✅ NUEVO: Destacar campos importantes de entrega
  static void _highlightDeliveryFields(Map<String, dynamic> data) {
    final relevantFields = [
      'tipo_entrega',
      'tipo_confirmacion',
      'tipo_novedad',
      'estado_pago',
      'monto_recibido',
      'fotos',
      'desglose_pagos',
    ];

    final highlighted = <String, dynamic>{};
    data.forEach((key, value) {
      if (relevantFields.contains(key)) {
        highlighted[key] = value;
      }
    });

    if (highlighted.isNotEmpty) {
      debugPrint('');
      debugPrint('⚠️ CAMPOS IMPORTANTES DE ENTREGA:');
      highlighted.forEach((key, value) {
        if (value is List) {
          debugPrint('  ✓ $key: ${value.length} items');
        } else if (value is Map) {
          debugPrint('  ✓ $key: ${value.keys.toList()}');
        } else {
          debugPrint('  ✓ $key: $value');
        }
      });
      debugPrint('');
    }
  }

  /// Verificar si un header es sensible
  static bool _isSensitiveHeader(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('authorization') ||
        lowerKey.contains('token') ||
        lowerKey.contains('password') ||
        lowerKey.contains('secret') ||
        lowerKey.contains('cookie');
  }

  /// Pretty print JSON con formato legible
  static String _prettyPrintJson(dynamic json) {
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
