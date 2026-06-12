import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../widgets/chofer/productos_agrupados_widget.dart';

class TabProductosWidget extends StatelessWidget {
  final Entrega entrega;
  final EntregaProvider provider;

  const TabProductosWidget({
    Key? key,
    required this.entrega,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Actualizando productos...');
        await provider.obtenerEntrega(entrega.id);
        debugPrint('✅ Productos actualizados');
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            key: ValueKey('productos_${entrega.id}'),
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductosAgrupadsWidget(
              entregaId: entrega.id,
              mostrarDetalleVentas: true,
            ),
          ),
        ],
      ),
    );
  }
}
