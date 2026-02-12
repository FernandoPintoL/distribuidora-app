import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/print_service.dart';
import '../../utils/phone_utils.dart';

class VentaDetalleScreen extends StatefulWidget {
  final int ventaId;

  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  State<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ventasProvider = context.read<VentasProvider>();
      ventasProvider.loadVentaDetalle(widget.ventaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Venta'), elevation: 0),
      body: Consumer<VentasProvider>(
        builder: (context, ventasProvider, _) {
          // Loading state
          if (ventasProvider.isLoadingDetalle) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (ventasProvider.errorMessage != null &&
              ventasProvider.ventaDetalle == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ventasProvider.errorMessage ?? 'Error desconocido',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ventasProvider.loadVentaDetalle(widget.ventaId);
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final venta = ventasProvider.ventaDetalle;
          if (venta == null) {
            return const Center(child: Text('Sin datos de venta'));
          }

          // Success state - show venta details
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card mejorado
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Número y Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Folio #${venta.id} | ${venta.numero}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venta.fecha.toString().split(' ')[0],
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Bs. ${venta.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.greenAccent
                                      : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    venta.estadoPago,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Cliente - Card mejorada con Avatar, Ubicación y Botones
                        Card(
                          elevation: 0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]?.withValues(alpha: 0.5)
                              : Colors.blue[50]?.withValues(alpha: 0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar y Nombre del Cliente
                                Row(
                                  children: [
                                    // Avatar con iniciales
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: Text(
                                        (venta.clienteNombre ?? 'C')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Información del Cliente
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            venta.clienteNombre ??
                                                'Cliente desconocido',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'NIT: ${venta.cliente ?? 'N/A'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          if (venta.clienteLocalidad != null &&
                                              venta.clienteLocalidad!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '📍 ${venta.clienteLocalidad}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                      ? Colors.greenAccent
                                                      : Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Ubicación de Entrega (si disponible)
                                if (venta.direccion != null &&
                                    venta.direccion!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Dirección de Entrega',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              venta.direccion!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Coordenadas GPS si disponibles
                                  if (venta.latitud != null &&
                                      venta.longitud != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '🧭 ${venta.latitud!.toStringAsFixed(4)}, ${venta.longitud!.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).brightness ==
                                            Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                                // Botones de Contacto
                                if (venta.clienteTelefono != null &&
                                    venta.clienteTelefono!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Botón Llamar
                                      _buildContactButton(
                                        context,
                                        icon: Icons.phone,
                                        label: 'Llamar',
                                        color: Colors.green,
                                        onPressed: () =>
                                            PhoneUtils.llamarCliente(
                                          context,
                                          venta.clienteTelefono,
                                        ),
                                      ),
                                      // Botón WhatsApp
                                      _buildContactButton(
                                        context,
                                        icon: Icons.chat,
                                        label: 'WhatsApp',
                                        color: Colors.green[600]!,
                                        onPressed: () =>
                                            PhoneUtils.enviarWhatsApp(
                                          context,
                                          venta.clienteTelefono,
                                        ),
                                      ),
                                      // Botón Descargar PDF
                                      _buildContactButton(
                                        context,
                                        icon: Icons.download,
                                        label: 'Nota',
                                        color: Colors.blue,
                                        onPressed: () =>
                                            _descargarPDFVenta(venta.id),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: _buildContactButton(
                                      context,
                                      icon: Icons.download,
                                      label: 'Descargar Nota',
                                      color: Colors.blue,
                                      onPressed: () =>
                                          _descargarPDFVenta(venta.id),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Estados
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Estado Documento',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          venta.estadoLogistico,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Estado Logístico',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          venta.estadoLogisticoCodigo ?? 'SIN_ENTREGA',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Chips de información
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (venta.canalOrigen != null)
                              Chip(
                                label: Text(venta.canalOrigen!),
                                avatar: const Icon(Icons.storefront, size: 16),
                              ),
                            if (venta.tipoPago != null)
                              Chip(
                                label: Text(venta.tipoPago!.nombre),
                                avatar: const Icon(Icons.payment, size: 16),
                              ),
                            if (venta.politicaPago != null)
                              Chip(
                                label: Text(venta.politicaPago!),
                                avatar: const Icon(Icons.schedule, size: 16),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sección de productos
                Text(
                  'Productos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (venta.detalles.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Sin productos',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ...venta.detalles.map((detalle) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    detalle.producto?.nombre ??
                                        'Producto desconocido',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x${detalle.cantidad.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'P.U: Bs. ${detalle.precioUnitario.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Subtotal: Bs. ${detalle.subtotal.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.greenAccent
                                            : Colors.green,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 24),
                // Resumen de pago
                Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /* Text(
                          'Resumen de Pago',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('Bs. ${venta.subtotal.toStringAsFixed(2)}'),
                          ],
                        ), */
                        if (venta.impuesto > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Impuesto:'),
                              Text('Bs. ${venta.impuesto.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Descuento:'),
                            Text('Bs. ${venta.descuento.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Bs. ${venta.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget para los botones de contacto
  Widget _buildContactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Descargar PDF de la venta
  Future<void> _descargarPDFVenta(int ventaId) async {
    try {
      final printService = PrintService();
      final success = await printService.downloadDocument(
        documentoId: ventaId,
        documentType: PrintDocumentType.venta,
        format: PrintFormat.ticket58,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo descargar el PDF'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nota de venta descargada'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
