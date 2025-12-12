import 'package:flutter/foundation.dart';
import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Check if it's the direct format (contains 'user') or wrapped format (contains 'success')
      if (json.containsKey('user')) {
        // Direct format: {user: ..., token: ..., roles: ..., permissions: ...}
        return AuthResponse(
          success: true,
          message: '',
          data: AuthData.fromJson(json),
        );
      } else {
        // Wrapped format: {success: true, message: ..., data: {user: ..., ...}}
        return AuthResponse(
          success: json['success'] ?? false,
          message: json['message'] ?? '',
          data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
        );
      }
    } catch (e) {
      debugPrint('❌ Error parsing AuthResponse: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class AuthData {
  final User user;
  final String token;
  final List<String>? roles;
  final List<String>? permissions;
  final int? cacheTtl; // En segundos
  final int? permissionsUpdatedAt; // Unix timestamp

  AuthData({
    required this.user,
    required this.token,
    this.roles,
    this.permissions,
    this.cacheTtl,
    this.permissionsUpdatedAt,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    try {
      final user = User.fromJson(json['user']);
      user.roles = json['roles'] != null
          ? List<String>.from(json['roles'])
          : null;
      user.permissions = json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null;
      return AuthData(
        user: user,
        token: json['token'],
        roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
        permissions: json['permissions'] != null
            ? List<String>.from(json['permissions'])
            : null,
        cacheTtl: json['cache_ttl'],
        permissionsUpdatedAt: json['permissions_updated_at'],
      );
    } catch (e) {
      debugPrint('❌ Error parsing AuthData: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'roles': roles,
      'permissions': permissions,
      'cache_ttl': cacheTtl,
      'permissions_updated_at': permissionsUpdatedAt,
    };
  }
}
