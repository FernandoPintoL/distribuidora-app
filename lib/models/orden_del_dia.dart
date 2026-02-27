import 'localidad.dart';

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

  Preventista({required this.id, required this.nombre, required this.codigo});

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
  final String? fotoPerfil;
  final DireccionCliente direccion;
  final VentanaHoraria ventanaHoraria;
  final bool visitado;
  final String? visitadoALas;
  final String? tipoVisitaRealizada;
  final String? estadoVisita;
  final double? limiteCredito;
  final bool puedeAtenerCredito;
  final Localidad? localidad;

  ClienteOrdenDelDia({
    required this.clienteId,
    required this.nombre,
    this.telefono,
    this.email,
    this.codigoCliente,
    this.fotoPerfil,
    required this.direccion,
    required this.ventanaHoraria,
    required this.visitado,
    this.visitadoALas,
    this.tipoVisitaRealizada,
    this.estadoVisita,
    this.limiteCredito,
    required this.puedeAtenerCredito,
    this.localidad,
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
      fotoPerfil: json['foto_perfil'],
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
      localidad: json['localidad'] != null
          ? Localidad.fromJson(json['localidad'])
          : null,
    );
  }
}

class DireccionCliente {
  final String? direccion;
  final String? ciudad;
  final double? latitud;
  final double? longitud;

  DireccionCliente({this.direccion, this.ciudad, this.latitud, this.longitud});

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

  VentanaHoraria({this.horaInicio, this.horaFin, this.diaSemana});

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

/// ✅ NUEVO: Resumen de un día de la semana para vista de semana
class DiaSemanaResumen {
  final String fecha;
  final String diaSemana;
  final int totalClientes;
  final int visitados;
  final int pendientes;
  final double porcentajeCompletado;

  DiaSemanaResumen({
    required this.fecha,
    required this.diaSemana,
    required this.totalClientes,
    required this.visitados,
    required this.pendientes,
    required this.porcentajeCompletado,
  });

  /// Helper: ¿Es hoy?
  bool get esHoy {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    return fecha == hoy;
  }

  factory DiaSemanaResumen.fromJson(Map<String, dynamic> json) {
    return DiaSemanaResumen(
      fecha: json['fecha'] ?? '',
      diaSemana: json['dia_semana'] ?? '',
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

/// ✅ NUEVO: Semana completa con todos los días
class SemanaOrdenDelDia {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<DiaSemanaResumen> dias;

  SemanaOrdenDelDia({
    required this.fechaInicio,
    required this.fechaFin,
    required this.dias,
  });

  /// Helper: Obtener día actual si existe en la semana
  DiaSemanaResumen? get diaActual {
    try {
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      return dias.firstWhere((d) => d.fecha == hoy);
    } catch (e) {
      return null;
    }
  }

  factory SemanaOrdenDelDia.fromJson(Map<String, dynamic> json) {
    final diasList = (json['semana'] as List?)
            ?.map((d) => DiaSemanaResumen.fromJson(d))
            .toList() ??
        [];

    return SemanaOrdenDelDia(
      fechaInicio: DateTime.parse(diasList.isNotEmpty
          ? diasList.first.fecha
          : DateTime.now().toIso8601String()),
      fechaFin: DateTime.parse(diasList.isNotEmpty
          ? diasList.last.fecha
          : DateTime.now().toIso8601String()),
      dias: diasList,
    );
  }
}
