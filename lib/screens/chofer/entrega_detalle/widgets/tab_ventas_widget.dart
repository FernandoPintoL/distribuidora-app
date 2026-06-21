import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../models/venta.dart'; // ✅ NUEVO: Para parsear ventas JSON
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
  Future<ApiResponse<Map<String, dynamic>>>? _futureVentasResumidas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _cargarVentasResumidas();
      });
    });
  }

  void _cargarVentasResumidas() {
    _futureVentasResumidas = widget.provider.obtenerVentasResumidas(
      widget.entrega.id,
    );
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
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.success) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
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
          final ventasJson = ventasData['ventas'] as List? ?? [];
          final resumenTotal =
              ventasData['resumen_total'] as Map<String, dynamic>? ?? {};

          // ✅ NUEVO 2026-06-14: Agregar entrega_id a cada venta antes de parsearla
          final ventasParseadas = ventasJson.cast<Map<String, dynamic>>().map((
            v,
          ) {
            // Inyectar el ID de la entrega actual en cada venta
            v['entrega_id'] = widget.entrega.id;
            return Venta.fromJson(v);
          }).toList();

          if (ventasParseadas.isEmpty) {
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
              if (widget.entrega.estado == 'EN_TRANSITO' ||
                  widget.entrega.estado == 'ENTREGADO')
                // ✅ RESUMEN TOTAL FINANCIERO (al final)
                _buildResumenTotal(resumenTotal, isDarkMode),
              VentasAsignadasCard(
                key: ValueKey(
                  'ventas_${widget.entrega.id}_${ventasParseadas.length}',
                ),
                entrega: _crearEntregaConVentas(ventasParseadas),
                provider: widget.provider,
                onLlamarCliente: (tel) =>
                    PhoneUtils.llamarCliente(widget.context, tel),
                onEnviarWhatsApp: (tel) =>
                    PhoneUtils.enviarWhatsApp(widget.context, tel),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ✅ NUEVO 2026-06-15: Resumen total de pagos (simplificado)
  Widget _buildResumenTotal(Map<String, dynamic> resumen, bool isDarkMode) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                ),
                Text(
                  'Resumen Total',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildResumenItemCompacto(
                  label: 'Efectivo',
                  valor:
                      '\$${(resumen['efectivo_registrado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  color: Colors.green,
                ),
                _buildResumenItemCompacto(
                  label: 'QR',
                  valor:
                      '\$${(resumen['qr_registrado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  color: Colors.blue,
                ),
                _buildResumenItemCompacto(
                  label: 'Pendiente',
                  valor:
                      '\$${(resumen['total_pendiente'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  color: Colors.orange,
                ),
                _buildResumenItemCompacto(
                  label: 'Rechazadas',
                  valor:
                      '\$${(resumen['total_rechazado'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NUEVO 2026-06-15: Item compacto de resumen
  Widget _buildResumenItemCompacto({
    required String label,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Entrega _crearEntregaConVentas(List<Venta> ventas) {
    return Entrega(
      id: widget.entrega.id,
      estado: widget.entrega.estado,
      historialEstados: widget.entrega.historialEstados,
      ventas: ventas,
      productosGenerico: widget.entrega.productosGenerico,
    );
  }
}
