import 'package:flutter/material.dart';

/// Modelo para Notificaciones Recurrentes desde Laravel
class RecurringNotification {
  final int id;
  final String titulo;
  final String descripcion;
  final String tipo;
  final int totalEnviadas;
  final int vistas;
  final List<Map<String, dynamic>>? roles;
  final DateTime timestamp;

  RecurringNotification({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.totalEnviadas,
    required this.vistas,
    this.roles,
    required this.timestamp,
  });

  factory RecurringNotification.fromJson(Map<String, dynamic> json) {
    return RecurringNotification(
      id: _toInt(json['id']),
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'informativo',
      totalEnviadas: _toInt(json['total_enviadas']),
      vistas: _toInt(json['vistas']),
      roles: _parseRoles(json['roles']),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convierte num (int o double) a int de forma segura
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parsea roles array de forma segura
  static List<Map<String, dynamic>>? _parseRoles(dynamic rolesData) {
    if (rolesData == null) return null;
    if (rolesData is! List) return null;
    try {
      return List<Map<String, dynamic>>.from(
        rolesData.map((role) => role as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'total_enviadas': totalEnviadas,
      'vistas': vistas,
      'roles': roles,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Ícono según el tipo
  IconData get icon {
    switch (tipo) {
      case 'promocion':
        return Icons.local_offer;
      case 'evento':
        return Icons.event;
      case 'oferta':
        return Icons.card_giftcard;
      case 'informativo':
      default:
        return Icons.info;
    }
  }

  /// Color según el tipo
  Color get color {
    switch (tipo) {
      case 'promocion':
        return Colors.blue;
      case 'evento':
        return Colors.purple;
      case 'oferta':
        return Colors.red;
      case 'informativo':
      default:
        return Colors.grey;
    }
  }

  /// Label del tipo
  String get tipoLabel {
    switch (tipo) {
      case 'promocion':
        return '🎁 Promoción';
      case 'evento':
        return '🎉 Evento';
      case 'oferta':
        return '🏷️ Oferta';
      case 'informativo':
      default:
        return 'ℹ️ Informativo';
    }
  }
}
