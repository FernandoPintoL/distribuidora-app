import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/venta_service.dart';

/// Diálogo para registrar un pago rápido en una venta
///
/// Permite al usuario:
/// - Ingresar monto a pagar
/// - Seleccionar tipo de pago
/// - Agregar referencia (opcional)
/// - Validar y registrar el pago
class PaymentRegistrationDialog extends StatefulWidget {
  final Venta venta;
  final VoidCallback? onPaymentSuccess;

  const PaymentRegistrationDialog({
    super.key,
    required this.venta,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentRegistrationDialog> createState() =>
      _PaymentRegistrationDialogState();
}

class _PaymentRegistrationDialogState extends State<PaymentRegistrationDialog> {
  late TextEditingController _montoController;
  late TextEditingController _referenciaController;
  String _tipoPago = 'EFECTIVO';
  bool _isLoading = false;
  String? _errorMessage;

  // Tipos de pago disponibles
  final List<String> _tiposPago = [
    'EFECTIVO',
    'TRANSFERENCIA',
    'CHEQUE',
    'TARJETA',
    'QR',
    'OTRO',
  ];

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
    _referenciaController = TextEditingController();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  /// Calcular monto pendiente
  double _getMontoPendiente() {
    // Asumir 50% pendiente si estado es PARCIAL (el backend debería proporcionar esto)
    if (widget.venta.estadoPago.toUpperCase() == 'PAGADO') {
      return 0;
    } else if (widget.venta.estadoPago.toUpperCase() == 'PARCIAL') {
      return widget.venta.total * 0.5;
    }
    return widget.venta.total;
  }

  /// Validar entrada
  String? _validateMonto(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }

    final monto = double.tryParse(value);
    if (monto == null) {
      return 'Ingresa un monto válido';
    }

    if (monto <= 0) {
      return 'El monto debe ser mayor a 0';
    }

    final montoPendiente = _getMontoPendiente();
    if (monto > montoPendiente) {
      return 'No puedes pagar más que Bs. ${montoPendiente.toStringAsFixed(2)}';
    }

    return null;
  }

  /// Registrar el pago
  Future<void> _registrarPago() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final monto = double.parse(_montoController.text);

      final ventaService = VentaService();
      final response = await ventaService.registrarPago(
        ventaId: widget.venta.id,
        monto: monto,
        tipoPago: _tipoPago,
        numeroReferencia:
            _referenciaController.text.isEmpty ? null : _referenciaController.text,
      );

      if (!mounted) return;

      if (response.success) {
        // ✅ Éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago registrado: Bs. ${monto.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Llamar callback si existe
        widget.onPaymentSuccess?.call();

        // Cerrar diálogo
        Navigator.pop(context, true);
      } else {
        // ❌ Error
        setState(() {
          _errorMessage =
              response.message ?? 'Error al registrar pago';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Validar formulario
  bool _validateForm() {
    if (_validateMonto(_montoController.text) != null) {
      setState(() {
        _errorMessage = _validateMonto(_montoController.text);
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final montoPendiente = _getMontoPendiente();
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Registrar Pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info de venta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta: ${widget.venta.numero}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pendiente: Bs. ${montoPendiente.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monto
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Monto a Pagar',
                hintText: 'Ej: 250.50',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _validateMonto(_montoController.text),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // Tipo de pago
            DropdownButtonFormField<String>(
              value: _tipoPago,
              items: _tiposPago
                  .map(
                    (tipo) => DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _tipoPago = newValue;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Tipo de Pago',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Número de referencia
            TextField(
              controller: _referenciaController,
              decoration: InputDecoration(
                labelText: 'Número de Referencia (opcional)',
                hintText: 'Ej: Número de transferencia, cheque, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _registrarPago,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Registrar Pago'),
        ),
      ],
    );
  }
}
