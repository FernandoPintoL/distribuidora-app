import 'package:flutter/material.dart';
import 'package:distribuidora/config/app_text_styles.dart';

/// ✅ Widget Stateless para resumen de montos de la venta
class ResumenMontosWidget extends StatelessWidget {
  final double totalVenta;
  final double totalRecibido;
  final double montoRechazado;
  final double montoCredito;
  final bool esCredito;
  final String tipoNovedad;
  final bool isDarkMode;

  const ResumenMontosWidget({
    Key? key,
    required this.totalVenta,
    required this.totalRecibido,
    required this.montoRechazado,
    required this.montoCredito,
    required this.esCredito,
    required this.tipoNovedad,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular total ajustado si es DEVOLUCION_PARCIAL
    double totalAjustado =
        tipoNovedad == 'DEVOLUCION_PARCIAL' ? totalVenta - montoRechazado : totalVenta;
    double totalComprometido = totalRecibido + montoCredito;
    double faltaPorRecibir = esCredito ? 0 : (totalAjustado - totalRecibido).clamp(0.0, double.infinity);
    double porcentajePagado =
        totalAjustado > 0 ? (totalRecibido / totalAjustado * 100) : 0;

    // Determinar estado
    bool estaPerfecto =
        (totalRecibido + montoCredito) >= totalAjustado && totalRecibido > 0;
    bool esParcial = totalRecibido > 0 && totalRecibido < totalAjustado;
    bool esCredito_ = totalRecibido == 0 && esCredito;
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
        : esCredito_
        ? '💳 Crédito Total'
        : 'Registrando...';

    // Icono según estado
    IconData statusIcon = faltaRegistrar
        ? Icons.hourglass_empty
        : estaPerfecto
        ? Icons.check_circle
        : esParcial
        ? Icons.warning_amber
        : esCredito_
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
          // Encabezado con estado mejorado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '💰 Resumen de Pagos',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
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

          // Total de la venta (prominente)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Original:',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Bs. ${totalVenta.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total ajustado si hay devolución parcial
          if (tipoNovedad == 'DEVOLUCION_PARCIAL')
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rechazado:',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '- Bs. ${montoRechazado.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a Recibir:',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Bs. ${totalAjustado.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

          // Monto recibido
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recibido Hoy:',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Bs. ${totalRecibido.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalAjustado > 0 ? porcentajePagado / 100 : 0,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                estaPerfecto ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${porcentajePagado.toStringAsFixed(1)}% pagado',
            style: TextStyle(
              fontSize: AppTextStyles.labelSmall(context).fontSize!,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Monto a crédito (si aplica)
          if (esCredito)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Promesa de Pago:',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bs. ${montoCredito.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            )
          else if (faltaPorRecibir > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Falta por Recibir:',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bs. ${faltaPorRecibir.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                      fontWeight: FontWeight.w700,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
