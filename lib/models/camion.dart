class Camion {
  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final int? anio;
  final String? color;
  final double? capacidadKg;
  final double? capacidadM3;
  final String? fotoUrl;
  final bool activo;
  final DateTime? fechaRevisionTecnica;
  final String? observaciones;

  Camion({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.anio,
    this.color,
    this.capacidadKg,
    this.capacidadM3,
    this.fotoUrl,
    this.activo = true,
    this.fechaRevisionTecnica,
    this.observaciones,
  });

  factory Camion.fromJson(Map<String, dynamic> json) {
    return Camion(
      id: json['id'] as int,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anio: json['anio'] as int?,
      color: json['color'] as String?,
      capacidadKg: json['capacidad_kg'] != null
          ? (json['capacidad_kg'] as num).toDouble()
          : null,
      capacidadM3: json['capacidad_m3'] != null
          ? (json['capacidad_m3'] as num).toDouble()
          : null,
      fotoUrl: json['foto_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaRevisionTecnica: json['fecha_revision_tecnica'] != null
          ? DateTime.parse(json['fecha_revision_tecnica'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'color': color,
      'capacidad_kg': capacidadKg,
      'capacidad_m3': capacidadM3,
      'foto_url': fotoUrl,
      'activo': activo,
      'fecha_revision_tecnica': fechaRevisionTecnica?.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  String get descripcion => '$marca $modelo${anio != null ? ' ($anio)' : ''}';

  String get placaFormateada => placa.toUpperCase();

  bool get revisionVigente {
    if (fechaRevisionTecnica == null) return false;
    return fechaRevisionTecnica!.isAfter(DateTime.now());
  }

  bool get revisionPorVencer {
    if (fechaRevisionTecnica == null) return false;
    final diasRestantes = fechaRevisionTecnica!.difference(DateTime.now()).inDays;
    return diasRestantes > 0 && diasRestantes <= 30;
  }
}
