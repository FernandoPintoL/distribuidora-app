import 'package:distribuidora/models/almacen_prestable.dart';

class DevolucionClienteDetalleAlmacen {
  final int id;
  final int devolucionClienteDetalleId;
  final int almacenesPrestablesId;
  final int cantidadDevuelta;
  final int cantidadDaniadaTotal;
  final String? montoGarantiaDevuelta;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;
  final AlmacenPrestable? almacen;

  DevolucionClienteDetalleAlmacen({
    required this.id,
    required this.devolucionClienteDetalleId,
    required this.almacenesPrestablesId,
    required this.cantidadDevuelta,
    required this.cantidadDaniadaTotal,
    this.montoGarantiaDevuelta,
    this.esProveedor = false,
    this.createdAt,
    this.updatedAt,
    this.almacen,
  });

  factory DevolucionClienteDetalleAlmacen.fromJson(Map<String, dynamic> json) {
    return DevolucionClienteDetalleAlmacen(
      id: json['id'] as int? ?? 0,
      devolucionClienteDetalleId:
          json['devolucion_cliente_detalle_id'] as int? ?? 0,
      almacenesPrestablesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int? ?? 0,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      almacen: json['almacen'] != null
          ? AlmacenPrestable.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
    );
  }

  DevolucionClienteDetalleAlmacen copyWith({
    int? id,
    int? devolucionClienteDetalleId,
    int? almacenesPrestablesId,
    int? cantidadDevuelta,
    int? cantidadDaniadaTotal,
    String? montoGarantiaDevuelta,
    bool? esProveedor,
    String? createdAt,
    String? updatedAt,
    AlmacenPrestable? almacen,
  }) {
    return DevolucionClienteDetalleAlmacen(
      id: id ?? this.id,
      devolucionClienteDetalleId:
          devolucionClienteDetalleId ?? this.devolucionClienteDetalleId,
      almacenesPrestablesId:
          almacenesPrestablesId ?? this.almacenesPrestablesId,
      cantidadDevuelta: cantidadDevuelta ?? this.cantidadDevuelta,
      cantidadDaniadaTotal: cantidadDaniadaTotal ?? this.cantidadDaniadaTotal,
      montoGarantiaDevuelta:
          montoGarantiaDevuelta ?? this.montoGarantiaDevuelta,
      esProveedor: esProveedor ?? this.esProveedor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      almacen: almacen ?? this.almacen,
    );
  }
}
