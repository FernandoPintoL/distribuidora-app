import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../services/print_service.dart';
import '../../../../widgets/chofer/productos_agrupados_widget.dart';
import '../dialogs/confirmar_venta_entregada_dialog.dart';

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
    final porcentaje =
        (ventasConfirmadas / totalVentas * 100).toStringAsFixed(0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (esModoCarga) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$ventasConfirmadas/$totalVentas cargadas ($porcentaje%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (esModoCarga)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontSize: 11,
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
                  value:
                      totalVentas > 0 ? ventasConfirmadas / totalVentas : 0,
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

                final isEnRuta =
                    venta.estadoLogisticoCodigo == 'EN_RUTA';
                final borderColor = isEnRuta
                    ? (isDarkMode ? Colors.green[600]! : Colors.green[200]!)
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!);
                final borderWidth = isEnRuta ? 2.0 : 1.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: isEnRuta ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: borderColor, width: borderWidth),
                  ),
                  child: ExpansionTile(
                    leading: esModoCarga
                        ? cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              )
                            : Checkbox(
                                value: confirmada,
                                onChanged: (value) {
                                  final nuevoEstado = value ?? false;
                                  _procesarConfirmacionVenta(
                                    context,
                                    nuevoEstado,
                                    venta,
                                  );
                                },
                              )
                        : Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 20,
                          ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venta.clienteNombre?.toUpperCase() ?? 'Cliente',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // ✅ NUEVO: Mostrar localidad del cliente
                                  if (venta.clienteLocalidad != null && venta.clienteLocalidad!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Chip(
                                      label: Text(
                                        venta.clienteLocalidad!,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      avatar: const Icon(
                                        Icons.location_on,
                                        size: 12,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isEnRuta)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.green[900]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.green[600]!
                                        : Colors.green[400]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_run,
                                      size: 12,
                                      color: isDarkMode
                                          ? Colors.green[400]
                                          : Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'En Ruta',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.green[400]
                                            : Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${venta.id} | #${venta.numero}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  if (venta.clienteTelefono != null &&
                                      venta.clienteTelefono!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      venta.clienteTelefono!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDarkMode
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (venta.clienteTelefono != null &&
                                venta.clienteTelefono!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.phone),
                                  iconSize: 16,
                                  color: Colors.green,
                                  tooltip: 'Llamar',
                                  onPressed: () => widget.onLlamarCliente(
                                    venta.clienteTelefono,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.chat),
                                  iconSize: 16,
                                  color: Colors.green[600],
                                  tooltip: 'WhatsApp',
                                  onPressed: () =>
                                      widget.onEnviarWhatsApp(
                                    venta.clienteTelefono,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.download),
                                  iconSize: 16,
                                  color: Colors.blue,
                                  tooltip: 'Descargar PDF',
                                  onPressed: () =>
                                      _descargarPDFVenta(venta.id),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildUbicacionBadge(entregaActual),
                      ],
                    ),
                    subtitle: SizedBox(
                      width: 135,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BS ${venta.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[100]
                                  : Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 16,
                            child: _buildEstadoLogisticoBadge(venta),
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 16,
                            child: _buildEstadoPagoBadge(venta.estadoPago),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entregaActual.fechaEntregaComprometida !=
                                null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.blue[900]
                                      : Colors.blue[50],
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.blue[700]!
                                        : Colors.blue[200]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: isDarkMode
                                              ? Colors.blue[400]
                                              : Colors.blue[600],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Información de Entrega',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.blue[300]
                                                : Colors.blue[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (entregaActual.ventanaEntregaIni !=
                                            null &&
                                        entregaActual.ventanaEntregaFin != null)
                                      Text(
                                        'Ventana: ${entregaActual.ventanaEntregaIni!.hour.toString().padLeft(2, '0')}:${entregaActual.ventanaEntregaIni!.minute.toString().padLeft(2, '0')} - ${entregaActual.ventanaEntregaFin!.hour.toString().padLeft(2, '0')}:${entregaActual.ventanaEntregaFin!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              'Productos',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (venta.detalles.isNotEmpty)
                              ...venta.detalles.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final detalle = entry.value;
                                final isLast =
                                    idx == venta.detalles.length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.blue[900]
                                                : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${detalle.cantidad % 1 == 0 ? detalle.cantidad.toInt() : detalle.cantidad}x',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detalle.producto?.nombre ??
                                                    'Producto desconocido',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.grey[100]
                                                      : Colors.grey[900],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (detalle.producto
                                                      ?.descripcion !=
                                                  null)
                                                Text(
                                                  'SKU: ${detalle.producto!.descripcion}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDarkMode
                                                        ? Colors.grey[500]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'BS ${detalle.subtotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.grey[100]
                                                    : Colors.grey[900],
                                              ),
                                            ),
                                            Text(
                                              'BS ${detalle.precioUnitario.toStringAsFixed(2)} c/u',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode
                                                    ? Colors.grey[500]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }).toList()
                            else
                              Text(
                                'Sin productos',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (venta.detalles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'BS ${venta.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.grey[100]
                                            : Colors.grey[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 16),
                            // ✅ Botón de confirmación solo en EN_TRANSITO
                            if (venta.estadoLogisticoCodigo == 'EN_TRANSITO')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // ✅ NUEVO: Navegar a la pantalla de confirmación
                                    await ConfirmarVentaEntregadaDialog.show(
                                      context,
                                      entregaActual,
                                      venta,
                                      widget.provider,
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label:
                                      const Text('Confirmar Entrega'),
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
                        ),
                      ),
                    ],
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
                  color:
                      isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BS ${entregaActual.ventas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cantidad de Ventas',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entregaActual.ventas.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                          ),
                        ),
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

  Widget _buildEstadoPagoBadge(String estadoPago) {
    const estadoColores = {
      'PENDIENTE': {
        'color': Color(0xFFef4444),
        'label': 'Pendiente',
        'icon': '⏳',
      },
      'PAGADO': {
        'color': Color(0xFF22c55e),
        'label': 'Pagado',
        'icon': '✓',
      },
      'PARCIAL': {
        'color': Color(0xFFf97316),
        'label': 'Parcial',
        'icon': '⚠',
      },
      'CANCELADO': {
        'color': Color(0xFF6b7280),
        'label': 'Cancelado',
        'icon': '✗',
      },
    };

    final config = estadoColores[estadoPago] ??
        {'color': Colors.grey, 'label': estadoPago, 'icon': '?'};

    return Builder(
      builder: (context) {
        final isDarkMode =
            Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? (config['color'] as Color).withOpacity(0.25)
            : (config['color'] as Color).withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: config['color'] as Color, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config['icon'] as String,
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  config['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: config['color'] as Color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadoLogisticoBadge(Venta venta) {
    Color color = Colors.grey;
    if (venta.estadoLogisticoColor != null) {
      try {
        final hexColor =
            venta.estadoLogisticoColor!.replaceFirst('#', '');
        color = Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        color = Colors.grey;
      }
    }

    return Builder(
      builder: (context) {
        final isDarkMode =
            Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? color.withOpacity(0.25)
            : color.withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                venta.estadoLogisticoIcon ?? '📦',
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  venta.estadoLogistico,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUbicacionBadge(Entrega entrega) {
    final tieneUbicacion =
        (entrega.latitudeDestino != null &&
                entrega.longitudeDestino != null) ||
            (entrega.direccion != null && entrega.direccion!.isNotEmpty);

    return Builder(
      builder: (context) {
        final isDarkMode =
            Theme.of(context).brightness == Brightness.dark;

        final bgColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[900] : Colors.green[100])
            : (isDarkMode ? Colors.red[900] : Colors.red[100]);

        final borderColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[700] : Colors.green[600])
            : (isDarkMode ? Colors.red[700] : Colors.red[600]);

        final textColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[300] : Colors.green[700])
            : (isDarkMode ? Colors.red[300] : Colors.red[700]);

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor!, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tieneUbicacion ? '📍' : '❌',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tieneUbicacion ? 'Ubicación' : 'Sin ubicación',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarConfirmacionVenta(
    BuildContext context,
    bool nuevoEstado,
    Venta venta,
  ) async {
    if (!mounted) return;

    setState(() {
      _cargandoVenta[venta.id] = true;
    });

    try {
      bool exito = false;

      if (nuevoEstado) {
        exito = await widget.provider.confirmarVentaCargada(
          widget.entrega.id,
          venta.id,
        );
      } else {
        exito = await widget.provider.desmarcarVentaCargada(
          widget.entrega.id,
          venta.id,
        );
      }

      if (!mounted) return;

      if (exito) {
        await widget.provider.obtenerEntrega(widget.entrega.id);

        if (!mounted) return;

        if (widget.provider.entregaActual != null) {
          setState(() {
            for (var v in widget.provider.entregaActual!.ventas) {
              _ventasConfirmadas[v.id] =
                  (v.estadoLogisticoCodigo == 'PENDIENTE_ENVIO');
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? 'Venta #${venta.numero} cargada ✓'
                  : 'Venta #${venta.numero} desmarcada ✓',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoVenta[venta.id] = false;
        });
      }
    }
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
                final exito =
                    await widget.provider.confirmarCargoCompleto(
                  widget.entrega.id,
                );

                if (mounted) {
                  if (exito) {
                    await widget.provider.obtenerEntrega(
                        widget.entrega.id);

                    if (mounted &&
                        currentContext.mounted) {
                      ScaffoldMessenger.of(
                              currentContext)
                          .showSnackBar(
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
                    if (mounted &&
                        currentContext.mounted) {
                      ScaffoldMessenger.of(
                              currentContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
                          ),
                          backgroundColor:
                              Colors.red,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (mounted &&
                    currentContext.mounted) {
                  ScaffoldMessenger.of(
                          currentContext)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                          'Error inesperado: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
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
}
