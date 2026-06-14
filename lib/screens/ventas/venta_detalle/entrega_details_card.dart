import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';
import '../../../utils/phone_utils.dart';
import 'historial_intentos_widget.dart';
import 'entrega_info_row_widget.dart';
import 'galeria_imagenes_widget.dart';

class EntregaDetailsCard extends StatelessWidget {
  final bool isLoadingEntrega;
  final Map<String, dynamic>? entregaData;
  final bool isLoadingIntentos;
  final Map<String, dynamic>? historialIntentos;
  final Color Function(String) getEstadoEntregaColor;
  final String Function(dynamic) formatearFecha;
  final String Function(dynamic) formatearTipoNovedad;
  final Function(BuildContext, List<String>, int) mostrarVisorImagenes;

  const EntregaDetailsCard({
    Key? key,
    required this.isLoadingEntrega,
    required this.entregaData,
    required this.isLoadingIntentos,
    required this.historialIntentos,
    required this.getEstadoEntregaColor,
    required this.formatearFecha,
    required this.formatearTipoNovedad,
    required this.mostrarVisorImagenes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoadingEntrega) {
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
                Text('Cargando información de entrega...'),
              ],
            ),
          ),
        ),
      );
    }

    if (entregaData == null) {
      return const SizedBox.shrink();
    }

    // Extraer datos de la entrega
    final entregaId = entregaData?['id'];
    final numeroEntrega = entregaData?['numero_entrega'] ?? 'N/A';
    final estadoEntrega =
        entregaData?['tipo_novedad']?['nombre'] ?? 'Desconocido';
    final estadoColor = getEstadoEntregaColor(
      entregaData?['tipo_novedad']?['codigo'] ?? '',
    );

    // Datos del chofer
    final choferNombre = entregaData?['chofer']?['nombre'] ?? 'Sin asignar';
    final choferTelefono =
        entregaData?['chofer']?['usuario']?['telefono'] ?? '';

    // Datos del vehículo
    final vehiculoPlaca = entregaData?['vehiculo']?['placa'] ?? 'N/A';
    final vehiculoMarca = entregaData?['vehiculo']?['marca'] ?? '';
    final vehiculoModelo = entregaData?['vehiculo']?['modelo'] ?? '';

    // Fechas
    final fechaAsignacion = entregaData?['created_at'];
    final fechaInicio = entregaData?['fecha_inicio'];
    final fechaEntrega = entregaData?['fecha_entrega'];

    // Extraer confirmacionesVentas (última confirmación)
    final confirmacionesVentas = entregaData?['confirmacionesVentas'] as List?;
    final ultimaConfirmacion =
        confirmacionesVentas != null && confirmacionesVentas.isNotEmpty
        ? confirmacionesVentas.last as Map
        : null;
    final tipoEntrega = ultimaConfirmacion?['tipo_entrega'];
    final tipoNovedad = ultimaConfirmacion?['tipo_novedad'];
    final observacionesLogistica =
        ultimaConfirmacion?['observaciones_logistica'];
    final firmaDigitalUrl = ultimaConfirmacion?['firma_digital_url'];
    final productosDevueltos =
        ultimaConfirmacion?['productos_devueltos'] as List? ?? [];
    final montoDevuelto = ultimaConfirmacion?['monto_devuelto'];
    final montoAceptado = ultimaConfirmacion?['monto_aceptado'];

    return Column(
      children: [
        // Título de la sección
        Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: estadoColor, size: 24),
            const SizedBox(width: 12),
            Text('Detalles de Entrega'),
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
                        Text('Entrega #$numeroEntrega'),
                        const SizedBox(height: 4),
                        Text('ID: $entregaId'),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.2),
                        border: Border.all(color: estadoColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estadoEntrega,
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
                EntregaInfoRowWidget(
                  icon: Icons.person_outline,
                  label: 'Chofer',
                  value: choferNombre,
                  secondaryValue: choferTelefono.isNotEmpty
                      ? choferTelefono
                      : null,
                  onSecondaryTap: choferTelefono.isNotEmpty
                      ? () => PhoneUtils.llamarCliente(context, choferTelefono)
                      : null,
                ),
                const SizedBox(height: 12),
                // Sección Vehículo
                EntregaInfoRowWidget(
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
                  EntregaInfoRowWidget(
                    icon: Icons.calendar_today_outlined,
                    label: 'Asignación',
                    value: formatearFecha(fechaAsignacion),
                  ),
                if (fechaInicio != null) ...[
                  const SizedBox(height: 12),
                  EntregaInfoRowWidget(
                    icon: Icons.play_circle_outline,
                    label: 'Inicio',
                    value: formatearFecha(fechaInicio),
                  ),
                ],
                if (fechaEntrega != null) ...[
                  const SizedBox(height: 12),
                  EntregaInfoRowWidget(
                    icon: Icons.check_circle_outline,
                    label: 'Entregado',
                    value: formatearFecha(fechaEntrega),
                  ),
                ],
                // Información de Confirmación
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
                    EntregaInfoRowWidget(
                      icon: tipoEntrega.toString().toUpperCase() == 'COMPLETA'
                          ? Icons.check_circle
                          : Icons.warning_outlined,
                      label: 'Tipo de Entrega',
                      value: tipoEntrega.toString().toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Tipo de Novedad (si aplica)
                  if (tipoNovedad != null &&
                      tipoNovedad.toString().isNotEmpty) ...[
                    EntregaInfoRowWidget(
                      icon: Icons.info_outlined,
                      label: 'Novedad',
                      value: formatearTipoNovedad(tipoNovedad.toString()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Productos Devueltos en DEVOLUCION_PARCIAL
                  if (tipoNovedad?.toString().toUpperCase() ==
                          'DEVOLUCION_PARCIAL' &&
                      productosDevueltos.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📦 Productos Devueltos',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange[900]?.withValues(alpha: 0.2)
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange[200] ?? Colors.orange,
                            ),
                          ),
                          child: Column(
                            children: [
                              ...productosDevueltos.asMap().entries.map((
                                entry,
                              ) {
                                final producto = entry.value as Map?;
                                final index = entry.key;
                                final nombre =
                                    producto?['producto_nombre'] ??
                                    'Producto desconocido';
                                final cantidad = producto?['cantidad'] ?? 0;
                                final precioUnitario =
                                    producto?['precio_unitario'] ?? 0;
                                final subtotal = producto?['subtotal'] ?? 0;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Cantidad: $cantidad'),
                                              Text(
                                                'Unitario: \$${precioUnitario.toStringAsFixed(2)}',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox.shrink(),
                                              Text(
                                                'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                                                style: TextStyle(
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
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]?.withValues(alpha: 0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (montoDevuelto != null)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Devuelto:'),
                                      Text(
                                        '\$${(montoDevuelto is num ? montoDevuelto : 0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (montoAceptado != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Monto Aceptado:'),
                                      Text(
                                        '\$${(montoAceptado is num ? montoAceptado : 0).toStringAsFixed(2)}',
                                        style: TextStyle(
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
                  if (observacionesLogistica != null &&
                      observacionesLogistica.toString().isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📝 Observaciones',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]?.withValues(alpha: 0.3)
                                : Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300] ?? Colors.grey,
                            ),
                          ),
                          child: Text(observacionesLogistica.toString()),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        // Galería de Imágenes de Entrega
        GaleriaImagenesWidget(
          entregaData: entregaData,
          mostrarVisorImagenes: mostrarVisorImagenes,
        ),
        // Historial de Intentos de Entrega
        const SizedBox(height: 24),
        HistorialIntentosWidget(
          isLoading: isLoadingIntentos,
          historialIntentos: historialIntentos,
        ),
      ],
    );
  }
}
