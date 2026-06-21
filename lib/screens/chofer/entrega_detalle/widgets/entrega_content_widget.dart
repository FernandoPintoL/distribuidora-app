import 'package:flutter/material.dart';
import '../../../../providers/entrega_provider.dart';
import '../../../../widgets/chofer/sla_status_widget.dart';
import 'estado_card.dart';
import 'informacion_general_card.dart';
import 'entregador_info.dart';
import 'localidades_card.dart';
import 'ventas_asignadas_card.dart';

class EntregaContentWidget extends StatelessWidget {
  final EntregaProvider provider;

  const EntregaContentWidget({Key? key, required this.provider})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entrega = provider.entregaActual!;
    debugPrint(
      '✅ [BUILD_CONTENT] Renderizando contenido de entrega ${entrega.id}',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ✅ CRÍTICO: Keys únicos para forzar reconstrucción cuando los datos cambien
        // Estado - Widget extraído
        EstadoCard(
          key: ValueKey('estado_${entrega.id}_${entrega.estado}'),
          entrega: entrega,
        ),
        const SizedBox(height: 16),

        // ✅ NUEVO: Localidades - Widget extraído
        LocalidadesCard(
          key: ValueKey('localidades_${entrega.id}'),
          entrega: entrega,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
        const SizedBox(height: 16),
        // Información general - Widget extraído
        InformacionGeneralCard(
          key: ValueKey('info_${entrega.id}'),
          entrega: entrega,
        ),
        const SizedBox(height: 16),
        // ✅ NUEVO: Información del entregador
        EntregadorInfo(
          key: ValueKey('entregador_${entrega.id}'),
          entregador: entrega.entregador,
          choferNombre: entrega.chofer?.nombre,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
