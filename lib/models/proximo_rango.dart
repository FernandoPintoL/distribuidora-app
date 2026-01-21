/// Información del próximo rango de precio disponible
/// 🔑 FASE 2: Incluye tipo_precio_nombre
class ProximoRango {
  final int cantidadMinima;
  final int? cantidadMaxima;
  final String rangoTexto; // Ej: "50+"
  final int faltaCantidad; // Cantidad adicional needed para alcanzar este rango
  final String? tipoPrecioNombre; // 🔑 NUEVO: Nombre del tipo de precio en el próximo rango

  ProximoRango({
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.rangoTexto,
    required this.faltaCantidad,
    this.tipoPrecioNombre,
  });

  factory ProximoRango.fromJson(Map<String, dynamic> json) {
    final cantidadMinima = _parseInt(json['cantidad_minima']);
    final cantidadMaxima = _parseInt(json['cantidad_maxima']);

    return ProximoRango(
      cantidadMinima: cantidadMinima,
      cantidadMaxima: cantidadMaxima > 0 ? cantidadMaxima : null,
      rangoTexto: json['rango_texto'] ?? _generarRangoTexto(
        cantidadMinima > 0 ? cantidadMinima : null,
        cantidadMaxima > 0 ? cantidadMaxima : null,
      ),
      faltaCantidad: _parseInt(json['falta_cantidad']),
      tipoPrecioNombre: json['tipo_precio_nombre'] as String?,
    );
  }

  // Helper to safely parse int from string or number
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return double.parse(value).toInt();
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_minima': cantidadMinima,
      'cantidad_maxima': cantidadMaxima,
      'rango_texto': rangoTexto,
      'falta_cantidad': faltaCantidad,
      'tipo_precio_nombre': tipoPrecioNombre,
    };
  }

  /// Generar texto del rango si no viene en la respuesta
  static String _generarRangoTexto(int? min, int? max) {
    if (min == null) return '';
    if (max == null) return '$min+';
    return '$min-$max';
  }
}
