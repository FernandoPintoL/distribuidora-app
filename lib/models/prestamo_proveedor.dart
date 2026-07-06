import 'almacen_prestable.dart';
import 'devolucion_prestamo_proveedor.dart';
import 'prestable.dart';
import 'prestamo_cliente.dart';
import 'prestamo_proveedor_detalle_por_almacen.dart';
import 'prestamo_ubicacion.dart';
import 'proveedor.dart';

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
  final AlmacenPrestable? almacen;
  final ChoferPrestamo? chofer;
  final List<PrestamoProveedorDetalle>? detalles;
  // ✅ NUEVO: Ubicación del préstamo
  final List<PrestamoUbicacion>? ubicaciones;
  final List<DevolucionProveedor>? devoluciones;

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
    this.ubicaciones,
    this.devoluciones,
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
          ? AlmacenPrestable.fromJson(json['almacen'] as Map<String, dynamic>)
          : null,
      chofer: json['chofer'] != null
          ? ChoferPrestamo.fromJson(json['chofer'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List?)
          ?.map(
            (d) => PrestamoProveedorDetalle.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
      // ✅ NUEVO: Cargar ubicacion
      ubicaciones: (json['ubicaciones'] as List?)
          ?.map((u) => PrestamoUbicacion.fromJson(u as Map<String, dynamic>))
          .toList(),
      devoluciones: (json['devoluciones'] as List?)
          ?.map((d) => DevolucionProveedor.fromJson(d as Map<String, dynamic>))
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
      // ✅ NUEVO: Parsear almacenes
      almacenes: (json['almacenes'] as List?)
          ?.map(
            (a) => PrestamoProveedorAlmacen.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
