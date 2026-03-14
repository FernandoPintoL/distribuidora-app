import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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

  /// Log de petición HTTP
  static void logRequest(RequestOptions options) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
      '═══════════════════════════════════════════════════════════════',
    );
    buffer.writeln('$_requestPrefix: ${options.method.toUpperCase()}');
    buffer.writeln('URL: ${options.uri}');

    // Headers (sin sensibles)
    buffer.writeln('\n📋 Headers:');
    options.headers.forEach((key, value) {
      final displayValue = _maskSensitiveHeader(key, value);
      buffer.writeln('  $key: $displayValue');
    });

    // Query parameters
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('\n📌 Query Parameters:');
      options.queryParameters.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    // Body/Data
    if (options.data != null) {
      buffer.writeln('\n📦 Body/Data:');
      if (options.data is FormData) {
        buffer.writeln('  [FormData]');
        for (var field in options.data.fields) {
          buffer.writeln('    ${field.key}: ${field.value}');
        }
        if (options.data.files.isNotEmpty) {
          buffer.writeln('  [Files]');
          for (var file in options.data.files) {
            buffer.writeln('    ${file.key}: ${file.value.filename}');
          }
        }
      } else if (options.data is String) {
        try {
          final decoded = jsonDecode(options.data);
          buffer.writeln(_prettyPrintJson(decoded, indent: 2));
        } catch (_) {
          buffer.writeln('  ${options.data}');
        }
      } else if (options.data is Map) {
        buffer.writeln(_prettyPrintJson(options.data, indent: 2));
      } else {
        buffer.writeln('  ${options.data.toString()}');
      }
    }

    buffer.writeln(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint(buffer.toString());
  }

  /// Log de respuesta HTTP exitosa
  static void logResponse(Response response) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
      '───────────────────────────────────────────────────────────────',
    );
    buffer.writeln('$_responsePrefix: ${response.statusCode}');
    buffer.writeln('URL: ${response.requestOptions.uri}');
    buffer.writeln('Tiempo: ${response.realUri}');

    // Headers de respuesta
    buffer.writeln('\n📋 Response Headers:');
    response.headers.forEach((key, values) {
      if (values.isNotEmpty) {
        buffer.writeln('  $key: ${values.first}');
      }
    });

    // Body/Data
    if (response.data != null) {
      buffer.writeln('\n📦 Response Data:');
      if (response.data is Map || response.data is List) {
        buffer.writeln(_prettyPrintJson(response.data, indent: 2));
      } else if (response.data is String) {
        try {
          final decoded = jsonDecode(response.data);
          buffer.writeln(_prettyPrintJson(decoded, indent: 2));
        } catch (_) {
          buffer.writeln('  ${response.data}');
        }
      } else {
        buffer.writeln('  ${response.data.toString()}');
      }
    }

    buffer.writeln(
      '───────────────────────────────────────────────────────────────',
    );
    debugPrint(buffer.toString());
  }

  /// Log de error HTTP
  static void logError(DioException error) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
      '╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳',
    );
    buffer.writeln('$_errorPrefix: ${error.type}');
    buffer.writeln('Status Code: ${error.response?.statusCode}');
    buffer.writeln('URL: ${error.requestOptions.uri}');
    buffer.writeln('Message: ${error.message}');

    // Detalles del error
    if (error.response != null) {
      buffer.writeln('\n📋 Request Headers:');
      error.requestOptions.headers.forEach((key, value) {
        final displayValue = _maskSensitiveHeader(key, value);
        buffer.writeln('  $key: $displayValue');
      });

      if (error.requestOptions.data != null) {
        buffer.writeln('\n📦 Request Data:');
        if (error.requestOptions.data is Map) {
          buffer.writeln(
            _prettyPrintJson(error.requestOptions.data, indent: 2),
          );
        } else {
          buffer.writeln('  ${error.requestOptions.data}');
        }
      }

      buffer.writeln('\n📋 Response Headers:');
      error.response!.headers.forEach((key, values) {
        if (values.isNotEmpty) {
          buffer.writeln('  $key: ${values.first}');
        }
      });

      if (error.response?.data != null) {
        buffer.writeln('\n📦 Response Data:');
        if (error.response?.data is Map || error.response?.data is List) {
          buffer.writeln(_prettyPrintJson(error.response?.data, indent: 2));
        } else if (error.response?.data is String) {
          try {
            final decoded = jsonDecode(error.response?.data);
            buffer.writeln(_prettyPrintJson(decoded, indent: 2));
          } catch (_) {
            buffer.writeln('  ${error.response?.data}');
          }
        } else {
          buffer.writeln('  ${error.response?.data.toString()}');
        }
      }
    }

    buffer.writeln(
      '╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳╳',
    );
    // debugPrint(buffer.toString());
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
}
