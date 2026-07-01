/// Evento de timeline para visualizar el ciclo completo del pedido
class PedidoTimelineEvent {
  final String categoria;      // proforma, venta, logistica
  final String estado;         // PENDIENTE, APROBADA, etc
  final String label;          // Texto para mostrar
  final DateTime timestamp;    // Cuándo ocurrió
  final String icono;          // Emoji o ícono

  PedidoTimelineEvent({
    required this.categoria,
    required this.estado,
    required this.label,
    required this.timestamp,
    required this.icono,
  });
}
