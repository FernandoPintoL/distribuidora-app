import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart';
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (esModoCarga) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$ventasConfirmadas/$totalVentas cargadas ($porcentaje%)',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
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
                        fontSize: AppTextStyles.labelSmall(context).fontSize!,
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

                final isEnRuta = venta.estadoLogisticoCodigo == 'EN_RUTA';
                final borderColor = isEnRuta
                    ? (isDarkMode ? Colors.green[600]! : Colors.green[200]!)
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!);
                final borderWidth = isEnRuta ? 2.0 : 1.0;

                return InkWell(
                  onTap: () {
                    // Navegar a la pantalla de detalle de venta
                    Navigator.of(
                      context,
                    ).pushNamed('/venta-detalle', arguments: venta.id);
                  },
                  child: Card(
                    // margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: isEnRuta ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: borderColor, width: borderWidth),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (esModoCarga)
                                if (cargando)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[400],
                                    size: 20,
                                  ),
                              const SizedBox(width: 12),
                              // ✅ NUEVO 2026-03-05: Mostrar estado_entrega dinámicamente
                              if (entregaActual.estadoEntregaCodigo != null)
                                _buildEstadoEntregaBadge(entregaActual),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ✅ DASHBOARD DESIGN: Encabezado (VEN# | Cliente | Monto)
                          _buildVentaEncabezado(venta),
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          // ✅ DASHBOARD DESIGN: Información (Localidad | Teléfono | Estado)
                          _buildVentaInformacion(venta),
                          const SizedBox(height: 4),
                          // ✅ DASHBOARD DESIGN: Detalles (Fotos | Pagos | Devueltas)
                          _buildVentaDetalles(venta),
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              /* Expanded(
                                child: _buildUbicacionBadge(entregaActual),
                              ),
                              const SizedBox(width: 8), */
                              if (venta.clienteTelefono != null &&
                                  venta.clienteTelefono!.isNotEmpty) ...[
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
                                    onPressed: () => widget.onEnviarWhatsApp(
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
                        Text(
                          'Total a Entregar',
                          style: TextStyle(
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
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
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
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
                            fontSize: AppTextStyles.bodySmall(
                              context,
                            ).fontSize!,
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
                            fontSize: AppTextStyles.bodyLarge(
                              context,
                            ).fontSize!,
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
      'PAGADO': {'color': Color(0xFF22c55e), 'label': 'Pagado', 'icon': '✓'},
      'PARCIAL': {'color': Color(0xFFf97316), 'label': 'Parcial', 'icon': '⚠'},
      'CANCELADO': {
        'color': Color(0xFF6b7280),
        'label': 'Cancelado',
        'icon': '✗',
      },
    };

    final config =
        estadoColores[estadoPago] ??
        {'color': Colors.grey, 'label': estadoPago, 'icon': '?'};

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? (config['color'] as Color).withOpacity(0.25)
            : (config['color'] as Color).withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: config['color'] as Color, width: 0.5),
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

  // ✅ NUEVO: Widget para mostrar el tipo de pago de la venta
  Widget _buildTipoPagoBadge(String? tipoPago) {
    if (tipoPago == null || tipoPago.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mapeo de tipos de pago con colores e iconos
    const tipoPagoColores = {
      'Efectivo': {
        'color': Color(0xFF10b981), // Verde
        'label': 'Efectivo',
        'icon': '💵',
      },
      'Transferencia': {
        'color': Color(0xFF3b82f6), // Azul
        'label': 'Transferencia',
        'icon': '💳',
      },
      'Transferencia / QR': {
        'color': Color(0xFF3b82f6), // Azul
        'label': 'Transfer.',
        'icon': '📱',
      },
      'Cheque': {
        'color': Color(0xFF8b5cf6), // Púrpura
        'label': 'Cheque',
        'icon': '📄',
      },
      'Crédito': {
        'color': Color(0xFFf59e0b), // Ámbar
        'label': 'Crédito',
        'icon': '📋',
      },
    };

    final config =
        tipoPagoColores[tipoPago] ??
        {
          'color': Colors.blueGrey,
          'label': tipoPago.length > 10 ? tipoPago.substring(0, 10) : tipoPago,
          'icon': '💰',
        };

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? (config['color'] as Color).withOpacity(0.25)
            : (config['color'] as Color).withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: config['color'] as Color, width: 0.5),
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
        final hexColor = venta.estadoLogisticoColor!.replaceFirst('#', '');
        color = Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        color = Colors.grey;
      }
    }

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        (entrega.latitudeDestino != null && entrega.longitudeDestino != null) ||
        (entrega.direccion != null && entrega.direccion!.isNotEmpty);

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                style: const TextStyle(
                  fontSize: 10,
                ), // TODO: usar AppTextStyles.labelSmall,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tieneUbicacion ? 'Ubicación' : 'Sin ubicación',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: AppTextStyles.labelSmall(context).fontSize!,
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

  Widget _buildTipoEntregaBadge(String? tipoEntrega, String? tipoNovedad) {
    if (tipoEntrega == null) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final esCompleta = tipoEntrega == 'COMPLETA';

    // Si es CON_NOVEDAD, usar tipoNovedad en la etiqueta
    final etiqueta = esCompleta
        ? '✅ Completa'
        : '⚠️ ${tipoNovedad ?? 'Novedad'}';
    final color = esCompleta
        ? (isDarkMode ? Colors.green[400] : Colors.green[600])
        : (isDarkMode ? Colors.orange[400] : Colors.orange[600]);
    final bgColor = esCompleta
        ? (isDarkMode ? Colors.green[900] : Colors.green[50])
        : (isDarkMode ? Colors.orange[900] : Colors.orange[50]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color ?? Colors.grey, width: 0.5),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ✅ NUEVO 2026-03-05: Badge para mostrar info de confirmaciones
  Widget _buildConfirmacionesBadges(List<Map<String, dynamic>> confirmaciones) {
    if (confirmaciones.isEmpty) {
      return const SizedBox.shrink();
    }

    final confirmacion = confirmaciones.first; // Usar la primera confirmación
    final tieneFotos = (confirmacion['fotos'] as List?)?.isNotEmpty ?? false;
    final tieneDesglose =
        (confirmacion['desglose_pagos'] as List?)?.isNotEmpty ?? false;
    final tieneProductosDevueltos =
        (confirmacion['productos_devueltos'] as List?)?.isNotEmpty ?? false;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        if (tieneFotos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color:
                    (isDarkMode ? Colors.blue[400] : Colors.blue[600]) ??
                    Colors.blue,
                width: 0.5,
              ),
            ),
            child: Text(
              '📷 ${(confirmacion['fotos'] as List?)?.length ?? 0}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
              ),
            ),
          ),
        if (tieneDesglose)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.purple[900] : Colors.purple[50],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color:
                    (isDarkMode ? Colors.purple[400] : Colors.purple[600]) ??
                    Colors.purple,
                width: 0.5,
              ),
            ),
            child: Text(
              '💳 ${(confirmacion['desglose_pagos'] as List?)?.length ?? 0}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.purple[300] : Colors.purple[700],
              ),
            ),
          ),
        if (tieneProductosDevueltos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.red[900] : Colors.red[50],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color:
                    (isDarkMode ? Colors.red[400] : Colors.red[600]) ??
                    Colors.red,
                width: 0.5,
              ),
            ),
            child: Text(
              '↩️ ${(confirmacion['productos_devueltos'] as List?)?.length ?? 0}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.red[300] : Colors.red[700],
              ),
            ),
          ),
      ],
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
                'Venta Folio #${venta.id}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                ),
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
                Text('📍', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.clienteLocalidadObj?.nombre ?? 'Ubicación',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
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
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        /*if (venta.clienteTelefono != null && venta.clienteTelefono!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📱', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text(
                venta.clienteTelefono!,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ],
          ),*/
        // ✅ NUEVO 2026-03-05: Mostrar tipo de entrega (solo COMPLETA o CON_NOVEDAD)
        if (venta.tipoEntrega == 'COMPLETA' || venta.tipoEntrega == 'CON_NOVEDAD')
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                venta.tipoEntrega == 'COMPLETA' ? '✅' : '⚠️',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 2),
              Text(
                venta.tipoEntrega == 'COMPLETA' ? 'Completa' : 'Con Novedad',
                style: TextStyle(
                  fontSize: 12,
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
              Text('📋', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text(
                _obtenerNombreTipoNovedad(venta.tipoNovedad),
                style: TextStyle(
                  fontSize: 12,
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
              Text(
                'Fotos:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              Text(
                '📷 ${(confirmacion['fotos'] as List?)?.length ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.blue[600]),
              ),
            ],
          ),
        if (tieneDesglose)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pagos:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              Text(
                '💳 ${(confirmacion['desglose_pagos'] as List?)?.length ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.purple[600]),
              ),
            ],
          ),
        if (tieneProductosDevueltos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Devueltas:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              Text(
                '↩️ ${(confirmacion['productos_devueltos'] as List?)?.length ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
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
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar icono emoji si existe
          if (icono != null && icono.isNotEmpty)
            Text(
              icono,
              style: const TextStyle(fontSize: 12),
            )
          else
            Icon(
              Icons.local_shipping,
              size: 12,
              color: badgeColor,
            ),
          const SizedBox(width: 4),
          Text(
            nombre,
            style: TextStyle(
              fontSize: AppTextStyles.labelSmall(context).fontSize!,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
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
