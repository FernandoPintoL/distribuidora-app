import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'client.dart';
import 'pedido_item.dart';
import 'pedido_estado_historial.dart';
import 'reserva_stock.dart';
import 'chofer.dart';
import 'camion.dart';
import 'direccion_cliente.dart';
import 'user.dart';
import 'pedido_venta.dart';
import 'pedido_timeline_event.dart';
import '../services/estados_helpers.dart';

class Pedido {
  final int id;
  final String numero;
  final int? clienteId;
  final Client? cliente;
  final int? direccionId;
  final ClientAddress? direccionEntrega;
  final int? direccionEntregaSolicitadaId;
  final DireccionCliente? direccionEntregaSolicitada;
  final int? direccionEntregaConfirmadaId;
  final DireccionCliente? direccionEntregaConfirmada;

  // Estados del pedido - AHORA DINÁMICOS desde estados_logistica
  final String estadoCodigo; // Ej: 'PENDIENTE', 'APROBADA', 'EN_RUTA'
  final String estadoCategoria; // Ej: 'proforma', 'venta_logistica'
  final Map<String, dynamic>?
  estadoData; // Datos completos: id, codigo, nombre, color, icono
  final DateTime? fechaProgramada;
  final DateTime? horaInicioPreferida;
  final DateTime? horaFinPreferida;

  // Getters para información visual (usando EstadosHelper como fallback)
  String get estadoNombre =>
      estadoData?['nombre'] ??
      EstadosHelper.getEstadoLabel(estadoCategoria, estadoCodigo);

  String get estadoColor =>
      estadoData?['color'] ??
      EstadosHelper.getEstadoColor(estadoCategoria, estadoCodigo);

  String get estadoIcono =>
      estadoData?['icono'] ??
      EstadosHelper.getEstadoIcon(estadoCategoria, estadoCodigo);

  // Montos
  final double subtotal;
  final double descuento; // Descuento aplicado
  final double impuesto;
  final double total;
  final String? observaciones;
  final String? observacionesRechazo;
  final int? monedaId; // ID de la moneda

  // Items del pedido
  final List<PedidoItem> items;

  // Tracking
  final List<PedidoEstadoHistorial> historialEstados;
  final List<ReservaStock> reservas;

  // Asignaciones (para admin/chofer)
  final int? choferId;
  final Chofer? chofer;
  final int? camionId;
  final Camion? camion;

  // Metadata
  final String canalOrigen;
  final DateTime fechaCreacion;
  final DateTime? updatedAt; // Última actualización
  final DateTime? fechaAprobacion;
  final DateTime? fechaEntrega;
  final int? usuarioAprobadorId;
  final int? usuarioCreadorId; // ID del usuario que creó el pedido
  final User? usuarioCreador; // Usuario que creó el pedido
  final String? comentariosAprobacion;
  final String? comentarioRechazo;

  // ✅ NUEVO: Fechas de vencimiento y entrega solicitada
  final DateTime? fechaVencimiento;
  final DateTime? fechaEntregaSolicitada;
  final String? horaEntregaSolicitada; // Hora solicitada (HH:MM:SS)
  final DateTime? fechaEntregaConfirmada; // Fecha confirmada de entrega
  final String? horaEntregaConfirmada; // Hora confirmada (HH:MM:SS)

  // Comprobantes de entrega
  final String? firmaDigitalUrl;
  final String? fotoEntregaUrl;
  final DateTime? fechaFirmaEntrega;

  // Campos de proforma (nuevo backend)
  final int? estadoProformaId;

  // ✅ NUEVO: Información de entrega y coordinación
  final String? tipoEntrega; // DELIVERY, PICKUP
  final String? politicaPago; // CONTRA_ENTREGA, CREDITO, etc
  final int? preventistaId; // ID del preventista asignado
  final bool requiereEnvio; // ¿Requiere envío?
  final bool coordinacionCompletada; // ¿Coordinación completada?

  // ✅ NUEVO: Información de la venta cuando se convierte
  final int? ventaId;
  final String? ventaNumero;
  final PedidoVenta? venta;

  Pedido({
    required this.id,
    required this.numero,
    this.clienteId,
    this.cliente,
    this.direccionId,
    this.direccionEntrega,
    this.direccionEntregaSolicitadaId,
    this.direccionEntregaSolicitada,
    this.direccionEntregaConfirmadaId,
    this.direccionEntregaConfirmada,
    required this.estadoCodigo,
    required this.estadoCategoria,
    this.estadoData,
    this.fechaProgramada,
    this.horaInicioPreferida,
    this.horaFinPreferida,
    required this.subtotal,
    this.descuento = 0.0,
    required this.impuesto,
    required this.total,
    this.monedaId,
    this.observaciones,
    this.observacionesRechazo,
    this.items = const [],
    this.historialEstados = const [],
    this.reservas = const [],
    this.choferId,
    this.chofer,
    this.camionId,
    this.camion,
    required this.canalOrigen,
    required this.fechaCreacion,
    this.updatedAt,
    this.fechaAprobacion,
    this.fechaEntrega,
    this.usuarioAprobadorId,
    this.usuarioCreadorId,
    this.usuarioCreador,
    this.comentariosAprobacion,
    this.comentarioRechazo,
    this.firmaDigitalUrl,
    this.fotoEntregaUrl,
    this.fechaFirmaEntrega,
    this.estadoProformaId,
    this.fechaVencimiento,
    this.fechaEntregaSolicitada,
    this.horaEntregaSolicitada,
    this.fechaEntregaConfirmada,
    this.horaEntregaConfirmada,
    this.tipoEntrega,
    this.politicaPago,
    this.preventistaId,
    this.requiereEnvio = false,
    this.coordinacionCompletada = false,
    this.ventaId,
    this.ventaNumero,
    this.venta,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    try {
      if (json.isEmpty) {
        throw Exception('Empty JSON provided for Pedido');
      }

      // Safely parse all datetime fields (backend can use created_at or fecha_creacion)
      final createdAtString = json['created_at'] ?? json['fecha_creacion'];
      final createdAt = createdAtString != null
          ? DateTime.parse(createdAtString as String)
          : DateTime.now();

      // ✅ NUEVO: Parsear objeto estado dinámico desde backend
      // El backend puede enviar:
      // 1. Formato app: { 'estado': { id, codigo, nombre, color, icono, categoria } }
      // 2. Formato snake_case: { 'estado_logistica': { id, codigo, nombre, ... } }
      // 3. Formato camelCase: { 'estadoLogistica': { ... } }
      // 4. Legacy: { 'estado': 'CODIGO_STRING' }
      final estadoObj =
          json['estado'] ?? json['estado_logistica'] ?? json['estadoLogistica'];
      String estadoCodigo = 'PENDIENTE';
      String estadoCategoria = 'proforma';
      Map<String, dynamic>? estadoData;

      if (estadoObj is Map<String, dynamic>) {
        // Objeto completo con datos dinámicos
        estadoCodigo = estadoObj['codigo'] as String? ?? 'PENDIENTE';
        estadoCategoria = estadoObj['categoria'] as String? ?? 'proforma';
        estadoData = estadoObj;
        debugPrint(
          '✅ Pedido.fromJson - Estado parseado: $estadoCodigo ($estadoCategoria)',
        );
      } else if (estadoObj is String) {
        // Solo código string (legacy)
        estadoCodigo = estadoObj;
        estadoData = null;
        debugPrint('✅ Pedido.fromJson - Estado string legacy: $estadoCodigo');
      } else {
        debugPrint(
          '⚠️ Pedido.fromJson - No se encontró estado, usando default: $estadoCodigo',
        );
      }

      // Safely parse nested objects with fallback
      Client? cliente;
      try {
        if (json['cliente'] != null) {
          cliente = Client.fromJson(json['cliente'] as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing cliente: $e');
      }

      ClientAddress? direccionEntrega;
      try {
        if (json['direccion_entrega'] != null) {
          direccionEntrega = ClientAddress.fromJson(
            json['direccion_entrega'] as Map<String, dynamic>,
          );
        } else if (json['direccion_solicitada'] != null) {
          direccionEntrega = ClientAddress.fromJson(
            json['direccion_solicitada'] as Map<String, dynamic>,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing direccionEntrega: $e');
      }

      return Pedido(
        id: json['id'] as int,
        numero: json['numero'] as String,
        clienteId: json['cliente_id'] as int?,
        cliente: cliente,
        direccionId: json['direccion_id'] as int?,
        direccionEntrega: direccionEntrega,
        direccionEntregaSolicitadaId: json['direccion_entrega_solicitada_id'] as int?,
        direccionEntregaSolicitada: _safeParseDireccionCliente(json['direccion_entrega_solicitada']),
        direccionEntregaConfirmadaId: json['direccion_entrega_confirmada_id'] as int?,
        direccionEntregaConfirmada: _safeParseDireccionCliente(json['direccion_entrega_confirmada']),
        estadoCodigo: estadoCodigo,
        estadoCategoria: estadoCategoria,
        estadoData: estadoData,
        // Backend can use fecha_programada, fecha_entrega_solicitada, or fecha
        fechaProgramada: json['fecha_programada'] != null
            ? DateTime.parse(json['fecha_programada'] as String)
            : (json['fecha_entrega_solicitada'] != null
                  ? DateTime.parse(json['fecha_entrega_solicitada'] as String)
                  : (json['fecha'] != null
                        ? DateTime.parse(json['fecha'] as String)
                        : null)),
        // Backend returns hora_inicio_preferida (use only if it's a complete DateTime)
        // Ignore hora_entrega_solicitada as it's just a time string (HH:MM:SS)
        horaInicioPreferida: json['hora_inicio_preferida'] != null
            ? DateTime.parse(json['hora_inicio_preferida'] as String)
            : null,
        horaFinPreferida: json['hora_fin_preferida'] != null
            ? DateTime.parse(json['hora_fin_preferida'] as String)
            : null,
        // Convert string numbers to double
        subtotal: _parseDouble(json['subtotal']),
        descuento: _parseDouble(json['descuento']),
        impuesto: _parseDouble(json['impuesto']),
        total: _parseDouble(json['total']),
        monedaId: json['moneda_id'] as int?,
        observaciones: json['observaciones'] as String?,
        observacionesRechazo: json['observaciones_rechazo'] as String?,
        // Backend returns detalles instead of items
        items: json['items'] != null
            ? (json['items'] as List)
                  .map(
                    (item) => PedidoItem.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
            : (json['detalles'] != null
                  ? (json['detalles'] as List)
                        .map(
                          (item) =>
                              PedidoItem.fromJson(item as Map<String, dynamic>),
                        )
                        .toList()
                  : []),
        historialEstados: json['historial_estados'] != null
            ? (json['historial_estados'] as List)
                  .map(
                    (h) => PedidoEstadoHistorial.fromJson(
                      h as Map<String, dynamic>,
                    ),
                  )
                  .toList()
            : [],
        reservas: json['reservas'] != null
            ? (json['reservas'] as List)
                  .map((r) => ReservaStock.fromJson(r as Map<String, dynamic>))
                  .toList()
            : [],
        choferId: json['chofer_id'] as int?,
        chofer: _safeParseChofer(json['chofer']),
        camionId: json['camion_id'] as int?,
        camion: _safeParseCamion(json['camion']),
        canalOrigen: json['canal_origen'] as String? ?? 'APP_EXTERNA',
        fechaCreacion: createdAt,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        fechaAprobacion: json['fecha_aprobacion'] != null
            ? DateTime.parse(json['fecha_aprobacion'] as String)
            : null,
        fechaEntrega: json['fecha_entrega'] != null
            ? DateTime.parse(json['fecha_entrega'] as String)
            : null,
        usuarioAprobadorId: json['usuario_aprobador_id'] as int?,
        usuarioCreadorId: json['usuario_creador_id'] as int?,
        usuarioCreador: _safeParseUser(json['usuario_creador']),
        comentariosAprobacion: json['comentarios_aprobacion'] as String?,
        comentarioRechazo:
            json['comentario_rechazo'] as String? ??
            json['observaciones_rechazo'] as String?,
        firmaDigitalUrl: json['firma_digital_url'] as String?,
        fotoEntregaUrl: json['foto_entrega_url'] as String?,
        fechaFirmaEntrega: json['fecha_firma_entrega'] != null
            ? DateTime.parse(json['fecha_firma_entrega'] as String)
            : null,
        estadoProformaId: json['estado_proforma_id'] as int?,
        // ✅ NUEVO: Parsear fechas de vencimiento y entrega solicitada
        fechaVencimiento: json['fecha_vencimiento'] != null
            ? DateTime.parse(json['fecha_vencimiento'] as String)
            : null,
        fechaEntregaSolicitada: json['fecha_entrega_solicitada'] != null
            ? DateTime.parse(json['fecha_entrega_solicitada'] as String)
            : null,
        horaEntregaSolicitada: json['hora_entrega_solicitada'] as String?,
        fechaEntregaConfirmada: json['fecha_entrega_confirmada'] != null
            ? DateTime.parse(json['fecha_entrega_confirmada'] as String)
            : null,
        horaEntregaConfirmada: json['hora_entrega_confirmada'] as String?,
        direccionEntregaConfirmada: _safeParseDireccionCliente(
          json['direccion_entrega_confirmada'],
        ),
        tipoEntrega: json['tipo_entrega'] as String?,
        politicaPago: json['politica_pago'] as String?,
        preventistaId: json['preventista_id'] as int?,
        requiereEnvio: json['requiere_envio'] as bool? ?? false,
        coordinacionCompletada:
            json['coordinacion_completada'] as bool? ?? false,
        // ✅ NUEVO: Información de venta cuando se convierte
        ventaId: json['venta_id'] as int?,
        ventaNumero:
            json['venta_numero'] as String? ??
            json['venta']?['numero'] as String?,
        venta: _safeParsePedidoVenta(json['venta']),
      );
    } catch (e) {
      debugPrint('❌ Error parsing Pedido: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
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
        debugPrint('⚠️  Could not parse "$value" as double, defaulting to 0.0');
        return 0.0;
      }
    }
    return 0.0;
  }

  static Chofer? _safeParseChofer(dynamic data) {
    try {
      if (data != null && data is Map<String, dynamic>) {
        return Chofer.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing Chofer: $e');
    }
    return null;
  }

  static Camion? _safeParseCamion(dynamic data) {
    try {
      if (data != null && data is Map<String, dynamic>) {
        return Camion.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing Camion: $e');
    }
    return null;
  }

  static User? _safeParseUser(dynamic data) {
    try {
      if (data != null && data is Map<String, dynamic>) {
        return User.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing User: $e');
    }
    return null;
  }

  static DireccionCliente? _safeParseDireccionCliente(dynamic data) {
    try {
      if (data != null && data is Map<String, dynamic>) {
        return DireccionCliente.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing DireccionCliente: $e');
    }
    return null;
  }

  static PedidoVenta? _safeParsePedidoVenta(dynamic data) {
    try {
      if (data != null && data is Map<String, dynamic>) {
        final venta = PedidoVenta.fromJson(data);
        debugPrint(
          '📋 Pedido.fromJson - Venta parseada: #${venta.numero} con ${venta.confirmacionesEntrega.length} confirmaciones',
        );
        return venta;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing PedidoVenta: $e');
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'cliente_id': clienteId,
      'cliente': cliente?.toJson(),
      'direccion_id': direccionId,
      'direccion_entrega': direccionEntrega?.toJson(),
      'direccion_entrega_solicitada_id': direccionEntregaSolicitadaId,
      'direccion_entrega_solicitada': direccionEntregaSolicitada?.toJson(),
      'direccion_entrega_confirmada_id': direccionEntregaConfirmadaId,
      'direccion_entrega_confirmada': direccionEntregaConfirmada?.toJson(),
      // ✅ NUEVO: Devolver objeto estado completo si está disponible
      'estado': estadoData ?? estadoCodigo,
      'estado_codigo': estadoCodigo,
      'estado_categoria': estadoCategoria,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'hora_inicio_preferida': horaInicioPreferida?.toIso8601String(),
      'hora_fin_preferida': horaFinPreferida?.toIso8601String(),
      'subtotal': subtotal,
      'descuento': descuento,
      'impuesto': impuesto,
      'total': total,
      'moneda_id': monedaId,
      'observaciones': observaciones,
      'observaciones_rechazo': observacionesRechazo,
      'items': items.map((item) => item.toJson()).toList(),
      'historial_estados': historialEstados.map((h) => h.toJson()).toList(),
      'reservas': reservas.map((r) => r.toJson()).toList(),
      'chofer_id': choferId,
      'chofer': chofer?.toJson(),
      'camion_id': camionId,
      'camion': camion?.toJson(),
      'canal_origen': canalOrigen,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'fecha_aprobacion': fechaAprobacion?.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'usuario_aprobador_id': usuarioAprobadorId,
      'usuario_creador_id': usuarioCreadorId,
      'usuario_creador': usuarioCreador?.toJson(),
      'comentarios_aprobacion': comentariosAprobacion,
      'comentario_rechazo': comentarioRechazo,
      'firma_digital_url': firmaDigitalUrl,
      'foto_entrega_url': fotoEntregaUrl,
      'fecha_firma_entrega': fechaFirmaEntrega?.toIso8601String(),
      'estado_proforma_id': estadoProformaId,
      // ✅ NUEVO: Incluir fechas de vencimiento y entrega solicitada
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'fecha_entrega_solicitada': fechaEntregaSolicitada?.toIso8601String(),
      'hora_entrega_solicitada': horaEntregaSolicitada,
      'fecha_entrega_confirmada': fechaEntregaConfirmada?.toIso8601String(),
      'hora_entrega_confirmada': horaEntregaConfirmada,
      'direccion_entrega_confirmada': direccionEntregaConfirmada?.toJson(),
      'tipo_entrega': tipoEntrega,
      'politica_pago': politicaPago,
      'preventista_id': preventistaId,
      'requiere_envio': requiereEnvio,
      'coordinacion_completada': coordinacionCompletada,
      // ✅ NUEVO: Incluir información de venta
      'venta_id': ventaId,
      'venta_numero': ventaNumero,
    };
  }

  Pedido copyWith({
    int? id,
    String? numero,
    int? clienteId,
    Client? cliente,
    int? direccionId,
    ClientAddress? direccionEntrega,
    int? direccionEntregaSolicitadaId,
    DireccionCliente? direccionEntregaSolicitada,
    int? direccionEntregaConfirmadaId,
    DireccionCliente? direccionEntregaConfirmada,
    String? estadoCodigo,
    String? estadoCategoria,
    Map<String, dynamic>? estadoData,
    DateTime? fechaProgramada,
    DateTime? horaInicioPreferida,
    DateTime? horaFinPreferida,
    double? subtotal,
    double? descuento,
    double? impuesto,
    double? total,
    int? monedaId,
    String? observaciones,
    String? observacionesRechazo,
    List<PedidoItem>? items,
    List<PedidoEstadoHistorial>? historialEstados,
    List<ReservaStock>? reservas,
    int? choferId,
    Chofer? chofer,
    int? camionId,
    Camion? camion,
    String? canalOrigen,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
    DateTime? fechaAprobacion,
    DateTime? fechaEntrega,
    int? usuarioAprobadorId,
    int? usuarioCreadorId,
    User? usuarioCreador,
    String? comentariosAprobacion,
    String? comentarioRechazo,
    String? firmaDigitalUrl,
    String? fotoEntregaUrl,
    DateTime? fechaFirmaEntrega,
    int? estadoProformaId,
    DateTime? fechaVencimiento,
    DateTime? fechaEntregaSolicitada,
    String? horaEntregaSolicitada,
    DateTime? fechaEntregaConfirmada,
    String? horaEntregaConfirmada,
    DireccionCliente? direccionEntregaConfirmada,
    String? tipoEntrega,
    String? politicaPago,
    int? preventistaId,
    bool? requiereEnvio,
    bool? coordinacionCompletada,
    int? ventaId,
    String? ventaNumero,
    PedidoVenta? venta,
  }) {
    return Pedido(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      cliente: cliente ?? this.cliente,
      direccionId: direccionId ?? this.direccionId,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      direccionEntregaSolicitadaId: direccionEntregaSolicitadaId ?? this.direccionEntregaSolicitadaId,
      direccionEntregaSolicitada: direccionEntregaSolicitada ?? this.direccionEntregaSolicitada,
      direccionEntregaConfirmadaId: direccionEntregaConfirmadaId ?? this.direccionEntregaConfirmadaId,
      direccionEntregaConfirmada: direccionEntregaConfirmada ?? this.direccionEntregaConfirmada,
      estadoCodigo: estadoCodigo ?? this.estadoCodigo,
      estadoCategoria: estadoCategoria ?? this.estadoCategoria,
      estadoData: estadoData ?? this.estadoData,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      horaInicioPreferida: horaInicioPreferida ?? this.horaInicioPreferida,
      horaFinPreferida: horaFinPreferida ?? this.horaFinPreferida,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      monedaId: monedaId ?? this.monedaId,
      observaciones: observaciones ?? this.observaciones,
      observacionesRechazo: observacionesRechazo ?? this.observacionesRechazo,
      items: items ?? this.items,
      historialEstados: historialEstados ?? this.historialEstados,
      reservas: reservas ?? this.reservas,
      choferId: choferId ?? this.choferId,
      chofer: chofer ?? this.chofer,
      camionId: camionId ?? this.camionId,
      camion: camion ?? this.camion,
      canalOrigen: canalOrigen ?? this.canalOrigen,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      updatedAt: updatedAt ?? this.updatedAt,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      usuarioAprobadorId: usuarioAprobadorId ?? this.usuarioAprobadorId,
      usuarioCreadorId: usuarioCreadorId ?? this.usuarioCreadorId,
      usuarioCreador: usuarioCreador ?? this.usuarioCreador,
      comentariosAprobacion:
          comentariosAprobacion ?? this.comentariosAprobacion,
      comentarioRechazo: comentarioRechazo ?? this.comentarioRechazo,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      fotoEntregaUrl: fotoEntregaUrl ?? this.fotoEntregaUrl,
      fechaFirmaEntrega: fechaFirmaEntrega ?? this.fechaFirmaEntrega,
      estadoProformaId: estadoProformaId ?? this.estadoProformaId,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaEntregaSolicitada:
          fechaEntregaSolicitada ?? this.fechaEntregaSolicitada,
      horaEntregaSolicitada:
          horaEntregaSolicitada ?? this.horaEntregaSolicitada,
      fechaEntregaConfirmada:
          fechaEntregaConfirmada ?? this.fechaEntregaConfirmada,
      horaEntregaConfirmada:
          horaEntregaConfirmada ?? this.horaEntregaConfirmada,
      direccionEntregaConfirmada:
          direccionEntregaConfirmada ?? this.direccionEntregaConfirmada,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      politicaPago: politicaPago ?? this.politicaPago,
      preventistaId: preventistaId ?? this.preventistaId,
      requiereEnvio: requiereEnvio ?? this.requiereEnvio,
      coordinacionCompletada:
          coordinacionCompletada ?? this.coordinacionCompletada,
      ventaId: ventaId ?? this.ventaId,
      ventaNumero: ventaNumero ?? this.ventaNumero,
      venta: venta ?? this.venta,
    );
  }

  // Helpers
  bool get tieneReservasActivas {
    return reservas.any((r) => r.estado == EstadoReserva.ACTIVA);
  }

  bool get tieneReservasProximasAVencer {
    return reservas.any(
      (r) => r.estado == EstadoReserva.ACTIVA && r.tiempoRestante.inHours < 24,
    );
  }

  ReservaStock? get reservaMasProximaAVencer {
    final reservasActivas = reservas
        .where((r) => r.estado == EstadoReserva.ACTIVA)
        .toList();

    if (reservasActivas.isEmpty) return null;

    reservasActivas.sort(
      (a, b) => a.fechaExpiracion.compareTo(b.fechaExpiracion),
    );
    return reservasActivas.first;
  }

  bool get puedeExtenderReservas {
    // ✅ Actualizado: Comparar con código string en lugar de enum
    return estadoCodigo == 'PENDIENTE' && tieneReservasActivas;
  }

  int get cantidadItems {
    return items.length;
  }

  int get cantidadTotalProductos {
    return items.fold(0, (sum, item) => sum + item.cantidad.toInt());
  }

  // ✅ NUEVOS HELPERS PARA TIMELINE UNIFICADO
  /// Obtener si este pedido ya se convirtió de proforma a venta
  bool get esVenta {
    // Verificar si existe relación venta (por ventaId o ventaNumero)
    return ventaId != null && ventaId! > 0;
  }

  /// Obtener el estado de pago si es venta (historial)
  String? get estadoPagoFromHistorial {
    // Buscar en el historial un evento de pago
    final pagoPendiente = historialEstados
        .where(
          (h) =>
              h.estadoNuevo.toUpperCase().contains('PAGO') ||
              h.estadoNuevo.toUpperCase().contains('PENDIENTE'),
        )
        .toList();

    if (pagoPendiente.isNotEmpty) {
      return pagoPendiente.last.estadoNuevo;
    }
    return null;
  }

  /// Obtener el estado logístico si es venta (por categoría)
  bool get tieneEstadoLogistico {
    return estadoCategoria.contains('logistica') ||
        estadoCategoria.contains('entrega');
  }

  /// Para display: categoría humanizada
  String get categoriaHumanizada {
    switch (estadoCategoria.toLowerCase()) {
      case 'proforma':
        return '📋 Proforma';
      case 'venta':
        return '💳 Venta';
      case 'venta_logistica':
      case 'venta_logísticas':
        return '🚚 Envío';
      default:
        return estadoCategoria;
    }
  }

  /// Timeline visual: retorna lista de eventos en orden cronológico
  List<PedidoTimelineEvent> get timelineEvents {
    final events = <PedidoTimelineEvent>[];

    // Agregar evento de creación (proforma inicial)
    events.add(
      PedidoTimelineEvent(
        categoria: 'proforma',
        estado: 'PENDIENTE',
        label: 'Proforma Creada',
        timestamp: fechaCreacion,
        icono: '📋',
      ),
    );

    // Agregar eventos del historial en orden
    for (final evento in historialEstados) {
      // ✅ ACTUALIZADO: Usar estadoNuevo en lugar de estadoCodigo
      final esConversion = evento.estadoNuevo.toUpperCase() == 'CONVERTIDA';

      // Detectar si es un evento de proforma (estado anterior/nuevo contiene palabras clave)
      final esProformaEvent =
          evento.estadoNuevo.toUpperCase().contains('PENDIENTE') ||
          evento.estadoNuevo.toUpperCase().contains('APROBADA') ||
          evento.estadoNuevo.toUpperCase().contains('CONVERTIDA') ||
          evento.estadoNuevo.toUpperCase().contains('RECHAZADA') ||
          evento.estadoNuevo.toUpperCase().contains('VENCIDA');

      if (esProformaEvent) {
        events.add(
          PedidoTimelineEvent(
            categoria: 'proforma',
            estado: evento.estadoNuevo,
            label: 'Proforma ${evento.estadoNuevo}',
            timestamp: evento.fecha,
            icono: _getIconoParaEstadoProforma(evento.estadoNuevo),
          ),
        );
      }

      // Si se convirtió, agregar venta
      if (esConversion) {
        events.add(
          PedidoTimelineEvent(
            categoria: 'venta',
            estado: 'CREADA',
            label: 'Convertida a Venta',
            timestamp: evento.fecha,
            icono: '💳',
          ),
        );
      }
    }

    // Agregar evento actual si es logística
    if (tieneEstadoLogistico) {
      events.add(
        PedidoTimelineEvent(
          categoria: 'logistica',
          estado: estadoCodigo,
          label: estadoNombre,
          timestamp: DateTime.now(),
          icono: _getIconoParaEstadoLogistica(estadoCodigo),
        ),
      );
    }

    return events;
  }

  String _getIconoParaEstadoProforma(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'PENDIENTE':
        return '⏳';
      case 'APROBADA':
        return '✅';
      case 'CONVERTIDA':
        return '🔄';
      case 'RECHAZADA':
        return '❌';
      case 'VENCIDA':
        return '⏰';
      default:
        return '📋';
    }
  }

  String _getIconoParaEstadoLogistica(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'PENDIENTE_ENVIO':
        return '📦';
      case 'EN_TRANSITO':
        return '🚚';
      case 'ENTREGADO':
        return '✅';
      case 'ENTREGADA':
        return '✅';
      default:
        return '🚚';
    }
  }
}
