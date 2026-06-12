import 'package:flutter/material.dart';
import '../../../../providers/entrega_provider.dart';
import 'entrega_content_widget.dart';

class TabGeneralWidget extends StatelessWidget {
  final EntregaProvider provider;

  const TabGeneralWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Actualizando datos de entrega...');
        await provider.obtenerEntrega(provider.entregaActual?.id ?? 0);
        debugPrint('✅ Datos actualizados');
      },
      child: EntregaContentWidget(
        provider: provider,
      ),
    );
  }
}
