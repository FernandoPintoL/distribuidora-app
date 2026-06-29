import 'package:flutter/foundation.dart';
import 'credito_cliente.dart';
import 'cliente.dart';
import 'localidad.dart';
import 'direccion_cliente.dart';
import 'estado_logistico.dart';
import 'pedido.dart';
import 'entrega_venta_confirmacion.dart';
import 'product.dart';
import 'combo_item_seleccionado.dart';

// ✅ NUEVO 2026-06-23: Clase para información de proforma relacionada a una venta
class Proforma {
  final int id;
  final String numero;
  final String? estado;
  final DateTime? fecha;
  final double? total;

  Proforma({
    required this.id,
    required this.numero,
    this.estado,
    this.fecha,
    this.total,
  });

  factory Proforma.fromJson(Map<String, dynamic> json) {
    return Proforma(
      id: json['id'] as int,
      numero: json['numero'] as String,
      estado: json['estado'] as String?,
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'] as String) : null,
      total: (json['total'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'estado': estado,
      'fecha': fecha?.toIso8601String(),
      'total': total,
    };
  }
}

class Venta {
  final int id;
  final String numero;
  final Cliente? cliente; // ✅ NUEVO 2026-06-14: Cliente como objeto completo
  final double total;
  final double subtotal;
  final double descuento; // Puede venir del backend o calcularse
  final double impuesto;
  final String? observaciones;
  final String? observacionesLogistica;  // ✅ NUEVO: Observaciones sobre entrega (completa, incidentes, etc.)
  final int? estadoLogisticoId; // ID del estado logístico
  final String?
  estadoLogisticoCodigo; // Código del estado (PENDIENTE_ENVIO, EN_TRANSITO, etc)
  final String estadoLogistico; // Nombre del estado logístico
  final String? estadoLogisticoColor; // Color del estado (hex)
  final String? estadoLogisticoIcon; // Icono del estado
  final EstadoLogistico? estadoLogisticoObj; // ✅ NUEVO: Objeto EstadoLogistico completo (centralizado)
  final EstadoDocumento? estadoDocumentoObj; // ✅ NUEVO: Objeto EstadoDocumento (Aprobado, Rechazado, etc)
  final String estadoPago;
  final DateTime fecha;
  final List<VentaDetalle> detalles;

  // ✅ NUEVO 2026-06-14: Información de dirección del cliente como objeto
  final DireccionCliente? direccionCliente;

  // ✅ NUEVO: Campos de pago y origen
  final String? canalOrigen; // Canal de venta: PRESENCIAL, ONLINE, etc.
  final String? politicaPago; // Política de pago
  final TipoPago? tipoPago; // Tipo de pago relacionado

  // ✅ NUEVO (2026-02-17): Información de entrega
  final int? entregaId; // ID de la entrega asignada a esta venta
  final String? numeroEntrega; // Número de entrega (ej: ENT-20260217-001)
  final String? estadoEntrega; // Estado de la entrega (ASIGNADA, EN_CAMINO, ENTREGADO, etc)
  final String? tipoEntrega; // ✅ NUEVO (2026-03-05): Tipo de entrega (COMPLETA, CON_NOVEDAD)
  final String? tipoNovedad; // ✅ NUEVO (2026-03-05): Tipo de novedad (CLIENTE_CERRADO, DEVOLUCION_PARCIAL, etc)
  final List<EntregaVentaConfirmacion> confirmaciones; // ✅ NUEVO (2026-03-05): Confirmaciones de entrega
  final Map<String, dynamic>? resumenPago; // ✅ NUEVO (2026-06-12): Resumen de pagos (estado, pendiente, fecha)

  // ✅ NUEVO (2026-06-23): Información de proforma y entrega relacionadas
  final int? proformaId; // ID de la proforma relacionada
  final Proforma? proforma; // Proforma relacionada a esta venta (si existe)

  Venta({
    required this.id,
    required this.numero,
    this.cliente, // ✅ NUEVO 2026-06-14: Cliente como objeto
    required this.total,
    required this.subtotal,
    required this.descuento,
    required this.impuesto,
    this.observaciones,
    this.observacionesLogistica,  // ✅ NUEVO
    this.estadoLogisticoId,
    this.estadoLogisticoCodigo,
    required this.estadoLogistico,
    this.estadoLogisticoColor,
    this.estadoLogisticoIcon,
    this.estadoLogisticoObj, // ✅ NUEVO: Objeto EstadoLogistico
    this.estadoDocumentoObj, // ✅ NUEVO: Objeto EstadoDocumento
    required this.estadoPago,
    required this.fecha,
    this.detalles = const [],
    this.direccionCliente, // ✅ NUEVO 2026-06-14
    this.canalOrigen,
    this.politicaPago,
    this.tipoPago,
    this.entregaId,
    this.numeroEntrega,
    this.estadoEntrega,
    this.tipoEntrega, // ✅ NUEVO
    this.tipoNovedad, // ✅ NUEVO
    this.confirmaciones = const [], // ✅ NUEVO
    this.resumenPago, // ✅ NUEVO: Resumen de pagos
    this.proformaId, // ✅ NUEVO 2026-06-23: ID de proforma
    this.proforma, // ✅ NUEVO 2026-06-23: Proforma relacionada
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    // ✅ NUEVO 2026-06-14: Parsear cliente como objeto completo
    Cliente? clienteObj;
    if (json['cliente'] is Map<String, dynamic>) {
      clienteObj = Cliente.fromJson(json['cliente'] as Map<String, dynamic>);
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
    EstadoLogistico? estadoLogisticoObjValue; // ✅ NUEVO: Objeto EstadoLogistico

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
      // ✅ NUEVO: Parsear objeto EstadoLogistico completo
      try {
        estadoLogisticoObjValue = EstadoLogistico.fromJson(estadoObj);
      } catch (e) {
        debugPrint('⚠️ Error parseando EstadoLogistico: $e');
      }
    } else {
      // Fallback: parsear como string o id
      estadoLogisticoNombre =
          json['estado_logistico'] as String? ?? 'EN_TRANSITO';
      estadoLogisticoId = json['estado_logistico_id'] as int?;
      estadoLogisticoCodigo = null; // No disponible en fallback
    }

    // ✅ NUEVO: Parsear estado documento (Aprobado, Rechazado, etc)
    EstadoDocumento? estadoDocumentoObjValue;
    if (json['estado_documento'] is Map<String, dynamic>) {
      try {
        estadoDocumentoObjValue =
            EstadoDocumento.fromJson(json['estado_documento'] as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ Error parseando EstadoDocumento: $e');
      }
    }

    // ✅ NUEVO 2026-06-14: Parsear direccionCliente como objeto completo (si viene como relación)
    DireccionCliente? direccionClienteObj;

    Map<String, dynamic>? dirClienteJson;
    if (json['direccionCliente'] is Map<String, dynamic>) {
      dirClienteJson = json['direccionCliente'] as Map<String, dynamic>;
    } else if (json['direccion_cliente'] is Map<String, dynamic>) {
      dirClienteJson = json['direccion_cliente'] as Map<String, dynamic>;
    } else if (json['direccion_cliente'] is List) {
      // ✅ NUEVO 2026-06-14: Si viene como array, buscar la dirección con coordenadas
      final direccionesArray = json['direccion_cliente'] as List<dynamic>;

      // Preferir dirección con latitud/longitud y que sea principal o de entrega
      for (var dir in direccionesArray) {
        if (dir is Map<String, dynamic>) {
          final lat = dir['latitud'];
          final lng = dir['longitud'];
          if (lat != null && lng != null) {
            dirClienteJson = dir;
            break; // Usar la primera con coordenadas válidas
          }
        }
      }

      // Si ninguna tiene coordenadas, usar la principal o la primera
      if (dirClienteJson == null && direccionesArray.isNotEmpty) {
        final primera = direccionesArray.first as Map<String, dynamic>;
        dirClienteJson = primera;
      }
    }

    if (dirClienteJson != null) {
      try {
        direccionClienteObj = DireccionCliente.fromJson(dirClienteJson);
        debugPrint('✅ [VENTA] DireccionCliente parseada - Venta: ${json['numero']} | Lat: ${direccionClienteObj.latitud}, Lng: ${direccionClienteObj.longitud}');
      } catch (e) {
        debugPrint('⚠️ [VENTA] Error parseando direccionCliente: $e');
      }
    } else {
      debugPrint('⚠️ [VENTA] No se encontró direccionCliente para venta: ${json['numero']}');
    }
    // Si no viene la relación direccionCliente, simplemente quedará null (es normal en algunos endpoints)

    // Calcular descuento si no viene en el JSON
    double descuentoValue = 0.0;
    if (json['descuento'] != null) {
      descuentoValue = _parseDouble(json['descuento']);
    }

    // ✅ ACTUALIZADO 2026-06-14: Parsear tipoPago si viene como objeto (algunos endpoints no incluyen la relación)
    TipoPago? tipoPago;
    if (json['tipo_pago'] is Map<String, dynamic>) {
      tipoPago = TipoPago.fromJson(json['tipo_pago'] as Map<String, dynamic>);
      debugPrint('✅ [VENTA] Tipo de pago parseado: ${tipoPago.nombre}');
    } else if (json['tipoPago'] is Map<String, dynamic>) {
      tipoPago = TipoPago.fromJson(json['tipoPago'] as Map<String, dynamic>);
      debugPrint('✅ [VENTA] Tipo de pago parseado (camelCase): ${tipoPago.nombre}');
    }
    // Si no viene la relación tipoPago, simplemente quedará null (es normal en algunos endpoints)

    return Venta(
      id: _parseInt(json['id']),
      numero: json['numero'] as String? ?? '',
      cliente: clienteObj, // ✅ NUEVO 2026-06-14: Cliente como objeto
      total: _parseDouble(json['total']),
      subtotal: _parseDouble(json['subtotal']),
      descuento: descuentoValue,
      impuesto: _parseDouble(json['impuesto']),
      observaciones: json['observaciones'] as String?,
      observacionesLogistica: json['observaciones_logistica'] as String?,  // ✅ NUEVO
      estadoLogisticoId: estadoLogisticoId,
      estadoLogisticoCodigo: estadoLogisticoCodigo,
      estadoLogistico: estadoLogisticoNombre,
      estadoLogisticoColor: estadoLogisticoColor,
      estadoLogisticoIcon: estadoLogisticoIcon,
      estadoLogisticoObj: estadoLogisticoObjValue, // ✅ NUEVO: Objeto EstadoLogistico centralizado
      estadoDocumentoObj: estadoDocumentoObjValue, // ✅ NUEVO: Objeto EstadoDocumento
      estadoPago: json['estado_pago'] as String? ?? 'PENDIENTE',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      detalles: detallesList,
      direccionCliente: direccionClienteObj, // ✅ NUEVO 2026-06-14
      canalOrigen: json['canal_origen'] as String?,
      politicaPago: json['politica_pago'] as String?,
      tipoPago: tipoPago,
      entregaId: json['entrega_id'] as int?,
      numeroEntrega: json['numero_entrega'] as String?,
      // ✅ CORREGIDO 2026-03-05: Extraer código de estado_entrega (es un objeto, no string)
      estadoEntrega: (() {
        if (json['estado_entrega'] is Map<String, dynamic>) {
          return (json['estado_entrega'] as Map<String, dynamic>)['codigo'] as String?;
        }
        return json['estado_entrega'] as String?;
      })(),
      // ✅ CORREGIDO 2026-03-05: Extraer tipo_entrega y tipo_novedad de la primera confirmación
      tipoEntrega: (() {
        final confirmacionesList = (json['entregas_venta_confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? (json['confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (confirmacionesList.isNotEmpty) {
          return confirmacionesList.first['tipo_confirmacion'] as String?;
        }
        return json['tipo_entrega'] as String?;
      })(),
      tipoNovedad: (() {
        final confirmacionesList = (json['entregas_venta_confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? (json['confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (confirmacionesList.isNotEmpty) {
          return confirmacionesList.first['tipo_novedad'] as String?;
        }
        return json['tipo_novedad'] as String?;
      })(),
      confirmaciones: (() {
        final confirmacionesList = (json['entregas_venta_confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? (json['confirmaciones'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        return confirmacionesList
            .map((c) => EntregaVentaConfirmacion.fromJson(c))
            .toList();
      })(), // ✅ NUEVO: Confirmaciones de entrega (entregas_venta_confirmaciones del backend)
      resumenPago: json['resumen_pago'] is Map<String, dynamic>
          ? json['resumen_pago'] as Map<String, dynamic>
          : null, // ✅ NUEVO: Resumen de pagos
      // ✅ NUEVO 2026-06-23: Parsear proforma relacionada
      proformaId: json['proforma_id'] as int?,
      proforma: (() {
        try {
          if (json['proforma'] is Map<String, dynamic>) {
            return Proforma.fromJson(json['proforma'] as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('⚠️ Error parseando proforma: $e');
        }
        return null;
      })(),
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
      'cliente': cliente?.toJson(), // ✅ NUEVO 2026-06-14: Cliente como objeto
      'total': total,
      'subtotal': subtotal,
      'descuento': descuento,
      'impuesto': impuesto,
      'observaciones': observaciones,
      'observaciones_logistica': observacionesLogistica,
      'estado_logistico_id': estadoLogisticoId,
      'estado_logistico_codigo': estadoLogisticoCodigo,
      'estado_logistico': estadoLogistico,
      'estado_logistico_color': estadoLogisticoColor,
      'estado_logistico_icon': estadoLogisticoIcon,
      'estado_pago': estadoPago,
      'fecha': fecha.toIso8601String(),
      'direccion_cliente': direccionCliente?.toJson(),
      'canal_origen': canalOrigen,
      'politica_pago': politicaPago,
      'tipo_pago': tipoPago?.toJson(),
      'proforma_id': proformaId, // ✅ NUEVO 2026-06-23: ID de proforma
      'proforma': proforma?.toJson(), // ✅ NUEVO 2026-06-23: Proforma relacionada
    };
  }

  /// Obtener tipo de confirmación de la primera confirmación
  String? get tipoConfirmacionValue {
    if (confirmaciones.isEmpty) return tipoNovedad;
    return confirmaciones.first.tipoConfirmacion;
  }

  /// Obtener tipo de novedad de la primera confirmación
  String? get tipoNovedadValue {
    if (confirmaciones.isEmpty) return tipoNovedad;
    return confirmaciones.first.tipoNovedad;
  }

  /// Obtener tipo de entrega de la primera confirmación
  String? get tipoEntregaValue {
    if (confirmaciones.isEmpty) return tipoEntrega;
    return confirmaciones.first.tipoEntrega;
  }

  /// Obtener la primera confirmación de la venta
  EntregaVentaConfirmacion? get confirmacionPrimera {
    return confirmaciones.isNotEmpty ? confirmaciones.first : null;
  }

  /// Obtener la última confirmación de la venta
  EntregaVentaConfirmacion? get confirmacionReciente {
    return confirmaciones.isNotEmpty ? confirmaciones.last : null;
  }

  @override
  String toString() =>
      'Venta(numero: $numero, cliente: ${cliente?.nombre}, total: $total)';
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
  final String? nombreProducto; // ✅ NUEVO 2026-02-21: Nombre del producto desde backend
  final List<ComboItemSeleccionado>? comboItemsSeleccionados;

  VentaDetalle({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
    this.producto,
    this.nombreProducto,
    this.comboItemsSeleccionados,
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
      nombreProducto: json['producto_nombre'] as String?,
      comboItemsSeleccionados: json['combo_items_seleccionados'] != null
          ? (json['combo_items_seleccionados'] as List)
              .map((item) => ComboItemSeleccionado.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
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
      if (comboItemsSeleccionados != null)
        'combo_items_seleccionados': comboItemsSeleccionados,
    };
  }
}

/// Representa un producto
class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double? peso;
  final List<ImagenProducto>? imagenes;
  final List<ComboItem>? comboItems; // NUEVO: Items del combo

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.peso,
    this.imagenes,
    this.comboItems,
  });

  /// Obtener la imagen principal (es_principal == true) o la primera imagen
  ImagenProducto? get imagenPrincipal {
    if (imagenes == null || imagenes!.isEmpty) return null;
    // Buscar la imagen principal
    try {
      return imagenes!.firstWhere((img) => img.esPrincipal == true);
    } catch (e) {
      // Si no hay imagen principal, retornar la primera
      return imagenes!.isNotEmpty ? imagenes!.first : null;
    }
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    List<ImagenProducto>? imagenes;

    // Intentar parsear 'imagenes' como array (formato antiguo)
    if (json['imagenes'] != null && json['imagenes'] is List) {
      imagenes = (json['imagenes'] as List)
          .map((img) => ImagenProducto.fromJson(img))
          .toList();
    }
    // Si no, intentar parsear 'imagen' como objeto singular (formato nuevo)
    else if (json['imagen'] != null && json['imagen'] is Map<String, dynamic>) {
      try {
        final imagenObj = ImagenProducto.fromJson(json['imagen'] as Map<String, dynamic>);
        imagenes = [imagenObj];
      } catch (e) {
        debugPrint('⚠️ Error parseando imagen singular: $e');
        imagenes = null;
      }
    }

    // Parsear combo items
    List<ComboItem>? comboItems;
    if (json['comboItems'] != null && json['comboItems'] is List) {
      comboItems = (json['comboItems'] as List)
          .map((item) => ComboItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      peso: (json['peso'] as num?)?.toDouble(),
      imagenes: imagenes,
      comboItems: comboItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'peso': peso,
      'imagenes': imagenes?.map((img) => img.toJson()).toList(),
      if (comboItems != null)
        'comboItems': comboItems!.map((item) => item.toJson()).toList(),
    };
  }
}

class ImagenProducto {
  final int? id;
  final int? productoId;
  final String url;
  final bool esPrincipal;
  final int? orden;

  ImagenProducto({
    this.id,
    this.productoId,
    required this.url,
    this.esPrincipal = false,
    this.orden,
  });

  factory ImagenProducto.fromJson(Map<String, dynamic> json) {
    return ImagenProducto(
      id: json['id'] as int?,
      productoId: json['producto_id'] as int?,
      url: json['url'] as String,
      esPrincipal: json['es_principal'] == true || json['es_principal'] == 1,
      orden: json['orden'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'url': url,
      'es_principal': esPrincipal,
      'orden': orden,
    };
  }
}
