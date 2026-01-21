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
    final cantidadMinima = _parseInt(json['cantidad_minima']);
    final cantidadMaxima = _parseInt(json['cantidad_maxima']);

    return RangoAplicado(
      cantidadMinima: cantidadMinima,
      cantidadMaxima: cantidadMaxima > 0 ? cantidadMaxima : null,
      rangoTexto: json['rango_texto'] ?? _generarRangoTexto(
        cantidadMinima > 0 ? cantidadMinima : null,
        cantidadMaxima > 0 ? cantidadMaxima : null,
      ),
      tipoPrecioId: json['tipo_precio_id'] as int?,
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
