import 'package:flutter/material.dart';
import 'models.dart';
import '../../../../config/app_text_styles.dart';

// ✅ WIDGET: Resumen de Montos de la Venta
class ResumenMontosWidget extends StatelessWidget {
  final double totalVenta;
  final double montoRechazado;
  final double totalRecibido;
  final bool esCredito;
  final List<PagoEntrega> pagos;

  const ResumenMontosWidget({
    Key? key,
    required this.totalVenta,
    required this.montoRechazado,
    required this.totalRecibido,
    required this.esCredito,
    required this.pagos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular totales ajustados
    double totalAjustado = totalVenta - montoRechazado;
    double montoCredito = esCredito
        ? (totalAjustado - totalRecibido).clamp(0.0, double.infinity)
        : 0;
    double faltaPorRecibir = esCredito
        ? 0
        : (totalAjustado - totalRecibido).clamp(0.0, double.infinity);
    double porcentajePagado = totalAjustado > 0
        ? (totalRecibido / totalAjustado * 100)
        : 0;

    // Determinar estado
    bool estaPerfecto =
        (totalRecibido + montoCredito) >= totalAjustado && totalRecibido > 0;
    bool esParcial = totalRecibido > 0 && totalRecibido < totalAjustado;
    bool esCredito_state = totalRecibido == 0 && esCredito;
    bool faltaRegistrar = totalRecibido == 0 && !esCredito;

    // Colores según estado
    Color statusColor = faltaRegistrar
        ? Colors.grey[600]!
        : estaPerfecto
        ? Colors.green
        : esParcial
        ? Colors.orange
        : Colors.blue;

    String statusLabel = faltaRegistrar
        ? '⏳ Pendiente de Registrar'
        : estaPerfecto
        ? '✅ PAGO COMPLETADO'
        : esParcial
        ? '⚠️ Pago Parcial'
        : esCredito_state
        ? '💳 Crédito Total'
        : 'Registrando...';

    IconData statusIcon = faltaRegistrar
        ? Icons.hourglass_empty
        : estaPerfecto
        ? Icons.check_circle
        : esParcial
        ? Icons.warning_amber
        : esCredito_state
        ? Icons.credit_card
        : Icons.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: estaPerfecto
            ? LinearGradient(
                colors: [Colors.green[50]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: estaPerfecto ? null : statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(estaPerfecto ? 0.5 : 0.3),
          width: estaPerfecto ? 2.5 : 2,
        ),
        boxShadow: estaPerfecto
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '💰 Resumen de Pagos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: estaPerfecto
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: AppTextStyles.labelSmall(context).fontSize!,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total de la venta
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estaPerfecto
                  ? Colors.green[50]
                  : Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: estaPerfecto
                  ? Border.all(color: Colors.green[200]!, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de la Venta',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (montoRechazado > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Orig: Bs. ${totalVenta.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${totalAjustado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppTextStyles.displaySmall(context).fontSize!,
                        fontWeight: FontWeight.w700,
                        color: estaPerfecto
                            ? Colors.green[700]
                            : (montoRechazado > 0
                                  ? Colors.green[600]
                                  : Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
                if (estaPerfecto)
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Desglose
          Column(
            children: [
              _buildMontoRecibidoCard(context, totalRecibido),
              const SizedBox(height: 8),
              if (montoCredito > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMontoCreditoCard(context, montoCredito),
                ),
              if (faltaPorRecibir > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: _buildFaltaPorRecibirCard(context, faltaPorRecibir),
                ),
            ],
          ),

          // Barra de progreso
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Pago',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${porcentajePagado.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalAjustado > 0
                        ? (totalRecibido / totalAjustado).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      estaPerfecto
                          ? Colors.green
                          : esParcial
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Estado final
          const SizedBox(height: 12),
          if (estaPerfecto)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pago completado y verificado ✓',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (esParcial)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registra el saldo pendiente para completar el pago',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMontoRecibidoCard(BuildContext context, double totalRecibido) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: totalRecibido > 0 ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: totalRecibido > 0 ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, size: 18, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'Dinero Recibido:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Bs. ${totalRecibido.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                  fontWeight: FontWeight.w700,
                  color: totalRecibido > 0
                      ? Colors.green[700]
                      : Colors.grey[600],
                ),
              ),
              if (totalRecibido > 0) ...[
                const SizedBox(width: 6),
                Icon(Icons.check, size: 16, color: Colors.green[600]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMontoCreditoCard(BuildContext context, double montoCredito) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Crédito Otorgado:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            'Bs. ${montoCredito.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppTextStyles.bodyMedium(context).fontSize!,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaltaPorRecibirCard(
    BuildContext context,
    double faltaPorRecibir,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, size: 18, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Falta por Recibir:',
                style: TextStyle(
                  fontSize: AppTextStyles.bodySmall(context).fontSize!,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'Bs. ${faltaPorRecibir.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppTextStyles.bodyMedium(context).fontSize!,
              fontWeight: FontWeight.w700,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }
}
