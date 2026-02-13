import 'package:flutter/material.dart';
import '../../../../models/entrega.dart';
import '../../../../providers/entrega_provider.dart';
import 'boton_accion.dart';

class BotonesAccion extends StatelessWidget {
  final Entrega entrega;
  final EntregaProvider provider;
  final Function(BuildContext, Entrega, EntregaProvider) onIniciarEntrega;
  final Function(BuildContext, Entrega, EntregaProvider) onMarcarLlegada;
  final Function(BuildContext, Entrega, EntregaProvider) onMarcarEntregada;
  final Function(BuildContext, Entrega, EntregaProvider) onReportarNovedad;
  final Function(BuildContext, Entrega, EntregaProvider, {VoidCallback? onReload})? onConfirmarCargaLista;
  final Function(BuildContext, Entrega, EntregaProvider)? onEntregasTerminadas;
  final VoidCallback? onReintentarGps;
  final VoidCallback? onReload;

  const BotonesAccion({
    Key? key,
    required this.entrega,
    required this.provider,
    required this.onIniciarEntrega,
    required this.onMarcarLlegada,
    required this.onMarcarEntregada,
    required this.onReportarNovedad,
    this.onConfirmarCargaLista,
    this.onEntregasTerminadas,
    this.onReintentarGps,
    this.onReload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esListoParaEntrega =
        entrega.estadoEntregaCodigo == 'LISTO_PARA_ENTREGA' ||
        (entrega.estadoEntregaCodigo == null &&
            entrega.estado == 'LISTO_PARA_ENTREGA');

    final esEnTransito =
        entrega.estadoEntregaCodigo == 'EN_TRANSITO' ||
        entrega.estado == 'EN_TRANSITO' ||
        entrega.estado == 'EN_CAMINO';

    final esLlego =
        entrega.estadoEntregaCodigo == 'LLEGO' || entrega.estado == 'LLEGO';

    final esPreparacionCarga =
        entrega.estadoEntregaCodigo == 'PREPARACION_CARGA' ||
        entrega.estado == 'PREPARACION_CARGA';

    return Column(
      spacing: 8,
      children: [
        // ✅ NUEVO: Botón confirmar carga lista cuando está en PREPARACION_CARGA
        if (esPreparacionCarga && onConfirmarCargaLista != null)
          BotonAccion(
            label: 'Confirmar Carga Lista',
            icon: Icons.check_circle,
            color: Colors.blue,
            onPressed: () {
              onConfirmarCargaLista!(
                context,
                entrega,
                provider,
                onReload: onReload,
              );
            },
          ),
        if (esListoParaEntrega)
          BotonAccion(
            label: 'Iniciar Entrega',
            icon: Icons.play_circle,
            color: Colors.green,
            onPressed: () {
              onIniciarEntrega(context, entrega, provider);
            },
          ),
        if (entrega.puedeIniciarRuta && !esListoParaEntrega)
          BotonAccion(
            label: 'Iniciar Ruta',
            icon: Icons.navigation,
            color: Colors.green,
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/chofer/iniciar-ruta', arguments: entrega.id);
            },
          ),
        // ❌ OCULTO: Botón Entregas Terminadas - Solo el cajero en oficina puede terminar entregas
        // if (esEnTransito && onEntregasTerminadas != null)
        //   BotonAccion(
        //     label: 'Entregas Terminadas',
        //     icon: Icons.check_circle_outline,
        //     color: Colors.green,
        //     onPressed: () async {
        //       await onEntregasTerminadas!(context, entrega, provider);
        //     },
        //   ),
        if (esLlego)
          BotonAccion(
            label: 'Marcar Carga Entregada',
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: () async {
              await onMarcarEntregada(context, entrega, provider);
            },
          ),
      ],
    );
  }
}
