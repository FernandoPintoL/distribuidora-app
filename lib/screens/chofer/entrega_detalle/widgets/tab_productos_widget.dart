import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../widgets/chofer/productos_agrupados_widget.dart';

class TabProductosWidget extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;

  const TabProductosWidget({
    Key? key,
    required this.entrega,
    required this.provider,
  }) : super(key: key);

  @override
  State<TabProductosWidget> createState() => _TabProductosWidgetState();
}

class _TabProductosWidgetState extends State<TabProductosWidget> {
  void recargar() {
    debugPrint('🔄 Recargando Productos...');
    widget.provider.obtenerEntrega(widget.entrega.id).then((_) {
      debugPrint('✅ Productos actualizados');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Actualizando productos...');
        await widget.provider.obtenerEntrega(widget.entrega.id);
        debugPrint('✅ Productos actualizados');
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            key: ValueKey('productos_${widget.entrega.id}'),
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductosAgrupadsWidget(
              entregaId: widget.entrega.id,
              mostrarDetalleVentas: true,
            ),
          ),
        ],
      ),
    );
  }
}
