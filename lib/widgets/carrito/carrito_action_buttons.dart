import 'package:flutter/material.dart';

/// Widget que agrupa los botones de acción del carrito
class CarritoActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onContinuarCompra;
  final Future<void> Function() onGuardarCarrito;
  final Future<void> Function() onConvertirProforma;

  const CarritoActionButtons({
    super.key,
    required this.isLoading,
    required this.isSaving,
    required this.onContinuarCompra,
    required this.onGuardarCarrito,
    required this.onConvertirProforma,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón principal: Continuar Compra
            ElevatedButton(
              onPressed: onContinuarCompra,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Continuar Compra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // Fila de acciones secundarias
            /*Row(
              children: [
                // Botón: Guardar Carrito
                Expanded(
                  child: _GuardarCarritoButton(
                    isSaving: isSaving,
                    onPressed: onGuardarCarrito,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón: Convertir a Proforma
                Expanded(
                  child: _ConvertirProformaButton(
                    isLoading: isLoading,
                    onPressed: onConvertirProforma,
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}

/// Botón para guardar carrito
class _GuardarCarritoButton extends StatelessWidget {
  final bool isSaving;
  final Future<void> Function() onPressed;

  const _GuardarCarritoButton({
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isSaving ? null : () => onPressed(),
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(
        isSaving ? 'Guardando...' : 'Guardar',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

/// Botón para convertir a proforma
class _ConvertirProformaButton extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function() onPressed;

  const _ConvertirProformaButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : () => onPressed(),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.description),
      label: Text(
        isLoading ? 'Creando...' : 'Proforma',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
