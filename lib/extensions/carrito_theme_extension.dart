import 'package:flutter/material.dart';
import 'theme_extension.dart';

/// 🎨 Extension para colores adaptativos en la pantalla del carrito
/// Se desvincula de la paleta general para optimizar modo oscuro
extension CarritoThemeExtension on BuildContext {
  bool get isDarkCarrito => isDark;

  /// Colores para errores y advertencias (stock insuficiente)
  Color get carritoErrorBg => isDarkCarrito
      ? Colors.red.shade900.withAlpha(50)
      : Colors.red.shade50;

  Color get carritoErrorBorder => isDarkCarrito
      ? Colors.red.shade700
      : Colors.red.shade300;

  Color get carritoErrorText => isDarkCarrito
      ? Colors.red.shade200
      : Colors.red.shade800;

  Color get carritoErrorIcon => isDarkCarrito
      ? Colors.red.shade400
      : Colors.red.shade700;

  /// Colores para ahorro (verde)
  Color get carritoSavingsBg => isDarkCarrito
      ? Colors.green.shade900.withAlpha(50)
      : Colors.green.shade50;

  Color get carritoSavingsBorder => isDarkCarrito
      ? Colors.green.shade700
      : Colors.green.shade300;

  Color get carritoSavingsText => isDarkCarrito
      ? Colors.green.shade300
      : Colors.green.shade700;

  Color get carritoSavingsIcon => isDarkCarrito
      ? Colors.green.shade400
      : Colors.green.shade700;

  /// Colores para advertencias (naranja)
  Color get carritoWarningBg => isDarkCarrito
      ? Colors.orange.shade900.withAlpha(50)
      : Colors.orange.shade50;

  Color get carritoWarningBorder => isDarkCarrito
      ? Colors.orange.shade700
      : Colors.orange.shade300;

  Color get carritoWarningText => isDarkCarrito
      ? Colors.orange.shade200
      : Colors.orange.shade800;

  Color get carritoWarningIcon => isDarkCarrito
      ? Colors.orange.shade400
      : Colors.orange.shade700;

  /// Colores para notas/observaciones (ámbar)
  Color get carritoNotesBg => isDarkCarrito
      ? Colors.amber.shade900.withAlpha(50)
      : Colors.amber.shade50;

  Color get carritoNotesBorder => isDarkCarrito
      ? Colors.amber.shade700
      : Colors.amber.shade200;

  Color get carritoNotesText => isDarkCarrito
      ? Colors.amber.shade200
      : Colors.amber.shade800;

  Color get carritoNotesIcon => isDarkCarrito
      ? Colors.amber.shade400
      : Colors.amber.shade700;

  /// Colores para bordes y separadores
  Color get carritorBorderColor => isDarkCarrito
      ? Colors.grey.shade700
      : Colors.grey.shade300;

  /// Colores para texto secundario
  Color get carritoSecondaryText => isDarkCarrito
      ? Colors.grey.shade400
      : Colors.grey.shade600;

  /// Colores para cantidad (número)
  Color get carritoQuantityText => isDarkCarrito
      ? Colors.grey.shade100
      : Colors.black;

  /// Color del icono de eliminar
  Color get carritoDeleteIconColor => isDarkCarrito
      ? Colors.red.shade400
      : Colors.red;

  /// Color para placeholder de imagen
  Color get carritoImagePlaceholderColor => isDarkCarrito
      ? Colors.grey.shade700
      : Colors.grey.shade300;

  /// Fondo vacío del carrito
  Color get carritoEmptyIconColor => isDarkCarrito
      ? Colors.grey.shade600
      : Colors.grey.shade300;
}
