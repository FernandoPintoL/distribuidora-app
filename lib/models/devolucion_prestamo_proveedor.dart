class DevolucionProveedor {
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
  final List<DevolucionProveedorDetalle>? detalles;

  DevolucionProveedor({
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

  factory DevolucionProveedor.fromJson(Map<String, dynamic> json) {
    return DevolucionProveedor(
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
            (d) =>
                DevolucionProveedorDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DevolucionProveedorDetalle {
  final int id;
  final int cantidadDevuelta;
  final String? observaciones;
  final String? fechaDevolucion;
  final String? createdAt;
  final String? updatedAt;
  final int? prestamoProveedorDetalleId;
  final int? devolucionProveedorId;
  final int? cantidadDaniadaParcial;
  final int? cantidadDaniadaTotal;
  final String? montoCobradoDanio;
  final String? montoGarantiaDevuelta;
  final dynamic detallePrestamoProveedor;
  final List<DevolucionProveedorDetalleAlmacen>? devolucionesAlmacenes;

  DevolucionProveedorDetalle({
    required this.id,
    required this.cantidadDevuelta,
    this.observaciones,
    this.fechaDevolucion,
    this.createdAt,
    this.updatedAt,
    this.prestamoProveedorDetalleId,
    this.devolucionProveedorId,
    this.cantidadDaniadaParcial,
    this.cantidadDaniadaTotal,
    this.montoCobradoDanio,
    this.montoGarantiaDevuelta,
    this.detallePrestamoProveedor,
    this.devolucionesAlmacenes,
  });

  factory DevolucionProveedorDetalle.fromJson(Map<String, dynamic> json) {
    return DevolucionProveedorDetalle(
      id: json['id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      observaciones: json['observaciones'] as String?,
      fechaDevolucion: json['fecha_devolucion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      prestamoProveedorDetalleId: json['prestamo_proveedor_detalle_id'] as int?,
      devolucionProveedorId: json['devolucion_proveedor_id'] as int?,
      cantidadDaniadaParcial: json['cantidad_dañada_parcial'] as int?,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int?,
      montoCobradoDanio: json['monto_cobrado_daño'] as String?,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      detallePrestamoProveedor: json['detalle_prestamo_proveedor'] != null
          ? json['detalle_prestamo_proveedor']
          : null,
      devolucionesAlmacenes: (json['devoluciones_almacenes'] as List?)
          ?.map((a) => DevolucionProveedorDetalleAlmacen.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DevolucionProveedorDetalleAlmacen {
  final int id;
  final int devolucionProveedorDetalleId;
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

  DevolucionProveedorDetalleAlmacen({
    required this.id,
    required this.devolucionProveedorDetalleId,
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

  factory DevolucionProveedorDetalleAlmacen.fromJson(Map<String, dynamic> json) {
    return DevolucionProveedorDetalleAlmacen(
      id: json['id'] as int? ?? 0,
      devolucionProveedorDetalleId: json['devolucion_proveedor_detalle_id'] as int? ?? 0,
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
