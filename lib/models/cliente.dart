import 'localidad.dart';

class Cliente {
  final int id;
  final String nombre;
  final String? telefono;
  final String? fotoPerfil;
  final String? razonSocial;
  final String? nit;
  final int localidadId;
  final double creditoUtilizado;
  final List<int> categoriasIds;
  final Localidad? localidad;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.fotoPerfil,
    this.razonSocial,
    this.nit,
    required this.localidadId,
    this.creditoUtilizado = 0,
    this.categoriasIds = const [],
    this.localidad,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    Localidad? localidadObj;
    if (json['localidad'] is Map<String, dynamic>) {
      localidadObj = Localidad.fromJson(json['localidad'] as Map<String, dynamic>);
    }

    List<int> categoriasIdsList = [];
    if (json['categorias_ids'] is List) {
      categoriasIdsList = (json['categorias_ids'] as List)
          .whereType<int>()
          .toList();
    }

    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      razonSocial: json['razon_social'] as String?,
      nit: json['nit'] as String?,
      localidadId: json['localidad_id'] as int? ?? 0,
      creditoUtilizado: (json['credito_utilizado'] as num?)?.toDouble() ?? 0,
      categoriasIds: categoriasIdsList,
      localidad: localidadObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'foto_perfil': fotoPerfil,
      'razon_social': razonSocial,
      'nit': nit,
      'localidad_id': localidadId,
      'credito_utilizado': creditoUtilizado,
      'categorias_ids': categoriasIds,
      'localidad': localidad?.toJson(),
    };
  }
}
