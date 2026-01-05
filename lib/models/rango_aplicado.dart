/// Información del rango de precio aplicado al producto actual
class RangoAplicado {
  final int cantidadMinima;
  final int? cantidadMaxima; // null = sin límite
  final String rangoTexto; // Ej: "10-49", "50+"

  RangoAplicado({
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.rangoTexto,
  });

  factory RangoAplicado.fromJson(Map<String, dynamic> json) {
    return RangoAplicado(
      cantidadMinima: json['cantidad_minima'] ?? 0,
      cantidadMaxima: json['cantidad_maxima'],
      rangoTexto: json['rango_texto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_minima': cantidadMinima,
      'cantidad_maxima': cantidadMaxima,
      'rango_texto': rangoTexto,
    };
  }
}
