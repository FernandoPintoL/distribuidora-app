import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import 'estado_row_widget.dart';

class VentaConvertidaSection extends StatelessWidget {
  final Pedido pedido;
  final ColorScheme colorScheme;
  final BuildContext parentContext;

  const VentaConvertidaSection({
    super.key,
    required this.pedido,
    required this.colorScheme,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final venta = pedido.venta;

    if (venta == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estados de Venta Convertida',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyMedium(
                                parentContext,
                              ).fontSize!,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Folio: #${venta.id}',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyLarge(
                                parentContext,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${venta.numero}',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyLarge(
                                parentContext,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Estado del documento
                if (venta.estadoDocumentoObj != null) ...[
                  EstadoRowWidget(
                    icon: Icons.description,
                    label: 'Estado Documento',
                    estadoData: venta.estadoDocumentoObj!,
                    colorScheme: colorScheme,
                    parentContext: parentContext,
                  ),
                  const SizedBox(height: 12),
                ],

                // Estado de logística
                if (venta.estadoLogisticoObj != null) ...[
                  EstadoRowWidget(
                    icon: Icons.local_shipping,
                    label: 'Estado Logística',
                    estadoData: venta.estadoLogisticoObj!,
                    colorScheme: colorScheme,
                    parentContext: parentContext,
                  ),
                  const SizedBox(height: 12),
                ],

                // Motivo de anulación si está anulada
                if (venta.estadoDocumentoObj?.codigo == 'ANULADA' &&
                    venta.observaciones != null &&
                    venta.observaciones!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de Anulación',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(
                                  parentContext,
                                ).fontSize!,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          venta.observaciones!,
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              parentContext,
                            ).fontSize!,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Confirmaciones de entrega
                if (venta.confirmaciones.isNotEmpty) ...[
                  Text(
                    'Confirmaciones de Entrega',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(
                        parentContext,
                      ).fontSize!,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...venta.confirmaciones.map((confirmacion) {
                    final isCompleted =
                        confirmacion.tipoConfirmacion.toUpperCase() ==
                        'COMPLETA';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.schedule,
                              color: isCompleted ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${confirmacion.tipoEntrega} - ${confirmacion.tipoConfirmacion}',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        parentContext,
                                      ).fontSize!,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  if (confirmacion.confirmadoEn != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Confirmado: ${DateFormat('dd/MM/yyyy HH:mm').format(confirmacion.confirmadoEn!)}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          parentContext,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (confirmacion.observacionesLogistica !=
                                      null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Observaciones: ${confirmacion.observacionesLogistica}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          parentContext,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (confirmacion.confirmadoEn != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Monto: Bs. ${confirmacion.montoRecibido.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.labelSmall(
                                          parentContext,
                                        ).fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
