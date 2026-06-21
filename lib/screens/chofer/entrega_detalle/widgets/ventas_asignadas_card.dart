import 'package:flutter/material.dart';
import '../../../../config/app_urls.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
import '../../../../models/estado_logistico.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../services/print_service.dart';
import '../../../../widgets/map_location_selector.dart';
import '../confirmar_entrega_venta_screen.dart';

class VentasAsignadasCard extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;
  final Function(String?) onLlamarCliente;
  final Function(String?) onEnviarWhatsApp;

  const VentasAsignadasCard({
    Key? key,
    required this.entrega,
    required this.provider,
    required this.onLlamarCliente,
    required this.onEnviarWhatsApp,
  }) : super(key: key);

  @override
  State<VentasAsignadasCard> createState() => _VentasAsignadasCardState();
}

class _VentasAsignadasCardState extends State<VentasAsignadasCard> {
  late Map<int, bool> _ventasConfirmadas;
  late Map<int, bool> _cargandoVenta;
  bool _procesandoConfirmacion = false;

  @override
  void initState() {
    super.initState();
    _ventasConfirmadas = {};
    _cargandoVenta = {};
    for (var venta in widget.entrega.ventas) {
      _ventasConfirmadas[venta.id] =
          (venta.estadoLogisticoCodigo == 'PENDIENTE_ENVIO');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final entrega = widget.entrega;

    // ✅ DEBUG 2026-06-14: Verificar si se están parseando las direcciones
    for (var venta in entrega.ventas) {
      final tieneDir = venta.direccionCliente != null;
      final tieneLat = venta.direccionCliente?.latitud != null;
      final tieneLng = venta.direccionCliente?.longitud != null;
      debugPrint(
        '🗺️ [VENTAS_CARD] Venta ${venta.numero} | DireccionCliente: $tieneDir | Lat: $tieneLat | Lng: $tieneLng | Lat=${venta.direccionCliente?.latitud}, Lng=${venta.direccionCliente?.longitud}',
      );
    }

    final esPreparacion = entrega.estado == 'PREPARACION_CARGA';
    final esEnCarga = entrega.estado == 'EN_CARGA';
    final esModoCarga = esPreparacion || esEnCarga;

    if (entrega.ventas.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ NUEVO: Ordenar ventas por ID ascendente (como el backend)
    final ventasOrdenadas = List<Venta>.from(entrega.ventas)
      ..sort((a, b) => a.id.compareTo(b.id));

    final totalVentas = ventasOrdenadas.length;
    final ventasConfirmadas = _ventasConfirmadas.values.where((v) => v).length;
    final porcentaje = (ventasConfirmadas / totalVentas * 100).toStringAsFixed(
      0,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: isDarkMode ? Colors.blue[400] : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ventas Asignadas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (esModoCarga) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$ventasConfirmadas/$totalVentas cargadas ($porcentaje%)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                if (esModoCarga)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ventasConfirmadas == totalVentas
                          ? (isDarkMode ? Colors.green[900] : Colors.green[100])
                          : (isDarkMode
                                ? Colors.orange[900]
                                : Colors.orange[100]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ventasConfirmadas == totalVentas
                          ? '✅ Completo'
                          : '⏳ En progreso',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ventasConfirmadas == totalVentas
                            ? (isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[900])
                            : (isDarkMode
                                  ? Colors.orange[300]
                                  : Colors.orange[900]),
                      ),
                    ),
                  ),
              ],
            ),
            if (esModoCarga) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalVentas > 0 ? ventasConfirmadas / totalVentas : 0,
                  minHeight: 6,
                  backgroundColor: isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ventasConfirmadas == totalVentas
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventasOrdenadas.length,
              itemBuilder: (context, index) {
                final venta = ventasOrdenadas[index];
                final isEnRuta = venta.estadoLogisticoCodigo == 'EN_TRANSITO';
                final borderColor = _getEstadoLogisticoColor(
                  venta.estadoLogisticoCodigo,
                );
                final borderWidth = isEnRuta ? 2.0 : 1.0;

                final tipoEntrega = venta.tipoEntregaValue;
                final tipoConfirmacion = venta.tipoConfirmacionValue;
                bool mostrarResumen =
                    tipoConfirmacion == 'COMPLETA' ||
                    tipoConfirmacion == 'DEVOLUCION_PARCIAL';
                return InkWell(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed('/venta-detalle', arguments: venta.id);
                  },
                  child: Card(
                    elevation: isEnRuta ? 2 : 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shadowColor: borderColor,
                    surfaceTintColor: borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor, width: borderWidth),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ NUEVO: Encabezado - Avatar + VEN# + Cliente + Monto
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ✅ NUEVO: Avatar del cliente
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                backgroundImage:
                                    venta.cliente?.fotoPerfil != null
                                    ? NetworkImage(
                                        AppUrls.buildImageUrl(
                                          venta.cliente!.fotoPerfil!,
                                        ),
                                      )
                                    : null,
                                child: venta.cliente!.fotoPerfil == null
                                    ? Icon(
                                        Icons.person,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Folio #${venta.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      venta.cliente?.nombre ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (venta.cliente?.localidad != null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: isDarkMode
                                                ? Colors.blue[400]
                                                : Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              venta
                                                      .cliente
                                                      ?.localidad
                                                      ?.nombre ??
                                                  "S/N Localidad",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    // ✅ NUEVO: Observaciones de la dirección
                                    if (venta.direccionCliente?.observaciones !=
                                        null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.pin_drop_outlined,
                                            size: 16,
                                            color: Colors.orange[400],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              venta
                                                      .direccionCliente!
                                                      .observaciones ??
                                                  "",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.orange[300]
                                                    : Colors.orange[800],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ✅ Monto destacado a la derecha
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'Bs ${venta.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[400],
                                        ),
                                      ),
                                      // Badge Tipo de Pago
                                      if (venta.tipoPago != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getTipoPagoIcon(
                                                  venta.tipoPago?.codigo,
                                                ),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                venta.tipoPago?.nombre
                                                        .toUpperCase() ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  // ✅ NUEVO: Menú popup de acciones (3 puntos)
                                  PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      if (value == 'llamar' &&
                                          venta.cliente?.telefono != null) {
                                        widget.onLlamarCliente(
                                          venta.cliente?.telefono,
                                        );
                                      } else if (value == 'whatsapp' &&
                                          venta.cliente?.telefono != null) {
                                        widget.onEnviarWhatsApp(
                                          venta.cliente?.telefono,
                                        );
                                      } else if (value == 'pdf') {
                                        _descargarPDFVenta(venta.id);
                                      } else if (value == 'mapa' &&
                                          venta.direccionCliente?.latitud !=
                                              null &&
                                          venta.direccionCliente?.longitud !=
                                              null) {
                                        _abrirMapa(venta);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      if (venta.cliente?.telefono != null)
                                        const PopupMenuItem<String>(
                                          value: 'llamar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.call, size: 20),
                                              SizedBox(width: 12),
                                              Text('Llamar'),
                                            ],
                                          ),
                                        ),
                                      if (venta.cliente?.telefono != null)
                                        const PopupMenuItem<String>(
                                          value: 'whatsapp',
                                          child: Row(
                                            children: [
                                              Icon(Icons.chat, size: 20),
                                              SizedBox(width: 12),
                                              Text('WhatsApp'),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuItem<String>(
                                        value: 'pdf',
                                        child: Row(
                                          children: [
                                            Icon(Icons.download, size: 20),
                                            SizedBox(width: 12),
                                            Text('Descargar PDF'),
                                          ],
                                        ),
                                      ),
                                      // ✅ NUEVO 2026-06-14: Opción para mostrar mapa
                                      if (venta.direccionCliente?.latitud !=
                                              null &&
                                          venta.direccionCliente?.longitud !=
                                              null)
                                        const PopupMenuItem<String>(
                                          value: 'mapa',
                                          child: Row(
                                            children: [
                                              Icon(Icons.map, size: 20),
                                              SizedBox(width: 12),
                                              Text('Mapa'),
                                            ],
                                          ),
                                        ),
                                    ],
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ✅ NUEVO 2026-06-13: Badges de Estado Logístico + Tipo de Pago
                          Wrap(
                            spacing: 4,
                            runSpacing: 8,
                            children: [
                              // Badge Estado Logístico de la venta
                              if (venta.estadoLogistico != null &&
                                  venta.estadoLogistico!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: venta.estadoLogisticoColor != null
                                        ? Color(
                                            int.parse(
                                              venta.estadoLogisticoColor!
                                                  .replaceFirst('#', '0xFF'),
                                            ),
                                          ).withValues(alpha: 0.2)
                                        : (isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[200]),
                                    border: Border.all(
                                      color: venta.estadoLogisticoColor != null
                                          ? Color(
                                              int.parse(
                                                venta.estadoLogisticoColor!
                                                    .replaceFirst('#', '0xFF'),
                                              ),
                                            )
                                          : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (venta.estadoLogisticoIcon != null)
                                        Text(
                                          venta.estadoLogisticoIcon!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (venta.estadoLogisticoIcon != null)
                                        const SizedBox(width: 6),
                                      Text(
                                        venta.estadoLogistico!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              venta.estadoLogisticoColor != null
                                              ? Color(
                                                  int.parse(
                                                    venta.estadoLogisticoColor!
                                                        .replaceFirst(
                                                          '#',
                                                          '0xFF',
                                                        ),
                                                  ),
                                                )
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // ✅ NUEVO: Badge Tipo de Entrega
                              if (tipoEntrega != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _getTipoEntregaColor(tipoEntrega),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTipoEntregaIcon(tipoEntrega),
                                        size: 14,
                                        color: _getTipoEntregaColor(
                                          tipoEntrega,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        tipoEntrega!.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getTipoEntregaColor(
                                            tipoEntrega,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ✅ NUEVO: Badge Tipo de Confirmación
                              if (tipoConfirmacion != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _getTipoConfirmacionColor(
                                        tipoConfirmacion,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTipoConfirmacionIcon(
                                          tipoConfirmacion,
                                        ),
                                        size: 14,
                                        color: _getTipoConfirmacionColor(
                                          tipoConfirmacion,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        tipoConfirmacion!.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getTipoConfirmacionColor(
                                            tipoConfirmacion,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // ✅ NUEVO: Mini Resumen de Pago (solo si hay desglose)
                          if (venta.confirmaciones.isNotEmpty &&
                              venta
                                  .confirmaciones
                                  .last
                                  .desglosePageos
                                  .isNotEmpty &&
                              mostrarResumen) ...[
                            const SizedBox(height: 12),
                            _buildMiniResumenPago(venta, isDarkMode),
                          ],
                          // ✅ Botón de confirmación solo en EN_TRANSITO
                          if (venta.estadoLogisticoCodigo == 'EN_TRANSITO') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ConfirmarEntregaVentaScreen(
                                            entrega: entrega,
                                            venta: venta,
                                            provider: widget.provider,
                                          ),
                                    ),
                                  ).then((result) {
                                    // ✅ Si se confirmó exitosamente, recargar entrega
                                    if (result == true) {
                                      debugPrint(
                                        '✅ [VENTAS_CARD] Confirmación exitosa, recargando...',
                                      );
                                      widget.provider
                                          .obtenerEntrega(entrega.id)
                                          .then((_) {
                                            debugPrint(
                                              '✅ [VENTAS_CARD] Entrega recargada',
                                            );
                                            setState(
                                              () {},
                                            ); // Forzar rebuild para mostrar cambios
                                          });
                                    }
                                  });
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Confirmar Entrega'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (esModoCarga &&
                ventasConfirmadas > 0 &&
                ventasConfirmadas == totalVentas) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mostrarDialogoConfirmarCarga(context);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirmar Carga Completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            /*if (ventasOrdenadas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total a Entregar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BS ${ventasOrdenadas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cantidad de Ventas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('${ventasOrdenadas.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],*/
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoConfirmarCarga(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ✅ No permitir cerrar tocando afuera
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool procesando = false;

          return AlertDialog(
            title: const Text('Confirmar Carga Completa'),
            content: procesando
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Confirmando carga...'),
                    ],
                  )
                : const Text(
                    'Todas las ventas han sido marcadas como cargadas. '
                    '¿Confirmas que la carga está lista para entregar?',
                  ),
            actions: [
              if (!procesando)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              if (!procesando)
                ElevatedButton(
                  onPressed: () async {
                    setState(() => procesando = true);
                    final currentContext = context;

                    try {
                      final exito = await widget.provider
                          .confirmarCargoCompleto(widget.entrega.id);

                      if (mounted) {
                        if (exito) {
                          // ✅ Esperar a que isLoading sea false antes de cerrar
                          while (widget.provider.isLoading && mounted) {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                          }

                          if (mounted && currentContext.mounted) {
                            Navigator.pop(
                              currentContext,
                            ); // ✅ Cerrar diálogo después
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Carga confirmada correctamente. Estado: Listo para entrega',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          Navigator.pop(currentContext);
                          if (mounted && currentContext.mounted) {
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      Navigator.pop(currentContext);
                      if (mounted && currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Error inesperado: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Confirmar'),
                ),
            ],
          );
        },
      ),
    );
  }

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
            content: Text('Abriendo PDF...'),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ NUEVO 2026-06-14: Abrir mapa de ubicación de la venta
  Future<void> _abrirMapa(Venta venta) async {
    try {
      if (!mounted) return;

      final fotoPerfil = venta.cliente?.fotoPerfil != null
          ? '${AppUrls.baseUrlImg}${venta.cliente!.fotoPerfil}'
          : null;

      final ubicacionVenta = MapLocation(
        latitude: venta.direccionCliente!.latitud!,
        longitude: venta.direccionCliente!.longitud!,
        title: venta.cliente?.nombre ?? 'Sin nombre',
        subtitle: venta.id.toString(),
        isSelected: false,
        razonSocial: venta.cliente?.razonSocial,
        telefono: venta.cliente?.telefono,
        ventaId: venta.id,
        markerColor: venta.estadoLogisticoColor,
        fotoPerfil: fotoPerfil,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MapLocationSelector(
              initialLatitude: venta.direccionCliente!.latitud!,
              initialLongitude: venta.direccionCliente!.longitud!,
              onLocationSelected: (lat, lng, address) {
                Navigator.pop(context);
              },
              additionalLocations: [ubicacionVenta],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir mapa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NUEVO 2026-03-12: Mini resumen de pago para cada venta
  Widget _buildMiniResumenPago(Venta venta, bool isDarkMode) {
    // Obtener datos de confirmación más reciente
    final confirmacionReciente = venta.confirmaciones.isNotEmpty
        ? venta.confirmaciones.last
        : null;

    // ✅ Extraer efectivo y QR de desglose_pagos
    double efectivo = 0.0;
    double qr = 0.0;

    if (confirmacionReciente != null &&
        confirmacionReciente.desglosePageos.isNotEmpty) {
      for (var pago in confirmacionReciente.desglosePageos) {
        final nombre = pago.tipoPagoNombre.toUpperCase();
        final monto = pago.monto;

        if (nombre.contains('EFECTIVO')) {
          efectivo = monto;
        } else if (nombre.contains('TRANSFERENCIA') || nombre.contains('QR')) {
          qr = monto;
        }
      }
    }

    final pendiente = confirmacionReciente?.montoPendiente ?? 0.0;
    final estado = confirmacionReciente?.estadoPago ?? 'PENDIENTE';

    // Determinar color según estado
    Color estadoColor;
    String estadoLabel;
    switch (estado) {
      case 'PAGADO':
        estadoColor = Colors.green;
        estadoLabel = '✅ Pagado';
        break;
      case 'RECHAZADO':
        estadoColor = Colors.red;
        estadoLabel = '❌ Rechazado';
        break;
      case 'PARCIAL':
        estadoColor = Colors.orange;
        estadoLabel = '⚠️ Parcial';
        break;
      default:
        estadoColor = Colors.grey;
        estadoLabel = '⏳ Pendiente';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: estadoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: estadoColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              estadoLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: estadoColor),
            ),
          ),
          const SizedBox(height: 8),
          // Desglose de pagos en fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Efectivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💵 Efectivo',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${efectivo.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                  ],
                ),
              ),
              // QR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 QR',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${qr.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
              ),
              // Pendiente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏳ Pendiente',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${pendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pendiente > 0
                            ? Colors.orange[400]
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO 2026-06-13: Obtener icono para Estado Logistico de la venta
  Color _getEstadoLogisticoColor(String? estado) {
    final estadoUpper = estado?.toUpperCase() ?? '';
    switch (estadoUpper) {
      case 'EN_TRANSITO':
        return Colors.blue;
      case 'ENTREGADA':
        return Colors.green;
      case 'PROBLEMAS':
        return Colors.deepOrange;
      case 'RECHAZADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ NUEVO 2026-06-13: Obtener icono para tipo de pago
  IconData _getTipoPagoIcon(String? codigo) {
    final codigoUpper = codigo?.toUpperCase() ?? '';
    switch (codigoUpper) {
      case 'EFECTIVO':
        return Icons.money;
      case 'QR':
        return Icons.qr_code_2;
      case 'TRANSFERENCIA':
        return Icons.transfer_within_a_station;
      case 'CHEQUE':
        return Icons.description;
      case 'CREDITO':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  // ✅ NUEVO 2026-06-13: Obtener color para tipo de confirmación
  Color _getTipoConfirmacionColor(String? tipo) {
    final tipoUpper = tipo?.toUpperCase() ?? '';
    switch (tipoUpper) {
      case 'COMPLETA':
        return Colors.green[700]!;
      case 'PARCIAL':
        return Colors.orange[700]!;
      case 'RECHAZADO':
      case 'CLIENTE_CERRADO':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // ✅ NUEVO 2026-06-13: Obtener icono para tipo de confirmación
  IconData _getTipoConfirmacionIcon(String? tipo) {
    final tipoUpper = tipo?.toUpperCase() ?? '';
    switch (tipoUpper) {
      case 'COMPLETA':
        return Icons.check_circle;
      case 'PARCIAL':
        return Icons.warning;
      case 'RECHAZADO':
      case 'CLIENTE_CERRADO':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // ✅ NUEVO 2026-06-13: Obtener color para tipo de entrega
  Color _getTipoEntregaColor(String? tipo) {
    final tipoUpper = tipo?.toUpperCase() ?? '';
    switch (tipoUpper) {
      case 'COMPLETA':
        return Colors.green[700]!;
      case 'PARCIAL':
        return Colors.orange[700]!;
      case 'CON_NOVEDAD':
        return Colors.amber[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // ✅ NUEVO 2026-06-13: Obtener icono para tipo de entrega
  IconData _getTipoEntregaIcon(String? tipo) {
    final tipoUpper = tipo?.toUpperCase() ?? '';
    switch (tipoUpper) {
      case 'COMPLETA':
        return Icons.local_shipping;
      case 'PARCIAL':
        return Icons.inventory_2;
      case 'CON_NOVEDAD':
        return Icons.error_outline;
      default:
        return Icons.info;
    }
  }
}
