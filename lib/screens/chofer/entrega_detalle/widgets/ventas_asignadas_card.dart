import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../config/app_urls.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
import '../../../../models/estado_logistico.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../services/print_service.dart';
import '../../../../widgets/chofer/productos_agrupados_widget.dart';
import '../dialogs/confirmar_venta_entregada_dialog.dart';
import '../confirmar_entrega_venta_screen.dart'; // ✅ NUEVO: Para abrir la pantalla de confirmación

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
    final entregaActual = widget.provider.entregaActual ?? widget.entrega;

    final esPreparacion = entregaActual.estado == 'PREPARACION_CARGA';
    final esEnCarga = entregaActual.estado == 'EN_CARGA';
    final esModoCarga = esPreparacion || esEnCarga;

    if (entregaActual.ventas.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVentas = entregaActual.ventas.length;
    final ventasConfirmadas = _ventasConfirmadas.values.where((v) => v).length;
    final porcentaje = (ventasConfirmadas / totalVentas * 100).toStringAsFixed(
      0,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entregaActual.ventas.length,
              itemBuilder: (context, index) {
                final venta = entregaActual.ventas[index];
                final confirmada = _ventasConfirmadas[venta.id] ?? false;
                final cargando = _cargandoVenta[venta.id] ?? false;

                final isEnRuta = venta.estadoLogisticoCodigo == 'EN_TRANSITO';
                final borderColor = isEnRuta
                    ? (isDarkMode ? Colors.green[600]! : Colors.green[200]!)
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!);
                final borderWidth = isEnRuta ? 2.0 : 1.0;

                return InkWell(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed('/venta-detalle', arguments: venta.id);
                  },
                  child: Card(
                    elevation: isEnRuta ? 2 : 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
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
                                backgroundImage: venta.clienteFotoPerfil != null
                                    ? NetworkImage(
                                        AppUrls.buildImageUrl(
                                          venta.clienteFotoPerfil!,
                                        ),
                                      )
                                    : null,
                                child: venta.clienteFotoPerfil == null
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
                                      venta.clienteNombre ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      venta.clienteRazonSocial ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ✅ Monto destacado a la derecha
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Bs ${venta.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[400],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${venta.detalles.length} productos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ✅ NUEVO: Información (Localidad | Estado)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (venta.clienteLocalidad != null)
                                Expanded(
                                  child: Row(
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
                                          venta.clienteLocalidad!,
                                          style: TextStyle(
                                            fontSize: 13,
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
                                ),
                              const SizedBox(width: 8),
                              // ✅ Badge de estado vibrantee
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(
                                    venta.estadoLogisticoObj,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getEstadoColor(
                                      venta.estadoLogisticoObj,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getEstadoLabel(venta.estadoLogisticoObj),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getEstadoColor(
                                      venta.estadoLogisticoObj,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ✅ NUEVO: Observaciones de la dirección
                          if (venta.direccionObservaciones != null &&
                              venta.direccionObservaciones!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.orange[900]?.withValues(alpha: 0.2)
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.orange[700]!
                                      : Colors.orange[200]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pin_drop_outlined,
                                    size: 16,
                                    color: Colors.orange[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      venta.direccionObservaciones!,
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
                            ),
                          ],
                          const SizedBox(height: 12),
                          // ✅ NUEVO: Mini Resumen de Pago
                          _buildMiniResumenPago(venta, isDarkMode),
                          const SizedBox(height: 12),
                          // ✅ NUEVO: Botones de acción - Horizontal
                          if (venta.clienteTelefono != null &&
                              venta.clienteTelefono!.isNotEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () => widget.onLlamarCliente(
                                        venta.clienteTelefono,
                                      ),
                                      icon: const Icon(Icons.call, size: 18),
                                      label: const Text('Llamar'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () => widget.onEnviarWhatsApp(
                                        venta.clienteTelefono,
                                      ),
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('WhatsApp'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: IconButton(
                                    onPressed: () =>
                                        _descargarPDFVenta(venta.id),
                                    icon: const Icon(Icons.download, size: 18),
                                    style: IconButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: isDarkMode
                                            ? Colors.grey[600]!
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    tooltip: 'Descargar PDF',
                                  ),
                                ),
                              ],
                            ),
                          // ✅ NUEVO: Botón de Registrar Pago/Incidencia
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                debugPrint('💳 [VENTAS_CARD] Abriendo registro de pago para venta #${venta.id}');
                                _navegarARegistroPago(context, venta, entregaActual);
                              },
                              icon: const Icon(Icons.payment),
                              label: const Text('Registrar Pago/Incidencia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
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
                                            entrega: entregaActual,
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
                                          .obtenerEntrega(entregaActual.id)
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
            if (entregaActual.ventas.isNotEmpty) ...[
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
                        Text('Total a Entregar'),
                        const SizedBox(height: 4),
                        Text(
                          'BS ${entregaActual.ventas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Cantidad de Ventas'),
                        const SizedBox(height: 4),
                        Text('${entregaActual.ventas.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoConfirmarCarga(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga Completa'),
        content: const Text(
          'Todas las ventas han sido marcadas como cargadas. '
          '¿Confirmas que la carga está lista para entregar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.pop(currentContext);

              try {
                final exito = await widget.provider.confirmarCargoCompleto(
                  widget.entrega.id,
                );

                if (mounted) {
                  if (exito) {
                    await widget.provider.obtenerEntrega(widget.entrega.id);

                    if (mounted && currentContext.mounted) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
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

  // ✅ NUEVO: Obtener color desde el objeto EstadoLogistico centralizado
  Color _getEstadoColor(EstadoLogistico? estado) {
    if (estado != null && estado.color.isNotEmpty) {
      try {
        // Intentar parsear el color hex del backend
        return Color(int.parse('FF${estado.color.replaceFirst('#', '')}', radix: 16));
      } catch (e) {
        debugPrint('⚠️ Error parseando color: ${estado.color}');
      }
    }
    // Fallback si no viene color o hay error
    return _getEstadoColorFallback(estado?.codigo);
  }

  // ✅ FALLBACK: Colores por defecto si el backend no proporciona color
  Color _getEstadoColorFallback(String? codigo) {
    switch (codigo) {
      case 'PENDIENTE_ENVIO':
        return Colors.orange;
      case 'EN_RUTA':
        return Colors.blue;
      case 'EN_TRANSITO':
        return Colors.purple;
      case 'ENTREGADO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ NUEVO: Obtener etiqueta desde el objeto EstadoLogistico centralizado
  String _getEstadoLabel(EstadoLogistico? estado) {
    return estado?.nombre ?? 'Desconocido';
  }

  // ✅ NUEVO 2026-03-05: Construir encabezado mejorado (número | cliente | monto)
  Widget _buildVentaEncabezado(Venta venta) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venta.clienteNombre ?? 'Sin cliente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Folio #${venta.id}',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Bs. ${venta.total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.green[600],
          ),
        ),
      ],
    );
  }

  // ✅ NUEVO 2026-03-05: Construir fila de información (localidad | teléfono | estado)
  Widget _buildVentaInformacion(Venta venta) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        // ✅ NUEVO 2026-03-05: Ubicación + Razón Social con tooltip
        if (venta.clienteLocalidadObj != null ||
            venta.clienteRazonSocial != null)
          Tooltip(
            message: _construirMensajeUbicacion(venta),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📍'),
                const SizedBox(width: 2),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.clienteLocalidadObj?.nombre ?? 'Ubicación',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // ✅ NUEVO: Mostrar razón social si existe
        if (venta.clienteRazonSocial != null &&
            venta.clienteRazonSocial!.isNotEmpty)
          Text(
            venta.clienteRazonSocial!.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        // ✅ NUEVO 2026-03-05: Mostrar tipo de entrega (solo COMPLETA o CON_NOVEDAD)
        if (venta.tipoEntrega == 'COMPLETA' ||
            venta.tipoEntrega == 'CON_NOVEDAD')
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(venta.tipoEntrega == 'COMPLETA' ? '✅' : '⚠️'),
              const SizedBox(width: 2),
              Text(
                venta.tipoEntrega == 'COMPLETA' ? 'Completa' : 'Con Novedad',
                style: TextStyle(
                  color: venta.tipoEntrega == 'COMPLETA'
                      ? Colors.green[700]
                      : Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        // ✅ NUEVO 2026-03-05: Mostrar tipo de novedad específico como badge separado
        if (venta.tipoNovedad != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📋'),
              const SizedBox(width: 2),
              Text(
                _obtenerNombreTipoNovedad(venta.tipoNovedad),
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ✅ NUEVO 2026-03-05: Construir fila de detalles (fotos | pagos | devoluciones)
  Widget _buildVentaDetalles(Venta venta) {
    if (venta.confirmaciones.isEmpty) return const SizedBox.shrink();

    final confirmacion = venta.confirmaciones.first;
    final tieneFotos = (confirmacion['fotos'] as List?)?.isNotEmpty ?? false;
    final tieneDesglose =
        (confirmacion['desglose_pagos'] as List?)?.isNotEmpty ?? false;
    final tieneProductosDevueltos =
        (confirmacion['productos_devueltos'] as List?)?.isNotEmpty ?? false;

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (tieneFotos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fotos:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Text(
                '📷 ${(confirmacion['fotos'] as List?)?.length ?? 0}',
                style: TextStyle(color: Colors.blue[600]),
              ),
            ],
          ),
        if (tieneDesglose)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pagos:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Text(
                '💳 ${(confirmacion['desglose_pagos'] as List?)?.length ?? 0}',
                style: TextStyle(color: Colors.purple[600]),
              ),
            ],
          ),
        if (tieneProductosDevueltos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Devueltas:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Text(
                '↩️ ${(confirmacion['productos_devueltos'] as List?)?.length ?? 0}',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
      ],
    );
  }

  // ✅ NUEVO 2026-03-05: Traducir tipos de novedad a nombres legibles
  String _obtenerNombreTipoNovedad(String? tipo) {
    if (tipo == null) return 'Novedad';
    switch (tipo.toUpperCase()) {
      case 'DEVOLUCION_PARCIAL':
        return 'Devolución Parcial';
      case 'CLIENTE_CERRADO':
        return 'Cliente Cerrado';
      case 'NO_CONTACTADO':
        return 'No Contactado';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return tipo;
    }
  }

  // ✅ NUEVO 2026-03-05: Badge dinámico del estado_entrega
  Widget _buildEstadoEntregaBadge(dynamic entrega) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final codigo = entrega.estadoEntregaCodigo as String?;
    final nombre = entrega.estadoEntregaNombre as String?;
    final icono = entrega.estadoEntregaIcono as String?;
    final colorHex = entrega.estadoEntregaColor as String?;

    if (codigo == null || nombre == null) {
      return const SizedBox.shrink();
    }

    // Convertir color hex a Color Flutter
    Color badgeColor = Colors.blue[400]!;
    if (colorHex != null && colorHex.startsWith('#')) {
      try {
        badgeColor = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
      } catch (_) {
        badgeColor = Colors.blue[400]!;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar icono emoji si existe
          if (icono != null && icono.isNotEmpty)
            Text(icono, style: const TextStyle(fontSize: 12))
          else
            Icon(Icons.local_shipping, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            nombre,
            style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO 2026-03-12: Mini resumen de pago para cada venta
  Widget _buildMiniResumenPago(Venta venta, bool isDarkMode) {
    // Obtener datos de confirmación más reciente
    final confirmacionReciente = (venta.confirmaciones as List?)?.isNotEmpty ?? false
        ? (venta.confirmaciones.first as Map<String, dynamic>?)
        : null;

    final efectivo = (confirmacionReciente?['efectivo'] as num?)?.toDouble() ?? 0.0;
    final qr = (confirmacionReciente?['qr'] as num?)?.toDouble() ?? 0.0;
    final pendiente = (confirmacionReciente?['pendiente'] as num?)?.toDouble() ?? 0.0;
    final estado = confirmacionReciente?['estado'] as String? ?? 'PENDIENTE';

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
        border: Border.all(
          color: estadoColor.withValues(alpha: 0.3),
          width: 1,
        ),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: estadoColor,
              ),
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
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${efectivo.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
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
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${qr.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
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
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${pendiente.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: pendiente > 0 ? Colors.orange[400] : Colors.grey[400],
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

  /// ✅ NUEVO 2026-03-12: Navegar a pantalla de registro de pago/incidencia
  /// Sigue el patrón de resumen_pagos_entrega_screen.dart
  void _navegarARegistroPago(BuildContext context, Venta venta, Entrega entrega) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmarEntregaVentaScreen(
          entrega: entrega,
          venta: venta,
          provider: widget.provider,
          isEditing: true, // Modo edición para volver a registrar
        ),
      ),
    ).then((result) {
      // Si se guardó correctamente, recargar la lista de ventas
      if (result == true) {
        debugPrint('✅ [VENTAS_CARD] Pago registrado, recargando ventas...');
        widget.provider.obtenerEntrega(entrega.id);
      }
    });
  }

  // ✅ NUEVO 2026-03-05: Construir mensaje de ubicación completo con dirección y observaciones
  String _construirMensajeUbicacion(Venta venta) {
    final parts = <String>[];

    if (venta.clienteLocalidadObj != null) {
      parts.add('📍 ${venta.clienteLocalidadObj!.nombre}');
    }

    if (venta.clienteRazonSocial != null &&
        venta.clienteRazonSocial!.isNotEmpty) {
      parts.add('🏢 ${venta.clienteRazonSocial}');
    }

    if (venta.direccion != null && venta.direccion!.isNotEmpty) {
      parts.add('🏠 ${venta.direccion}');
    }

    if (venta.direccionObservaciones != null &&
        venta.direccionObservaciones!.isNotEmpty) {
      parts.add('📝 ${venta.direccionObservaciones}');
    }

    return parts.isEmpty ? 'Sin información de ubicación' : parts.join('\n');
  }
}
