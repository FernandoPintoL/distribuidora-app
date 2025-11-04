class Chofer {
  final int id;
  final int userId;
  final String nombres;
  final String apellidos;
  final String ci;
  final String telefono;
  final String? licenciaConducir;
  final String? categoriaLicencia;
  final DateTime? fechaVencimientoLicencia;
  final String? fotoUrl;
  final bool activo;
  final DateTime? fechaContratacion;

  Chofer({
    required this.id,
    required this.userId,
    required this.nombres,
    required this.apellidos,
    required this.ci,
    required this.telefono,
    this.licenciaConducir,
    this.categoriaLicencia,
    this.fechaVencimientoLicencia,
    this.fotoUrl,
    this.activo = true,
    this.fechaContratacion,
  });

  factory Chofer.fromJson(Map<String, dynamic> json) {
    return Chofer(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      ci: json['ci'] as String,
      telefono: json['telefono'] as String,
      licenciaConducir: json['licencia_conducir'] as String?,
      categoriaLicencia: json['categoria_licencia'] as String?,
      fechaVencimientoLicencia: json['fecha_vencimiento_licencia'] != null
          ? DateTime.parse(json['fecha_vencimiento_licencia'] as String)
          : null,
      fotoUrl: json['foto_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaContratacion: json['fecha_contratacion'] != null
          ? DateTime.parse(json['fecha_contratacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombres': nombres,
      'apellidos': apellidos,
      'ci': ci,
      'telefono': telefono,
      'licencia_conducir': licenciaConducir,
      'categoria_licencia': categoriaLicencia,
      'fecha_vencimiento_licencia': fechaVencimientoLicencia?.toIso8601String(),
      'foto_url': fotoUrl,
      'activo': activo,
      'fecha_contratacion': fechaContratacion?.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombres $apellidos';

  bool get licenciaVigente {
    if (fechaVencimientoLicencia == null) return false;
    return fechaVencimientoLicencia!.isAfter(DateTime.now());
  }

  bool get licenciaPorVencer {
    if (fechaVencimientoLicencia == null) return false;
    final diasRestantes = fechaVencimientoLicencia!.difference(DateTime.now()).inDays;
    return diasRestantes > 0 && diasRestantes <= 30;
  }
}
