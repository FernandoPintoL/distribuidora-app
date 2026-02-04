import 'credito_cliente.dart'; // Para importar TipoPago

class Venta {
  final int id;
  final String numero;
  final String? cliente;
  final String? clienteNombre;
  final String? clienteTelefono; // Nuevo: Teléfono del cliente
  final double total;
  final double subtotal;
  final double descuento; // Puede venir del backend o calcularse
  final double impuesto;
  final String? observaciones;
  final int? estadoLogisticoId; // ID del estado logístico
  final String?
  estadoLogisticoCodigo; // Código del estado (PENDIENTE_ENVIO, EN_TRANSITO, etc)
  final String estadoLogistico; // Nombre del estado logístico
  final String? estadoLogisticoColor; // Color del estado (hex)
  final String? estadoLogisticoIcon; // Icono del estado
  final String estadoPago;
  final DateTime fecha;
  final List<VentaDetalle> detalles;

  // Ubicación de entrega desde direccionCliente
  final double? latitud; // Latitud de entrega
  final double? longitud; // Longitud de entrega
  final String? direccion; // Dirección de entrega completa

  // ✅ NUEVO: Campos de pago y origen
  final String? canalOrigen; // Canal de venta: PRESENCIAL, ONLINE, etc.
  final String? politicaPago; // Política de pago
  final TipoPago? tipoPago; // Tipo de pago relacionado

  Venta({
    required this.id,
    required this.numero,
    this.cliente,
    this.clienteNombre,
    this.clienteTelefono,
    required this.total,
    required this.subtotal,
    required this.descuento,
    required this.impuesto,
    this.observaciones,
    this.estadoLogisticoId,
    this.estadoLogisticoCodigo,
    required this.estadoLogistico,
    this.estadoLogisticoColor,
    this.estadoLogisticoIcon,
    required this.estadoPago,
    required this.fecha,
    this.detalles = const [],
    this.latitud,
    this.longitud,
    this.direccion,
    this.canalOrigen,
    this.politicaPago,
    this.tipoPago,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    // Extraer nombre y teléfono del cliente si es un objeto
    String? clienteNom;
    String? clienteTel;
    if (json['cliente'] is Map<String, dynamic>) {
      final clienteObj = json['cliente'] as Map<String, dynamic>;
      clienteNom = clienteObj['nombre'] as String?;
      clienteTel = clienteObj['telefono'] as String?;
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

    // Parsear estado logístico (puede venir como objeto relationship o como string/id)
    int? estadoLogisticoId;
    String? estadoLogisticoCodigo; // Código del estado (PENDIENTE_ENVIO, etc)
    String estadoLogisticoNombre = 'EN_TRANSITO'; // default
    String? estadoLogisticoColor;
    String? estadoLogisticoIcon;

    // Intentar cargar desde la relación estadoLogistica (tabla estados_logistica)
    // El backend retorna en snake_case: estado_logistica
    Map<String, dynamic>? estadoObj;

    if (json['estado_logistica'] is Map<String, dynamic>) {
      estadoObj = json['estado_logistica'] as Map<String, dynamic>;
    } else if (json['estadoLogistica'] is Map<String, dynamic>) {
      estadoObj = json['estadoLogistica'] as Map<String, dynamic>;
    }

    if (estadoObj != null) {
      // Viene como objeto completo del backend (eager-loaded desde tabla estados_logistica)
      estadoLogisticoId = estadoObj['id'] as int?;
      estadoLogisticoCodigo =
          estadoObj['codigo'] as String?; // Capturar el código del estado
      estadoLogisticoNombre = estadoObj['nombre'] as String? ?? 'EN_TRANSITO';
      estadoLogisticoColor = estadoObj['color'] as String?;
      estadoLogisticoIcon = estadoObj['icono'] as String?;
    } else {
      // Fallback: parsear como string o id
      estadoLogisticoNombre =
          json['estado_logistico'] as String? ?? 'EN_TRANSITO';
      estadoLogisticoId = json['estado_logistico_id'] as int?;
      estadoLogisticoCodigo = null; // No disponible en fallback
    }

    // Parsear ubicación desde direccionCliente (probar ambos formatos: camelCase y snake_case)
    double? latEntrega;
    double? lngEntrega;
    String? direccionEntrega;

    Map<String, dynamic>? dirCliente;

    // Intentar camelCase primero
    if (json['direccionCliente'] is Map<String, dynamic>) {
      dirCliente = json['direccionCliente'] as Map<String, dynamic>;
    }
    // Si no, intentar snake_case
    else if (json['direccion_cliente'] is Map<String, dynamic>) {
      dirCliente = json['direccion_cliente'] as Map<String, dynamic>;
    }

    if (dirCliente != null) {
      latEntrega = (dirCliente['latitud'] as num?)?.toDouble();
      lngEntrega = (dirCliente['longitud'] as num?)?.toDouble();
      direccionEntrega = dirCliente['direccion'] as String?;
      // print('[VENTA_PARSE] direccionCliente encontrada: lat=$latEntrega, lng=$lngEntrega, dir=$direccionEntrega');
    } else {
      // print('[VENTA_PARSE] NO se encontró direccionCliente en JSON. Keys: ${json.keys.toList()}');
    }

    // Calcular descuento si no viene en el JSON
    double descuentoValue = 0.0;
    if (json['descuento'] != null) {
      descuentoValue = _parseDouble(json['descuento']);
    }

    // ✅ NUEVO: Parsear tipoPago si existe
    TipoPago? tipoPago;
    if (json['tipo_pago'] is Map<String, dynamic>) {
      tipoPago = TipoPago.fromJson(json['tipo_pago'] as Map<String, dynamic>);
    } else if (json['tipoPago'] is Map<String, dynamic>) {
      tipoPago = TipoPago.fromJson(json['tipoPago'] as Map<String, dynamic>);
    }

    return Venta(
      id: _parseInt(json['id']),
      numero: json['numero'] as String? ?? '',
      cliente: json['cliente'] is String ? json['cliente'] as String? : null,
      clienteNombre: clienteNom,
      clienteTelefono: clienteTel,
      total: _parseDouble(json['total']),
      subtotal: _parseDouble(json['subtotal']),
      descuento: descuentoValue,
      impuesto: _parseDouble(json['impuesto']),
      observaciones: json['observaciones'] as String?,
      estadoLogisticoId: estadoLogisticoId,
      estadoLogisticoCodigo: estadoLogisticoCodigo,
      estadoLogistico: estadoLogisticoNombre,
      estadoLogisticoColor: estadoLogisticoColor,
      estadoLogisticoIcon: estadoLogisticoIcon,
      estadoPago: json['estado_pago'] as String? ?? 'PENDIENTE',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      detalles: detallesList,
      latitud: latEntrega,
      longitud: lngEntrega,
      direccion: direccionEntrega,
      canalOrigen: json['canal_origen'] as String?,
      politicaPago: json['politica_pago'] as String?,
      tipoPago: tipoPago,
    );
  }

  // Helper to safely parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  // Helper to safely parse int from string or number
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'cliente': cliente,
      'cliente_telefono': clienteTelefono,
      'total': total,
      'subtotal': subtotal,
      'descuento': descuento,
      'impuesto': impuesto,
      'observaciones': observaciones,
      'estado_logistico_id': estadoLogisticoId,
      'estado_logistico_codigo': estadoLogisticoCodigo,
      'estado_logistico': estadoLogistico,
      'estado_logistico_color': estadoLogisticoColor,
      'estado_logistico_icon': estadoLogisticoIcon,
      'estado_pago': estadoPago,
      'fecha': fecha.toIso8601String(),
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'canal_origen': canalOrigen,
      'politica_pago': politicaPago,
      'tipo_pago': tipoPago?.toJson(),
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
  final double cantidad; // Cambiar a double para soportar decimales del backend
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

    // Parsear cantidad - puede venir como int, double o string (con decimales)
    double cantidadDouble = 0.0;
    try {
      if (json['cantidad'] is num) {
        cantidadDouble = (json['cantidad'] as num).toDouble();
      } else {
        cantidadDouble = double.parse(json['cantidad'].toString());
      }
    } catch (e) {
      // Si no se puede parsear, usar cantidad 0
      cantidadDouble = 0.0;
    }

    return VentaDetalle(
      id: _parseInt(json['id']),
      ventaId: _parseInt(json['venta_id']),
      productoId: _parseInt(json['producto_id']),
      cantidad: cantidadDouble,
      precioUnitario: _parseDouble(json['precio_unitario']),
      descuento: _parseDouble(json['descuento']),
      subtotal: _parseDouble(json['subtotal']),
      producto: productoObj,
    );
  }

  // Helper to safely parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  // Helper to safely parse int from string or number
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
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
