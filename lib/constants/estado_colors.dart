import 'package:flutter/material.dart';

/// Colores y constantes para estados de entrega
class EstadoColors {
  /// Colores de estados de entrega
  static const Map<String, Color> estadosEntrega = {
    'PROGRAMADO': Color(0xFFeab308),
    'ASIGNADA': Color(0xFF3b82f6),
    'EN_CAMINO': Color(0xFFf97316),
    'EN_TRANSITO': Color(0xFFf97316),
    'LLEGO': Color(0xFFeab308),
    'ENTREGADO': Color(0xFF22c55e),
    'PREPARACION_CARGA': Color(0xFFf97316),
    'EN_CARGA': Color(0xFFf97316),
    'LISTO_PARA_ENTREGA': Color(0xFFeab308),
    'NOVEDAD': Color(0xFFef4444),
    'RECHAZADO': Color(0xFFef4444),
    'CANCELADA': Color(0xFF6b7280),
  };

  /// Obtener color para un estado, con fallback a la base de datos
  static Color getColorForEstado(String? estado, String? colorHexFromDb) {
    // Usar primero el color del estado desde la BD (estado_entrega.color)
    if (colorHexFromDb != null &&
        colorHexFromDb.isNotEmpty &&
        colorHexFromDb.startsWith('#')) {
      try {
        return Color(int.parse('0xff${colorHexFromDb.substring(1)}'));
      } catch (e) {
        debugPrint('❌ Error parseando color: $colorHexFromDb - $e');
      }
    }

    // Fallback: usar colores hardcodeados si no viene desde la BD
    return estadosEntrega[estado] ?? Colors.grey;
  }
}
