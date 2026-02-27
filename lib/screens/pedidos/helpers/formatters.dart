import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ✅ HELPERS: Formateo de fechas, horas y colores
class PedidosFormatters {
  /// Formatear fecha a formato "dd/MM/yy"
  static String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yy').format(fecha);
  }

  /// Formatear fecha a formato "dd MMM yyyy" (ej: 27 Feb 2026)
  static String formatearFechaLarga(DateTime fecha) {
    final formatter = DateFormat('dd MMM yyyy', 'es_ES');
    return formatter.format(fecha);
  }

  /// Formatear hora a formato "HH:mm"
  static String formatearHora(DateTime fecha) {
    final formatter = DateFormat('HH:mm', 'es_ES');
    return formatter.format(fecha);
  }

  /// Convertir hex string (#RRGGBB o RRGGBB) a Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey; // Fallback
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
