import 'package:distribuidora/models/devolucion_cliente_detalle_almacenes.dart';
import 'package:distribuidora/models/prestamo_cliente.dart';

class DevolucionCliente {
  final int id;
  final int prestamoClienteId;
  final String? fechaDevolucion;
  final String? montoCobradoDanioTotal;
  final String? montoGarantiaDevueltaTotal;
  final String? montoExcedidoGarantia;
  final String? observaciones;
  final int? choferId;
  final String? createdAt;
  final String? updatedAt;
  final List<DevolucionClienteDetalle>? detalles;

  DevolucionCliente({
    required this.id,
    required this.prestamoClienteId,
    this.fechaDevolucion,
    this.montoCobradoDanioTotal,
    this.montoGarantiaDevueltaTotal,
    this.montoExcedidoGarantia,
    this.observaciones,
    this.choferId,
    this.createdAt,
    this.updatedAt,
    this.detalles,
  });

  factory DevolucionCliente.fromJson(Map<String, dynamic> json) {
    return DevolucionCliente(
      id: json['id'] as int? ?? 0,
      prestamoClienteId: json['prestamo_cliente_id'] as int? ?? 0,
      fechaDevolucion: json['fecha_devolucion'] as String?,
      montoCobradoDanioTotal: json['monto_cobrado_daño_total'] as String?,
      montoGarantiaDevueltaTotal:
          json['monto_garantia_devuelta_total'] as String?,
      montoExcedidoGarantia: json['monto_excedido_garantia'] as String?,
      observaciones: json['observaciones'] as String?,
      choferId: json['chofer_id'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      detalles: (json['detalles'] as List?)
          ?.map(
            (d) => DevolucionClienteDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DevolucionClienteDetalle {
  final int id;
  final int cantidadDevuelta;
  final int cantidadDaniadaTotal;
  final String? montoCobradoDanio;
  final String? montoGarantiaDevuelta;
  final String? montoExcedidoDetalle;
  final String? fechaDevolucion;
  final String? observaciones;
  final List<DevolucionClienteDetalleAlmacen>? devolucionesAlmacenes;
  final PrestamoClienteDetalle? detallePrestamoCliente;

  DevolucionClienteDetalle({
    required this.id,
    required this.cantidadDevuelta,
    required this.cantidadDaniadaTotal,
    this.montoCobradoDanio,
    this.montoGarantiaDevuelta,
    this.montoExcedidoDetalle,
    this.fechaDevolucion,
    this.observaciones,
    this.devolucionesAlmacenes,
    this.detallePrestamoCliente,
  });

  factory DevolucionClienteDetalle.fromJson(Map<String, dynamic> json) {
    return DevolucionClienteDetalle(
      id: json['id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int? ?? 0,
      montoCobradoDanio: json['monto_cobrado_daño'] as String?,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      montoExcedidoDetalle: json['monto_excedido_detalle'] as String?,
      fechaDevolucion: json['fecha_devolucion'] as String?,
      observaciones: json['observaciones'] as String?,
      devolucionesAlmacenes: (json['devoluciones_almacenes'] as List?)
          ?.map(
            (a) => DevolucionClienteDetalleAlmacen.fromJson(
              a as Map<String, dynamic>,
            ),
          )
          .toList(),
      detallePrestamoCliente: json['detalle_prestamo_cliente'] != null
          ? PrestamoClienteDetalle.fromJson(
              json['detalle_prestamo_cliente'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
