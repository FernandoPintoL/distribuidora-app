import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String name;
  final String? usernick;
  final String? email;
  final bool activo;
  List<String>? roles;
  List<String>? permissions;

  User({
    required this.id,
    required this.name,
    this.usernick,
    this.email,
    required this.activo,
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
      'roles': roles,
      'permissions': permissions,
    };
  }
}
