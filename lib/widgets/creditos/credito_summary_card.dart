import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/credito.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra un resumen del crédito disponible
/// Se utiliza en el Dashboard principal
class CreditoSummaryCard extends StatelessWidget {
  final Credito credito;
  final VoidCallback? onTap;

  const CreditoSummaryCard({
    super.key,
    required this.credito,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final porcentajeUtilizado = credito.porcentajeUtilizado;
    final colorEstado = Color(credito.colorEstado);
    final esCritico = credito.estado == 'critico';
    final estaExcedido = credito.estado == 'excedido';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorEstado.withOpacity(0.15),
              colorEstado.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: colorEstado.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: esCritico || estaExcedido
              ? [
                  BoxShadow(
                    color: colorEstado.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: colorEstado,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mi Crédito',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      credito.estado
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs. ${credito.saldoDisponible.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Límite',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs. ${credito.limiteCreditoAprobado.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilizado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs. ${credito.saldoUtilizado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar con porcentaje
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Utilización',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${porcentajeUtilizado.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorEstado,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (porcentajeUtilizado / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                    ),
                  ),
                ],
              ),

              // Alertas si es crítico o vencido
              if (esCritico || estaExcedido || credito.cuentasVencidasCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                            children: [
                              if (estaExcedido)
                                const TextSpan(
                                  text:
                                      'Tu crédito está excedido. Contacta a ventas.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              else if (esCritico)
                                const TextSpan(
                                  text:
                                      'Tu crédito está al 80% o más. Por favor realiza un pago.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              else
                                TextSpan(
                                  text:
                                      'Tienes ${credito.cuentasVencidasCount} cuenta${credito.cuentasVencidasCount > 1 ? 's' : ''} vencida${credito.cuentasVencidasCount > 1 ? 's' : ''}.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Info adicional
              if (credito.cuentasPendientesCount > 0 ||
                  credito.cuentasVencidasCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (credito.cuentasPendientesCount > 0)
                        Expanded(
                          child: _buildStatBadge(
                            'Pendientes',
                            credito.cuentasPendientesCount.toString(),
                            Colors.orange,
                          ),
                        ),
                      if (credito.cuentasVencidasCount > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBadge(
                            'Vencidas',
                            credito.cuentasVencidasCount.toString(),
                            Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Botón de acción
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ver detalles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Pendientes' ? Icons.pending_actions : Icons.warning,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
