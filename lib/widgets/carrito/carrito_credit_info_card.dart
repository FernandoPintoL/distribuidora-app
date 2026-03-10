import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../models/client.dart';

class CarritoCreditInfoCard extends StatelessWidget {
  final Client cliente;

  const CarritoCreditInfoCard({
    super.key,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    final limiteCredito = cliente.limiteCredito ?? 0.0;
    // ✅ CORRECTO: Usar creditoUtilizado (campo que retorna el backend)
    final creditoUtilizado = cliente.creditoUtilizado ?? 0.0;
    final creditoDisponible = limiteCredito - creditoUtilizado;
    final porcentajeUsado = limiteCredito > 0
        ? (creditoUtilizado / limiteCredito) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Límite de crédito
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Límite de Crédito',
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(context).fontSize!,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Bs. ${limiteCredito.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(context).fontSize!,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // ✅ NUEVO: Mostrar crédito utilizado si está disponible
          if (cliente.creditoUtilizado != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crédito Utilizado',
                  style: TextStyle(
                    fontSize: AppTextStyles.labelSmall(context).fontSize!,
                    color: Colors.orange.shade600,
                  ),
                ),
                Text(
                  'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppTextStyles.labelSmall(context).fontSize!,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Barra de progreso visual
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentajeUsado / 100,
                minHeight: 6,
                backgroundColor: Colors.green.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  porcentajeUsado > 80
                      ? Colors.red.shade500
                      : porcentajeUsado > 50
                      ? Colors.orange.shade500
                      : Colors.green.shade500,
                ),
              ),
            ),
          ],

          // Fila 3: Disponible
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponible',
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(context).fontSize!,
                  color: creditoDisponible > 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.labelSmall(context).fontSize!,
                  color: creditoDisponible > 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
