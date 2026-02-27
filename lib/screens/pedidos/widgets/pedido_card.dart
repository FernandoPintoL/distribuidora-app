import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';

/// ✅ REFACTORIZADA: Card de pedido con Timeline unificado
/// Muestra: Proforma → Venta → Logística en paralelo
class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;
  final Function(String action, String url, String numero)? onPrint;

  const PedidoCard({
    required this.pedido,
    required this.onTap,
    this.onPrint,
  });

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yy').format(fecha);
  }

  Color _getColorForEstado(String categoria, String codigo) {
    final colors = {
      'proforma:PENDIENTE': Colors.blue,
      'proforma:APROBADA': Colors.green,
      'proforma:RECHAZADA': Colors.red,
      'proforma:CONVERTIDA': Colors.green,
      'venta:CONVERTIDA': Colors.green,
      'logistica:EN_RUTA': Colors.orange,
      'logistica:ENTREGADO': Colors.green,
      'logistica:CANCELADO': Colors.red,
    };
    return colors['$categoria:$codigo'] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseUrl = 'http://192.168.100.20:8000';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // ============================================================
              // HEADER CON INFO RÁPIDA
              // ============================================================
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pedido.numero,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final url =
                                '$baseUrl/proformas/${pedido.id}/imprimir?formato=TICKET_80&accion=preview';
                            if (onPrint != null) {
                              onPrint!('preview', url, pedido.numero);
                            }
                          },
                          icon: const Icon(Icons.print, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Vista previa',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pedido.cliente?.nombre ?? 'Cliente desconocido',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bs. ${pedido.total.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        Text(
                          _formatearFecha(pedido.fechaCreacion),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

              // ============================================================
              // TIMELINE DE ESTADOS
              // ============================================================
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    _buildTimelineItem(
                      context,
                      '📋 Proforma',
                      pedido.estadoCategoria,
                      pedido.estadoCodigo,
                      pedido.esVenta
                          ? '✅ Convertida'
                          : pedido.estadoCodigo,
                      colorScheme,
                      isDark,
                    ),
                    if (pedido.esVenta || pedido.tieneEstadoLogistico)
                      Container(
                        width: 2,
                        height: 16,
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    if (pedido.esVenta && pedido.ventaNumero != null) ...[
                      _buildTimelineItem(
                        context,
                        '🛍️ ${pedido.ventaNumero}',
                        'venta',
                        'CONVERTIDA',
                        'Convertida',
                        colorScheme,
                        isDark,
                      ),
                      if (pedido.tieneEstadoLogistico)
                        Container(
                          width: 2,
                          height: 16,
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                    ],
                    if (pedido.tieneEstadoLogistico)
                      _buildTimelineItem(
                        context,
                        '🚚 ${pedido.estadoNombre}',
                        pedido.estadoCategoria,
                        pedido.estadoCodigo,
                        pedido.estadoNombre,
                        colorScheme,
                        isDark,
                      ),
                  ],
                ),
              ),

              // ============================================================
              // INFO DETALLADA
              // ============================================================
              if (pedido.cantidadItems > 0 ||
                  pedido.direccionEntrega != null ||
                  pedido.tieneReservasProximasAVencer ||
                  pedido.fechaVencimiento != null ||
                  pedido.fechaEntregaSolicitada != null) ...[
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pedido.cantidadItems > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${pedido.cantidadItems} productos',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      if (pedido.direccionEntrega != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📍 ',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Expanded(
                                child: Text(
                                  pedido.direccionEntrega!.direccion,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (pedido.fechaVencimiento != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '📅 Vencimiento: ${_formatearFecha(pedido.fechaVencimiento!)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                      if (pedido.fechaEntregaSolicitada != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '🚚 Entrega Solicitada: ${_formatearFecha(pedido.fechaEntregaSolicitada!)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                      if (pedido.tieneReservasProximasAVencer) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '⏰ Reserva expira ${pedido.reservaMasProximaAVencer?.tiempoRestanteFormateado ?? 'pronto'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    String categoria,
    String codigo,
    String subtitle,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final color = _getColorForEstado(categoria, codigo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
