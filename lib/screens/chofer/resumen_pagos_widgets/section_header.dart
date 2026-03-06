import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

/// Widget para encabezados de secciones con emoji/icono
class SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  final Color? textColor;
  final bool isDarkMode;
  final EdgeInsets padding;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.emoji,
    this.textColor,
    required this.isDarkMode,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  /// Factory para sección de pagos (azul)
  factory SectionHeader.pagos({Key? key, required bool isDarkMode}) {
    return SectionHeader(
      key: key,
      title: 'Pagos Registrados',
      emoji: '💳',
      isDarkMode: isDarkMode,
      textColor: isDarkMode ? Colors.lightBlue[200] : Colors.blue[900],
    );
  }

  /// Factory para sección de fotos (naranja)
  factory SectionHeader.fotos({Key? key, required bool isDarkMode}) {
    return SectionHeader(
      key: key,
      title: 'Fotos de la Novedad',
      emoji: '📸',
      isDarkMode: isDarkMode,
      textColor: isDarkMode ? Colors.orange[200] : Colors.orange[900],
    );
  }

  /// Factory para sección de productos devueltos (rojo)
  factory SectionHeader.productosDevueltos({Key? key, required bool isDarkMode}) {
    return SectionHeader(
      key: key,
      title: 'Productos Devueltos',
      emoji: '↩️',
      isDarkMode: isDarkMode,
      textColor: isDarkMode ? Colors.red[200] : Colors.red[900],
    );
  }

  /// Factory para sección de total (verde)
  factory SectionHeader.total({Key? key, required bool isDarkMode}) {
    return SectionHeader(
      key: key,
      title: 'Total de la Venta',
      emoji: '💰',
      isDarkMode: isDarkMode,
      textColor: isDarkMode ? Colors.green[200] : Colors.green[900],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        '$emoji $title',
        style: TextStyle(
          fontSize: (AppTextStyles.titleMedium(context).fontSize ?? 20) + 2,
          fontWeight: FontWeight.w900,
          color: textColor ?? (isDarkMode ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
