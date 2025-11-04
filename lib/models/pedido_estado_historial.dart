import 'estado_pedido.dart';

class PedidoEstadoHistorial {
  final int id;
  final int pedidoId;
  final EstadoPedido estadoAnterior;
  final EstadoPedido estadoNuevo;
  final int? usuarioId;
  final String? nombreUsuario;
  final String? comentario;
  final DateTime fecha;
  final Map<String, dynamic>? metadata;

  PedidoEstadoHistorial({
    required this.id,
    required this.pedidoId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.usuarioId,
    this.nombreUsuario,
    this.comentario,
    required this.fecha,
    this.metadata,
  });

  factory PedidoEstadoHistorial.fromJson(Map<String, dynamic> json) {
    return PedidoEstadoHistorial(
      id: json['id'] as int,
      pedidoId: json['pedido_id'] as int,
      estadoAnterior: EstadoInfo.fromString(json['estado_anterior'] as String),
      estadoNuevo: EstadoInfo.fromString(json['estado_nuevo'] as String),
      usuarioId: json['usuario_id'] as int?,
      nombreUsuario: json['nombre_usuario'] as String?,
      comentario: json['comentario'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedido_id': pedidoId,
      'estado_anterior': EstadoInfo.enumToString(estadoAnterior),
      'estado_nuevo': EstadoInfo.enumToString(estadoNuevo),
      'usuario_id': usuarioId,
      'nombre_usuario': nombreUsuario,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'metadata': metadata,
    };
  }
}
