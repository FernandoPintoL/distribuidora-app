import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../config/app_urls.dart';
import '../../ventas/venta_detalle/cliente_avatar_widget.dart';
import 'entrega_timeline_widget.dart';
import '../../../widgets/info_chip_widget.dart';

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

  Color _parseHexColor(String? hexColor) {
    if (hexColor == null) return Colors.transparent;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
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

  Widget _buildEstadoBadge(EstadoLogistico estado) {
    // Parsear color hex del backend
    Color badgeColor = Colors.grey;
    if (estado.color != null) {
      try {
        final hex = estado.color!.replaceFirst('#', '');
        badgeColor = Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        debugPrint('⚠️ Error al parsear color: ${estado.color}');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (estado.icono != null) ...[
            Text(estado.icono!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Text(
            estado.nombre,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Folio y Button de impresion
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Pedido Folio: #${pedido.id}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: pedido.estadoLogistico?.color != null
                                  ? _parseHexColor(
                                      pedido.estadoLogistico?.color,
                                    )
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (pedido.estadoLogistico != null)
                          _buildEstadoBadge(pedido.estadoLogistico!),
                      ],
                    ),
                    // venta y entrega
                    if (pedido.venta != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InfoChipWidget(
                                icon: Icons.shopping_cart,
                                label: 'Folio Venta',
                                color:
                                    pedido.venta?.estadoLogisticoObj?.color !=
                                        null
                                    ? _parseHexColor(
                                        pedido.venta!.estadoLogisticoObj!.color,
                                      )
                                    : colorScheme.primary,
                                id: pedido.ventaId?.toString(),
                                estadoLogistico:
                                    pedido.venta?.estadoLogisticoObj?.nombre,
                              ),
                            ),
                            if (pedido.venta != null &&
                                pedido.venta?.entrega != null) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: InfoChipWidget(
                                  icon: Icons.delivery_dining,
                                  label: 'Folio Entrega',
                                  color:
                                      pedido.venta?.estadoLogisticoObj?.color !=
                                          null
                                      ? _parseHexColor(
                                          pedido
                                              .venta!
                                              .estadoLogisticoObj!
                                              .color,
                                        )
                                      : colorScheme.secondary,
                                  id: pedido.venta?.entrega?.id.toString(),
                                  estadoLogistico:
                                      pedido.venta?.estadoLogisticoObj?.nombre,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Cliente con Avatar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ClienteAvatarWidget(
                            clienteNombre: pedido.cliente?.nombre,
                            clienteFotoPerfil: pedido.cliente?.fotoPerfil,
                            clienteLocalidad: pedido.cliente?.localidad?.nombre,
                            clienteObservaciones:
                                pedido.direccionEntrega?.observaciones ?? '',
                          ),
                        ),
                        Flexible(
                          child: Column(
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
                                _formatearFecha(pedido.fechaCreacion),
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ============================================================
                    // INFO DETALLADA
                    // ============================================================
                    if (pedido.cantidadItems > 0 ||
                        pedido.direccionEntrega != null ||
                        pedido.tieneReservasProximasAVencer ||
                        pedido.fechaVencimiento != null ||
                        pedido.fechaEntregaSolicitada != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (pedido.fechaEntregaSolicitada != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '🚚 Entrega Solicitada: ${_formatearFecha(pedido.fechaEntregaSolicitada!)}',
                                  style: TextStyle(color: colorScheme.tertiary),
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
                                    color: Colors.orange.shade200,
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
              // Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

              // ============================================================
              // TIMELINE DE ESTADOS
              // ============================================================
              // Timeline de pedido.venta.estadoLogistica
              /*if (pedido.venta?.estadoLogistico != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '📦 Estado Logístico',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (pedido.venta?.estadoLogisticoObj != null)
                        _buildEstadoBadge(pedido.venta!.estadoLogisticoObj!),
                    ],
                  ),
                ),
              ],*/
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
    return [
      // 1. Estado del documento: Proforma
      /*if (!pedido.esVenta) ...[
        _buildTimelineItem(
          ctx,
          '📋 Pedido ->',
          _getProformaStatus(pedido),
          colorScheme,
        ),
        if (pedido.tieneEstadoLogistico) _buildTimelineSeparator(colorScheme),
      ],*/

      // 2. Estado del documento: Venta
      /*if (pedido.esVenta && pedido.venta != null) ...[
        _buildTimelineItem(
          ctx,
          '🛍️ Venta F. #${pedido.ventaId ?? ''}',
          _getVentaStatus(pedido.venta),
          colorScheme,
        ),
        if (pedido.tieneEstadoLogistico) _buildTimelineSeparator(colorScheme),
      ],*/

      // 3. Estado logístico: Entrega y confirmación
      ...EntregaTimelineWidget.buildTimelineItems(
        pedido,
        colorScheme,
        ctx,
        _buildTimelineSeparator,
        _buildTimelineItem,
        _getLogisticaStatus,
        _getConfirmacionStatusDetallado,
        _debeActualizarConfirmacion,
      ),
    ];
  }

  Widget _buildTimelineSeparator(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    ({String subtitle, Color color}) status,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: status.color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            Text(
              status.subtitle,
              style: TextStyle(
                color: status.color.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  ({String subtitle, Color color}) _getProformaStatus(Pedido pedido) {
    return switch (pedido.estadoCodigo.toUpperCase()) {
      'RECHAZADA' => (subtitle: '❌ Rechazada', color: Colors.red),
      _ when pedido.esVenta => (subtitle: '✅ Convertida', color: Colors.green),
      final estado => (subtitle: estado, color: Colors.blue),
    };
  }

  ({String subtitle, Color color}) _getVentaStatus(PedidoVenta venta) {
    final codigoDoc = venta.estadoDocumento?.codigo?.toUpperCase() ?? '';
    final nombreDoc = venta.estadoDocumento?.nombre ?? 'SIN ESTADO';

    return switch (codigoDoc) {
      'ANULADO' => (subtitle: '❌ Anulada', color: Colors.red),
      'APROBADO' => (subtitle: '✅ Aprobada', color: Colors.green),
      _ => (subtitle: nombreDoc, color: Colors.orange),
    };
  }

  ({String subtitle, Color color}) _getLogisticaStatus(Pedido pedido) {
    final estadoLogistica = pedido.venta?.estadoLogisticoObj;

    if (estadoLogistica != null) {
      final codigo = estadoLogistica.codigo?.toUpperCase() ?? '';
      return switch (codigo) {
        'PENDIENTE' ||
        'PENDIENTE_ENVIO' => (subtitle: '⏳ Pendiente', color: Colors.blue),
        'EN_RUTA' ||
        'EN_CAMINO' => (subtitle: '📍 En Ruta', color: Colors.purple),
        'ENTREGADO' ||
        'COMPLETADO' => (subtitle: '✅ Entregado', color: Colors.green),
        'RECHAZADA' ||
        'RECHAZADO' ||
        'FALLIDA' => (subtitle: '❌ Rechazada', color: Colors.red),
        'CANCELADA' ||
        'CANCELADO' => (subtitle: '⛔ Cancelada', color: Colors.red),
        _ => (subtitle: estadoLogistica.nombre, color: Colors.grey),
      };
    }

    if (pedido.estadoNombre.isNotEmpty) {
      return (
        subtitle: pedido.estadoNombre,
        color: _getColorForEstado(pedido.estadoCategoria, pedido.estadoCodigo),
      );
    }

    return (subtitle: 'SIN ENTREGA', color: Colors.grey);
  }

  ({String subtitle, Color color}) _getConfirmacionStatusDetallado(
    EntregaVentaConfirmacion confirmacion,
  ) {
    final tipoEntrega = confirmacion.tipoEntrega.toUpperCase();
    final tipoConfirmacion = confirmacion.tipoConfirmacion.toUpperCase();
    final subtitle = '$tipoEntrega - $tipoConfirmacion';

    final color = switch (tipoConfirmacion) {
      'COMPLETA' => Colors.green,
      'RECHAZADA' => Colors.red,
      'CLIENTE_CERRADO' => Colors.orange,
      'DEVOLUCION_PARCIAL' => Colors.amber,
      _ => Colors.grey,
    };

    return (subtitle: subtitle, color: color);
  }

  bool _debeActualizarConfirmacion(EntregaVentaConfirmacion confirmacion) {
    // Filtrar por tipoEntrega y tipoConfirmacion
    final tipoEntregaValido =
        confirmacion.tipoEntrega.toUpperCase() == 'COMPLETA' ||
        confirmacion.tipoEntrega.toUpperCase() == 'CON_NOVEDAD';

    final tipoConfirmacionValido = [
      'CLIENTE_CERRADO',
      'RECHAZADO',
      'COMPLETA',
      'DEVOLUCION_PARCIAL',
    ].contains(confirmacion.tipoConfirmacion.toUpperCase());

    return tipoEntregaValido && tipoConfirmacionValido;
  }
}
