import 'package:flutter/material.dart';

/// Modelo de notificación persistente desde Laravel
class AppNotification {
  final int id;
  final int userId;
  final String type;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? readAt;
  final int? proformaId;
  final int? ventaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    required this.read,
    this.readAt,
    this.proformaId,
    this.ventaId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      read: json['read'] == true || json['read'] == 1,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      proformaId: json['proforma_id'] as int?,
      ventaId: json['venta_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'data': data,
      'read': read,
      'read_at': readAt?.toIso8601String(),
      'proforma_id': proformaId,
      'venta_id': ventaId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Título según el tipo de notificación
  String get title {
    switch (type) {
      case 'proforma.creada':
        return 'Proforma Creada';
      case 'proforma.aprobada':
        return '¡Proforma Aprobada!';
      case 'proforma.rechazada':
        return 'Proforma Rechazada';
      case 'proforma.convertida':
        return '¡Pedido Confirmado!';
      default:
        return 'Notificación';
    }
  }

  /// Mensaje descriptivo según el tipo
  String get message {
    switch (type) {
      case 'proforma.creada':
        final numero = data['proforma_numero'] as String?;
        return numero != null
            ? 'Proforma $numero ha sido creada'
            : 'Nueva proforma creada';

      case 'proforma.aprobada':
        final numero = data['proforma_numero'] as String?;
        return numero != null
            ? 'Tu proforma $numero ha sido aprobada'
            : 'Tu proforma ha sido aprobada';

      case 'proforma.rechazada':
        final numero = data['proforma_numero'] as String?;
        final motivo = data['motivo_rechazo'] as String?;
        String msg = numero != null
            ? 'Proforma $numero rechazada'
            : 'Proforma rechazada';
        if (motivo != null && motivo.isNotEmpty) {
          msg += ': $motivo';
        }
        return msg;

      case 'proforma.convertida':
        final ventaNumero = data['venta_numero'] as String?;
        return ventaNumero != null
            ? 'Pedido $ventaNumero confirmado exitosamente'
            : 'Tu pedido ha sido confirmado';

      default:
        return 'Nueva notificación';
    }
  }

  /// Ícono según el tipo
  IconData get icon {
    switch (type) {
      case 'proforma.creada':
        return Icons.note_add;
      case 'proforma.aprobada':
        return Icons.check_circle;
      case 'proforma.rechazada':
        return Icons.cancel;
      case 'proforma.convertida':
        return Icons.shopping_cart;
      default:
        return Icons.notifications;
    }
  }

  /// Color según el tipo
  Color get color {
    switch (type) {
      case 'proforma.aprobada':
        return Colors.green;
      case 'proforma.rechazada':
        return Colors.red;
      case 'proforma.convertida':
        return Colors.blue;
      case 'proforma.creada':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Copia con modificaciones
  AppNotification copyWith({
    int? id,
    int? userId,
    String? type,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? readAt,
    int? proformaId,
    int? ventaId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      data: data ?? this.data,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      proformaId: proformaId ?? this.proformaId,
      ventaId: ventaId ?? this.ventaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Estadísticas de notificaciones
class NotificationStats {
  final int total;
  final int unread;
  final int read;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      read: json['read'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
    };
  }
}
