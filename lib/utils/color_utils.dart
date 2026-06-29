import 'package:flutter/material.dart';

class ColorUtils {
  /// Convierte un string hexadecimal (#RRGGBB) a un Color de Flutter
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.grey;
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
