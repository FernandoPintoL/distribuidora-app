import 'estado_documento.dart';
import 'detalle_entrega.dart';
import 'entrega_venta_confirmacion.dart';

/// Modelo para información de venta convertida desde proforma
class PedidoVenta {
  final int id;
  final String numero;
  final DateTime? fecha;
  final EstadoDocumento? estadoDocumento;
  final EstadoDocumento? estadoLogistica;
  final List<EntregaVentaConfirmacion> confirmacionesEntrega;
  final String? observaciones;
  final DetalleEntrega? entrega;

  PedidoVenta({
    required this.id,
    required this.numero,
    this.fecha,
    this.estadoDocumento,
    this.estadoLogistica,
    this.confirmacionesEntrega = const [],
    this.observaciones,
    this.entrega,
  });

  factory PedidoVenta.fromJson(Map<String, dynamic> json) {
    return PedidoVenta(
      id: json['id'] as int,
      numero: json['numero'] as String,
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : null,
      estadoDocumento: json['estado_documento'] != null
          ? EstadoDocumento.fromJson(json['estado_documento'] as Map<String, dynamic>)
          : null,
      estadoLogistica: json['estado_logistica'] != null
          ? EstadoDocumento.fromJson(json['estado_logistica'] as Map<String, dynamic>)
          : null,
      confirmacionesEntrega: (json['confirmaciones_entrega'] ?? json['confirmaciones']) != null
          ? ((json['confirmaciones_entrega'] ?? json['confirmaciones']) as List)
              .map((c) => EntregaVentaConfirmacion.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      observaciones: json['observaciones'] as String?,
      entrega: json['entrega'] != null
          ? DetalleEntrega.fromJson(json['entrega'] as Map<String, dynamic>)
          : null,
    );
  }
}
