/// Información del próximo rango de precio disponible
class ProximoRango {
  final int cantidadMinima;
  final int? cantidadMaxima;
  final String rangoTexto; // Ej: "50+"
  final int faltaCantidad; // Cantidad adicional needed para alcanzar este rango

  ProximoRango({
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.rangoTexto,
    required this.faltaCantidad,
  });

  factory ProximoRango.fromJson(Map<String, dynamic> json) {
    return ProximoRango(
      cantidadMinima: json['cantidad_minima'] ?? 0,
      cantidadMaxima: json['cantidad_maxima'],
      rangoTexto: json['rango_texto'] ?? '',
      faltaCantidad: json['falta_cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cantidad_minima': cantidadMinima,
      'cantidad_maxima': cantidadMaxima,
      'rango_texto': rangoTexto,
      'falta_cantidad': faltaCantidad,
    };
  }
}
