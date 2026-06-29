import 'package:flutter/material.dart';

/// Utilidades para Date Pickers con soporte para modo oscuro
class DatePickerUtils {
  /// Muestra un date picker respetando el tema de la app (claro/oscuro)
  static Future<DateTime?> showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    Locale? locale,
    String? helpText,
    String? cancelText,
    String? confirmText,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: locale,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
  }
}
