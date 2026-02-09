import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
import '../../../../providers/entrega_provider.dart';
import '../confirmar_entrega_venta_screen.dart';  // ✅ NUEVO: Importar la nueva pantalla

class ConfirmarVentaEntregadaDialog {
  static Future<void> show(
    BuildContext context,
    Entrega entrega,
    Venta venta,
    EntregaProvider provider,
  ) async {
    // ✅ NUEVO: Navegar a la nueva pantalla en lugar de mostrar un dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmarEntregaVentaScreen(
          entrega: entrega,
          venta: venta,
          provider: provider,
        ),
      ),
    );
  }
}

class _ConfirmarVentaEntregadaContent extends StatefulWidget {
  final Entrega entrega;
  final Venta venta;

  const _ConfirmarVentaEntregadaContent({
    required this.entrega,
    required this.venta,
  });

  @override
  State<_ConfirmarVentaEntregadaContent> createState() =>
      _ConfirmarVentaEntregadaContentState();
}

class _ConfirmarVentaEntregadaContentState
    extends State<_ConfirmarVentaEntregadaContent> {
  String _estadoEntrega = 'COMPLETA'; // ✅ NUEVO: Estado de entrega
  final TextEditingController _observacionesController = TextEditingController(); // ✅ NUEVO

  final List<Map<String, String>> _estadosEntrega = [
    {
      'value': 'COMPLETA',
      'label': '✅ Entrega Completa',
      'icon': '✓',
      'color': 'green',
    },
    {
      'value': 'PARCIAL',
      'label': '⚠️ Entrega Parcial',
      'icon': '⚠',
      'color': 'orange',
    },
    {
      'value': 'INCIDENTES',
      'label': '❌ Con Incidentes',
      'icon': '✕',
      'color': 'red',
    },
  ];

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedEstado = _estadosEntrega
        .firstWhere((e) => e['value'] == _estadoEntrega, orElse: () => _estadosEntrega[0]);

    return AlertDialog(
      title: const Text('Confirmar Entrega de Venta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '¿Confirmas que la venta fue entregada?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // ✅ NUEVO: Información de la venta
            if (widget.venta.clienteNombre != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.green[900]?.withOpacity(0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.green[700]! : Colors.green[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.venta.numero} - ${widget.venta.clienteNombre}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ✅ NUEVO: Selector de estado de entrega
            Text(
              'Estado de la Entrega',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 12),
            Column(
              children: _estadosEntrega.map((estado) {
                final isSelected = _estadoEntrega == estado['value'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _estadoEntrega = estado['value']!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getColorForStatus(estado['color']!)
                                .withOpacity(0.15)
                            : isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _getColorForStatus(estado['color']!)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: estado['value']!,
                            groupValue: _estadoEntrega,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _estadoEntrega = value;
                                });
                              }
                            },
                            activeColor: _getColorForStatus(estado['color']!),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              estado['label']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getColorForStatus(estado['color']!)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ✅ NUEVO: Campo de observaciones si no es entrega completa
            if (_estadoEntrega != 'COMPLETA') ...[
              Text(
                'Detalles del Incidente / Situación',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _estadoEntrega == 'PARCIAL'
                      ? 'Ej: Se entregó parcialmente, faltan 5 unidades...'
                      : 'Ej: Producto dañado, cliente rechazó, dirección incorrecta...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blue[900]?.withOpacity(0.3)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDarkMode ? Colors.blue[400] : Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los detalles del incidente se registrarán en el sistema',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validar que hay observaciones si no es entrega completa
            if (_estadoEntrega != 'COMPLETA' &&
                _observacionesController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Por favor, detallar el incidente o situación de la entrega'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // Construir observaciones_logistica con estado y detalles
            final observacionesLogistica = _estadoEntrega == 'COMPLETA'
                ? 'Entrega completa'
                : '$_estadoEntrega: ${_observacionesController.text.trim()}';

            Navigator.pop(context, {
              'observacionesLogistica': observacionesLogistica,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Confirmar Entrega'),
        ),
      ],
    );
  }

  Color _getColorForStatus(String color) {
    switch (color) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
