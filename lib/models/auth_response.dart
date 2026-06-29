import 'package:flutter/foundation.dart';
import 'user.dart';
import 'preventist_stats.dart';

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
  final PreventistStats?
  preventistaStats; // ✅ NUEVO: Estadísticas del preventista

  AuthData({
    required this.user,
    required this.token,
    this.roles,
    this.permissions,
    this.cacheTtl,
    this.permissionsUpdatedAt,
    this.preventistaStats,
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

      // ✅ NUEVO: Parsear estadísticas del preventista si existen
      PreventistStats? preventistaStats;
      if (json['preventista_stats'] != null) {
        preventistaStats = PreventistStats.fromJson(json['preventista_stats']);
      }

      return AuthData(
        user: user,
        token: json['token'],
        roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
        permissions: json['permissions'] != null
            ? List<String>.from(json['permissions'])
            : null,
        cacheTtl: json['cache_ttl'],
        permissionsUpdatedAt: json['permissions_updated_at'],
        preventistaStats: preventistaStats,
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
      'preventista_stats': preventistaStats?.toJson(),
    };
  }
}

// ✅ NOTA: PreventistStats está importado desde preventist_stats.dart

// ✅ NUEVO: Modelo básico de cliente para la respuesta
class ClienteBasico {
  final int id;
  final String nombre;
  final String? razonSocial;
  final String? telefono;
  final String? email;
  final String? localidad;
  final bool activo;
  final double? limiteCredito;
  final bool puedeAtenerCredito;

  ClienteBasico({
    required this.id,
    required this.nombre,
    this.razonSocial,
    this.telefono,
    this.email,
    this.localidad,
    required this.activo,
    this.limiteCredito,
    this.puedeAtenerCredito = false,
  });

  factory ClienteBasico.fromJson(Map<String, dynamic> json) {
    return ClienteBasico(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      razonSocial: json['razon_social'],
      telefono: json['telefono'],
      email: json['email'],
      localidad: json['localidad'],
      activo: json['activo'] ?? false,
      limiteCredito: json['limite_credito'] != null
          ? double.tryParse(json['limite_credito'].toString())
          : null,
      // ✅ Aceptar ambas variantes: puede_tener_credito y puede_atener_credito
      puedeAtenerCredito:
          json['puede_tener_credito'] ?? json['puede_atener_credito'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'razon_social': razonSocial,
      'telefono': telefono,
      'email': email,
      'localidad': localidad,
      'activo': activo,
      'limite_credito': limiteCredito,
      'puede_tener_credito': puedeAtenerCredito,
    };
  }
}
