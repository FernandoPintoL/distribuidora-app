import 'prestamo_completo.dart';

class PrestamoEvento {
  final int id;
  final int? eventoId;
  final String? nombreEvento;
  final int? choferId;
  final int cantidad;
  final double? montoGarantia;
  final String? fechaPrestamo;
  final String? fechaEsperadaDevolucion;
  final String? estado;
  final String? createdAt;
  final String? updatedAt;
  final int? ventaId;
  final String? encargadoEvento;
  final String? vehiculoAsignado;
  final String? direccionEvento;
  final String? telefonoUno;
  final String? telefonoDos;
  final String? fechaEntrega;
  final int? clienteId;
  final int? almacenesPrestasblesId;

  // Relaciones
  final Cliente? cliente;
  final Almacen? almacen;
  final ChoferPrestamo? chofer;
  final List<PrestamoEventoDetalle>? detalles;
  final List<dynamic>? ventas;
  final List<DevolucionEvento>? devoluciones;

  PrestamoEvento({
    required this.id,
    this.eventoId,
    this.nombreEvento,
    this.choferId,
    required this.cantidad,
    this.montoGarantia,
    this.fechaPrestamo,
    this.fechaEsperadaDevolucion,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.ventaId,
    this.encargadoEvento,
    this.vehiculoAsignado,
    this.direccionEvento,
    this.telefonoUno,
    this.telefonoDos,
    this.fechaEntrega,
    this.clienteId,
    this.almacenesPrestasblesId,
    this.cliente,
    this.almacen,
    this.chofer,
    this.detalles,
    this.ventas,
    this.devoluciones,
  });

  factory PrestamoEvento.fromJson(Map<String, dynamic> json) {
    double? parseMontoGarantia(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PrestamoEvento(
      id: json['id'] as int? ?? 0,
      eventoId: json['evento_id'] as int?,
      nombreEvento: json['nombre_evento'] as String?,
      choferId: json['chofer_id'] as int?,
      cantidad: json['cantidad'] as int? ?? 0,
      montoGarantia: parseMontoGarantia(json['monto_garantia']),
      fechaPrestamo: json['fecha_prestamo'] as String?,
      fechaEsperadaDevolucion: json['fecha_esperada_devolucion'] as String?,
      estado: json['estado'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      ventaId: json['venta_id'] as int?,
      encargadoEvento: json['encargado_evento'] as String?,
      vehiculoAsignado: json['vehiculo_asignado'] as String?,
      direccionEvento: json['direccion_evento'] as String?,
      telefonoUno: json['telefono_uno'] as String?,
      telefonoDos: json['telefono_dos'] as String?,
      fechaEntrega: json['fecha_entrega'] as String?,
      clienteId: json['cliente_id'] as int?,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int?,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      almacen: json['almacen'] != null
          ? Almacen.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map((d) => PrestamoEventoDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
      ventas: json['ventas'] as List?,
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => DevolucionEvento.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PrestamoEventoDetalle {
  final int id;
  final int prestamoEventoId;
  final int prestableId;
  final int cantidadPrestada;
  final String? montoGarantia;
  final String? estado;
  final String? createdAt;
  final String? updatedAt;
  final String? almacenesIds;
  final int? cantidad;
  final String? almacenNombre;
  final Prestable? prestable;
  final List<DevolucionEventoDetalle>? devoluciones;
  final List<PrestamoEventoAlmacen>? almacenes;

  PrestamoEventoDetalle({
    required this.id,
    required this.prestamoEventoId,
    required this.prestableId,
    required this.cantidadPrestada,
    this.montoGarantia,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.almacenesIds,
    this.cantidad,
    this.almacenNombre,
    this.prestable,
    this.devoluciones,
    this.almacenes,
  });

  factory PrestamoEventoDetalle.fromJson(Map<String, dynamic> json) {
    return PrestamoEventoDetalle(
      id: json['id'] as int? ?? 0,
      prestamoEventoId: json['prestamo_evento_id'] as int? ?? 0,
      prestableId: json['prestable_id'] as int? ?? 0,
      cantidadPrestada: json['cantidad_prestada'] as int? ?? 0,
      montoGarantia: json['monto_garantia'] as String?,
      estado: json['estado'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      almacenesIds: json['almacenes_ids'] as String?,
      cantidad: json['cantidad'] as int?,
      almacenNombre: json['almacen_nombre'] as String?,
      prestable: json['prestable'] != null
          ? Prestable.fromJson(json['prestable'] as Map<String, dynamic>)
          : null,
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => DevolucionEventoDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
      // ✅ NUEVO: Parsear almacenes
      almacenes: (json['almacenes'] as List?)
          ?.map((a) => PrestamoEventoAlmacen.fromJson(a as Map<String, dynamic>))
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
    );
  }
}

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
          ?.map((d) => DevolucionEventoDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ✅ NUEVO: Almacenes en los que se distribuyó un préstamo de evento
class PrestamoEventoAlmacen {
  final int id;
  final int prestamoEventoDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoEventoAlmacen({
    required this.id,
    required this.prestamoEventoDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    required this.esProveedor,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoEventoAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoEventoAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoEventoDetalleId: json['prestamo_evento_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
