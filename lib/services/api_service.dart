import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5), // antes: 30
        receiveTimeout: const Duration(seconds: 5), // antes: 30
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
        if (error.response?.statusCode == 401) {
          // Token expirado, intentar refresh
          await _handleTokenExpiration();
          // Reintentar la petición
          final options = error.requestOptions;
          options.headers['Authorization'] = 'Bearer $_token';
          final response = await _dio.fetch(options);
          return handler.resolve(response);
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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(tokenKey);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<void> _handleTokenExpiration() async {
    // Aquí podrías implementar lógica para refresh token
    // Por ahora, solo limpiamos el token
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

  // Singleton con inicialización lazy
  static ApiService? _instance;

  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      _instance = ApiService._internal();
      await _instance!._loadToken(); // Cargar token al inicializar
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
      await _instance!._loadToken();
    });
    return _instance!;
  }

  ApiService._internal() {
    _initializeDio();
    _loadToken(); // Cargar token automáticamente al inicializar
  }

  // Método público para recargar variables de entorno
  Future<void> reloadEnvironment() async {
    await dotenv.load(fileName: ".env");
    // Re-inicializar Dio con la nueva URL
    _initializeDio();
    // Recargar token por si cambió algo
    await _loadToken();
  }
}
