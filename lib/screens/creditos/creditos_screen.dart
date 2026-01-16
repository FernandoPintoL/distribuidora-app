import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_gradients.dart';
import '../../models/credito.dart';
import '../../extensions/theme_extension.dart';
import '../../widgets/widgets.dart';

/// Pantalla para visualizar créditos del cliente
/// Muestra: Resumen, Cuentas Pendientes, Historial de Pagos
class CreditosScreen extends StatefulWidget {
  const CreditosScreen({super.key});

  @override
  State<CreditosScreen> createState() => _CreditosScreenState();
}

class _CreditosScreenState extends State<CreditosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Datos de ejemplo (en producción, vendrían del provider)
  final Credito _credito = Credito(
    id: 1,
    clienteId: 1,
    limiteCreditoAprobado: 50000,
    saldoDisponible: 15000,
    saldoUtilizado: 35000,
    porcentajeUtilizado: 70,
    cuentasVencidasCount: 1,
    cuentasPendientesCount: 5,
    fechaAprobacion: DateTime(2024, 1, 15),
    fechaUltimaActualizacion: DateTime.now(),
  );

  final List<CuentaPorCobrar> _cuentasPendientes = [
    CuentaPorCobrar(
      id: 1,
      clienteId: 1,
      ventaId: 100,
      montoOriginal: 5000,
      saldoPendiente: 2500,
      diasVencido: 5,
      fechaVencimiento: DateTime.now().subtract(const Duration(days: 5)),
      estado: 'vencida',
      clienteNombre: 'Cliente A',
      ventaNumero: 'V-001',
      pagos: [
        Pago(
          id: 1,
          cuentaPorCobrarId: 1,
          monto: 2500,
          tipoPago: 'efectivo',
          numeroRecibo: 'REC-001',
          fechaPago: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    ),
    CuentaPorCobrar(
      id: 2,
      clienteId: 1,
      ventaId: 101,
      montoOriginal: 8000,
      saldoPendiente: 8000,
      diasVencido: 0,
      fechaVencimiento: DateTime.now().add(const Duration(days: 10)),
      estado: 'pendiente',
      clienteNombre: 'Cliente A',
      ventaNumero: 'V-002',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mis Créditos',
        customGradient: AppGradients.blue,
      ),
      body: Column(
        children: [
          // ✅ Card de resumen de crédito
          _buildCreditoResumenCard(),

          // TabBar
          Container(
            color: Colors.grey[50],
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                const Tab(text: 'Resumen', icon: Icon(Icons.description)),
                const Tab(
                  text: 'Pendientes',
                  icon: Icon(Icons.pending_actions),
                ),
                const Tab(text: 'Pagos', icon: Icon(Icons.receipt_long)),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabResumen(),
                _buildTabPendientes(),
                _buildTabPagos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de resumen de crédito
  Widget _buildCreditoResumenCard() {
    final porcentajeUtilizado = _credito.porcentajeUtilizado;
    final estado = _credito.estado;
    final colorEstado = Color(_credito.colorEstado);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorEstado.withOpacity(0.1), colorEstado.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorEstado.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crédito Total',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de información
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildCreditsummaryItem(
                'Límite Aprobado',
                'Bs. ${_credito.limiteCreditoAprobado.toStringAsFixed(2)}',
                Icons.account_balance,
              ),
              _buildCreditsummaryItem(
                'Utilizado',
                'Bs. ${_credito.saldoUtilizado.toStringAsFixed(2)}',
                Icons.trending_up,
              ),
              _buildCreditsummaryItem(
                'Disponible',
                'Bs. ${_credito.saldoDisponible.toStringAsFixed(2)}',
                Icons.check_circle,
              ),
              _buildCreditsummaryItem(
                'Utilización',
                '${porcentajeUtilizado.toStringAsFixed(0)}%',
                Icons.percent,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Porcentaje de Utilización',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  Text(
                    '${porcentajeUtilizado.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: porcentajeUtilizado / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de resumen
  Widget _buildCreditsummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Tab: Resumen
  Widget _buildTabResumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información importante
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este es tu crédito disponible. Úsalo con responsabilidad.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estadísticas
          Text(
            'Estadísticas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildStatItem(
            'Cuentas Pendientes',
            _credito.cuentasPendientesCount.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            'Cuentas Vencidas',
            _credito.cuentasVencidasCount.toString(),
            Icons.warning,
            Colors.red,
          ),
          const SizedBox(height: 20),

          // Fechas importantes
          Text(
            'Fechas Importantes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildDateInfo(
                  'Crédito Aprobado',
                  DateFormat('dd/MM/yyyy').format(_credito.fechaAprobacion),
                ),
                const Divider(),
                _buildDateInfo(
                  'Última Actualización',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(_credito.fechaUltimaActualizacion ?? DateTime.now()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab: Cuentas Pendientes
  Widget _buildTabPendientes() {
    if (_cuentasPendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              '¡No tienes cuentas pendientes!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Todas tus deudas están al día',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cuentasPendientes.length,
      itemBuilder: (context, index) {
        final cuenta = _cuentasPendientes[index];
        return _buildCuentaCard(cuenta);
      },
    );
  }

  /// Tab: Historial de Pagos
  Widget _buildTabPagos() {
    final todosPagos = _cuentasPendientes
        .expand((c) => c.pagos ?? [])
        .toList()
        .cast<Pago>();

    if (todosPagos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin pagos registrados',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todosPagos.length,
      itemBuilder: (context, index) {
        final pago = todosPagos[index];
        return _buildPagoCard(pago);
      },
    );
  }

  /// Card de cuenta por cobrar
  Widget _buildCuentaCard(CuentaPorCobrar cuenta) {
    final estaVencida = cuenta.estaVencida;
    final colorVencimiento = estaVencida ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta ${cuenta.ventaNumero ?? '#${cuenta.ventaId}'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (cuenta.clienteNombre != null)
                      Text(
                        cuenta.clienteNombre!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorVencimiento.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    estaVencida ? 'VENCIDA' : 'PENDIENTE',
                    style: TextStyle(
                      color: colorVencimiento,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Detalles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto Original',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      'Bs. ${cuenta.montoOriginal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Pendiente',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      'Bs. ${cuenta.saldoPendiente.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagado',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '${cuenta.porcentajePagado.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cuenta.porcentajePagado / 100,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 8),

            // Fecha
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Vence: ${DateFormat('dd/MM/yyyy').format(cuenta.fechaVencimiento)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (estaVencida) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Vencido hace ${cuenta.diasVencido} días',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de pago
  Widget _buildPagoCard(Pago pago) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bs. ${pago.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${pago.tipoPago.toUpperCase()} • ${pago.numeroRecibo ?? 'Sin recibo'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(pago.fechaPago),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (pago.usuarioNombre != null)
              Text(
                pago.usuarioNombre!,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  /// Item de estadística
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Información de fecha
  Widget _buildDateInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
