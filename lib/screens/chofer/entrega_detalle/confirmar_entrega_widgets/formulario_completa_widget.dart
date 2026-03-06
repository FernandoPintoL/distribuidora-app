import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/venta.dart';
import 'models.dart';

// ✅ WIDGET: Formulario para Entrega Completa
class FormularioCompletaWidget extends StatelessWidget {
  final Venta venta;
  final bool isDarkMode;
  final List<dynamic> fotosCapturadas;
  final List<Map<String, dynamic>> tiposPago;
  final List<PagoEntrega> pagos;
  final bool esCredito;
  final TextEditingController observacionesController;
  final String? tipoNovedad;
  final Function(double totalVenta) buildResumenMontos;
  final Function(BuildContext context, bool isDarkMode) buildPagoForm;

  const FormularioCompletaWidget({
    Key? key,
    required this.venta,
    required this.isDarkMode,
    required this.fotosCapturadas,
    required this.tiposPago,
    required this.pagos,
    required this.esCredito,
    required this.observacionesController,
    required this.tipoNovedad,
    required this.buildResumenMontos,
    required this.buildPagoForm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: isDarkMode ? Colors.green[400] : Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Entrega Completa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.green[900]!.withOpacity(0.2)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.green[700]!.withOpacity(0.5)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Venta',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Número:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              venta.numero,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cliente:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              venta.clienteNombre ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Bs. ${venta.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: AppTextStyles.bodyLarge(
                                  context,
                                ).fontSize!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resumen de montos
                  buildResumenMontos(venta.total),
                  const SizedBox(height: 24),
                  // Sección de Pagos Múltiples
                  Text(
                    '💳 Registrar Pagos (Múltiples Métodos)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente puede pagar en efectivo, transferencia, o combinación. También puede dejar crédito.',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pagos.isNotEmpty)
                    _buildPagosRegistrados(context, isDarkMode),
                  if (venta.estadoPago != 'CREDITO') ...[
                    buildPagoForm(context, isDarkMode),
                    const SizedBox(height: 24),
                    Text(
                      '✅ La entrega será registrada como completa',
                      style: TextStyle(
                        fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Novedad Registrada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                  fontSize: AppTextStyles.bodyLarge(
                                    context,
                                  ).fontSize!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ NO se requiere registro de pago para novedades. La entrega será registrada con la novedad.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: AppTextStyles.bodySmall(
                                      context,
                                    ).fontSize!,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '✅ La entrega será registrada con novedad',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagosRegistrados(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.blue[900]!.withOpacity(0.2)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.blue[700]!.withOpacity(0.5)
                  : Colors.blue.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ Pagos Registrados (${pagos.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildPagosList(context, isDarkMode),
              const SizedBox(height: 8),
              Divider(color: Colors.blue.withOpacity(0.3)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Recibido:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Bs. ${pagos.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildPagosList(BuildContext context, bool isDarkMode) {
    return pagos.asMap().entries.map((entry) {
      final idx = entry.key;
      final pago = entry.value;
      final tipoNombre = tiposPago.firstWhere(
            (t) => t['id'] == pago.tipoPagoId,
            orElse: () => {'nombre': 'Desconocido'},
          )['nombre'] ??
          'Desconocido';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipoNombre,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Bs. ${pago.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.blue[300]
                          : Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pago.referencia != null &&
                      pago.referencia!.isNotEmpty)
                    Text(
                      'Ref: ${pago.referencia}',
                      style: TextStyle(
                        fontSize:
                            AppTextStyles.labelSmall(context).fontSize!,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
