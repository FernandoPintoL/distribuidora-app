import 'package:distribuidora/models/almacen_prestable.dart';
import 'cliente.dart';
import 'devolucion_prestamo_evento.dart';
import 'prestable.dart';
import 'prestamo_cliente.dart';
import 'prestamo_evento_detalle_por_almacen.dart';
import 'prestamo_ubicacion.dart';

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
  final AlmacenPrestable? almacen;
  final ChoferPrestamo? chofer;
  final List<PrestamoEventoDetalle>? detalles;
  final List<dynamic>? ventas;
  final List<DevolucionEvento>? devoluciones;
  // ✅ NUEVO: Ubicación del préstamo
  final List<PrestamoUbicacion>? ubicaciones;

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
    this.ubicaciones,
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
          ? AlmacenPrestable.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map(
            (d) => PrestamoEventoDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
      ventas: json['ventas'] as List?,
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => DevolucionEvento.fromJson(d as Map<String, dynamic>))
          .toList(),
      // ✅ NUEVO: Cargar ubicacion
      ubicaciones: (json['ubicaciones'] as List?)
          ?.map((u) => PrestamoUbicacion.fromJson(u as Map<String, dynamic>))
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
          ?.map(
            (d) => DevolucionEventoDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
      // ✅ NUEVO: Parsear almacenes
      almacenes: (json['almacenes'] as List?)
          ?.map(
            (a) => PrestamoEventoAlmacen.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// ✅ NUEVO: Almacenes en los que se distribuyó un préstamo de evento
