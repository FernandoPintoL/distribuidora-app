import 'package:flutter/material.dart';
import '../../services/print_service.dart';

/// Diálogo para seleccionar formato de impresión
///
/// Permite al usuario elegir entre:
/// - Ticket 58mm (compacto)
/// - Ticket 80mm (recomendado)
/// - A4 (factura completa)
Future<PrintFormat?> showPrintFormatDialog(BuildContext context) {
  return showDialog<PrintFormat>(
    context: context,
    builder: (BuildContext context) => _PrintFormatDialog(),
  );
}

class _PrintFormatDialog extends StatefulWidget {
  @override
  State<_PrintFormatDialog> createState() => _PrintFormatDialogState();
}

class _PrintFormatDialogState extends State<_PrintFormatDialog> {
  late PrintFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    // TICKET_80 es el formato recomendado por defecto
    _selectedFormat = PrintFormat.ticket80;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Seleccionar Formato de Impresión'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Elige el formato que deseas usar para imprimir el ticket',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildFormatOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedFormat),
          child: const Text('Imprimir'),
        ),
      ],
    );
  }

  /// Construir opciones de formato
  List<Widget> _buildFormatOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PrintFormat.values.map((format) {
      final isSelected = _selectedFormat == format;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(
                    isDark ? 0.2 : 0.1,
                  )
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<PrintFormat>(
          value: format,
          groupValue: _selectedFormat,
          onChanged: (PrintFormat? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFormat = newValue;
              });
            }
          },
          title: Row(
            children: [
              Text(
                _getFormatIcon(format),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormatDescription(format),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      );
    }).toList();
  }

  /// Obtener icono para cada formato
  String _getFormatIcon(PrintFormat format) {
    switch (format) {
      case PrintFormat.ticket58:
        return '🎟️';
      case PrintFormat.ticket80:
        return '🧾';
      case PrintFormat.a4:
        return '📄';
    }
  }

  /// Obtener descripción para cada formato
  String _getFormatDescription(PrintFormat format) {
    switch (format) {
      case PrintFormat.ticket58:
        return 'Para impresoras térmicas de 58mm\nMuy compacto';
      case PrintFormat.ticket80:
        return 'Para impresoras térmicas de 80mm\nRecomendado';
      case PrintFormat.a4:
        return 'Factura completa en tamaño A4\nPara impresoras estándar';
    }
  }
}
