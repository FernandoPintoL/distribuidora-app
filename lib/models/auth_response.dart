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
  final PreventistStats? preventistaStats; // ✅ NUEVO: Estadísticas del preventista

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

// ✅ NUEVO: Modelo para estadísticas del preventista
class PreventistStats {
  final int totalClientes;
  final int clientesActivos;
  final int clientesInactivos;
  final double porcentajeActivos;
  final double porcentajeInactivos;
  final List<ClienteBasico> clientesParaReactivar;
  final int clientesParaReactivarCount;

  PreventistStats({
    required this.totalClientes,
    required this.clientesActivos,
    required this.clientesInactivos,
    required this.porcentajeActivos,
    required this.porcentajeInactivos,
    required this.clientesParaReactivar,
    required this.clientesParaReactivarCount,
  });

  factory PreventistStats.fromJson(Map<String, dynamic> json) {
    try {
      final clientesData = json['clientes_para_reactivar'] as List? ?? [];
      final clientes = clientesData
          .map((c) => ClienteBasico.fromJson(c))
          .toList();

      return PreventistStats(
        totalClientes: json['total_clientes'] ?? 0,
        clientesActivos: json['clientes_activos'] ?? 0,
        clientesInactivos: json['clientes_inactivos'] ?? 0,
        porcentajeActivos: (json['porcentaje_activos'] ?? 0).toDouble(),
        porcentajeInactivos: (json['porcentaje_inactivos'] ?? 0).toDouble(),
        clientesParaReactivar: clientes,
        clientesParaReactivarCount: json['clientes_para_reactivar_count'] ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error parsing PreventistStats: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'total_clientes': totalClientes,
      'clientes_activos': clientesActivos,
      'clientes_inactivos': clientesInactivos,
      'porcentaje_activos': porcentajeActivos,
      'porcentaje_inactivos': porcentajeInactivos,
      'clientes_para_reactivar': clientesParaReactivar.map((c) => c.toJson()).toList(),
      'clientes_para_reactivar_count': clientesParaReactivarCount,
    };
  }
}

// ✅ NUEVO: Modelo básico de cliente para la respuesta
class ClienteBasico {
  final int id;
  final String nombre;
  final String? razonSocial;
  final String? telefono;
  final String? email;
  final String? localidad;
  final bool activo;

  ClienteBasico({
    required this.id,
    required this.nombre,
    this.razonSocial,
    this.telefono,
    this.email,
    this.localidad,
    required this.activo,
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
    };
  }
}
