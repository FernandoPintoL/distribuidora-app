import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../config/app_text_styles.dart';
import '../../../utils/phone_utils.dart';
import '../../pedidos/pedido_detalle/widgets/observaciones_section.dart';
import 'cliente_avatar_widget.dart';
import '../../../widgets/info_chip_widget.dart';

class VentaClienteHeaderWidget extends StatelessWidget {
  final Venta venta;
  final BuildContext parentContext;
  final Function(int ventaId) onDescargarPDF;
  final Function(Venta venta) onAbrirMapa;

  const VentaClienteHeaderWidget({
    super.key,
    required this.venta,
    required this.parentContext,
    required this.onDescargarPDF,
    required this.onAbrirMapa,
  });

  Color _getEstadoDocumentoColor(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.orange;
      case 'ANULADO':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getEstadoLogisticoColor(String? codigo) {
    switch (codigo?.toUpperCase()) {
      case 'PENDIENTE_ENVIO':
        return Colors.brown;
      case 'PROBLEMAS':
        return Colors.deepOrangeAccent.shade200;
      case 'EN_TRANSITO':
        return Colors.purple;
      case 'ENTREGADA':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.blue;
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            // Cliente - Card mejorada con Avatar, Ubicación y Botones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y Nombre del Cliente
                  // Avatar con foto o iniciales
                  ClienteAvatarWidget(
                    clienteNombre: venta.cliente?.nombre,
                    clienteFotoPerfil: venta.cliente?.fotoPerfil,
                    clienteLocalidad: venta.direccionCliente?.localidad?.nombre,
                    clienteObservaciones: venta.direccionCliente?.observaciones,
                  ),
                  // Información del Cliente
                  if (venta.tipoPago != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bs. ${venta.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Chip(
                          padding: const EdgeInsets.all(0),
                          label: Text(venta.tipoPago!.nombre),
                          avatar: const Icon(
                            Icons.payment,
                            size: 16,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (venta.proforma != null)
                          Expanded(
                            child: InfoChipWidget(
                              icon: Icons.shopping_cart,
                              label: 'Folio Pedido',
                              color:
                                  venta.proforma?.estadoLogistico?.color != null
                                  ? _parseHexColor(
                                      venta.proforma?.estadoLogistico?.color,
                                    )
                                  : colorScheme.primary,
                              id: venta.proforma?.id.toString(),
                              estadoLogistico:
                                  venta.proforma?.estadoLogistico?.nombre,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (venta.entrega != null)
                          Expanded(
                            child: InfoChipWidget(
                              icon: Icons.delivery_dining,
                              label: 'Folio Entrega',
                              color: venta.estadoLogisticoObj?.color != null
                                  ? _parseHexColor(
                                      venta.estadoLogisticoObj?.color,
                                    )
                                  : colorScheme.secondary,
                              id: venta.entrega?.id.toString(),
                              estadoLogistico: venta.estadoLogisticoObj?.nombre,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botones de Contacto
                  if (venta.cliente?.telefono != null) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botón Llamar
                        Tooltip(
                          message: 'Llamar',
                          child: IconButton(
                            icon: Icon(Icons.phone),
                            color: Colors.green,
                            onPressed: () => PhoneUtils.llamarCliente(
                              context,
                              venta.cliente?.telefono,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                        // Botón WhatsApp
                        Tooltip(
                          message: 'WhatsApp',
                          child: IconButton(
                            icon: Icon(Icons.chat),
                            color: Colors.green[600],
                            onPressed: () => PhoneUtils.enviarWhatsApp(
                              context,
                              venta.cliente?.telefono,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                        // Botón Descargar PDF
                        Tooltip(
                          message: 'Descargar Nota',
                          child: IconButton(
                            icon: Icon(Icons.download),
                            color: Colors.blue,
                            onPressed: () => onDescargarPDF(venta.id),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                        // ✅ Botón Mapa (solo si hay dirección con coordenadas)
                        if (venta.direccionCliente?.latitud != null &&
                            venta.direccionCliente?.longitud != null)
                          Tooltip(
                            message: 'Ver en Mapa',
                            child: IconButton(
                              icon: Icon(Icons.map),
                              color: Colors.lightGreen,
                              onPressed: () => onAbrirMapa(venta),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Observaciones
            if (venta.observaciones != null && venta.observaciones!.isNotEmpty)
              ObservacionesSection(
                observaciones: venta.observaciones!,
                parentContext: context,
                estadoLogisticoColor: venta.estadoLogisticoObj?.color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoDocumento estado) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Estado',
            style: TextStyle(
              color: badgeColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            estado.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoLogisticoBadge(EstadoLogistico estado) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono del estado logístico (si existe)
          if (estado.icono != null)
            Text(estado.icono!, style: const TextStyle(fontSize: 18)),
          Text(
            estado.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
