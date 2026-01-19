class Gasto {
  final int id;
  final int cajaId;
  final double monto;
  final String descripcion;
  final String categoria; // TRANSPORTE, LIMPIEZA, MANTENIMIENTO, SERVICIOS, VARIOS
  final String? numeroComprobante;
  final String? proveedor;
  final String? observaciones;
  final DateTime fecha;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones opcionales
  final String? usuarioNombre;

  Gasto({
    required this.id,
    required this.cajaId,
    required this.monto,
    required this.descripcion,
    required this.categoria,
    this.numeroComprobante,
    this.proveedor,
    this.observaciones,
    required this.fecha,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.usuarioNombre,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    // Parsear usuario
    String? usuarioNom;
    if (json['usuario'] is Map<String, dynamic>) {
      final usuario = json['usuario'] as Map<String, dynamic>;
      usuarioNom = usuario['name'] as String? ?? usuario['nombre'] as String?;
    }

    return Gasto(
      id: json['id'] as int,
      cajaId: json['caja_id'] as int,
      monto: (json['monto'] as num).toDouble().abs(), // siempre positivo
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String? ?? 'VARIOS',
      numeroComprobante: json['numero_comprobante'] as String?,
      proveedor: json['proveedor'] as String?,
      observaciones: json['observaciones'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      usuarioNombre: usuarioNom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caja_id': cajaId,
      'monto': monto,
      'descripcion': descripcion,
      'categoria': categoria,
      'numero_comprobante': numeroComprobante,
      'proveedor': proveedor,
      'observaciones': observaciones,
      'fecha': fecha.toIso8601String(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get montoFormato => monto.toStringAsFixed(2);

  String get categoriaLabel {
    final labels = {
      'TRANSPORTE': '🚗 Transporte',
      'LIMPIEZA': '🧹 Limpieza',
      'MANTENIMIENTO': '🔧 Mantenimiento',
      'SERVICIOS': '⚙️ Servicios',
      'VARIOS': '📋 Varios',
    };
    return labels[categoria] ?? categoria;
  }

  static const List<String> categorias = [
    'TRANSPORTE',
    'LIMPIEZA',
    'MANTENIMIENTO',
    'SERVICIOS',
    'VARIOS',
  ];
}
