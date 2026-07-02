import 'package:flutter/material.dart';
import '../../../../extensions/theme_extension.dart';
import '../confirmar_entrega_widgets/models.dart';

class RegistroPagosCompletoWidget extends StatelessWidget {
  final double totalVenta;
  final List<PagoEntrega> pagos;
  final List<Map<String, dynamic>> tiposPago;
  final bool esCredito;
  final TextEditingController montoEfectivoController;
  final TextEditingController montoTransferenciaController;
  final Function(int tipoPagoId, double monto) onAgregarPago;
  final Function(int index) onEliminarPago;

  const RegistroPagosCompletoWidget({
    Key? key,
    required this.totalVenta,
    required this.pagos,
    required this.tiposPago,
    required this.esCredito,
    required this.montoEfectivoController,
    required this.montoTransferenciaController,
    required this.onAgregarPago,
    required this.onEliminarPago,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalRecibido = pagos.fold(0.0, (sum, p) => sum + p.monto);
    double montoEfectivo = double.tryParse(montoEfectivoController.text) ?? 0;
    double montoTransferencia =
        double.tryParse(montoTransferenciaController.text) ?? 0;
    double totalIngresado = totalRecibido;
    if (montoEfectivo > 0) totalIngresado += montoEfectivo;
    if (montoTransferencia > 0) totalIngresado += montoTransferencia;

    // Buscar IDs por código
    int? idEfectivo;
    int? idQR;
    for (var tipo in tiposPago) {
      final codigo = (tipo['codigo'] as String?)?.toUpperCase() ?? '';
      if (codigo == 'EFECTIVO') idEfectivo = tipo['id'] as int;
      if (codigo == 'TRANSFERENCIA/QR') idQR = tipo['id'] as int;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RESUMEN VISIBLE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: esCredito ? Colors.blue[300]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                if (esCredito)
                  Text(
                    '💳 Promesa de Pago (Crédito)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Ingresado:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Bs. ${totalIngresado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!esCredito) ...[
            // 2 INPUTS GRANDES Y SIMPLES
            if (idEfectivo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💵 Efectivo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: montoEfectivoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Ej: 1000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            if (idQR != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💸 Transferencia / QR',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: montoTransferenciaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Ej: 500',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) {},
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  // ✅ Verificar si hay montos para agregar
}
