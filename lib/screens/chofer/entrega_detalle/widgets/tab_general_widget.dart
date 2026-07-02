import 'package:flutter/material.dart';
import '../../../../providers/entrega_provider.dart';
import 'entrega_content_widget.dart';

class TabGeneralWidget extends StatefulWidget {
  final EntregaProvider provider;

  const TabGeneralWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  State<TabGeneralWidget> createState() => _TabGeneralWidgetState();
}

class _TabGeneralWidgetState extends State<TabGeneralWidget> {
  bool _mostrarError = true;

  void recargar() {
    debugPrint('🔄 Recargando General...');
    widget.provider.obtenerEntrega(widget.provider.entregaActual?.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Mostrar error si hay y el usuario no lo ha cerrado
    final mostrarErrorBanner = widget.provider.errorMessage != null && _mostrarError;

    return Column(
      children: [
        // ✅ NUEVO: Mostrar error si lo hay (dismissible)
        if (mostrarErrorBanner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.provider.errorMessage!,
                            style: TextStyle(
                              color: isDarkMode ? Colors.red[300] : Colors.red[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        setState(() => _mostrarError = false);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              debugPrint('🔄 Actualizando datos de entrega...');
              await widget.provider.obtenerEntrega(widget.provider.entregaActual?.id ?? 0);
              debugPrint('✅ Datos actualizados');
              // Mostrar error nuevamente si hay uno tras recargar
              if (widget.provider.errorMessage != null) {
                setState(() => _mostrarError = true);
              }
            },
            child: EntregaContentWidget(
              provider: widget.provider,
            ),
          ),
        ),
      ],
    );
  }
}
