import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';
import '../../resumen_pagos_entrega_screen.dart';

class TabPagosWidget extends StatelessWidget {
  final Entrega entrega;
  final EntregaProvider provider;

  const TabPagosWidget({
    Key? key,
    required this.entrega,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Actualizando resumen de pagos...');
        await provider.obtenerEntrega(entrega.id);
        debugPrint('✅ Resumen de pagos actualizado');
      },
      child: ResumenPagosEntregaScreen(
        entrega: entrega,
        provider: provider,
      ),
    );
  }
}
