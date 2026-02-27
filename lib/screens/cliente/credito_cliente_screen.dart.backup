import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../config/config.dart';

class CreditoClienteScreen extends StatefulWidget {
  final int clienteId;
  final String clienteNombre;

  const CreditoClienteScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  State<CreditoClienteScreen> createState() => _CreditoClienteScreenState();
}

class _CreditoClienteScreenState extends State<CreditoClienteScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCreditoDetails();
    });
  }

  void _loadCreditoDetails() {
    context.read<ClienteCreditoProvider>().cargarDetallesCreditoCliente(
          widget.clienteId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Crédito'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.teal),
        ),
      ),
      body: Consumer<ClienteCreditoProvider>(
        builder: (context, creditoProvider, child) {
          if (creditoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (creditoProvider.tieneError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar crédito',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    creditoProvider.errorMessage ?? 'Error desconocido',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadCreditoDetails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final credito = creditoProvider.detallesCreditoCliente;
          if (credito == null) {
            return const Center(
              child: Text('Sin datos de crédito'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadCreditoDetails();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(gradient: AppGradients.teal),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen de Crédito',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.clienteNombre,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta principal de crédito
                        _buildCreditoMainCard(credito),
                        const SizedBox(height: 24),

                        // Cuentas vencidas
                        if (credito.cuentasVencidas.isNotEmpty) ...[
                          _buildCuentasVencidasSection(credito),
                          const SizedBox(height: 24),
                        ],

                        // Cuentas pendientes
                        if (credito.cuentasPendientes.isNotEmpty) ...[
                          _buildCuentasPendientesSection(credito),
                          const SizedBox(height: 24),
                        ],

                        // Historial de pagos
                        if (credito.historialPagos.isNotEmpty) ...[
                          _buildHistorialPagosSection(credito),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditoMainCard(DetallesCreditoCliente credito) {
    final porcentajeDecimal = credito.porcentajeUtilizacion / 100;
    Color progressColor = Colors.green;
    if (porcentajeDecimal >= 0.8) {
      progressColor = Colors.red;
    } else if (porcentajeDecimal >= 0.6) {
      progressColor = Colors.orange;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Límite de crédito
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Límite de Crédito',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Bs. ${credito.limiteCredito.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: porcentajeDecimal.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),

            // Estadísticas en fila
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCreditoStat(
                  'Utilizado',
                  'Bs. ${credito.saldoUtilizado.toStringAsFixed(2)}',
                  Colors.orange,
                ),
                _buildCreditoStat(
                  'Disponible',
                  'Bs. ${credito.saldoDisponible.toStringAsFixed(2)}',
                  Colors.green,
                ),
                _buildCreditoStat(
                  'Porcentaje',
                  '${credito.porcentajeUtilizacion.toStringAsFixed(1)}%',
                  progressColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditoStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCuentasVencidasSection(DetallesCreditoCliente credito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cuentas Vencidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${credito.cuentasVencidas.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: credito.cuentasVencidas.length,
          itemBuilder: (context, index) {
            final cuenta = credito.cuentasVencidas[index];
            return _buildCuentaCard(cuenta, isVencida: true);
          },
        ),
      ],
    );
  }

  Widget _buildCuentasPendientesSection(DetallesCreditoCliente credito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cuentas Pendientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${credito.cuentasPendientes.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: credito.cuentasPendientes.length,
          itemBuilder: (context, index) {
            final cuenta = credito.cuentasPendientes[index];
            return _buildCuentaCard(cuenta, isVencida: false);
          },
        ),
      ],
    );
  }

  Widget _buildCuentaCard(CuentaPorCobrar cuenta, {required bool isVencida}) {
    final backgroundColor =
        isVencida ? Colors.red.withOpacity(0.05) : Colors.blue.withOpacity(0.05);
    final borderColor =
        isVencida ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2);
    final statusColor = isVencida ? Colors.red : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cuenta.venta?.numero != null)
                      Text(
                        'Venta #${cuenta.venta!.numero}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (cuenta.fechaVencimiento != null)
                      Text(
                        'Vence: ${cuenta.fechaVencimiento}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bs. ${cuenta.saldoPendiente.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (isVencida && cuenta.diasVencido != null)
                    Text(
                      '${cuenta.diasVencido} días vencido',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (cuenta.montoOriginal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monto Original: Bs. ${cuenta.montoOriginal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Pagado: Bs. ${(cuenta.montoOriginal - cuenta.saldoPendiente).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorialPagosSection(DetallesCreditoCliente credito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historial de Pagos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${credito.historialPagos.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: credito.historialPagos.length,
          itemBuilder: (context, index) {
            final pago = credito.historialPagos[index];
            return _buildPagoCard(pago);
          },
        ),
      ],
    );
  }

  Widget _buildPagoCard(Pago pago) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pago.tipoPago?.nombre != null)
                  Text(
                    pago.tipoPago!.nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (pago.fechaPago != null)
                  Text(
                    'Fecha: ${pago.fechaPago}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (pago.numeroRecibo != null)
                  Text(
                    'Recibo: ${pago.numeroRecibo}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Bs. ${pago.monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
