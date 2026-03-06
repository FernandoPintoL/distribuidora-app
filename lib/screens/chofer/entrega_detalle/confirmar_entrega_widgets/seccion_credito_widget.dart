import 'package:flutter/material.dart';

// ✅ WIDGET: Sección de Crédito
class SeccionCreditoWidget extends StatelessWidget {
  final bool esCredito;
  final Function(bool?) onCreditoChanged;

  const SeccionCreditoWidget({
    Key? key,
    required this.esCredito,
    required this.onCreditoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: esCredito,
      onChanged: onCreditoChanged,
      title: const Text(
        '💳 Esta venta es a Crédito',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Marcar si el cliente no paga ahora (promesa de pago)',
        style: TextStyle(fontSize: 12),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}
