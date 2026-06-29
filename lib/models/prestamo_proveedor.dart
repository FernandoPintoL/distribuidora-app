import 'prestamo_completo.dart';

class PrestamoProveedor {
  final int id;
  final int? proveedorId;
  final bool esCompra;
  final String? fechaPrestamo;
  final String? fechaEsperadaDevolucion;
  final String? estado;
  final String? createdAt;
  final String? updatedAt;
  final int? compraId;
  final double? montoGarantia;
  final String? observaciones;
  final int? almacenesPrestasblesId;
  final int? choferId;
  final String? vehiculoAsignado;

  // Relaciones
  final Proveedor? proveedor;
  final Almacen? almacen;
  final ChoferPrestamo? chofer;
  final List<PrestamoProveedorDetalle>? detalles;

  PrestamoProveedor({
    required this.id,
    this.proveedorId,
    this.esCompra = false,
    this.fechaPrestamo,
    this.fechaEsperadaDevolucion,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.compraId,
    this.montoGarantia,
    this.observaciones,
    this.almacenesPrestasblesId,
    this.choferId,
    this.vehiculoAsignado,
    this.proveedor,
    this.almacen,
    this.chofer,
    this.detalles,
  });

  factory PrestamoProveedor.fromJson(Map<String, dynamic> json) {
    double? parseMontoGarantia(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PrestamoProveedor(
      id: json['id'] as int? ?? 0,
      proveedorId: json['proveedor_id'] as int?,
      esCompra: json['es_compra'] as bool? ?? false,
      fechaPrestamo: json['fecha_prestamo'] as String?,
      fechaEsperadaDevolucion: json['fecha_esperada_devolucion'] as String?,
      estado: json['estado'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      compraId: json['compra_id'] as int?,
      montoGarantia: parseMontoGarantia(json['monto_garantia']),
      observaciones: json['observaciones'] as String?,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int?,
      choferId: json['chofer_id'] as int?,
      vehiculoAsignado: json['vehiculo_asignado'] as String?,
      proveedor: json['proveedor'] != null
          ? Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>)
          : null,
      almacen: json['almacen'] != null
          ? Almacen.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map((d) =>
              PrestamoProveedorDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PrestamoProveedorDetalle {
  final int id;
  final int prestamoProveedorId;
  final int prestableId;
  final int cantidadPrestada;
  final String? precioUnitario;
  final String? precioPrestamo;
  final String? estado;
  final String? createdAt;
  final String? updatedAt;
  final String? almacenesIds;
  final Prestable? prestable;
  final List<DevolucionProveedorDetalle>? devolucionDetalles;
  final List<PrestamoProveedorAlmacen>? almacenes;

  PrestamoProveedorDetalle({
    required this.id,
    required this.prestamoProveedorId,
    required this.prestableId,
    required this.cantidadPrestada,
    this.precioUnitario,
    this.precioPrestamo,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.almacenesIds,
    this.prestable,
    this.devolucionDetalles,
    this.almacenes,
  });

  factory PrestamoProveedorDetalle.fromJson(Map<String, dynamic> json) {
    return PrestamoProveedorDetalle(
      id: json['id'] as int? ?? 0,
      prestamoProveedorId: json['prestamo_proveedor_id'] as int? ?? 0,
      prestableId: json['prestable_id'] as int? ?? 0,
      cantidadPrestada: json['cantidad_prestada'] as int? ?? 0,
      precioUnitario: json['precio_unitario'] as String?,
      precioPrestamo: json['precio_prestamo'] as String?,
      estado: json['estado'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      almacenesIds: json['almacenes_ids'] as String?,
      prestable: json['prestable'] != null
          ? Prestable.fromJson(json['prestable'] as Map<String, dynamic>)
          : null,
      devolucionDetalles: (json['devolucion_detalles'] as List?)
          ?.map((d) => DevolucionProveedorDetalle.fromJson(
              d as Map<String, dynamic>))
          .toList(),
      // ✅ NUEVO: Parsear almacenes
      almacenes: (json['almacenes'] as List?)
          ?.map((a) => PrestamoProveedorAlmacen.fromJson(a as Map<String, dynamic>))
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
    );
  }
}

// ✅ NUEVO: Almacenes en los que se distribuyó un préstamo de proveedor
class PrestamoProveedorAlmacen {
  final int id;
  final int prestamoProveedorDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoProveedorAlmacen({
    required this.id,
    required this.prestamoProveedorDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    required this.esProveedor,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoProveedorAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoProveedorAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoProveedorDetalleId: json['prestamo_proveedor_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
