// ✅ ACTUALIZADO: Usar String para códigos de estado en lugar de enum EstadoPedido

class PedidoEstadoHistorial {
  final int id;
  final int pedidoId;
  final String estadoAnterior;  // Código de estado, ej: 'PENDIENTE', 'APROBADA'
  final String estadoNuevo;     // Código de estado, ej: 'EN_RUTA', 'ENTREGADO'
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
      // ✅ ACTUALIZADO: Usar String directamente
      estadoAnterior: json['estado_anterior'] as String? ?? 'DESCONOCIDO',
      estadoNuevo: json['estado_nuevo'] as String? ?? 'DESCONOCIDO',
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
      // ✅ ACTUALIZADO: Pasar String directamente
      'estado_anterior': estadoAnterior,
      'estado_nuevo': estadoNuevo,
      'usuario_id': usuarioId,
      'nombre_usuario': nombreUsuario,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'metadata': metadata,
    };
  }
}
