import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../extensions/theme_extension.dart';

/// Widget que muestra información completa de una venta
///
/// Incluye:
/// - Estado de pago con badge de color
/// - Montos pagado, pendiente y total
/// - Barra de progreso de pago
/// - Estado logístico
/// - Botones de acción (imprimir, registrar pago, más opciones)
class VentaInfoCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback? onPrintTicket;
  final VoidCallback? onRegisterPayment;
  final VoidCallback? onMoreOptions;

  const VentaInfoCard({
    super.key,
    required this.venta,
    this.onPrintTicket,
    this.onRegisterPayment,
    this.onMoreOptions,
  });

  /// Obtener color según estado de pago
  Color _getPaymentStatusColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return Colors.green;
      case 'PARCIAL':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtener icono según estado de pago
  String _getPaymentStatusIcon(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return '🟢';
      case 'PARCIAL':
        return '🟡';
      case 'PENDIENTE':
        return '⭕';
      default:
        return '❓';
    }
  }

  /// Obtener label en español
  String _getPaymentStatusLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return 'Pagado';
      case 'PARCIAL':
        return 'Pago Parcial';
      case 'PENDIENTE':
        return 'Pendiente de Pago';
      default:
        return estado;
    }
  }

  /// Calcular porcentaje pagado
  double _calculatePaymentProgress() {
    if (venta.total == 0) return 0;

    // Si no hay información de pago, usar el estado
    final montosPagados = _extractMontosPagados();
    return (montosPagados / venta.total).clamp(0.0, 1.0);
  }

  /// Extraer montos pagados desde el estado
  double _extractMontosPagados() {
    if (venta.estadoPago.toUpperCase() == 'PAGADO') {
      return venta.total;
    } else if (venta.estadoPago.toUpperCase() == 'PARCIAL') {
      // En estado parcial, asumir 50% (el backend debería proporcionar esto)
      // TODO: Obtener monto_pagado real del backend
      return venta.total * 0.5;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    final statusColor = _getPaymentStatusColor(venta.estadoPago);
    final statusIcon = _getPaymentStatusIcon(venta.estadoPago);
    final statusLabel = _getPaymentStatusLabel(venta.estadoPago);
    final progress = _calculatePaymentProgress();
    final montoPagado = _extractMontosPagados();
    final montoPendiente = (venta.total - montoPagado).clamp(0.0, double.infinity) as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y estado
          Row(
            children: [
              Text(
                '💳',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Venta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Venta: ${venta.numero}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estado de pago badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
              border: Border.all(color: statusColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusIcon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Estado de Pago: $statusLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Montos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMontoItem(
                label: 'Pagado',
                monto: montoPagado,
                color: Colors.green,
                context: context,
              ),
              _buildMontoItem(
                label: 'Pendiente',
                monto: montoPendiente,
                color: Colors.orange,
                context: context,
              ),
              _buildMontoItem(
                label: 'Total',
                monto: venta.total,
                color: colorScheme.primary,
                context: context,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Pago',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divisor
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),

          const SizedBox(height: 16),

          // Estado logístico
          if (venta.estadoLogistico.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🚚',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado Logístico',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _parseColorFromHex(
                                venta.estadoLogisticoColor,
                              ).withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              venta.estadoLogistico,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _parseColorFromHex(
                                  venta.estadoLogisticoColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Botones de acción
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Widget para mostrar un monto individual
  Widget _buildMontoItem({
    required String label,
    required double monto,
    required Color color,
    required BuildContext context,
  }) {
    final isDark = context.isDark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bs. ${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botones de acción (imprimir, registrar pago, más opciones)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Botón Imprimir Ticket
        if (onPrintTicket != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onPrintTicket,
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Imprimir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        if (onPrintTicket != null) const SizedBox(width: 8),

        // Botón Registrar Pago
        if (onRegisterPayment != null &&
            venta.estadoPago.toUpperCase() != 'PAGADO')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onRegisterPayment,
              icon: const Icon(Icons.add_card, size: 18),
              label: const Text('Registrar Pago'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        if (onRegisterPayment != null &&
            venta.estadoPago.toUpperCase() != 'PAGADO')
          const SizedBox(width: 8),

        // Botón Más opciones
        if (onMoreOptions != null)
          ElevatedButton.icon(
            onPressed: onMoreOptions,
            icon: const Icon(Icons.more_vert, size: 18),
            label: const Text('Más'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
      ],
    );
  }

  /// Convertir color hex a Color
  Color _parseColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }

    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    } else if (hexColor.length == 8 || hexColor.length == 9) {
      buffer.write(hexColor.replaceFirst('#', ''));
    } else {
      return Colors.grey;
    }

    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
