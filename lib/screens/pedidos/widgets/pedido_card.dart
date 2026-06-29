import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../config/app_urls.dart';

/// Tarjeta de pedido refactorizada con Timeline unificado
/// Muestra: Proforma → Venta → Logística en paralelo
class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;
  final Function(String action, String url, String numero)? onPrint;

  const PedidoCard({required this.pedido, required this.onTap, this.onPrint});

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
    final baseUrl = AppUrls.baseUrlWeb;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // ============================================================
              // HEADER CON INFO RÁPIDA
              // ============================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pedido.numero,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final url =
                                '$baseUrl/proformas/${pedido.id}/imprimir?formato=TICKET_80&accion=download';
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
                    Text(
                      pedido.cliente?.nombre ?? 'Cliente desconocido',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bs. ${pedido.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                        Text(
                          _formatearFecha(pedido.fechaCreacion),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildTimelineItems(pedido, colorScheme, isDark, ctx: context),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pedido.direccionEntrega != null &&
                          pedido.direccionEntrega!.observaciones != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📍 '),
                              Expanded(
                                child: Text(
                                  pedido.direccionEntrega!.observaciones ?? '',
                                  style: TextStyle(
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
                      if (pedido.fechaEntregaSolicitada != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '🚚 Entrega Solicitada: ${_formatearFecha(pedido.fechaEntregaSolicitada!)}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      if (pedido.fechaVencimiento != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '📅 Vencimiento: ${_formatearFecha(pedido.fechaVencimiento!)}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
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

  List<Widget> _buildTimelineItems(
    Pedido pedido,
    ColorScheme colorScheme,
    bool isDark, {
    required BuildContext ctx,
  }) {
    final items = <Widget>[];

    // 1. ESTADO DE PROFORMA
    items.add(_buildTimelineItem(
      ctx,
      '📋 Proforma',
      _getProformaStatus(pedido),
      colorScheme,
    ));

    // Conector después de proforma
    if (pedido.esVenta || pedido.tieneEstadoLogistico) {
      items.add(_buildTimelineSeparator(colorScheme));
    }

    // 2. ESTADO DE VENTA Y DOCUMENTO (si aplica)
    if (pedido.esVenta && pedido.venta != null) {
      items.add(_buildTimelineItem(
        ctx,
        '🛍️ Venta ${pedido.ventaNumero ?? ''}',
        _getVentaStatus(pedido.venta!),
        colorScheme,
      ));

      // Conector después de venta
      if (pedido.tieneEstadoLogistico) {
        items.add(_buildTimelineSeparator(colorScheme));
      }
    }

    // 3. ESTADO LOGÍSTICO / ENTREGAS
    if (pedido.tieneEstadoLogistico || (pedido.venta?.confirmacionesEntrega.isNotEmpty ?? false)) {
      items.add(_buildTimelineItem(
        ctx,
        '🚚 Entrega',
        _getLogisticaStatus(pedido),
        colorScheme,
      ));

      // 4. CONFIRMACIONES DE ENTREGA (si hay)
      if (pedido.venta?.confirmacionesEntrega.isNotEmpty ?? false) {
        items.add(_buildTimelineSeparator(colorScheme));
        for (final confirmacion in pedido.venta!.confirmacionesEntrega) {
          items.add(_buildTimelineItem(
            ctx,
            _getConfirmacionIcon(confirmacion),
            _getConfirmacionStatus(confirmacion),
            colorScheme,
          ));
        }
      }
    }

    return items;
  }

  Widget _buildTimelineSeparator(ColorScheme colorScheme) {
    return Container(
      width: 2,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    Map<String, dynamic> status,
    ColorScheme colorScheme,
  ) {
    final color = status['color'] as Color;
    final subtitle = status['subtitle'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getProformaStatus(Pedido pedido) {
    final baseEstado = pedido.estadoCodigo.toUpperCase();

    String subtitulo;
    Color color;

    if (pedido.esVenta) {
      subtitulo = '✅ Convertida';
      color = Colors.green;
    } else if (baseEstado == 'RECHAZADA') {
      subtitulo = '❌ Rechazada';
      color = Colors.red;
    } else {
      subtitulo = baseEstado;
      color = Colors.blue;
    }

    return {
      'subtitle': subtitulo,
      'color': color,
    };
  }

  Map<String, dynamic> _getVentaStatus(PedidoVenta venta) {
    final estadoDoc = venta.estadoDocumento?.nombre ?? 'SIN ESTADO';
    final codigoDoc = venta.estadoDocumento?.codigo ?? '';

    String subtitulo;
    Color color;

    if (codigoDoc.toUpperCase() == 'ANULADO') {
      subtitulo = '❌ Anulada';
      color = Colors.red;
    } else if (codigoDoc.toUpperCase() == 'APROBADO') {
      subtitulo = '✅ Aprobada';
      color = Colors.green;
    } else {
      subtitulo = estadoDoc;
      color = Colors.orange;
    }

    return {
      'subtitle': subtitulo,
      'color': color,
    };
  }

  Map<String, dynamic> _getLogisticaStatus(Pedido pedido) {
    String subtitulo;
    Color color;

    if (pedido.venta?.estadoLogistica != null) {
      final estado = pedido.venta!.estadoLogistica!.codigo?.toUpperCase() ?? '';
      final nombre = pedido.venta!.estadoLogistica!.nombre;

      switch (estado) {
        case 'PENDIENTE':
          subtitulo = '⏳ Pendiente';
          color = Colors.blue;
          break;
        case 'EN_RUTA':
          subtitulo = '📍 En Ruta';
          color = Colors.purple;
          break;
        case 'ENTREGADO':
          subtitulo = '✅ Entregado';
          color = Colors.green;
          break;
        case 'RECHAZADA':
          subtitulo = '❌ Rechazada';
          color = Colors.red;
          break;
        default:
          subtitulo = nombre;
          color = Colors.grey;
      }
    } else if (pedido.estadoNombre.isNotEmpty) {
      subtitulo = pedido.estadoNombre;
      color = _getColorForEstado(pedido.estadoCategoria, pedido.estadoCodigo);
    } else {
      subtitulo = 'SIN ENTREGA';
      color = Colors.grey;
    }

    return {
      'subtitle': subtitulo,
      'color': color,
    };
  }

  String _getConfirmacionIcon(ConfirmacionEntrega confirmacion) {
    final tipo = confirmacion.estado.toUpperCase();

    switch (tipo) {
      case 'COMPLETA':
        return '✅ Completa';
      case 'RECHAZADA':
        return '❌ Rechazada';
      case 'CLIENTE_CERRADO':
        return '🔒 Cerrado';
      case 'DEVOLUCION_PARCIAL':
        return '↩️ Parcial';
      default:
        return '📦 ${tipo.replaceAll('_', ' ')}';
    }
  }

  Map<String, dynamic> _getConfirmacionStatus(ConfirmacionEntrega confirmacion) {
    final tipo = confirmacion.estado.toUpperCase();

    String subtitulo;
    Color color;

    switch (tipo) {
      case 'COMPLETA':
        subtitulo = 'Completada';
        color = Colors.green;
        break;
      case 'RECHAZADA':
        subtitulo = 'Rechazada';
        color = Colors.red;
        break;
      case 'CLIENTE_CERRADO':
        subtitulo = 'Cerrada';
        color = Colors.orange;
        break;
      case 'DEVOLUCION_PARCIAL':
        subtitulo = 'Devolución';
        color = Colors.amber;
        break;
      default:
        subtitulo = tipo;
        color = Colors.grey;
    }

    return {
      'subtitle': subtitulo,
      'color': color,
    };
  }

}
