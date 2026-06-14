import 'package:flutter/material.dart';
import '../../../config/app_text_styles.dart';

class HistorialIntentosWidget extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? historialIntentos;

  const HistorialIntentosWidget({
    Key? key,
    required this.isLoading,
    required this.historialIntentos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final confirmaciones = historialIntentos?['confirmaciones'] as List? ?? [];
    if (confirmaciones.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalConfirmaciones = confirmaciones.length;
    final resumen =
        historialIntentos?['resumen'] as Map<String, dynamic>? ?? {};
    final intentosExitosos = resumen['intentos_exitosos'] ?? 0;
    final intentosRechazados = resumen['intentos_rechazados'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 HISTORIAL DE INTENTOS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$totalConfirmaciones intentos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            // Estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('✅'),
                    const SizedBox(height: 4),
                    Text('Exitosos', style: TextStyle(color: Colors.grey)),
                    Text(
                      '$intentosExitosos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('❌'),
                    const SizedBox(height: 4),
                    Text('Rechazados', style: TextStyle(color: Colors.grey)),
                    Text(
                      '$intentosRechazados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Lista de intentos
            ...List.generate(confirmaciones.length, (index) {
              final confirmacion =
                  confirmaciones[index] as Map<String, dynamic>;
              final numeroIntento =
                  confirmacion['numero_intento'] ?? (index + 1);
              final estado = confirmacion['estado'] ?? 'DESCONOCIDO';
              final hace = confirmacion['hace'] ?? '';

              // Color según estado
              Color estadoColor = Colors.grey;
              String estadoIcon = '⏳';
              if (estado == 'PAGADO') {
                estadoColor = Colors.green;
                estadoIcon = '✅';
              } else if (estado == 'RECHAZADO') {
                estadoColor = Colors.red;
                estadoIcon = '❌';
              } else if (estado == 'PARCIAL') {
                estadoColor = Colors.orange;
                estadoIcon = '⚠️';
              }

              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _mostrarDetalleIntento(context, confirmacion),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]?.withValues(alpha: 0.3)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: estadoColor.withValues(alpha: 0.3),
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
                                      '$estadoIcon Intento #$numeroIntento',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estadoColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        estado,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: estadoColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hace,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: estadoColor),
                        ],
                      ),
                    ),
                  ),
                  if (index < confirmaciones.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleIntento(
    BuildContext context,
    Map<String, dynamic> confirmacion,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DetalleIntentoModal(confirmacion: confirmacion);
      },
    );
  }
}

class _DetalleIntentoModal extends StatelessWidget {
  final Map<String, dynamic> confirmacion;

  const _DetalleIntentoModal({required this.confirmacion});

  @override
  Widget build(BuildContext context) {
    final numeroIntento = confirmacion['numero_intento'] ?? 0;
    final estado = confirmacion['estado'] ?? 'DESCONOCIDO';
    final tipoConfirmacion = confirmacion['tipo_confirmacion'] ?? 'DESCONOCIDO';
    final tipoNovedad = confirmacion['tipo_novedad'];
    final motivoRechazo = confirmacion['motivo_rechazo'];
    final observacionesLogistica = confirmacion['observaciones_logistica'];
    final clientePresente = confirmacion['cliente_presente'] ?? false;
    final tiendaAbierta = confirmacion['tienda_abierta'] ?? false;
    final montoAceptado = confirmacion['monto_aceptado'] ?? 0;
    final montoDevuelto = confirmacion['monto_devuelto'] ?? 0;
    final pagos = confirmacion['pagos'] as Map<String, dynamic>? ?? {};
    final confirmadoEn = confirmacion['confirmado_en'] ?? '';
    final entrega = confirmacion['entrega'] as Map<String, dynamic>? ?? {};

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Intento #$numeroIntento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              // Estado
              _buildDetalleRow(
                context,
                label: 'Estado',
                value: estado,
                valueColor: estado == 'PAGADO'
                    ? Colors.green
                    : estado == 'RECHAZADO'
                    ? Colors.red
                    : Colors.orange,
              ),
              const SizedBox(height: 12),
              // Tipo de Confirmación
              _buildDetalleRow(
                context,
                label: 'Tipo de Confirmación',
                value: tipoConfirmacion,
              ),
              const SizedBox(height: 12),
              // Si fue rechazado, mostrar motivo
              if (tipoNovedad != null) ...[
                _buildDetalleRow(
                  context,
                  label: 'Tipo de Novedad',
                  value: _formatearTipoNovedad(tipoNovedad),
                ),
                const SizedBox(height: 12),
              ],
              if (motivoRechazo != null) ...[
                _buildDetalleRow(
                  context,
                  label: 'Motivo de Rechazo',
                  value: motivoRechazo,
                ),
                const SizedBox(height: 12),
              ],
              // Detalles de Entrega
              if (entrega.isNotEmpty) ...[
                Text(
                  '🚚 Detalles de Entrega',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetalleRow(
                  context,
                  label: 'Entrega',
                  value: entrega['numero_entrega'] ?? 'N/A',
                ),
                const SizedBox(height: 8),
                if (entrega['chofer'] != null) ...[
                  _buildDetalleRow(
                    context,
                    label: 'Chofer',
                    value: entrega['chofer']['nombre'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              // Detalles de Pagos
              if (pagos.isNotEmpty) ...[
                Text(
                  '💰 Detalles de Pagos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (pagos['efectivo'] != null)
                  _buildDetalleRow(
                    context,
                    label: 'Efectivo',
                    value: 'Bs. ${pagos['efectivo'].toString()}',
                  ),
                if (pagos['qr'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetalleRow(
                    context,
                    label: 'QR/Transferencia',
                    value: 'Bs. ${pagos['qr'].toString()}',
                  ),
                ],
                if (pagos['total_recibido'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetalleRow(
                    context,
                    label: 'Total Recibido',
                    value: 'Bs. ${pagos['total_recibido'].toString()}',
                    valueColor: Colors.green,
                  ),
                ],
                if (pagos['pendiente'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetalleRow(
                    context,
                    label: 'Pendiente',
                    value: 'Bs. ${pagos['pendiente'].toString()}',
                    valueColor: pagos['pendiente'] != 0 ? Colors.red : null,
                  ),
                ],
                const SizedBox(height: 12),
              ],
              // Montos
              if (montoAceptado != 0 || montoDevuelto != 0) ...[
                Text(
                  '📊 Montos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (montoAceptado != 0)
                  _buildDetalleRow(
                    context,
                    label: 'Monto Aceptado',
                    value: 'Bs. ${montoAceptado.toString()}',
                  ),
                if (montoDevuelto != 0) ...[
                  const SizedBox(height: 8),
                  _buildDetalleRow(
                    context,
                    label: 'Monto Devuelto',
                    value: 'Bs. ${montoDevuelto.toString()}',
                  ),
                ],
                const SizedBox(height: 12),
              ],
              // Observaciones
              if (observacionesLogistica != null &&
                  observacionesLogistica.toString().isNotEmpty) ...[
                Text(
                  '📝 Observaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]?.withValues(alpha: 0.3)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    observacionesLogistica.toString(),
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Fecha de Confirmación
              if (confirmadoEn.isNotEmpty) ...[
                _buildDetalleRow(
                  context,
                  label: 'Confirmado en',
                  value: confirmadoEn,
                ),
                const SizedBox(height: 12),
              ],
              // Clientes presentes y tienda abierta
              if (clientePresente || tiendaAbierta) ...[
                Text(
                  '✓ Verificaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (clientePresente)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Cliente presente'),
                    ],
                  ),
                if (tiendaAbierta) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Tienda abierta'),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    );
  }

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
}
