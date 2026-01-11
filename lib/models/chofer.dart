class Chofer {
  final int id;
  final int? userId;  // FASE 3: Ahora opcional (puede ser null si solo viene el User)
  final String? nombres;  // FASE 3: Ahora opcional (no viene en User response)
  final String? apellidos;  // FASE 3: Ahora opcional (no viene en User response)
  final String? ci;  // FASE 3: Ahora opcional (no viene en User response)
  final String? telefono;  // FASE 3: Ahora opcional (no viene en User response)
  final String? licenciaConducir;
  final String? categoriaLicencia;
  final DateTime? fechaVencimientoLicencia;
  final String? fotoUrl;
  final bool activo;
  final DateTime? fechaContratacion;
  final String? nombre; // Campo adicional que viene del API (nombre completo o User.name)
  final String? email;
  final String? usernick;  // FASE 3: Nuevo campo del User (usernick)

  Chofer({
    required this.id,
    this.userId,  // FASE 3: Ahora opcional
    this.nombres,  // FASE 3: Ahora opcional
    this.apellidos,  // FASE 3: Ahora opcional
    this.ci,  // FASE 3: Ahora opcional
    this.telefono,  // FASE 3: Ahora opcional
    this.licenciaConducir,
    this.categoriaLicencia,
    this.fechaVencimientoLicencia,
    this.fotoUrl,
    this.activo = true,
    this.fechaContratacion,
    this.nombre,
    this.email,
    this.usernick,  // FASE 3: Nuevo campo
  });

  factory Chofer.fromJson(Map<String, dynamic> json) {
    // FASE 3: Manejar ambos casos - Empleado y User
    // Si viene 'name' es un User (FASE 3), si viene 'nombre' es un Empleado (FASE 1-2)

    return Chofer(
      id: json['id'] as int,
      userId: json['user_id'] as int?,  // Opcional en FASE 3
      nombres: json['nombres'] as String?,  // Opcional en FASE 3
      apellidos: json['apellidos'] as String?,  // Opcional en FASE 3
      ci: json['ci'] as String?,  // Opcional en FASE 3
      telefono: json['telefono'] as String?,  // Opcional en FASE 3
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
      // Mapear nombre: primero intenta 'name' (User), luego 'nombre' (Empleado)
      nombre: json['nombre'] as String? ?? json['name'] as String?,
      email: json['email'] as String?,
      usernick: json['usernick'] as String?,  // Nuevo en FASE 3 (User)
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
      'nombre': nombre,
      'name': nombre,  // FASE 3: Incluir también como 'name' (User)
      'email': email,
      'usernick': usernick,  // FASE 3: Nuevo campo
    };
  }

  // Prioriza el campo 'nombre' si está disponible, sino combina nombres y apellidos
  String get nombreCompleto {
    if (nombre != null && nombre!.isNotEmpty) {
      return nombre!;
    }
    final nom = (nombres ?? '') + (nombres != null && apellidos != null ? ' ' : '') + (apellidos ?? '');
    return nom.trim();
  }

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
