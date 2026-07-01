/// Modelo para confirmación de entrega
class ConfirmacionEntrega {
  final int id;
  final String estado;
  final DateTime? fecha;
  final String? chofer;
  final String? cliente;

  ConfirmacionEntrega({
    required this.id,
    required this.estado,
    this.fecha,
    this.chofer,
    this.cliente,
  });

  factory ConfirmacionEntrega.fromJson(Map<String, dynamic> json) {
    return ConfirmacionEntrega(
      id: json['id'] as int,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : null,
      chofer: json['chofer'] as String?,
      cliente: json['cliente'] as String?,
    );
  }
}
