import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/print_service.dart';
import '../../services/venta_service.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/map_location_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class VentaDetalleScreen extends StatefulWidget {
  final int ventaId;

  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  State<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  late VentaService _ventaService;
  Map<String, dynamic>? _entregaData;
  bool _isLoadingEntrega = false;
  int _indiceImagenActual = 0;
  bool _isDownloadingImagen = false;

  @override
  void initState() {
    super.initState();
    _ventaService = VentaService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ventasProvider = context.read<VentasProvider>();
      ventasProvider.loadVentaDetalle(widget.ventaId);
      _loadEntregaDetails();
    });
  }

  /// Carga los detalles de la entrega asociada a la venta
  Future<void> _loadEntregaDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEntrega = true;
    });

    try {
      final response = await _ventaService.getEntregaPorVenta(widget.ventaId);

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _entregaData = response.data;
          }
          _isLoadingEntrega = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEntrega = false;
        });
      }
      debugPrint('Error loading entrega details: $e');
    }
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '🧭 ${venta.latitud!.toStringAsFixed(4)}, ${venta.longitud!.toStringAsFixed(4)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // ✅ NUEVO: Botón "Ver en Mapa"
                                        ElevatedButton.icon(
                                          onPressed: () => _abrirMapa(
                                            venta.latitud!,
                                            venta.longitud!,
                                          ),
                                          icon: const Icon(Icons.map, size: 16),
                                          label: const Text('Mapa'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
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
                // ✅ NUEVA SECCIÓN: Detalles de Entrega (si existe)
                if (_entregaData != null) ...[
                  _buildEntregaDetailsCard(context),
                  const SizedBox(height: 24),
                ],
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
                    // ✅ NUEVO: Obtener URL de imagen del producto
                    final imageUrl = detalle.producto?.imagenPrincipal?.url;
                    final tieneImagen = imageUrl != null && imageUrl.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ NUEVO: Mostrar imagen del producto si existe
                            if (tieneImagen) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Imagen no disponible',
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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

  /// Abrir ubicación de entrega en mapa interactivo o Google Maps
  Future<void> _abrirMapa(double latitud, double longitud) async {
    // Primero intentar abrir el mapa interactivo
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Ubicación de Entrega'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: MapLocationSelector(
                initialLatitude: latitud,
                initialLongitude: longitud,
                onLocationSelected: (lat, lng, address) {
                  // En modo lectura, solo cerramos el diálogo
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 ${address ?? "Ubicación: $lat, $lng"}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          },
        );
      }
    } catch (e) {
      // Si hay error con el mapa interactivo, fallback a Google Maps externo
      debugPrint('⚠️ Error abriendo mapa interactivo: $e');
      _abrirGoogleMaps(latitud, longitud);
    }
  }

  /// Fallback: Abrir Google Maps en aplicación externa
  Future<void> _abrirGoogleMaps(double latitud, double longitud) async {
    try {
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final mapsUrl = Uri.parse(
          'geo:$latitud,$longitud?q=$latitud,$longitud',
        );
        if (await canLaunchUrl(mapsUrl)) {
          await launchUrl(mapsUrl);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ No se pudo abrir Google Maps'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
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

  /// ✅ NUEVA FUNCIÓN: Construir Card de detalles de entrega
  Widget _buildEntregaDetailsCard(BuildContext context) {
    if (_isLoadingEntrega) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cargando información de entrega...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_entregaData == null) {
      return const SizedBox.shrink();
    }

    // Extraer datos de la entrega
    final entregaId = _entregaData?['id'];
    final numeroEntrega = _entregaData?['numero_entrega'] ?? 'N/A';
    final estadoEntrega = _entregaData?['tipo_novedad']?['nombre'] ?? 'Desconocido';
    final estadoColor = _getEstadoEntregaColor(_entregaData?['tipo_novedad']?['codigo'] ?? '');

    // Datos del chofer
    final choferNombre = _entregaData?['chofer']?['nombre'] ?? 'Sin asignar';
    final choferTelefono = _entregaData?['chofer']?['usuario']?['telefono'] ?? '';

    // Datos del vehículo
    final vehiculoPlaca = _entregaData?['vehiculo']?['placa'] ?? 'N/A';
    final vehiculoMarca = _entregaData?['vehiculo']?['marca'] ?? '';
    final vehiculoModelo = _entregaData?['vehiculo']?['modelo'] ?? '';

    // Fechas
    final fechaAsignacion = _entregaData?['created_at'];
    final fechaInicio = _entregaData?['fecha_inicio'];
    final fechaEntrega = _entregaData?['fecha_entrega'];

    // ✅ NUEVA: Extraer confirmacionesVentas (última confirmación)
    final confirmacionesVentas = _entregaData?['confirmacionesVentas'] as List?;
    final ultimaConfirmacion = confirmacionesVentas != null && confirmacionesVentas.isNotEmpty
        ? confirmacionesVentas.last as Map
        : null;
    final tipoEntrega = ultimaConfirmacion?['tipo_entrega'];
    final tipoNovedad = ultimaConfirmacion?['tipo_novedad'];
    final observacionesLogistica = ultimaConfirmacion?['observaciones_logistica'];
    final firmaDigitalUrl = ultimaConfirmacion?['firma_digital_url'];
    final productosDevueltos = ultimaConfirmacion?['productos_devueltos'] as List? ?? [];  // ✅ NUEVO 2026-02-17: Productos devueltos
    final montoDevuelto = ultimaConfirmacion?['monto_devuelto'];  // ✅ NUEVO 2026-02-17: Monto devuelto
    final montoAceptado = ultimaConfirmacion?['monto_aceptado'];  // ✅ NUEVO 2026-02-17: Monto aceptado

    return Column(
      children: [
        // Título de la sección
        Row(
          children: [
            Icon(Icons.local_shipping_outlined,
              color: estadoColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Detalles de Entrega',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card principal de entrega
        Card(
          elevation: 0,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]?.withValues(alpha: 0.5)
              : Colors.blue[50]?.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número y Estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrega #$numeroEntrega',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $entregaId',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.2),
                        border: Border.all(color: estadoColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estadoEntrega,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: estadoColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Sección Chofer
                _buildEntregaInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Chofer',
                  value: choferNombre,
                  secondaryValue: choferTelefono.isNotEmpty ? choferTelefono : null,
                  onSecondaryTap: choferTelefono.isNotEmpty
                      ? () => PhoneUtils.llamarCliente(context, choferTelefono)
                      : null,
                ),
                const SizedBox(height: 12),
                // Sección Vehículo
                _buildEntregaInfoRow(
                  context,
                  icon: Icons.directions_car_outlined,
                  label: 'Vehículo',
                  value: vehiculoPlaca,
                  secondaryValue: vehiculoMarca.isNotEmpty
                      ? '$vehiculoMarca ${vehiculoModelo.isNotEmpty ? vehiculoModelo : ''}'
                      : null,
                ),
                const SizedBox(height: 12),
                // Sección Fechas
                if (fechaAsignacion != null)
                  _buildEntregaInfoRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Asignación',
                    value: _formatearFecha(fechaAsignacion),
                  ),
                if (fechaInicio != null) ...[
                  const SizedBox(height: 12),
                  _buildEntregaInfoRow(
                    context,
                    icon: Icons.play_circle_outline,
                    label: 'Inicio',
                    value: _formatearFecha(fechaInicio),
                  ),
                ],
                if (fechaEntrega != null) ...[
                  const SizedBox(height: 12),
                  _buildEntregaInfoRow(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Entregado',
                    value: _formatearFecha(fechaEntrega),
                  ),
                ],
                // ✅ NUEVA SECCIÓN: Información de Confirmación
                if (ultimaConfirmacion != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '📋 Confirmación de Entrega',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tipo de Entrega
                  if (tipoEntrega != null) ...[
                    _buildEntregaInfoRow(
                      context,
                      icon: tipoEntrega.toString().toUpperCase() == 'COMPLETA'
                          ? Icons.check_circle
                          : Icons.warning_outlined,
                      label: 'Tipo de Entrega',
                      value: tipoEntrega.toString().toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Tipo de Novedad (si aplica)
                  if (tipoNovedad != null && tipoNovedad.toString().isNotEmpty) ...[
                    _buildEntregaInfoRow(
                      context,
                      icon: Icons.info_outlined,
                      label: 'Novedad',
                      value: _formatearTipoNovedad(tipoNovedad.toString()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ✅ NUEVO 2026-02-17: Productos Devueltos en DEVOLUCION_PARCIAL
                  if (tipoNovedad?.toString().toUpperCase() == 'DEVOLUCION_PARCIAL' && productosDevueltos.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📦 Productos Devueltos',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange[900]?.withValues(alpha: 0.2)
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange[200] ?? Colors.orange,
                            ),
                          ),
                          child: Column(
                            children: [
                              ...productosDevueltos.asMap().entries.map((entry) {
                                final producto = entry.value as Map?;
                                final index = entry.key;
                                final nombre = producto?['producto_nombre'] ?? 'Producto desconocido';
                                final cantidad = producto?['cantidad'] ?? 0;
                                final precioUnitario = producto?['precio_unitario'] ?? 0;
                                final subtotal = producto?['subtotal'] ?? 0;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Cantidad: $cantidad',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              Text(
                                                'Unitario: \$${precioUnitario.toStringAsFixed(2)}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox.shrink(),
                                              Text(
                                                'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < productosDevueltos.length - 1)
                                      Divider(
                                        height: 1,
                                        color: Colors.grey[300],
                                      ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        // Totales de devolución
                        if (montoDevuelto != null || montoAceptado != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[700]?.withValues(alpha: 0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (montoDevuelto != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Devuelto:',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '\$${(montoDevuelto is num ? montoDevuelto : 0).toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (montoAceptado != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Monto Aceptado:',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        '\$${(montoAceptado is num ? montoAceptado : 0).toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                  // Observaciones
                  if (observacionesLogistica != null && observacionesLogistica.toString().isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 Observaciones',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]?.withValues(alpha: 0.3)
                                : Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300] ?? Colors.grey,
                            ),
                          ),
                          child: Text(
                            observacionesLogistica.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                  // Firma Digital (si existe)
                  if (firmaDigitalUrl != null && firmaDigitalUrl.toString().isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✍️ Firma Digital',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _mostrarVisorImagenes(context, [firmaDigitalUrl.toString()], 0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                firmaDigitalUrl.toString(),
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        // 🎨 Galería de Imágenes de Entrega
        _buildGaleriaImagenes(context),
      ],
    );
  }

  /// ✅ NUEVA FUNCIÓN: Formatear tipo de novedad para mostrar
  String _formatearTipoNovedad(String tipoNovedad) {
    const novedadMap = {
      'CLIENTE_CERRADO': '🏪 Tienda Cerrada',
      'DEVOLUCION_PARCIAL': '📦 Devolución Parcial',
      'RECHAZADO': '🚫 Rechazado',
      'DIRECCION_INCORRECTA': '📍 Dirección Incorrecta',
      'CLIENTE_NO_IDENTIFICADO': '🆔 Cliente No Identificado',
      'OTRO': '❓ Otro Motivo',
    };

    return novedadMap[tipoNovedad.toUpperCase()] ?? tipoNovedad;
  }

  /// Widget auxiliar para mostrar información de entrega
  Widget _buildEntregaInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? secondaryValue,
    VoidCallback? onSecondaryTap,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onSecondaryTap,
                  child: Text(
                    secondaryValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: onSecondaryTap != null ? Colors.blue : Colors.grey,
                      decoration: onSecondaryTap != null ? TextDecoration.underline : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Obtener color según estado de entrega
  Color _getEstadoEntregaColor(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'ENTREGADA':
        return Colors.green;
      case 'EN_TRÁNSITO':
      case 'EN_TRANSITO':
        return Colors.orange;
      case 'PENDIENTE':
      case 'PENDIENTE_ENVIO':
        return Colors.grey;
      case 'CON_NOVEDAD':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Formatear fecha en formato legible
  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'N/A';

    try {
      final dateTime = DateTime.parse(fecha);
      final formatter = DateFormat('dd MMM yyyy HH:mm', 'es_ES');
      return formatter.format(dateTime);
    } catch (e) {
      return fecha.split('T')[0]; // Fallback a solo la fecha
    }
  }

  /// Construir galería de imágenes de la entrega
  Widget _buildGaleriaImagenes(BuildContext context) {
    // Extraer fotos de las confirmaciones
    List<String> imagenes = [];

    if (_entregaData != null) {
      // Obtener fotos de confirmaciones
      if (_entregaData?['confirmacionesVentas'] != null) {
        for (var confirmacion in _entregaData?['confirmacionesVentas'] as List) {
          final conf = confirmacion as Map;

          // Fotos de la entrega
          if (conf['fotos'] != null) {
            final fotos = conf['fotos'];
            if (fotos is List) {
              imagenes.addAll(fotos.cast<String>());
            } else if (fotos is String) {
              imagenes.add(fotos);
            }
          }

          // Firma digital
          if (conf['firma_digital_url'] != null && conf['firma_digital_url'].toString().isNotEmpty) {
            imagenes.add(conf['firma_digital_url'].toString());
          }
        }
      }
    }

    // Si no hay imágenes, mostrar mensaje
    if (imagenes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No hay imágenes de esta entrega',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Galería de miniaturas
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📸 Imágenes de la Entrega',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: imagenes.asMap().entries.map((entry) {
                final index = entry.key;
                final imagenUrl = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _mostrarVisorImagenes(context, imagenes, index),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagenUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar visor de imágenes en pantalla completa
  void _mostrarVisorImagenes(
    BuildContext context,
    List<String> imagenes,
    int indiceInicial,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImagenViewerModal(
          imagenes: imagenes,
          indiceInicial: indiceInicial,
          onDescargar: _descargarImagen,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Descargar imagen a dispositivo
  Future<void> _descargarImagen(String imagenUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Descargando imagen...')),
      );

      // Obtener directorio de documentos
      final directorio = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreArchivo = 'entrega_$timestamp.jpg';
      final rutaArchivo = '${directorio.path}/$nombreArchivo';

      // Descargar archivo
      final response = await http.get(Uri.parse(imagenUrl));

      if (response.statusCode == 200) {
        // Guardar archivo
        final archivo = File(rutaArchivo);
        await archivo.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Imagen descargada: $nombreArchivo')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al descargar imagen')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }
}

/// Modal para visualizar imágenes en pantalla completa
class _ImagenViewerModal extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;
  final Function(String) onDescargar;

  const _ImagenViewerModal({
    required this.imagenes,
    required this.indiceInicial,
    required this.onDescargar,
  });

  @override
  State<_ImagenViewerModal> createState() => _ImagenViewerModalState();
}

class _ImagenViewerModalState extends State<_ImagenViewerModal> {
  late int _indiceActual;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irAlAnterior() {
    if (_indiceActual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _irAlSiguiente() {
    if (_indiceActual < widget.imagenes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          'Imagen ${_indiceActual + 1} de ${widget.imagenes.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              widget.onDescargar(widget.imagenes[_indiceActual]);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView para navegar entre imágenes
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _indiceActual = index;
              });
            },
            itemCount: widget.imagenes.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(80),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  widget.imagenes[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.grey, size: 80),
                            SizedBox(height: 16),
                            Text('Error al cargar imagen',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              );
            },
          ),

          // Botones de navegación
          if (widget.imagenes.length > 1) ...[
            // Botón anterior (izquierda)
            if (_indiceActual > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _irAlAnterior,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),

            // Botón siguiente (derecha)
            if (_indiceActual < widget.imagenes.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _irAlSiguiente,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
