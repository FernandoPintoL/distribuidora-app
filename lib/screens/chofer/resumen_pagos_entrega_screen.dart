import 'package:flutter/material.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';
import '../../services/entrega_service.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class ResumenPagosEntregaScreen extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;

  const ResumenPagosEntregaScreen({
    Key? key,
    required this.entrega,
    required this.provider,
  }) : super(key: key);

  @override
  State<ResumenPagosEntregaScreen> createState() =>
      _ResumenPagosEntregaScreenState();
}

class _ResumenPagosEntregaScreenState extends State<ResumenPagosEntregaScreen> {
  final EntregaService _entregaService = EntregaService();
  late Future<Map<String, dynamic>?> _resumenFuture;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  void _cargarResumen() {
    _resumenFuture = _obtenerResumen();
  }

  Future<Map<String, dynamic>?> _obtenerResumen() async {
    final response = await _entregaService.obtenerResumenPagos(widget.entrega.id);
    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Resumen de Pagos - Entrega #${widget.entrega.id}',
        customGradient: AppGradients.green,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _resumenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDarkMode ? Colors.red[400] : Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar resumen',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _cargarResumen());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final resumen = snapshot.data!;
          return _buildResumen(resumen, isDarkMode);
        },
      ),
    );
  }

  Widget _buildResumen(Map<String, dynamic> resumen, bool isDarkMode) {
    final totalEsperado = resumen['total_esperado'] as num? ?? 0;
    final totalRecibido = resumen['total_recibido'] as num? ?? 0;
    final diferencia = resumen['diferencia'] as num? ?? 0;
    final porcentajeRecibido = resumen['porcentaje_recibido'] as num? ?? 0;
    final pagos = (resumen['pagos'] as List?) ?? [];
    final sinRegistrar = (resumen['sin_registrar'] as List?) ?? [];

    final diferenciaNegativa = diferencia < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TARJETA RESUMEN PRINCIPAL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[400]!,
                  Colors.green[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Entrega #${widget.entrega.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Esperado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs. ${totalEsperado.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Recibido',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs. ${totalRecibido.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalEsperado > 0 ? (totalRecibido / totalEsperado).toDouble() : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    diferenciaNegativa ? Colors.orange : Colors.lightGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance: ${porcentajeRecibido.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      diferenciaNegativa
                          ? 'Falta: Bs. ${diferencia.abs().toStringAsFixed(2)}'
                          : 'Completo ✅',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✅ SECCIÓN DE PAGOS POR TIPO
          Text(
            'Pagos Registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          if (pagos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No hay pagos registrados',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...pagos.map((pago) {
              final tipoPago = pago['tipo_pago'] as String;
              final tipoPagoCodigo = pago['tipo_pago_codigo'] as String;
              final totalPago = pago['total'] as num;
              final cantidadVentas = pago['cantidad_ventas'] as num;
              final ventas = pago['ventas'] as List;

              final iconoPago = _obtenerIconoPago(tipoPagoCodigo);
              final colorPago = _obtenerColorPago(tipoPagoCodigo);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPagoCard(
                  icono: iconoPago,
                  color: colorPago,
                  tipo: tipoPago,
                  total: totalPago.toDouble(),
                  cantidad: cantidadVentas.toInt(),
                  ventas: ventas,
                  isDarkMode: isDarkMode,
                ),
              );
            }).toList(),

          const SizedBox(height: 24),

          // ✅ SECCIÓN DE VENTAS SIN PAGO REGISTRADO
          if (sinRegistrar.isNotEmpty) ...[
            Text(
              'Ventas Sin Pago Registrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.orange[900]?.withOpacity(0.2) : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.orange[700]! : Colors.orange[200]!,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sinRegistrar.length,
                separatorBuilder: (_, __) => Divider(
                  color: isDarkMode ? Colors.orange[700] : Colors.orange[200],
                  height: 1,
                ),
                itemBuilder: (_, index) {
                  final venta = sinRegistrar[index];
                  final ventaNumero = venta['venta_numero'] as String;
                  final monto = venta['monto'] as num;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta $ventaNumero',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bs. ${monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ✅ BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _cargarResumen());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagoCard({
    required IconData icono,
    required Color color,
    required String tipo,
    required double total,
    required int cantidad,
    required List<dynamic> ventas,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          tipo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
          ),
        ),
        subtitle: Text(
          '$cantidad venta${cantidad > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Text(
          'Bs. ${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        children: [
          Divider(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ventas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final venta = ventas[index];
                final ventaNumero = venta['venta_numero'] as String;
                final montoRecibido = venta['monto_recibido'] as num;
                final tipoEntrega = venta['tipo_entrega'] as String;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venta $ventaNumero',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tipoEntrega == 'COMPLETA'
                                  ? '✅ Entrega Completa'
                                  : '⚠️ Con Novedad',
                              style: TextStyle(
                                fontSize: 11,
                                color: tipoEntrega == 'COMPLETA'
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bs. ${montoRecibido.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _obtenerIconoPago(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'EFECTIVO':
        return Icons.money;
      case 'TRANSFERENCIA':
      case 'QR':
        return Icons.account_balance;
      case 'TARJETA':
        return Icons.credit_card;
      case 'CHEQUE':
        return Icons.receipt;
      default:
        return Icons.payments;
    }
  }

  Color _obtenerColorPago(String codigo) {
    switch (codigo.toUpperCase()) {
      case 'EFECTIVO':
        return Colors.green;
      case 'TRANSFERENCIA':
      case 'QR':
        return Colors.blue;
      case 'TARJETA':
        return Colors.purple;
      case 'CHEQUE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
