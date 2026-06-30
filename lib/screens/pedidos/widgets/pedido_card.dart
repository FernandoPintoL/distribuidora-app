import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../config/app_urls.dart';
import '../../ventas/venta_detalle/cliente_avatar_widget.dart';

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
                    // Folio y Button de impresion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Folio: #${pedido.id}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
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
                    // Cliente con Avatar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClienteAvatarWidget(
                          clienteNombre: pedido.cliente?.nombre,
                          clienteFotoPerfil: pedido.cliente?.fotoPerfil,
                          clienteLocalidad: pedido.cliente?.localidad?.nombre,
                          clienteObservaciones:
                              pedido.direccionEntrega!.observaciones ?? '',
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bs. ${pedido.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                            Text(
                              "Creada: ${_formatearFecha(pedido.fechaCreacion)}",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                    children: _buildTimelineItems(
                      pedido,
                      colorScheme,
                      isDark,
                      ctx: context,
                    ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      const SizedBox(width: 4),
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

    // 1. ESTADO DE PROFORMA (solo si no fue convertida a venta)
    if (!pedido.esVenta) {
      items.add(
        _buildTimelineItem(
          ctx,
          '📋 Pedido ->',
          _getProformaStatus(pedido),
          colorScheme,
        ),
      );

      // Conector después de proforma
      if (pedido.esVenta || pedido.tieneEstadoLogistico) {
        items.add(_buildTimelineSeparator(colorScheme));
      }
    }

    // 2. ESTADO DE VENTA Y DOCUMENTO (si aplica)
    if (pedido.esVenta && pedido.venta != null) {
      items.add(
        _buildTimelineItem(
          ctx,
          '🛍️ Venta F. #${pedido.ventaId ?? ''}',
          _getVentaStatus(pedido.venta!),
          colorScheme,
        ),
      );

      // Conector después de venta
      if (pedido.tieneEstadoLogistico) {
        items.add(_buildTimelineSeparator(colorScheme));
      }
    }

    // 3. ESTADO LOGÍSTICO / ENTREGAS
    if (pedido.tieneEstadoLogistico ||
        (pedido.venta?.confirmacionesEntrega.isNotEmpty ?? false)) {
      items.add(
        _buildTimelineItem(
          ctx,
          '🚚 Entrega',
          _getLogisticaStatus(pedido),
          colorScheme,
        ),
      );

      // 4. INFORMACIÓN DE ENTREGA ASIGNADA (si hay)
      if (pedido.venta?.entrega != null) {
        items.add(_buildTimelineSeparator(colorScheme));
        items.add(
          _buildEntregaInfoWidget(ctx, pedido.venta!.entrega!, colorScheme),
        );
      }

      // 5. CONFIRMACIONES DE ENTREGA (si hay - solo las que cumplen filtros)
      if (pedido.venta?.confirmacionesEntrega.isNotEmpty ?? false) {
        final confirmacionesFiltradas = pedido.venta!.confirmacionesEntrega
            .where((c) => _debeActualizarConfirmacion(c))
            .toList();

        if (confirmacionesFiltradas.isNotEmpty) {
          items.add(_buildTimelineSeparator(colorScheme));
          for (final confirmacion in confirmacionesFiltradas) {
            items.add(
              _buildTimelineItem(
                ctx,
                _getConfirmacionIcon(confirmacion),
                _getConfirmacionStatus(confirmacion),
                colorScheme,
              ),
            );
          }
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntregaInfoWidget(
    BuildContext context,
    DetalleEntrega entrega,
    ColorScheme colorScheme,
  ) {
    final color = _getEntregaStatusColor(entrega.estado);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número de entrega
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🚗 ${entrega.numeroEntrega}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            // Chofer y Vehículo
            if (entrega.choferNombre != null || entrega.vehiculoPlaca != null)
              Text(
                '👤 ${entrega.choferNombre ?? 'Sin chofer'} • 🚙 ${entrega.vehiculoPlaca ?? 'Sin vehículo'}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (entrega.observaciones != null &&
                entrega.observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  entrega.observaciones!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEntregaStatusColor(String estado) {
    final upperEstado = estado.toUpperCase();
    switch (upperEstado) {
      case 'LISTO_PARA_ENTREGA':
        return Colors.blue;
      case 'EN_CAMINO':
      case 'EN_RUTA':
        return Colors.purple;
      case 'ENTREGADO':
      case 'COMPLETADO':
        return Colors.green;
      case 'CANCELADA':
      case 'CANCELADO':
      case 'FALLIDA':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

    return {'subtitle': subtitulo, 'color': color};
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

    return {'subtitle': subtitulo, 'color': color};
  }

  Map<String, dynamic> _getLogisticaStatus(Pedido pedido) {
    String subtitulo;
    Color color;

    if (pedido.venta?.estadoLogistica != null) {
      final estado = pedido.venta!.estadoLogistica!.codigo?.toUpperCase() ?? '';
      final nombre = pedido.venta!.estadoLogistica!.nombre;

      switch (estado) {
        case 'PENDIENTE':
        case 'PENDIENTE_ENVIO':
          subtitulo = '⏳ Pendiente';
          color = Colors.blue;
          break;
        case 'EN_RUTA':
        case 'EN_CAMINO':
          subtitulo = '📍 En Ruta';
          color = Colors.purple;
          break;
        case 'ENTREGADO':
        case 'COMPLETADO':
          subtitulo = '✅ Entregado';
          color = Colors.green;
          break;
        case 'RECHAZADA':
        case 'RECHAZADO':
        case 'FALLIDA':
          subtitulo = '❌ Rechazada';
          color = Colors.red;
          break;
        case 'CANCELADA':
        case 'CANCELADO':
          subtitulo = '⛔ Cancelada';
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

    return {'subtitle': subtitulo, 'color': color};
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

  Map<String, dynamic> _getConfirmacionStatus(
    ConfirmacionEntrega confirmacion,
  ) {
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

    return {'subtitle': subtitulo, 'color': color};
  }

  bool _debeActualizarConfirmacion(ConfirmacionEntrega confirmacion) {
    // Filtrar solo por estado (tipo_confirmacion)
    // Valores permitidos: CLIENTE_CERRADO, RECHAZADO, COMPLETA, DEVOLUCION_PARCIAL
    return [
      'CLIENTE_CERRADO',
      'RECHAZADO',
      'COMPLETA',
      'DEVOLUCION_PARCIAL',
    ].contains(confirmacion.estado.toUpperCase());
  }
}
