import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'http_logger.dart';

class ApiService {
  static const String tokenKey = 'auth_token';

  late Dio _dio;
  String? _token;

  String get baseUrl {
    if (dotenv.env.isEmpty) {
      // Cargar variables de entorno si no están cargadas
      dotenv.load(fileName: ".env");
    }
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      debugPrint(
        '⚠️  Warning: BASE_URL not found in .env file, using default URL',
      );
      return 'http://192.168.100.21:8000/api';
    }
    debugPrint('🌐 Using BASE_URL from .env: $url');
    return url;
  }

  // ✅ NUEVO: Getter público para acceder a Dio directamente (necesario para descargas con autenticación)
  Dio get dio {
    _initializeDio();
    return _dio;
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          // Do not set Content-Type by default so Dio can set it per-request
          'Accept': 'application/json',
        },
        // No lanzar excepción en errores 4xx/5xx - permitir que el código maneje los status codes
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    _dio.interceptors.addAll([_authInterceptor(), _loggingInterceptor()]);
  }

  bool _isRefreshing = false;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token == null) {
          await _loadToken();
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si es un 401 y NO es la ruta de refresh (para evitar loop infinito)
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/refresh') &&
            !_isRefreshing) {
          _isRefreshing = true;

          try {
            debugPrint('🔄 401 Unauthorized - Attempting token refresh...');
            await _handleTokenExpiration();

            // Si después del refresh tenemos token, reintentar la petición original
            if (_token != null) {
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $_token';
              final response = await _dio.fetch(options);
              _isRefreshing = false;
              return handler.resolve(response);
            }
          } catch (e) {
            debugPrint('❌ Error during token refresh: $e');
          } finally {
            _isRefreshing = false;
          }
        }

        return handler.next(error);
      },
    );
  }

  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        HttpLogger.logRequest(options);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        HttpLogger.logResponse(response);
        return handler.next(response);
      },
      onError: (error, handler) {
        HttpLogger.logError(error);
        return handler.next(error);
      },
    );
  }

  Future<void> _loadToken() async {
    // Intentar primero con SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(tokenKey);
      if (_token != null) {
        debugPrint('✅ Token loaded from SharedPreferences');
        return;
      } else {
        debugPrint('ℹ️ No token found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading token from SharedPreferences: $e');
    }

    // Fallback: intentar cargar del Secure Storage
    try {
      const storage = FlutterSecureStorage();
      _token = await storage.read(key: tokenKey);
      if (_token != null) {
        debugPrint('✅ Token loaded from Secure Storage (fallback)');
        return;
      }
    } catch (secureError) {
      debugPrint('⚠️ Error loading token from Secure Storage: $secureError');
    }

    // Reintento con SharedPreferences después de delay
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(tokenKey);
      if (_token != null) {
        debugPrint('✅ Token loaded from SharedPreferences (retry)');
        return;
      }
    } catch (retryError) {
      debugPrint('⚠️ Token load retry failed: $retryError');
    }

    if (_token == null) {
      debugPrint('❌ No token found anywhere');
    }
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    bool saved = false;

    // Intentar primero con SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      debugPrint('✅ Token saved successfully to SharedPreferences');
      saved = true;
    } catch (e) {
      debugPrint('❌ Error saving token to SharedPreferences: $e');

      // Fallback: usar flutter_secure_storage
      try {
        const storage = FlutterSecureStorage();
        await storage.write(key: tokenKey, value: token);
        debugPrint('✅ Token saved to Secure Storage (fallback)');
        saved = true;
      } catch (secureError) {
        debugPrint('❌ Error saving token to Secure Storage: $secureError');

        // Reintento con SharedPreferences después de delay
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(tokenKey, token);
          debugPrint('✅ Token saved successfully to SharedPreferences (retry)');
          saved = true;
        } catch (retryError) {
          debugPrint('❌ Token save retry failed: $retryError');
          debugPrint(
              '⚠️ Token stored in memory only. Some features may not work after app restart.');
        }
      }
    }

    if (saved) {
      debugPrint('✅ Token persistence confirmed');
    }
  }

  Future<void> _clearToken() async {
    _token = null;
    bool cleared = false;

    // Intentar limpiar de SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      debugPrint('✅ Token cleared from SharedPreferences');
      cleared = true;
    } catch (e) {
      debugPrint('⚠️ Error clearing token from SharedPreferences: $e');
    }

    // También limpiar del Secure Storage
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: tokenKey);
      debugPrint('✅ Token cleared from Secure Storage');
      cleared = true;
    } catch (secureError) {
      debugPrint('⚠️ Error clearing token from Secure Storage: $secureError');
    }

    // Reintento si nada funcionó
    if (!cleared) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
        debugPrint('✅ Token cleared from SharedPreferences (retry)');
      } catch (retryError) {
        debugPrint('⚠️ Token clear retry failed: $retryError');
      }
    }
  }

  Future<void> _handleTokenExpiration() async {
    debugPrint('🔄 Token expired, attempting to refresh...');

    try {
      // Intentar renovar el token
      final response = await _dio.post('/refresh');

      if (response.statusCode == 200) {
        // Laravel Sanctum refresh retorna: { "token": "nuevo_token" }
        final newToken = response.data['token'];
        if (newToken != null) {
          await _saveToken(newToken);
          debugPrint('✅ Token refreshed successfully');
          return;
        } else {
          debugPrint('⚠️ Token refresh response missing token field');
        }
      } else {
        debugPrint('⚠️ Token refresh failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
    }

    // Si el refresh falla, limpiar el token
    debugPrint('🚫 Clearing token - user will need to login again');
    await _clearToken();
  }

  // Métodos HTTP
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    // When sending FormData, don't manually set Content-Type: multipart/form-data
    // so Dio can set the proper boundary. We keep isFormData to allow callers
    // to indicate multipart behavior.
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: isFormData
          ? Options()
          : Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: isFormData
          ? Options()
          : Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(path, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  // Métodos de utilidad
  Future<void> setToken(String token) async {
    await _saveToken(token);
  }

  Future<void> clearToken() async {
    await _clearToken();
  }

  Future<String?> getToken() async {
    if (_token == null) {
      await _loadToken();
    }
    return _token;
  }

  /// ✅ NUEVO: Descargar PDF de proformas filtradas (por IDs)
  /// Descarga el PDF directamente del endpoint API
  /// Retorna los bytes del PDF para que la pantalla los maneje
  Future<List<int>> descargarPdfProformas({
    required String ids,
    required String formato,
  }) async {
    try {
      final url = '$baseUrl/proformas/descargar-pdf?ids=$ids&formato=$formato';

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'application/pdf',
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<int>;
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error descargando PDF: $e');
      rethrow;
    }
  }

  /// ✅ NUEVO: Descargar PDF de proformas con filtros (búsqueda completa)
  /// Envía filtros al backend para obtener TODOS los resultados que coincidan
  /// El backend busca sin paginación y genera el PDF completo
  Future<List<int>> descargarPdfProformasConFiltros({
    String? busqueda,
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    DateTime? fechaVencimientoDesde,
    DateTime? fechaVencimientoHasta,
    DateTime? fechaEntregaSolicitadaDesde,
    DateTime? fechaEntregaSolicitadaHasta,
    required String formato,
  }) async {
    try {
      final params = <String, dynamic>{};

      // Agregar filtros solo si tienen valor
      if (busqueda != null && busqueda.isNotEmpty) {
        params['busqueda'] = busqueda;
      }
      if (estado != null && estado.isNotEmpty) {
        params['estado'] = estado;
      }
      if (fechaDesde != null) {
        params['fecha_desde'] = fechaDesde.toIso8601String().split('T')[0];
      }
      if (fechaHasta != null) {
        params['fecha_hasta'] = fechaHasta.toIso8601String().split('T')[0];
      }
      if (fechaVencimientoDesde != null) {
        params['fecha_vencimiento_desde'] =
            fechaVencimientoDesde.toIso8601String().split('T')[0];
      }
      if (fechaVencimientoHasta != null) {
        params['fecha_vencimiento_hasta'] =
            fechaVencimientoHasta.toIso8601String().split('T')[0];
      }
      if (fechaEntregaSolicitadaDesde != null) {
        params['fecha_entrega_solicitada_desde'] =
            fechaEntregaSolicitadaDesde.toIso8601String().split('T')[0];
      }
      if (fechaEntregaSolicitadaHasta != null) {
        params['fecha_entrega_solicitada_hasta'] =
            fechaEntregaSolicitadaHasta.toIso8601String().split('T')[0];
      }
      params['formato'] = formato;

      debugPrint('📋 Filtros para PDF: $params');

      final response = await _dio.get(
        '$baseUrl/proformas/descargar-pdf-con-filtros',
        queryParameters: params,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'application/pdf',
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<int>;
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error descargando PDF con filtros: $e');
      rethrow;
    }
  }

  // Singleton con inicialización lazy
  static ApiService? _instance;

  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      _instance = ApiService._internal();
      try {
        await _instance!._loadToken(); // Cargar token al inicializar
      } catch (e) {
        debugPrint('⚠️ Error loading token during getInstance: $e');
      }
    }
    return _instance!;
  }

  // Método para obtener instancia sin inicialización adicional (para uso interno)
  static ApiService? get instance => _instance;

  factory ApiService() {
    // Si ya hay instancia, devolverla
    if (_instance != null) {
      return _instance!;
    }
    // Si no hay instancia, crear una nueva pero no inicializada
    // Esto es para compatibilidad con código existente
    _instance = ApiService._internal();
    // Cargar token de manera asíncrona sin bloquear
    Future.microtask(() async {
      try {
        await _instance!._loadToken();
      } catch (e) {
        debugPrint('⚠️ Error loading token in factory constructor: $e');
      }
    });
    return _instance!;
  }

  ApiService._internal() {
    _initializeDio();
    // No llamar a _loadToken aquí porque es async y el constructor es sync
    // Se carga en getInstance() o en el factory
  }

  // Método público para recargar variables de entorno
  Future<void> reloadEnvironment() async {
    await dotenv.load(fileName: ".env");
    // Re-inicializar Dio con la nueva URL
    _initializeDio();
    // Recargar token por si cambió algo
    try {
      await _loadToken();
    } catch (e) {
      debugPrint('⚠️ Error reloading token in reloadEnvironment: $e');
    }
  }
}
