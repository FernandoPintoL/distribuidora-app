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
    final creditoDisponible = limiteCredito - creditoUtilizado;
    final porcentajeUsado = limiteCredito > 0
        ? (creditoUtilizado / limiteCredito) * 100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Límite de Crédito',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${limiteCredito.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilizado',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disponible',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      fontWeight: FontWeight.bold,
                      color: creditoDisponible > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize:
                          AppTextStyles.bodySmall(parentContext).fontSize!,
                      fontWeight: FontWeight.bold,
                      color: creditoDisponible > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
