import 'localidad.dart';

class DireccionCliente {
  final int id;
  final int? clienteId; // ✅ OPCIONAL: Puede no venir en algunos endpoints
  final int? localidadId; // ✅ OPCIONAL: Puede no venir en algunos endpoints
  final String direccion;
  final String? observaciones;
  final double? latitud;
  final double? longitud;
  final bool esPrincipal;
  final Localidad? localidad;

  DireccionCliente({
    required this.id,
    this.clienteId,
    this.localidadId,
    required this.direccion,
    this.observaciones,
    this.latitud,
    this.longitud,
    this.esPrincipal = false,
    this.localidad,
  });

  factory DireccionCliente.fromJson(Map<String, dynamic> json) {
    Localidad? localidadObj;
    if (json['localidad'] is Map<String, dynamic>) {
      localidadObj = Localidad.fromJson(json['localidad'] as Map<String, dynamic>);
    }

    return DireccionCliente(
      id: (json['id'] as int?) ?? 0, // ✅ SEGURO
      clienteId: json['cliente_id'] as int?, // ✅ OPCIONAL
      localidadId: json['localidad_id'] as int?, // ✅ OPCIONAL
      direccion: (json['direccion'] as String?) ?? '', // ✅ SEGURO
      observaciones: json['observaciones'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      esPrincipal: json['es_principal'] == true || json['es_principal'] == 1,
      localidad: localidadObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'localidad_id': localidadId,
      'direccion': direccion,
      'observaciones': observaciones,
      'latitud': latitud,
      'longitud': longitud,
      'es_principal': esPrincipal,
      'localidad': localidad?.toJson(),
    };
  }
}
