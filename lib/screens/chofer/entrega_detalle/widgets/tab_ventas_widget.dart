import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../models/api_response.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../utils/phone_utils.dart';
import 'ventas_asignadas_card.dart';

class TabVentasWidget extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;
  final BuildContext context;

  const TabVentasWidget({
    Key? key,
    required this.entrega,
    required this.provider,
    required this.context,
  }) : super(key: key);

  @override
  State<TabVentasWidget> createState() => _TabVentasWidgetState();
}

class _TabVentasWidgetState extends State<TabVentasWidget> {
  late Future<ApiResponse<Map<String, dynamic>>> _futureVentasResumidas;

  @override
  void initState() {
    super.initState();
    _cargarVentasResumidas();
  }

  void _cargarVentasResumidas() {
    _futureVentasResumidas =
        widget.provider.obtenerVentasResumidas(widget.entrega.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Actualizando ventas resumidas...');
        setState(() => _cargarVentasResumidas());
        debugPrint('✅ Ventas resumidas actualizadas');
      },
      child: FutureBuilder<ApiResponse<Map<String, dynamic>>>(
        future: _futureVentasResumidas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.success) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.data?.message ?? 'No se pudieron cargar las ventas'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _cargarVentasResumidas()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final ventasData = snapshot.data!.data!;
          final ventas = ventasData['ventas'] as List? ?? [];
          final resumenTotal = ventasData['resumen_total'] as Map<String, dynamic>? ?? {};

          if (ventas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay ventas en esta entrega'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            children: [
              // ✅ LISTA DE VENTAS CON CARDS
              VentasAsignadasCard(
                key: ValueKey('ventas_${widget.entrega.id}_${ventas.length}'),
                entrega: widget.entrega,
                provider: widget.provider,
                onLlamarCliente: (tel) => PhoneUtils.llamarCliente(widget.context, tel),
                onEnviarWhatsApp: (tel) => PhoneUtils.enviarWhatsApp(widget.context, tel),
              ),
              const SizedBox(height: 24),

              // ✅ RESUMEN TOTAL FINANCIERO (al final)
              _buildResumenTotal(resumenTotal, isDarkMode),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// ✅ NUEVO: Construir resumen total de pagos
  Widget _buildResumenTotal(
    Map<String, dynamic> resumen,
    bool isDarkMode,
  ) {
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
                  Icons.assessment,
                  color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid 2x2: Totales principales
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildResumenItem(
                  label: 'Total Efectivo',
                  valor: '\$${(resumen['efectivo_registrado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  icono: Icons.money,
                  color: Colors.green,
                ),
                _buildResumenItem(
                  label: 'Total QR',
                  valor: '\$${(resumen['qr_registrado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  icono: Icons.qr_code_2,
                  color: Colors.blue,
                ),
                _buildResumenItem(
                  label: 'Pendiente',
                  valor: '\$${(resumen['total_pendiente'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  icono: Icons.hourglass_empty,
                  color: Colors.orange,
                ),
                _buildResumenItem(
                  label: 'Rechazadas',
                  valor: '\$${(resumen['total_rechazado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  icono: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Monto total y porcentaje
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto Total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(resumen['monto_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Completado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(resumen['porcentaje_completado'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Item pequeño de resumen
  Widget _buildResumenItem({
    required String label,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
