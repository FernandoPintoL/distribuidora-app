import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../extensions/theme_extension.dart';

/// Pantalla de detalle de una Cuenta por Cobrar
class CuentaPorCobrarDetalleScreen extends StatefulWidget {
  final int cuentaId;

  const CuentaPorCobrarDetalleScreen({super.key, required this.cuentaId});

  @override
  State<CuentaPorCobrarDetalleScreen> createState() =>
      _CuentaPorCobrarDetalleScreenState();
}

class _CuentaPorCobrarDetalleScreenState
    extends State<CuentaPorCobrarDetalleScreen> {
  late CuentaPorCobrarDetalleProvider _provider;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<CuentaPorCobrarDetalleProvider>();
      _provider.loadCuentaDetalle(widget.cuentaId);
    });
  }

  @override
  void dispose() {
    _provider.limpiar();
    super.dispose();
  }

  Color _getColorForCxCEstado(String? estado) {
    if (estado == null) return Colors.grey;
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACTIVO':
        return Colors.blue;
      case 'PARCIAL':
        return Colors.purple;
      case 'PAGADO':
        return Colors.green;
      case 'ANULADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Consumer<CuentaPorCobrarDetalleProvider>(
      builder: (context, provider, _) {
        final cuenta = provider.cuenta;
        final estadoColor = _getColorForCxCEstado(cuenta?.estado);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuenta por Cobrar #${widget.cuentaId}'),
                if (cuenta != null)
                  Text(
                    cuenta.estado.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            backgroundColor: estadoColor.withOpacity(0.85),
            elevation: 0,
          ),
          body: Consumer<CuentaPorCobrarDetalleProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null || provider.cuenta == null) {
                return _buildErrorState(provider);
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCuentaHeader(provider.cuenta!),
                    const SizedBox(height: 16),
                    _buildCuentaInfo(provider.cuenta!),
                    const SizedBox(height: 16),
                    _buildPagosSection(provider.pagos),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCuentaHeader(CuentaPorCobrar cuenta) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Folio CxC: #${cuenta.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (cuenta.referenciaDocumento != null)
                    Text(
                      cuenta.referenciaDocumento ?? 'Sin referencia',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  if (cuenta.venta != null)
                    Text('Venta Folio #${cuenta.venta!.id}'),
                  if (cuenta.cliente != null)
                    Text(
                      cuenta.cliente!.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              _buildEstadoBadge(cuenta),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monto Original',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                  Text(
                    'Bs. ${cuenta.montoOriginal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pagado',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Bs. ${cuenta.montoPagado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Bs. ${cuenta.saldoPendiente.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cuenta.saldoPendiente > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCuentaInfo(CuentaPorCobrar cuenta) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Vencimiento',
            cuenta.fechaVencimiento != null
                ? DateFormat('dd/MMM/yyyy').format(cuenta.fechaVencimiento!)
                : 'N/A',
          ),
          if (cuenta.diasVencido != null && cuenta.diasVencido! > 0)
            _buildInfoRow(
              'Vencida hace',
              '${cuenta.diasVencido} días',
              color: Colors.red,
            ),
          _buildInfoRow(
            'Porcentaje Pagado',
            '${cuenta.porcentajePagado.toStringAsFixed(1)}%',
          ),
          if (cuenta.observaciones != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observaciones',
                    style: TextStyle(
                      color: context.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cuenta.observaciones!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colorScheme.secondary)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(CuentaPorCobrar cuenta) {
    Color badgeColor;
    IconData badgeIcon;

    switch (cuenta.estado.toUpperCase()) {
      case 'PAGADO':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'ANULADO':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        break;
      case 'PARCIAL':
        badgeColor = Colors.orange;
        badgeIcon = Icons.schedule;
        break;
      case 'PENDIENTE':
      default:
        badgeColor = Colors.amber;
        badgeIcon = Icons.pending_actions;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            cuenta.estado.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagosSection(List<Pago> pagos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagos Registrados (${pagos.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pagos.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: context.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin pagos registrados',
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagos.length,
              itemBuilder: (context, index) {
                final pago = pagos[index];
                return _buildPagoCard(pago);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPagoCard(Pago pago) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago #${pago.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (pago.fechaPago != null)
                      Text(
                        DateFormat('dd/MMM/yyyy').format(pago.fechaPago!),
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                Text(
                  'Bs. ${pago.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pago.tipoPagoNombre != null || pago.numeroRecibo != null)
              Row(
                children: [
                  if (pago.tipoPagoNombre != null)
                    Expanded(
                      child: Text(
                        'Tipo: ${pago.tipoPagoNombre}',
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (pago.numeroRecibo != null)
                    Expanded(
                      child: Text(
                        'Recibo: ${pago.numeroRecibo}',
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            if (pago.observaciones != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nota: ${pago.observaciones}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CuentaPorCobrarDetalleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error al cargar', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Ocurrió un error inesperado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              provider.loadCuentaDetalle(widget.cuentaId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
