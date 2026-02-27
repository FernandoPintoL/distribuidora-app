import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/entrega.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/chofer/productos_agrupados_widget.dart';
import '../../../../widgets/map_location_selector.dart';
import 'estado_venta_badge.dart';
import 'info_row.dart';

class EntregaCard extends StatefulWidget {
  final Entrega entrega;
  final bool isDarkMode;

  const EntregaCard({Key? key, required this.entrega, required this.isDarkMode})
    : super(key: key);

  @override
  State<EntregaCard> createState() => _EntregaCardState();
}

class _EntregaCardState extends State<EntregaCard> {
  bool _ventasExpandidas = false;
  bool _productosExpandidos = false;

  Entrega get entrega => widget.entrega;
  bool get isDarkMode => widget.isDarkMode;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 4,
      color: cardColor,
      shadowColor: isDarkMode
          ? Colors.black.withAlpha((0.5 * 255).toInt())
          : Colors.grey.withAlpha((0.3 * 255).toInt()),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorEstado(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entrega.tipoWorkIcon,
                            style: const TextStyle(
                              fontSize: 18,
                            ), // TODO: usar AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getTituloTrabajo(entrega),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppTextStyles.bodyLarge(
                                  context,
                                ).fontSize!,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Entrega: ${entrega.numeroEntrega ?? '#${entrega.id}'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entrega.estadoLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entrega.id > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color.fromARGB(
                        255,
                        143,
                        134,
                        129,
                      )?.withAlpha((0.2 * 255).toInt())
                    : Colors.orange[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _productosExpandidos = !_productosExpandidos;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_shipping, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 Productos a Entregar',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.bodySmall(
                                      context,
                                    ).fontSize!,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Ver resumen consolidado',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.labelSmall(
                                      context,
                                    ).fontSize!,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          _productosExpandidos
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  // Productos expandidos
                  if (_productosExpandidos) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    ProductosAgrupadsWidget(
                      entregaId: entrega.id,
                      mostrarDetalleVentas: true,
                    ),
                  ],
                ],
              ),
            ),
          // Ventas asignadas (expandible)
          if (entrega.ventas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color.fromARGB(
                        255,
                        91,
                        94,
                        98,
                      )?.withAlpha((0.3 * 255).toInt())
                    : Colors.blue[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _ventasExpandidas = !_ventasExpandidas;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 ${entrega.ventas.length} venta${entrega.ventas.length > 1 ? 's' : ''} asignada${entrega.ventas.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.bodySmall(
                                      context,
                                    ).fontSize!,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (entrega.ventas.isNotEmpty)
                                  Text(
                                    'Total: BS ${entrega.ventas.fold<double>(0, (sum, v) => sum + v.subtotal).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodySmall(
                                        context,
                                      ).fontSize!,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          _ventasExpandidas
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  // Ventas expandidas
                  if (_ventasExpandidas) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entrega.ventas.length,
                      itemBuilder: (context, index) {
                        final venta = entrega.ventas[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]?.withAlpha(
                                      (0.3 * 255).toInt(),
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado: número, cliente y estado logístico
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      venta.clienteNombre
                                                              ?.toUpperCase() ??
                                                          venta.cliente
                                                              ?.toUpperCase() ??
                                                          'Cliente desconocido',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppTextStyles.bodyMedium(
                                                              context,
                                                            ).fontSize!,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      venta.numero,
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppTextStyles.bodySmall(
                                                              context,
                                                            ).fontSize!,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Estado logístico badge
                                              EstadoVentaBadge(
                                                estadoLogisticoId:
                                                    venta.estadoLogisticoId,
                                                estadoLogisticoCodigo:
                                                    venta.estadoLogistico,
                                                estadoLogisticoColor:
                                                    venta.estadoLogisticoColor,
                                                estadoLogisticoIcon:
                                                    venta.estadoLogisticoIcon,
                                                isDarkMode: isDarkMode,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Fila de montos: Subtotal y Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Subtotal
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize:
                                                  AppTextStyles.labelSmall(
                                                    context,
                                                  ).fontSize!,
                                              color: isDarkMode
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Bs. ${venta.subtotal?.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppTextStyles.labelSmall(
                                                    context,
                                                  ).fontSize!,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.grey[300]
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          // ✅ NUEVO: Localidades de la entrega
          if (entrega.localidades != null &&
              (entrega.localidades!['cantidad_localidades'] as int? ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.amber[900]?.withAlpha((0.2 * 255).toInt())
                    : Colors.amber[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📍 Localidades',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mostrar localidades como chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var localidad
                          in (entrega.localidades!['localidades'] as List? ??
                              []))
                        Chip(
                          label: Text(
                            localidad['nombre'] as String? ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 11,
                            ), // TODO: usar AppTextStyles.labelSmall,
                          ),
                          avatar: CircleAvatar(
                            backgroundColor: Colors.amber[100],
                            radius: 12,
                            child: const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.amber,
                            ),
                          ),
                          backgroundColor: isDarkMode
                              ? Colors.amber[900]!.withValues(alpha: 0.4)
                              : Colors.amber[100],
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Fecha y botones de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fecha asignada
                if (entrega.fechaAsignacion != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entrega.formatFecha(entrega.fechaAsignacion),
                            style: TextStyle(
                              fontSize: AppTextStyles.labelSmall(
                                context,
                              ).fontSize!,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ver Detalles
                    Tooltip(
                      message: 'Ver Detalles',
                      child: IconButton(
                        icon: const Icon(Icons.info_outline),
                        color: Colors.blue,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/chofer/entrega-detalle',
                            arguments: entrega.id,
                          );
                        },
                      ),
                    ),
                    // ✅ Descargar Ticket de Entrega
                    Tooltip(
                      message: 'Descargar Ticket',
                      child: IconButton(
                        icon: const Icon(Icons.print),
                        color: Colors.purple,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _descargarTicket(context),
                      ),
                    ),
                    // Cómo llegar
                    Tooltip(
                      message: 'Ver en mapa',
                      child: IconButton(
                        icon: const Icon(Icons.map),
                        color: Colors.orange,
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _abrirMapaConVentas(context),
                      ),
                    ),
                    // Iniciar Ruta (condicional)
                    if (entrega.puedeIniciarRuta)
                      Tooltip(
                        message: 'Iniciar Ruta',
                        child: IconButton(
                          icon: const Icon(Icons.navigation),
                          color: Colors.green,
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/chofer/iniciar-ruta',
                              arguments: entrega.id,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado() {
    final colorHex = entrega.estadoEntregaColor ?? entrega.estadoColor;

    if (colorHex.isEmpty || !colorHex.startsWith('#')) {
      return Colors.blue;
    }

    try {
      return Color(int.parse('0xff${colorHex.substring(1)}'));
    } catch (e) {
      debugPrint('❌ Error parseando color: $colorHex - $e');
      return Colors.blue;
    }
  }

  String _getTituloTrabajo(Entrega entrega) {
    if (entrega.trabajoType == 'entrega') {
      return 'Entrega #${entrega.id}';
    } else if (entrega.trabajoType == 'envio') {
      return 'Envío #${entrega.id}';
    }
    return 'Entrega #${entrega.id}';
  }

  /// ✅ MEJORADO 2026-02-17: Abrir mapa con todas las ubicaciones de ventas
  /// En lugar de abrir Google Maps, ahora abre MapLocationSelector mostrando
  /// todas las ubicaciones de las ventas que pertenecen a esta entrega
  void _abrirMapaConVentas(BuildContext context) {
    // Extraer ubicaciones de todas las ventas de la entrega
    final ubicaciones = <MapLocation>[];

    if (entrega.ventas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No hay ventas con ubicación en esta entrega'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Crear MapLocation para cada venta con ubicación válida
    for (final venta in entrega.ventas) {
      if (venta.latitud != null && venta.longitud != null) {
        ubicaciones.add(
          MapLocation(
            latitude: venta.latitud!,
            longitude: venta.longitud!,
            title: venta.clienteNombre ?? 'Cliente #${venta.cliente}',
            subtitle: venta.numero,
            isSelected: false,
          ),
        );
      }
    }

    if (ubicaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No hay ventas con ubicación válida en esta entrega'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Abrir mapa con todas las ubicaciones
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationSelector(
          onLocationSelected: (latitude, longitude, address) {
            // No hacer nada, solo visualizar
            Navigator.pop(context);
          },
          additionalLocations:
              ubicaciones, // ✅ NUEVO: Pasar ubicaciones de ventas
        ),
      ),
    );
  }

  /// ✅ NUEVO 2026-02-21: Descargar/Imprimir ticket de entrega
  Future<void> _descargarTicket(BuildContext context) async {
    try {
      // Obtener URL del backend usando ApiService
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl;
      // Nota: baseUrl incluye /api, así que construimos la URL completa
      final ticketUrl =
          '$baseUrl/entregas/${entrega.id}/descargar?formato=TICKET_80&accion=stream';

      // Mostrar snackbar informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📄 Abriendo ticket de entrega...'),
          backgroundColor: Colors.blue[600],
          duration: const Duration(seconds: 2),
        ),
      );

      // Intentar abrir el URL en el navegador
      final Uri uri = Uri.parse(ticketUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ No se puede abrir el navegador'),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
