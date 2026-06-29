class PrestamoCompleto {
  final int id;
  final int? clienteId;
  final int? ventaId;
  final int? choferId;
  final bool esVenta;
  final bool esEvento;
  final String? estado;
  final String? fechaPrestamo;
  final String? fechaEsperadaDevolucion;
  final String? createdAt;
  final String? updatedAt;
  final double? montoGarantia;
  final String? observaciones;
  final String? tipoPrestamo;
  final String? telefonoCliente1;
  final String? telefonoCliente2;
  final int? almacenesPrestasblesId;
  final int? vehiculoId;

  // Cliente
  final Cliente? cliente;

  // Almacén
  final Almacen? almacen;

  // Chofer
  final ChoferPrestamo? chofer;

  // Vehículo
  final VehiculoPrestamo? vehiculo;

  // Evento
  final String? nombreEvento;
  final String? encargadoEvento;
  final String? direccionEvento;

  // Proveedor
  final Proveedor? proveedor;

  // Detalles
  final List<PrestamoDetalle>? detalles;

  // Devoluciones
  final List<Devolucion>? devoluciones;

  PrestamoCompleto({
    required this.id,
    this.clienteId,
    this.ventaId,
    this.choferId,
    this.esVenta = false,
    this.esEvento = false,
    this.estado,
    this.fechaPrestamo,
    this.fechaEsperadaDevolucion,
    this.createdAt,
    this.updatedAt,
    this.montoGarantia,
    this.observaciones,
    this.tipoPrestamo,
    this.telefonoCliente1,
    this.telefonoCliente2,
    this.almacenesPrestasblesId,
    this.vehiculoId,
    this.cliente,
    this.almacen,
    this.chofer,
    this.vehiculo,
    this.nombreEvento,
    this.encargadoEvento,
    this.direccionEvento,
    this.proveedor,
    this.detalles,
    this.devoluciones,
  });

  factory PrestamoCompleto.fromJson(Map<String, dynamic> json) {
    double? parseMontoGarantia(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PrestamoCompleto(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int?,
      ventaId: json['venta_id'] as int?,
      choferId: json['chofer_id'] as int?,
      esVenta: json['es_venta'] as bool? ?? false,
      esEvento: json['es_evento'] as bool? ?? false,
      estado: json['estado'] as String?,
      fechaPrestamo: json['fecha_prestamo'] as String?,
      fechaEsperadaDevolucion: json['fecha_esperada_devolucion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      montoGarantia: parseMontoGarantia(json['monto_garantia']),
      observaciones: json['observaciones'] as String?,
      tipoPrestamo: json['tipo_prestamo'] as String?,
      telefonoCliente1: json['telefono_cliente_1'] as String?,
      telefonoCliente2: json['telefono_cliente_2'] as String?,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int?,
      vehiculoId: json['vehiculo_id'] as int?,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      almacen: json['almacen'] != null
          ? Almacen.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      vehiculo: json['vehiculo'] != null
          ? VehiculoPrestamo.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
      nombreEvento: json['nombre_evento'] as String?,
      encargadoEvento: json['encargado_evento'] as String?,
      direccionEvento: json['direccion_evento'] as String?,
      proveedor: json['proveedor'] != null
          ? Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map((d) => PrestamoDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => Devolucion.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Cliente {
  final int id;
  final String nombre;
  final String? razonSocial;
  final String? nit;
  final String? telefono;
  final String? email;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    this.razonSocial,
    this.nit,
    this.telefono,
    this.email,
    this.activo = true,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      razonSocial: json['razon_social'] as String?,
      nit: json['nit'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class Proveedor {
  final int id;
  final String nombre;
  final String? razonSocial;
  final String? nit;
  final String? telefono;
  final String? email;
  final bool activo;

  Proveedor({
    required this.id,
    required this.nombre,
    this.razonSocial,
    this.nit,
    this.telefono,
    this.email,
    this.activo = true,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      razonSocial: json['razon_social'] as String?,
      nit: json['nit'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class PrestamoDetalle {
  final int id;
  final int prestamoId;
  final int prestableId;
  final int cantidadPrestada;
  final String? estado;
  final Prestable? prestable;
  final List<DevolucionDetalle>? devolucionDetalles;
  final List<PrestamoClienteAlmacen>? almacenes;

  PrestamoDetalle({
    required this.id,
    required this.prestamoId,
    required this.prestableId,
    required this.cantidadPrestada,
    this.estado,
    this.prestable,
    this.devolucionDetalles,
    this.almacenes,
  });

  factory PrestamoDetalle.fromJson(Map<String, dynamic> json) {
    return PrestamoDetalle(
      id: json['id'] as int? ?? 0,
      prestamoId: json['prestamo_cliente_id'] as int? ??
          json['prestamo_evento_id'] as int? ??
          json['prestamo_proveedor_id'] as int? ??
          0,
      prestableId: json['prestable_id'] as int? ?? 0,
      cantidadPrestada: json['cantidad_prestada'] as int? ?? 0,
      estado: json['estado'] as String?,
      prestable: json['prestable'] != null
          ? Prestable.fromJson(json['prestable'] as Map<String, dynamic>)
          : null,
      devolucionDetalles: (json['devolucion_detalles'] as List?)
          ?.map((d) => DevolucionDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
      almacenes: (json['almacenes'] as List?)
          ?.map((a) => PrestamoClienteAlmacen.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Prestable {
  final int id;
  final String nombre;
  final String codigo;
  final String tipo;
  final int? capacidad;
  final bool activo;

  Prestable({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.tipo,
    this.capacidad,
    this.activo = true,
  });

  factory Prestable.fromJson(Map<String, dynamic> json) {
    return Prestable(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      capacidad: json['capacidad'] as int?,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class DevolucionDetalle {
  final int id;
  final int cantidadDevuelta;
  final int cantidadDaniadaTotal;
  final String? montoCobradoDanio;
  final String? montoGarantiaDevuelta;
  final String? montoExcedidoDetalle;
  final String? fechaDevolucion;
  final String? observaciones;

  DevolucionDetalle({
    required this.id,
    required this.cantidadDevuelta,
    required this.cantidadDaniadaTotal,
    this.montoCobradoDanio,
    this.montoGarantiaDevuelta,
    this.montoExcedidoDetalle,
    this.fechaDevolucion,
    this.observaciones,
  });

  factory DevolucionDetalle.fromJson(Map<String, dynamic> json) {
    return DevolucionDetalle(
      id: json['id'] as int? ?? 0,
      cantidadDevuelta: json['cantidad_devuelta'] as int? ?? 0,
      cantidadDaniadaTotal: json['cantidad_dañada_total'] as int? ?? 0,
      montoCobradoDanio: json['monto_cobrado_daño'] as String?,
      montoGarantiaDevuelta: json['monto_garantia_devuelta'] as String?,
      montoExcedidoDetalle: json['monto_excedido_detalle'] as String?,
      fechaDevolucion: json['fecha_devolucion'] as String?,
      observaciones: json['observaciones'] as String?,
    );
  }
}

class Almacen {
  final int id;
  final String nombre;
  final String? direccion;
  final String? ubicacionFisica;
  final bool requiereTransporteExterno;
  final String? responsable;
  final String? telefono;
  final bool activo;
  final String? createdAt;
  final String? updatedAt;
  final bool esProveedor;

  Almacen({
    required this.id,
    required this.nombre,
    this.direccion,
    this.ubicacionFisica,
    this.requiereTransporteExterno = false,
    this.responsable,
    this.telefono,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
    this.esProveedor = false,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) {
    return Almacen(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      ubicacionFisica: json['ubicacion_fisica'] as String?,
      requiereTransporteExterno:
          json['requiere_transporte_externo'] as bool? ?? false,
      responsable: json['responsable'] as String?,
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      esProveedor: json['es_proveedor'] as bool? ?? false,
    );
  }
}

class ChoferPrestamo {
  final int id;
  final String? name;
  final String? usernick;
  final String? email;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final bool activo;
  final bool canAccessWeb;
  final bool canAccessMobile;
  final int? empresaId;

  ChoferPrestamo({
    required this.id,
    this.name,
    this.usernick,
    this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.activo = true,
    this.canAccessWeb = false,
    this.canAccessMobile = false,
    this.empresaId,
  });

  factory ChoferPrestamo.fromJson(Map<String, dynamic> json) {
    return ChoferPrestamo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      usernick: json['usernick'] as String?,
      email: json['email'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      activo: json['activo'] as bool? ?? true,
      canAccessWeb: json['can_access_web'] as bool? ?? false,
      canAccessMobile: json['can_access_mobile'] as bool? ?? false,
      empresaId: json['empresa_id'] as int?,
    );
  }
}

class VehiculoPrestamo {
  final int id;
  final String? placa;
  final String? marca;
  final String? modelo;
  final int? anho;
  final String? capacidadKg;
  final String? capacidadVolumen;
  final String? estado;
  final int? choferAsignadoId;
  final String? observaciones;
  final bool activo;
  final String? createdAt;
  final String? updatedAt;
  final int? localidadId;

  VehiculoPrestamo({
    required this.id,
    this.placa,
    this.marca,
    this.modelo,
    this.anho,
    this.capacidadKg,
    this.capacidadVolumen,
    this.estado,
    this.choferAsignadoId,
    this.observaciones,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
    this.localidadId,
  });

  factory VehiculoPrestamo.fromJson(Map<String, dynamic> json) {
    return VehiculoPrestamo(
      id: json['id'] as int? ?? 0,
      placa: json['placa'] as String?,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      anho: json['anho'] as int?,
      capacidadKg: json['capacidad_kg'] as String?,
      capacidadVolumen: json['capacidad_volumen'] as String?,
      estado: json['estado'] as String?,
      choferAsignadoId: json['chofer_asignado_id'] as int?,
      observaciones: json['observaciones'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      localidadId: json['localidad_id'] as int?,
    );
  }
}

class PrestamoClienteAlmacen {
  final int id;
  final int prestamoClienteDetalleId;
  final int almacenesPrestasblesId;
  final int cantidad;
  final bool esProveedor;
  final String? createdAt;
  final String? updatedAt;

  PrestamoClienteAlmacen({
    required this.id,
    required this.prestamoClienteDetalleId,
    required this.almacenesPrestasblesId,
    required this.cantidad,
    this.esProveedor = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PrestamoClienteAlmacen.fromJson(Map<String, dynamic> json) {
    return PrestamoClienteAlmacen(
      id: json['id'] as int? ?? 0,
      prestamoClienteDetalleId: json['prestamo_cliente_detalle_id'] as int? ?? 0,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
      esProveedor: json['es_proveedor'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class Devolucion {
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
  final List<DevolucionDetalle>? detalles;

  Devolucion({
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

  factory Devolucion.fromJson(Map<String, dynamic> json) {
    return Devolucion(
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
          ?.map((d) => DevolucionDetalle.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
