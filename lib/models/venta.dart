class Venta {
  final int id;
  final String numero;
  final String? cliente;
  final String? clienteNombre;
  final double total;
  final double subtotal;
  final double descuento;
  final double impuesto;
  final String? observaciones;
  final String estadoLogistico;
  final String estadoPago;
  final DateTime fecha;
  final List<VentaDetalle> detalles;

  Venta({
    required this.id,
    required this.numero,
    this.cliente,
    this.clienteNombre,
    required this.total,
    required this.subtotal,
    required this.descuento,
    required this.impuesto,
    this.observaciones,
    required this.estadoLogistico,
    required this.estadoPago,
    required this.fecha,
    this.detalles = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    // Extraer nombre del cliente si es un objeto
    String? clienteNom;
    if (json['cliente'] is Map<String, dynamic>) {
      final clienteObj = json['cliente'] as Map<String, dynamic>;
      clienteNom = clienteObj['nombre'] as String?;
    } else {
      clienteNom = json['cliente'] as String?;
    }

    // Parsear detalles/productos si existen
    List<VentaDetalle> detallesList = [];
    if (json['detalles'] is List) {
      detallesList = (json['detalles'] as List)
          .map((d) => VentaDetalle.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    return Venta(
      id: json['id'] as int,
      numero: json['numero'] as String,
      cliente: json['cliente'] is String ? json['cliente'] as String? : null,
      clienteNombre: clienteNom,
      total: double.parse(json['total'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      descuento: double.parse(json['descuento'].toString()),
      impuesto: double.parse(json['impuesto'].toString()),
      observaciones: json['observaciones'] as String?,
      estadoLogistico: json['estado_logistico'] as String? ?? 'EN_TRANSITO',
      estadoPago: json['estado_pago'] as String? ?? 'PENDIENTE',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      detalles: detallesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'cliente': cliente,
      'total': total,
      'subtotal': subtotal,
      'descuento': descuento,
      'impuesto': impuesto,
      'observaciones': observaciones,
      'estado_logistico': estadoLogistico,
      'estado_pago': estadoPago,
      'fecha': fecha.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Venta(numero: $numero, cliente: $clienteNombre, total: $total)';
}

/// Representa un detalle/línea de producto en una venta
class VentaDetalle {
  final int id;
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;
  final Producto? producto;

  VentaDetalle({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
    this.producto,
  });

  factory VentaDetalle.fromJson(Map<String, dynamic> json) {
    // Parsear producto si existe
    Producto? productoObj;
    if (json['producto'] is Map<String, dynamic>) {
      productoObj = Producto.fromJson(json['producto'] as Map<String, dynamic>);
    }

    return VentaDetalle(
      id: json['id'] as int,
      ventaId: json['venta_id'] as int,
      productoId: json['producto_id'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: double.parse(json['precio_unitario'].toString()),
      descuento: double.parse(json['descuento'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      producto: productoObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'descuento': descuento,
      'subtotal': subtotal,
      'producto': producto?.toJson(),
    };
  }
}

/// Representa un producto
class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double? peso;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.peso,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      peso: (json['peso'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'peso': peso,
    };
  }
}
