import 'package:flutter/foundation.dart';

/// Modelo para la respuesta de permisos desde la API
/// Incluye permisos, roles y TTL para caché en app
class PermissionsResponse {
  final bool success;
  final List<String> permissions;
  final List<String> roles;
  final int cacheTtl; // En segundos
  final int permissionsUpdatedAt; // Timestamp de actualización

  PermissionsResponse({
    required this.success,
    required this.permissions,
    required this.roles,
    required this.cacheTtl,
    required this.permissionsUpdatedAt,
  });

  factory PermissionsResponse.fromJson(Map<String, dynamic> json) {
    try {
      return PermissionsResponse(
        success: json['success'] ?? false,
        permissions: json['permissions'] != null
            ? List<String>.from(json['permissions'])
            : [],
        roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
        cacheTtl: json['cache_ttl'] ?? (24 * 60 * 60), // 24 horas por defecto
        permissionsUpdatedAt: json['permissions_updated_at'] ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error parsing PermissionsResponse: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'permissions': permissions,
      'roles': roles,
      'cache_ttl': cacheTtl,
      'permissions_updated_at': permissionsUpdatedAt,
    };
  }

  /// Verificar si el caché de permisos es válido
  bool get isCacheValid {
    if (permissionsUpdatedAt == 0) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiry = permissionsUpdatedAt + cacheTtl;

    return now < expiry;
  }

  /// Obtener tiempo restante en minutos hasta que expire el caché
  int get minutosRestantes {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiry = permissionsUpdatedAt + cacheTtl;
    final segundosRestantes = expiry - now;

    return (segundosRestantes / 60).ceil();
  }
}
