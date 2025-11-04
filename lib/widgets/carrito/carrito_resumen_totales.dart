import 'package:flutter/material.dart';
import '../expandable_price_summary.dart';

/// Widget que muestra el resumen de totales y cupones del carrito
class CarritoResumenTotales extends StatefulWidget {
  final double subtotal;
  final double impuesto;
  final double costoEnvio;
  final double descuento;
  final double porcentajeDescuento;
  final bool tieneDescuento;
  final String? codigoDescuento;
  final bool validandoDescuento;
  final bool calculandoEnvio;
  final Future<bool> Function(String codigo) onAplicarDescuento;
  final VoidCallback onRemoverDescuento;

  const CarritoResumenTotales({
    super.key,
    required this.subtotal,
    required this.impuesto,
    required this.costoEnvio,
    required this.descuento,
    required this.porcentajeDescuento,
    required this.tieneDescuento,
    required this.codigoDescuento,
    required this.validandoDescuento,
    required this.calculandoEnvio,
    required this.onAplicarDescuento,
    required this.onRemoverDescuento,
  });

  @override
  State<CarritoResumenTotales> createState() => _CarritoResumenTotalesState();
}

class _CarritoResumenTotalesState extends State<CarritoResumenTotales> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Campo de código de cupón
          /*Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildCampoCupon(context),
          ),*/

          // Expandable Price Summary
          ExpandablePriceSummary(
            subtotal: widget.subtotal,
            impuesto: widget.impuesto,
            costoEnvio: widget.costoEnvio,
            descuento: widget.descuento,
            porcentajeDescuento: widget.porcentajeDescuento,
            initiallyExpanded: false,
            positiveColor: Colors.grey.shade700,
            negativeColor: Colors.green.shade700,
            totalColor: Theme.of(context).primaryColor,
          ),

          // Indicador de cálculo de envío
          if (widget.calculandoEnvio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Calculando envío...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampoCupon(BuildContext context) {
    if (widget.tieneDescuento) {
      return _buildCuponAplicado();
    }
    return _buildCampoAplicarCupon(context);
  }

  Widget _buildCuponAplicado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cupón aplicado: ${widget.codigoDescuento}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Ahorras: Bs ${widget.descuento.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onRemoverDescuento,
            child: Icon(Icons.close, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoAplicarCupon(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: '¿Tienes un cupón?',
              prefixIcon: Icon(Icons.local_offer, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: widget.validandoDescuento
                ? null
                : () async {
                    final codigo = _textController.text.trim();
                    final success = await widget.onAplicarDescuento(codigo);
                    if (success && mounted) {
                      _textController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cupón "$codigo" aplicado correctamente'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al aplicar cupón'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: widget.validandoDescuento
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
}
