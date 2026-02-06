import 'client.dart';

enum TipoVisitaPreventista { COBRO, TOMA_PEDIDO, SUPERVISION, OTRO }

enum EstadoVisitaPreventista { EXITOSA, NO_ATENDIDO }

enum MotivoNoAtencionVisita {
  CLIENTE_CERRADO,
  CLIENTE_AUSENTE,
  DIRECCION_INCORRECTA,
  OTRO,
}

class VisitaPreventistaCliente {
  final int id;
  final int preventistaId;
  final int clienteId;
  final DateTime fechaHoraVisita;
  final TipoVisitaPreventista tipoVisita;
  final EstadoVisitaPreventista estadoVisita;
  final MotivoNoAtencionVisita? motivoNoAtencion;
  final double latitud;
  final double longitud;
  final String? fotoLocal;
  final String? observaciones;
  final bool dentroVentanaHoraria;
  final int? ventanaEntregaId;
  final Client? cliente;
  final String? preventistaNombre;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VisitaPreventistaCliente({
    required this.id,
    required this.preventistaId,
    required this.clienteId,
    required this.fechaHoraVisita,
    required this.tipoVisita,
    required this.estadoVisita,
    this.motivoNoAtencion,
    required this.latitud,
    required this.longitud,
    this.fotoLocal,
    this.observaciones,
    required this.dentroVentanaHoraria,
    this.ventanaEntregaId,
    this.cliente,
    this.preventistaNombre,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitaPreventistaCliente.fromJson(Map<String, dynamic> json) {
    return VisitaPreventistaCliente(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      preventistaId: json['preventista_id'] is int
          ? json['preventista_id']
          : int.parse(json['preventista_id'].toString()),
      clienteId: json['cliente_id'] is int
          ? json['cliente_id']
          : int.parse(json['cliente_id'].toString()),
      fechaHoraVisita: DateTime.parse(json['fecha_hora_visita']),
      tipoVisita: _parseTipoVisita(json['tipo_visita']),
      estadoVisita: _parseEstadoVisita(json['estado_visita']),
      motivoNoAtencion: json['motivo_no_atencion'] != null
          ? _parseMotivoNoAtencion(json['motivo_no_atencion'])
          : null,
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      fotoLocal: json['foto_local'],
      observaciones: json['observaciones'],
      dentroVentanaHoraria: json['dentro_ventana_horaria'] ?? false,
      ventanaEntregaId: json['ventana_entrega_id'] != null
          ? json['ventana_entrega_id'] is int
                ? json['ventana_entrega_id']
                : int.parse(json['ventana_entrega_id'].toString())
          : null,
      cliente: json['cliente'] != null
          ? Client.fromJson(json['cliente'])
          : null,
      preventistaNombre: json['preventista']?['nombre'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'preventista_id': preventistaId,
      'cliente_id': clienteId,
      'fecha_hora_visita': fechaHoraVisita.toIso8601String(),
      'tipo_visita': tipoVisita.name,
      'estado_visita': estadoVisita.name,
      'motivo_no_atencion': motivoNoAtencion?.name,
      'latitud': latitud,
      'longitud': longitud,
      'foto_local': fotoLocal,
      'observaciones': observaciones,
      'dentro_ventana_horaria': dentroVentanaHoraria,
      'ventana_entrega_id': ventanaEntregaId,
    };
  }

  static TipoVisitaPreventista _parseTipoVisita(String value) {
    return TipoVisitaPreventista.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoVisitaPreventista.OTRO,
    );
  }

  static EstadoVisitaPreventista _parseEstadoVisita(String value) {
    return EstadoVisitaPreventista.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoVisitaPreventista.EXITOSA,
    );
  }

  static MotivoNoAtencionVisita _parseMotivoNoAtencion(String value) {
    return MotivoNoAtencionVisita.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MotivoNoAtencionVisita.OTRO,
    );
  }
}

// Extensions para labels
extension TipoVisitaLabel on TipoVisitaPreventista {
  String get label {
    switch (this) {
      case TipoVisitaPreventista.COBRO:
        return 'Cobro';
      case TipoVisitaPreventista.TOMA_PEDIDO:
        return 'Toma de Pedido';
      case TipoVisitaPreventista.SUPERVISION:
        return 'Supervisión';
      case TipoVisitaPreventista.OTRO:
        return 'Otro';
    }
  }
}

extension EstadoVisitaLabel on EstadoVisitaPreventista {
  String get label {
    switch (this) {
      case EstadoVisitaPreventista.EXITOSA:
        return 'Exitosa';
      case EstadoVisitaPreventista.NO_ATENDIDO:
        return 'No Atendido';
    }
  }
}

extension MotivoNoAtencionLabel on MotivoNoAtencionVisita {
  String get label {
    switch (this) {
      case MotivoNoAtencionVisita.CLIENTE_CERRADO:
        return 'Cliente Cerrado';
      case MotivoNoAtencionVisita.CLIENTE_AUSENTE:
        return 'Cliente Ausente';
      case MotivoNoAtencionVisita.DIRECCION_INCORRECTA:
        return 'Dirección Incorrecta';
      case MotivoNoAtencionVisita.OTRO:
        return 'Otro Motivo';
    }
  }
}
