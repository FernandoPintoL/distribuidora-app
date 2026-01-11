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
    return ProximoRango(
      cantidadMinima: json['cantidad_minima'] ?? 0,
      cantidadMaxima: json['cantidad_maxima'],
      rangoTexto: json['rango_texto'] ?? _generarRangoTexto(
        json['cantidad_minima'] as int?,
        json['cantidad_maxima'] as int?,
      ),
      faltaCantidad: json['falta_cantidad'] ?? 0,
      tipoPrecioNombre: json['tipo_precio_nombre'] as String?,
    );
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
