import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../config/app_text_styles.dart';
import '../../../utils/phone_utils.dart';
import 'cliente_avatar_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Estados (Documento y Logístico) - Mejorados con colores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Estado Documento
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getEstadoDocumentoColor(
                      venta.estadoDocumentoObj?.codigo,
                    ).withValues(alpha: 0.1),
                    border: Border.all(
                      color: _getEstadoDocumentoColor(
                        venta.estadoDocumentoObj?.codigo,
                      ),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: _getEstadoDocumentoColor(
                          venta.estadoDocumentoObj?.codigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Documento',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              venta.estadoDocumentoObj?.codigo ?? 'Desconocido',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getEstadoDocumentoColor(
                                  venta.estadoDocumentoObj?.codigo,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Estado Logístico
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getEstadoLogisticoColor(
                      venta.estadoLogisticoObj?.codigo,
                    ).withValues(alpha: 0.1),
                    border: Border.all(
                      color: _getEstadoLogisticoColor(
                        venta.estadoLogisticoObj?.codigo,
                      ),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 20,
                        color: _getEstadoLogisticoColor(
                          venta.estadoLogisticoObj?.codigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Logística',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              venta.estadoLogisticoObj?.nombre ??
                                  venta.estadoLogistico,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getEstadoLogisticoColor(
                                  venta.estadoLogisticoObj?.codigo,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cliente - Card mejorada con Avatar, Ubicación y Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar y Nombre del Cliente
                Row(
                  children: [
                    // Avatar con foto o iniciales
                    ClienteAvatarWidget(
                      clienteNombre: venta.cliente?.nombre,
                      clienteFotoPerfil: venta.cliente?.fotoPerfil,
                    ),
                    const SizedBox(width: 12),
                    // Información del Cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.cliente?.nombre ?? 'Cliente desconocido',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venta.cliente?.razonSocial ?? 'N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          if (venta.cliente?.localidad != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${venta.cliente?.localidad?.nombre ?? 'Localidad desconocida'}',
                              style: TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (venta.tipoPago != null)
                      Flexible(
                        child: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total:',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bs. ${venta.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Chip(
                              label: Text(venta.tipoPago!.nombre),
                              avatar: const Icon(
                                Icons.payment,
                                size: 16,
                                color: Colors.lightGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Ubicación de Entrega (si disponible)
                if (venta.direccionCliente != null) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dirección de Entrega',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (venta.direccionCliente?.observaciones != null)
                              Text(
                                venta.direccionCliente!.observaciones ??
                                    'Sin dirección específica',
                                style: TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 2),
                            Text(
                              venta.direccionCliente?.localidad?.nombre ??
                                  'Sin dirección específica',
                              style: TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Botones de Contacto
                if (venta.cliente?.telefono != null) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
