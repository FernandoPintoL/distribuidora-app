class OrdenDelDia {
  final String fecha;
  final String diaSemana;
  final Preventista preventista;
  final List<ClienteOrdenDelDia> clientes;
  final ResumenOrdenDelDia resumen;

  OrdenDelDia({
    required this.fecha,
    required this.diaSemana,
    required this.preventista,
    required this.clientes,
    required this.resumen,
  });

  factory OrdenDelDia.fromJson(Map<String, dynamic> json) {
    return OrdenDelDia(
      fecha: json['fecha'] ?? '',
      diaSemana: json['dia_semana'] ?? '',
      preventista: Preventista.fromJson(json['preventista'] ?? {}),
      clientes: json['clientes'] != null
          ? (json['clientes'] as List)
              .map((c) => ClienteOrdenDelDia.fromJson(c))
              .toList()
          : [],
      resumen: ResumenOrdenDelDia.fromJson(json['resumen'] ?? {}),
    );
  }
}

class Preventista {
  final int id;
  final String nombre;
  final String codigo;

  Preventista({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  factory Preventista.fromJson(Map<String, dynamic> json) {
    return Preventista(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'N/A',
      codigo: json['codigo'] ?? '',
    );
  }
}

class ClienteOrdenDelDia {
  final int clienteId;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? codigoCliente;
  final DireccionCliente direccion;
  final VentanaHoraria ventanaHoraria;
  final bool visitado;
  final String? visitadoALas;
  final String? tipoVisitaRealizada;
  final String? estadoVisita;
  final double? limiteCredito;
  final bool puedeAtenerCredito;

  ClienteOrdenDelDia({
    required this.clienteId,
    required this.nombre,
    this.telefono,
    this.email,
    this.codigoCliente,
    required this.direccion,
    required this.ventanaHoraria,
    required this.visitado,
    this.visitadoALas,
    this.tipoVisitaRealizada,
    this.estadoVisita,
    this.limiteCredito,
    required this.puedeAtenerCredito,
  });

  factory ClienteOrdenDelDia.fromJson(Map<String, dynamic> json) {
    return ClienteOrdenDelDia(
      clienteId: json['cliente_id'] is int
          ? json['cliente_id']
          : int.tryParse(json['cliente_id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      telefono: json['telefono'],
      email: json['email'],
      codigoCliente: json['codigo_cliente'],
      direccion: DireccionCliente.fromJson(json['direccion'] ?? {}),
      ventanaHoraria: VentanaHoraria.fromJson(json['ventana_horaria'] ?? {}),
      visitado: json['visitado'] ?? false,
      visitadoALas: json['visitado_a_las'],
      tipoVisitaRealizada: json['tipo_visita_realizada'],
      estadoVisita: json['estado_visita'],
      limiteCredito: json['limite_credito'] != null
          ? double.tryParse(json['limite_credito'].toString())
          : null,
      puedeAtenerCredito: json['puede_tener_credito'] ?? false,
    );
  }
}

class DireccionCliente {
  final String? direccion;
  final String? ciudad;
  final double? latitud;
  final double? longitud;

  DireccionCliente({
    this.direccion,
    this.ciudad,
    this.latitud,
    this.longitud,
  });

  factory DireccionCliente.fromJson(Map<String, dynamic> json) {
    return DireccionCliente(
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
    );
  }
}

class VentanaHoraria {
  final String? horaInicio;
  final String? horaFin;
  final int? diaSemana;

  VentanaHoraria({
    this.horaInicio,
    this.horaFin,
    this.diaSemana,
  });

  factory VentanaHoraria.fromJson(Map<String, dynamic> json) {
    return VentanaHoraria(
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      diaSemana: json['dia_semana'] is int
          ? json['dia_semana']
          : int.tryParse(json['dia_semana'].toString()),
    );
  }
}

class ResumenOrdenDelDia {
  final int totalClientes;
  final int visitados;
  final int pendientes;
  final double porcentajeCompletado;

  ResumenOrdenDelDia({
    required this.totalClientes,
    required this.visitados,
    required this.pendientes,
    required this.porcentajeCompletado,
  });

  factory ResumenOrdenDelDia.fromJson(Map<String, dynamic> json) {
    return ResumenOrdenDelDia(
      totalClientes: json['total_clientes'] is int
          ? json['total_clientes']
          : int.tryParse(json['total_clientes'].toString()) ?? 0,
      visitados: json['visitados'] is int
          ? json['visitados']
          : int.tryParse(json['visitados'].toString()) ?? 0,
      pendientes: json['pendientes'] is int
          ? json['pendientes']
          : int.tryParse(json['pendientes'].toString()) ?? 0,
      porcentajeCompletado: json['porcentaje_completado'] is num
          ? (json['porcentaje_completado'] as num).toDouble()
          : double.tryParse(json['porcentaje_completado'].toString()) ?? 0.0,
    );
  }
}
