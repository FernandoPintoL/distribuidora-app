/// Información del rango de precio aplicado al producto actual
/// 🔑 FASE 2: Incluye tipo_precio_id y tipo_precio_nombre
class RangoAplicado {
  final int cantidadMinima;
  final int? cantidadMaxima; // null = sin límite
  final String rangoTexto; // Ej: "10-49", "50+"
  final int? tipoPrecioId; // 🔑 NUEVO: ID del tipo de precio (2=VENTA, 6=DESCUENTO, 7=ESPECIAL)
  final String? tipoPrecioNombre; // 🔑 NUEVO: Nombre legible (Ej: "P. Descuento")

  RangoAplicado({
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.rangoTexto,
    this.tipoPrecioId,
    this.tipoPrecioNombre,
  });

  factory RangoAplicado.fromJson(Map<String, dynamic> json) {
    return RangoAplicado(
      cantidadMinima: json['cantidad_minima'] ?? 0,
      cantidadMaxima: json['cantidad_maxima'],
      rangoTexto: json['rango_texto'] ?? _generarRangoTexto(
        json['cantidad_minima'] as int?,
        json['cantidad_maxima'] as int?,
      ),
      tipoPrecioId: json['tipo_precio_id'] as int?,
      tipoPrecioNombre: json['tipo_precio_nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_minima': cantidadMinima,
      'cantidad_maxima': cantidadMaxima,
      'rango_texto': rangoTexto,
      'tipo_precio_id': tipoPrecioId,
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
