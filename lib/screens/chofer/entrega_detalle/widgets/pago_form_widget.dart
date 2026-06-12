import 'package:flutter/material.dart';
import 'package:distribuidora/config/app_text_styles.dart';

/// ✅ Widget Stateless para formulario de agregar pagos
class PagoFormWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tiposDisponibles;
  final int? tipoPagoSeleccionado;
  final TextEditingController montoController;
  final TextEditingController referenciaController;
  final bool cargandoTiposPago;
  final bool isDarkMode;
  final Function(int tipoPagoId, double monto, String? referencia) onAgregarPago;
  final Function(int? value) onTipoPagoChanged;

  const PagoFormWidget({
    Key? key,
    required this.tiposDisponibles,
    required this.tipoPagoSeleccionado,
    required this.montoController,
    required this.referenciaController,
    required this.cargandoTiposPago,
    required this.isDarkMode,
    required this.onAgregarPago,
    required this.onTipoPagoChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '➕ Agregar Nuevo Pago',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 12),

          // Selector de tipo de pago
          if (cargandoTiposPago)
            const Center(child: CircularProgressIndicator())
          else if (tiposDisponibles.isNotEmpty)
            DropdownButtonFormField<int>(
              value: tipoPagoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Tipo de Pago',
                hintText: 'Selecciona método',
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              items: tiposDisponibles.map((tipo) {
                return DropdownMenuItem<int>(
                  value: tipo['id'] as int,
                  child: Text(tipo['nombre'] as String),
                );
              }).toList(),
              onChanged: onTipoPagoChanged,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ Pago Completo Registrado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No hay más tipos de pago disponibles',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.bodySmall(context).fontSize!,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Campo de monto (solo si hay tipos disponibles)
          if (tiposDisponibles.isNotEmpty) ...[
            TextField(
              controller: montoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto (Bs.)',
                hintText: 'Ej: 100.50',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),

            // Campo de referencia (opcional)
            TextField(
              controller: referenciaController,
              decoration: InputDecoration(
                labelText: 'Referencia (Opcional)',
                hintText: 'Ej: Nro. de transacción',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón para agregar (solo si hay tipos disponibles)
          if (tiposDisponibles.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: tipoPagoSeleccionado == null ||
                        montoController.text.isEmpty
                    ? null
                    : () {
                        try {
                          final monto = double.parse(montoController.text);
                          if (monto <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('El monto debe ser mayor a 0'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          onAgregarPago(
                            tipoPagoSeleccionado!,
                            monto,
                            referenciaController.text.isNotEmpty
                                ? referenciaController.text
                                : null,
                          );

                          montoController.clear();
                          referenciaController.clear();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Agregar Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
