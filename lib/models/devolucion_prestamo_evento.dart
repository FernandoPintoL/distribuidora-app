class DevolucionEvento {
  final int id;
  final int prestamoEventoId;
  final String? fechaDevolucion;
  final int? cantidadTotalDevuelta;
  final String? montoCobradoDanioTotal;
  final String? montoGarantiaDevueltaTotal;
  final String? observaciones;
  final int? choferId;
  final String? createdAt;
  final String? updatedAt;
  final List<DevolucionEventoDetalle>? detalles;

  DevolucionEvento({
    required this.id,
    required this.prestamoEventoId,
    this.fechaDevolucion,
    this.cantidadTotalDevuelta,
    this.montoCobradoDanioTotal,
    this.montoGarantiaDevueltaTotal,
    this.observaciones,
    this.choferId,
    this.createdAt,
    this.updatedAt,
    this.detalles,
  });

  factory DevolucionEvento.fromJson(Map<String, dynamic> json) {
    return DevolucionEvento(
      id: json['id'] as int? ?? 0,
      prestamoEventoId: json['prestamo_evento_id'] as int? ?? 0,
      fechaDevolucion: json['fecha_devolucion'] as String?,
      cantidadTotalDevuelta: json['cantidad_total_devuelta'] as int?,
      montoCobradoDanioTotal: json['monto_cobrado_daño_total'] as String?,
      montoGarantiaDevueltaTotal:
          json['monto_garantia_devuelta_total'] as String?,
      observaciones: json['observaciones'] as String?,
      choferId: json['chofer_id'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      detalles: (json['detalles'] as List?)
          ?.map(
            (d) => DevolucionEventoDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DevolucionEventoDetalle {
  final int id;
  final int devolucionEventoId;
  final int prestamoEventoDetalleId;
  final int cantidadDevuelta;
  final int? cantidadDaniadaParcial;
  final int? cantidadDaniadaTotal;
  final String? montoCobradoDanio;
  final String? montoGarantiaDevuelta;
  final String? createdAt;
  final String? updatedAt;
  final dynamic detallePrestamoEvento;
  final List<DevolucionEventoDetalleAlmacen>? devolucionesAlmacenes;

  DevolucionEventoDetalle({
    required this.id,
    required this.devolucionEventoId,
    required this.prestamoEventoDetalleId,
    required this.cantidadDevuelta,
    this.cantidadDaniadaParcial,
    this.cantidadDaniadaTotal,
    this.montoCobradoDanio,
    this.montoGarantiaDevuelta,
    this.createdAt,
    this.updatedAt,
    this.detallePrestamoEvento,
    this.devolucionesAlmacenes,
  });

  factory DevolucionEventoDetalle.fromJson(Map<String, dynamic> json) {
    return DevolucionEventoDetalle(
      id: json['id'] as int? ?? 0,
      devolucionEventoId: json['devolucion_evento_id'] as int? ?? 0,
      prestamoEventoDetalleId: json['prestamo_evento_detalle_id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      cantidadDaniadaParcial: json['cantidad_dañada_parcial'] as int?,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int?,
      montoCobradoDanio: json['monto_cobrado_daño'] as String?,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      detallePrestamoEvento:
          json['detalle_prestamo_evento'] != null ? json['detalle_prestamo_evento'] : null,
      devolucionesAlmacenes: (json['devoluciones_almacenes'] as List?)
          ?.map((a) => DevolucionEventoDetalleAlmacen.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DevolucionEventoDetalleAlmacen {
  final int id;
  final int devolucionEventoDetalleId;
  final int almacenesPrestablesId;
  final int cantidadDevuelta;
  final int? cantidadDaniadaParcial;
  final int? cantidadDaniadaTotal;
  final String? montoCobradoDanio;
  final String? montoGarantiaDevuelta;
  final bool? esProveedor;
  final String? createdAt;
  final String? updatedAt;
  final dynamic almacen;

  DevolucionEventoDetalleAlmacen({
    required this.id,
    required this.devolucionEventoDetalleId,
    required this.almacenesPrestablesId,
    required this.cantidadDevuelta,
    this.cantidadDaniadaParcial,
    this.cantidadDaniadaTotal,
    this.montoCobradoDanio,
    this.montoGarantiaDevuelta,
    this.esProveedor,
    this.createdAt,
    this.updatedAt,
    this.almacen,
  });

  factory DevolucionEventoDetalleAlmacen.fromJson(Map<String, dynamic> json) {
    return DevolucionEventoDetalleAlmacen(
      id: json['id'] as int? ?? 0,
      devolucionEventoDetalleId: json['devolucion_evento_detalle_id'] as int? ?? 0,
      almacenesPrestablesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      cantidadDaniadaParcial: json['cantidad_dañada_parcial'] as int?,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int?,
      montoCobradoDanio: json['monto_cobrado_daño'] as String?,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      esProveedor: json['es_proveedor'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      almacen: json['almacen'] != null ? json['almacen'] : null,
    );
  }
}
