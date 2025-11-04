import 'product.dart';

enum EstadoReserva {
  ACTIVA,
  CONFIRMADA,
  LIBERADA,
  VENCIDA,
}

class ReservaStock {
  final int id;
  final int pedidoId;
  final int productoId;
  final Product? producto;
  final double cantidad;
  final EstadoReserva estado;
  final DateTime fechaCreacion;
  final DateTime fechaExpiracion;
  final DateTime? fechaLiberacion;

  ReservaStock({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    this.producto,
    required this.cantidad,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaExpiracion,
    this.fechaLiberacion,
  });

  factory ReservaStock.fromJson(Map<String, dynamic> json) {
    return ReservaStock(
      id: json['id'] as int,
      pedidoId: json['pedido_id'] as int,
      productoId: json['producto_id'] as int,
      producto: json['producto'] != null
          ? Product.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
      cantidad: (json['cantidad'] as num).toDouble(),
      estado: _estadoFromString(json['estado'] as String),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaExpiracion: DateTime.parse(json['fecha_expiracion'] as String),
      fechaLiberacion: json['fecha_liberacion'] != null
          ? DateTime.parse(json['fecha_liberacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedido_id': pedidoId,
      'producto_id': productoId,
      'producto': producto?.toJson(),
      'cantidad': cantidad,
      'estado': _estadoToString(estado),
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_expiracion': fechaExpiracion.toIso8601String(),
      'fecha_liberacion': fechaLiberacion?.toIso8601String(),
    };
  }

  static EstadoReserva _estadoFromString(String estado) {
    return EstadoReserva.values.firstWhere(
      (e) => e.toString().split('.').last == estado,
      orElse: () => EstadoReserva.ACTIVA,
    );
  }

  static String _estadoToString(EstadoReserva estado) {
    return estado.toString().split('.').last;
  }

  bool get estaVencida {
    return DateTime.now().isAfter(fechaExpiracion);
  }

  bool get puedeExtender {
    return estado == EstadoReserva.ACTIVA && !estaVencida;
  }

  Duration get tiempoRestante {
    return fechaExpiracion.difference(DateTime.now());
  }

  String get tiempoRestanteFormateado {
    final duration = tiempoRestante;

    if (duration.isNegative) {
      return 'Vencido';
    }

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
