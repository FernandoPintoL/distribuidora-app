// ✅ IMPORTAR CLASES EXISTENTES
import 'package:distribuidora/models/user.dart';
import 'almacen_prestable.dart';
import 'cliente.dart';
import 'devolucion_prestamo_cliente.dart';
import 'prestable.dart';
import 'prestamo_cliente_detalle_por_almacen.dart';
import 'prestamo_ubicacion.dart';
import 'vehiculo.dart';

class PrestamoCliente {
  final int id;
  final int? clienteId;
  final int? ventaId;
  final int? choferId;
  final String? estado;
  final String? fechaPrestamo;
  final String? fechaEsperadaDevolucion;
  final String? createdAt;
  final String? updatedAt;
  final double? montoGarantia;
  final String? observaciones;
  final String? telefonoCliente1;
  final String? telefonoCliente2;
  final int? almacenesPrestasblesId;
  final int? vehiculoId;
  final int? created_by;
  final User? creador;

  // Cliente
  final Cliente? cliente;

  // Almacén
  final AlmacenPrestable? almacen;

  // Chofer
  final ChoferPrestamo? chofer;

  // Vehículo
  final Vehiculo? vehiculo;

  // Detalles
  final List<PrestamoClienteDetalle>? detalles;

  // Devoluciones
  final List<DevolucionCliente>? devoluciones;

  // ✅ NUEVO: Ubicación del préstamo
  final List<PrestamoUbicacion>? ubicaciones;

  PrestamoCliente({
    required this.id,
    this.clienteId,
    this.ventaId,
    this.choferId,
    this.estado,
    this.fechaPrestamo,
    this.fechaEsperadaDevolucion,
    this.createdAt,
    this.updatedAt,
    this.montoGarantia,
    this.observaciones,
    this.telefonoCliente1,
    this.telefonoCliente2,
    this.almacenesPrestasblesId,
    this.vehiculoId,
    this.cliente,
    this.almacen,
    this.chofer,
    this.vehiculo,
    this.detalles,
    this.devoluciones,
    this.ubicaciones,
    this.created_by,
    this.creador,
  });

  factory PrestamoCliente.fromJson(Map<String, dynamic> json) {
    double? parseMontoGarantia(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PrestamoCliente(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int?,
      ventaId: json['venta_id'] as int?,
      choferId: json['chofer_id'] as int?,
      estado: json['estado'] as String?,
      fechaPrestamo: json['fecha_prestamo'] as String?,
      fechaEsperadaDevolucion: json['fecha_esperada_devolucion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      montoGarantia: parseMontoGarantia(json['monto_garantia']),
      observaciones: json['observaciones'] as String?,
      telefonoCliente1: json['telefono_cliente_1'] as String?,
      telefonoCliente2: json['telefono_cliente_2'] as String?,
      almacenesPrestasblesId: json['almacenes_prestables_id'] as int?,
      vehiculoId: json['vehiculo_id'] as int?,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      almacen: json['almacen'] != null
          ? AlmacenPrestable.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      vehiculo: json['vehiculo'] != null
          ? Vehiculo.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map(
            (d) => PrestamoClienteDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => DevolucionCliente.fromJson(d as Map<String, dynamic>))
          .toList(),
      ubicaciones: (json['ubicaciones'] as List?)
          ?.map((u) => PrestamoUbicacion.fromJson(u as Map<String, dynamic>))
          .toList(),
      created_by: json['created_by'] as int?,
      creador: json['creador'] != null
          ? User.fromJson(json['creador'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PrestamoClienteDetalle {
  final int id;
  final int prestamoId;
  final int prestableId;
  final int cantidadPrestada;
  final String? estado;
  final Prestable? prestable;
  final List<PrestamoClienteAlmacen>? prestamoPorAlmacenes;

  PrestamoClienteDetalle({
    required this.id,
    required this.prestamoId,
    required this.prestableId,
    required this.cantidadPrestada,
    this.estado,
    this.prestable,
    this.prestamoPorAlmacenes,
  });

  factory PrestamoClienteDetalle.fromJson(Map<String, dynamic> json) {
    return PrestamoClienteDetalle(
      id: json['id'] as int? ?? 0,
      prestamoId:
          json['prestamo_cliente_id'] as int? ??
          json['prestamo_evento_id'] as int? ??
          json['prestamo_proveedor_id'] as int? ??
          0,
      prestableId: json['prestable_id'] as int? ?? 0,
      cantidadPrestada: json['cantidad_prestada'] as int? ?? 0,
      estado: json['estado'] as String?,
      prestable: json['prestable'] != null
          ? Prestable.fromJson(json['prestable'] as Map<String, dynamic>)
          : null,
      prestamoPorAlmacenes: (json['prestamo_por_almacenes'] as List?)
          ?.map(
            (a) => PrestamoClienteAlmacen.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
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
