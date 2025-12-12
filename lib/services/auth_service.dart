import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/permissions_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<AuthResponse> login(String login, String password) async {
    try {
      final response = await _apiService.post(
        '/login',
        data: {'login': login, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _apiService.setToken(authResponse.data!.token);
      }

      return authResponse;
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String usernick,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        '/register',
        data: {
          'name': name,
          'usernick': usernick,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _apiService.setToken(authResponse.data!.token);
      }

      return authResponse;
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<User>> getUser() async {
    try {
      final response = await _apiService.get('/user');

      // 401 Unauthorized - El interceptor ya intentará refresh automáticamente
      // Si llegamos aquí con 401, significa que el refresh también falló
      if (response.statusCode == 401) {
        debugPrint('🔐 Token inválido/expirado después de refresh - Session terminada');
        await _apiService.clearToken();
        return ApiResponse<User>(
          success: false,
          message: 'Sesión expirada. Por favor inicia sesión nuevamente.',
          data: null,
        );
      }

      // 200 OK - Usuario encontrado
      if (response.statusCode == 200) {
        return ApiResponse<User>.fromJson(response.data, (data) {
          User user;
          if (data.containsKey('user')) {
            user = User.fromJson(data['user']);
            // Assign roles and permissions from top level if present
            if (data.containsKey('roles')) {
              user.roles = List<String>.from(data['roles']);
            }
            if (data.containsKey('permissions')) {
              user.permissions = List<String>.from(data['permissions']);
            }
          } else {
            user = User.fromJson(data);
          }
          return user;
        });
      }

      // Otro status code
      return ApiResponse<User>(
        success: false,
        message: 'Error al obtener usuario (Status: ${response.statusCode})',
        data: null,
      );
    } on DioException catch (e) {
      // Si es un 401 en la excepción, el interceptor ya lo manejó
      if (e.response?.statusCode == 401) {
        await _apiService.clearToken();
        return ApiResponse<User>(
          success: false,
          message: 'Sesión expirada. Por favor inicia sesión nuevamente.',
          data: null,
        );
      }

      return ApiResponse<User>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<String>> refreshToken() async {
    try {
      final response = await _apiService.post('/refresh');

      final apiResponse = ApiResponse<String>.fromJson(
        response.data,
        (data) => data['token'],
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _apiService.setToken(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<String>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<Null>> logout() async {
    try {
      final response = await _apiService.post('/logout');

      final apiResponse = ApiResponse<Null>.fromJson(response.data);

      if (apiResponse.success) {
        await _apiService.clearToken();
      }

      return apiResponse;
    } on DioException catch (e) {
      // Even if logout fails, we should clear the token locally
      await _apiService.clearToken();
      return ApiResponse<Null>(
        success: false,
        message: _getErrorMessage(e),
        data: null,
      );
    } catch (e) {
      await _apiService.clearToken();
      return ApiResponse<Null>(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null;
  }

  Future<String?> getToken() async {
    return await _apiService.getToken();
  }

  /// ✅ NUEVO: Refrescar permisos sin logout
  /// Útil para app móvil que quiere actualizar permisos sin volver a login
  Future<PermissionsResponse> refreshPermissions() async {
    try {
      final response = await _apiService.get('/auth/refresh-permissions');

      if (response.statusCode == 200) {
        final permResponse = PermissionsResponse.fromJson(response.data);
        debugPrint('✅ Permisos refrescados correctamente');
        return permResponse;
      } else {
        throw Exception('Error al refrescar permisos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Error refrescando permisos: ${_getErrorMessage(e)}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error inesperado refrescando permisos: $e');
      rethrow;
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.data != null) {
      try {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            return errorData['message'];
          }
          if (errorData.containsKey('error')) {
            return errorData['error'];
          }
        }
      } catch (_) {}
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return 'Error del servidor: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        return 'Error de conexión';
    }
  }
}
