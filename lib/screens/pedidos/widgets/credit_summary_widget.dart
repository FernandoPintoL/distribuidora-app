import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../config/config.dart';
import '../../../extensions/theme_extension.dart';

class CreditSummaryWidget extends StatelessWidget {
  final BuildContext parentContext;
  final Client cliente;

  const CreditSummaryWidget({
    super.key,
    required this.parentContext,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;
    final limiteCredito = cliente.limiteCredito ?? 0.0;
    final creditoUtilizado = cliente.creditoUtilizado ?? 0.0;
    final creditoDisponible = cliente.creditoDisponible ?? (limiteCredito - creditoUtilizado);
    final cuentasPorCobrarActivas = cliente.cuentasPorCobrarActivas ?? 0.0;
    final creditoTotalComprometido = cliente.creditoTotalComprometido ?? 0.0;

    final porcentajeUsado = limiteCredito > 0
        ? (creditoUtilizado / limiteCredito) * 100
        : 0.0;

    // Determinar color de alerta
    final Color colorEstado = creditoDisponible > 0
        ? Colors.green.shade700
        : creditoDisponible == 0
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: creditoDisponible <= 0
                ? Colors.red.shade300
                : Colors.blue.shade200,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resumen de Crédito',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(parentContext)
                          .fontSize!,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fila 1: Límite vs Utilizado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Límite de Crédito',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodySmall(parentContext).fontSize!,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bs. ${limiteCredito.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodySmall(parentContext).fontSize!,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Utilizado',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodySmall(parentContext).fontSize!,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize:
                              AppTextStyles.bodySmall(parentContext).fontSize!,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: porcentajeUsado / 100,
                  minHeight: 8,
                  backgroundColor: Colors.blue.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    porcentajeUsado > 80
                        ? Colors.red.shade500
                        : porcentajeUsado > 50
                        ? Colors.orange.shade500
                        : Colors.green.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fila 2: Cuentas por cobrar y Crédito comprometido
              if (cuentasPorCobrarActivas > 0 || creditoTotalComprometido > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deuda Activa',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.bodySmall(parentContext).fontSize!,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bs. ${cuentasPorCobrarActivas.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.bodySmall(parentContext).fontSize!,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Crédito Comprometido',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.bodySmall(parentContext).fontSize!,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bs. ${creditoTotalComprometido.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize:
                                AppTextStyles.bodySmall(parentContext).fontSize!,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Fila 3: Crédito disponible (resaltado)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorEstado.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorEstado.withAlpha(100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Crédito Disponible',
                      style: TextStyle(
                        fontSize:
                            AppTextStyles.bodySmall(parentContext).fontSize!,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                    Text(
                      'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize:
                            AppTextStyles.bodySmall(parentContext).fontSize!,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
