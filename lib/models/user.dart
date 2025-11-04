import 'package:flutter/foundation.dart';

class User {
  final int id;              // ID del usuario en la tabla users
  final String name;
  final String? usernick;
  final String? email;
  final bool activo;
  final int? clienteId;      // ID del cliente asociado al usuario ⭐ IMPORTANTE
  List<String>? roles;
  List<String>? permissions;

  User({
    required this.id,
    required this.name,
    this.usernick,
    this.email,
    required this.activo,
    this.clienteId,
    this.roles,
    this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name: json['name'],
        usernick: json['usernick'],
        email: json['email'],
        activo: json['activo'] is bool
            ? json['activo']
            : (json['activo'] == 'true' ||
                  json['activo'] == 1 ||
                  json['activo'] == true),
        clienteId: json['cliente_id'] != null
            ? (json['cliente_id'] is int
                ? json['cliente_id']
                : int.parse(json['cliente_id'].toString()))
            : null,
        roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
        permissions: json['permissions'] != null
            ? List<String>.from(json['permissions'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing User: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usernick': usernick,
      'email': email,
      'activo': activo,
      'cliente_id': clienteId,
      'roles': roles,
      'permissions': permissions,
    };
  }
}
