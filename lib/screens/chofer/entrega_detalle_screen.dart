import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/entrega_timeline.dart';
import '../../widgets/chofer/navigation_panel.dart';
import '../../widgets/chofer/animated_navigation_card.dart';
import '../../widgets/chofer/sla_status_widget.dart';
import '../../widgets/chofer/gps_tracking_status_widget.dart';
import '../../widgets/chofer/connection_health_widget.dart';
import '../../widgets/chofer/productos_agrupados_widget.dart';
import '../../config/config.dart';
import '../../services/location_service.dart';
import '../../services/print_service.dart';
import '../../utils/phone_utils.dart';
import 'resumen_pagos_entrega_screen.dart';  // ✅ NUEVO: Para ver resumen de pagos
// Widgets extraídos
import 'entrega_detalle/widgets/estado_card.dart';
import 'entrega_detalle/widgets/informacion_general_card.dart';
import 'entrega_detalle/widgets/botones_accion.dart';
import 'entrega_detalle/widgets/ventas_asignadas_card.dart';
import 'entrega_detalle/widgets/localidades_card.dart';
import 'entrega_detalle/widgets/entregador_info.dart';
// Diálogos extraídos
import 'entrega_detalle/dialogs/marcar_llegada_dialog.dart';
import 'entrega_detalle/dialogs/iniciar_entrega_dialog.dart';
import 'entrega_detalle/dialogs/marcar_entregada_dialog.dart';
import 'entrega_detalle/dialogs/reportar_novedad_dialog.dart';
import 'entrega_detalle/dialogs/confirmar_carga_lista_dialog.dart';
import 'entrega_detalle/dialogs/entregas_terminadas_dialog.dart';

class EntregaDetalleScreen extends StatefulWidget {
  final int entregaId;

  const EntregaDetalleScreen({Key? key, required this.entregaId})
    : super(key: key);

  @override
  State<EntregaDetalleScreen> createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen> {
  bool _isRetryingGps = false; // Estado para reintentos de GPS

  @override
  void initState() {
    super.initState();
    debugPrint('Iniciando detalle de entrega ID: ${widget.entregaId}');
    // NOTA: El WebSocket ya está conectado globalmente desde el login
    // NO necesitamos reconectarlo en cada pantalla
    // La conexión se mantiene activa durante toda la sesión del usuario
    // y solo se desconecta al hacer logout
  }

  @override
  void dispose() {
    // NOTA: NO desconectamos el WebSocket aquí porque es una conexión global
    // Se mantiene activa para otras pantallas
    super.dispose();
  }

  /// Reintentar iniciar el tracking GPS
  Future<void> _reintentarGpsTracking(
    EntregaProvider provider,
    Entrega entrega,
  ) async {
    setState(() => _isRetryingGps = true);

    try {
      debugPrint('🔄 Reintentando iniciar tracking GPS...');

      final success = await provider.reintentarTracking(
        onSuccess: (mensaje) {
          debugPrint('✅ Tracking reiniciado: $mensaje');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ GPS Tracking reiniciado. $mensaje'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onError: (error) {
          debugPrint('❌ Error al reintentar: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al reintentar: $error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );

      if (mounted && !success) {
        debugPrint('❌ Fallo al reiniciar GPS Tracking');
      }
    } catch (e) {
      debugPrint('❌ Excepción al reintentar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetryingGps = false);
      }
    }
  }

  Future<void> _cargarDetalle(EntregaProvider provider) async {
    debugPrint(
      '🔄 [RECARGAR] Recargando detalle de entrega ID: ${widget.entregaId}...',
    );

    try {
      final success = await provider.obtenerEntrega(widget.entregaId);

      if (mounted) {
        if (success) {
          debugPrint('✅ Entrega recargada exitosamente');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Información recargada'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('❌ Error al recargar entrega');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Error al recargar la información',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción al recargar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: CustomGradientAppBar(
        title: 'Detalle de Entrega # ${widget.entregaId}',
        customGradient: AppGradients.green,
        actions: [
          // ✅ NUEVO: Botón para ver resumen de pagos
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Consumer<EntregaProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: const Icon(Icons.receipt_long),
                  tooltip: 'Resumen de Pagos',
                  onPressed: () {
                    if (provider.entregaActual != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResumenPagosEntregaScreen(
                            entrega: provider.entregaActual!,
                            provider: provider,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: context.read<EntregaProvider>().obtenerEntrega(
          widget.entregaId,
        ),
        builder: (context, snapshot) {
          debugPrint(
            '🏗️ [FUTUREBUILDER] connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}',
          );

          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Stack(
              children: [
                // Placeholder vacío
                Container(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                ),
                // Loading overlay modal
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Cargando detalles de entrega...',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Por favor espera',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Si hay error o la carga falló
          if (snapshot.hasError || snapshot.data == false) {
            final provider = context.read<EntregaProvider>();
            return _buildErrorContentWithDebug(provider);
          }

          // Datos cargados correctamente
          // ✅ Usar Selector para escuchar específicamente cambios en entregaActual
          return Selector<EntregaProvider, Entrega?>(
            selector: (context, provider) => provider.entregaActual,
            builder: (context, entregaActual, _) {
              debugPrint(
                '🏗️ [CONSUMER_BUILD] entregaActual=${entregaActual?.id}',
              );

              if (entregaActual == null) {
                final provider = context.read<EntregaProvider>();
                return _buildErrorContentWithDebug(provider);
              }

              // ✅ Obtener provider para acceder a otros métodos
              final provider = context.read<EntregaProvider>();

              // ✅ NUEVO: RefreshIndicator para actualizar al hacer scroll hacia abajo
              return RefreshIndicator(
                onRefresh: () async {
                  debugPrint('🔄 Actualizando datos de entrega...');
                  await provider.obtenerEntrega(widget.entregaId);
                  debugPrint('✅ Datos actualizados');
                },
                child: _buildContent(provider),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorContentWithDebug(EntregaProvider provider) {
    debugPrint('❌ [BUILD_ERROR] _buildErrorContent está siendo renderizada');
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                'Error al cargar entrega',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _cargarDetalle(provider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(EntregaProvider provider) {
    final entrega = provider.entregaActual!;
    debugPrint(
      '✅ [BUILD_CONTENT] Renderizando contenido de entrega ${entrega.id}',
    );

    // ✅ REMOVIDO: RefreshIndicator redundante (ya está en el Selector)
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
            isDarkMode:
                Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: 16),

          // SLA Status - FASE 6
          if (entrega.fechaEntregaComprometida != null) ...[
            SlaStatusWidget(
              key: ValueKey('sla_${entrega.id}'),
              fechaEntregaComprometida: entrega.fechaEntregaComprometida,
              ventanaEntregaIni: entrega.ventanaEntregaIni,
              ventanaEntregaFin: entrega.ventanaEntregaFin,
              estado: entrega.estado,
              compact: false,
            ),
            const SizedBox(height: 16),
          ],
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
            isDarkMode:
                Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: 16),
          // ✅ Sección de Productos Agrupados (desde endpoint separado)
          Padding(
            key: ValueKey('productos_${entrega.id}'),
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductosAgrupadsWidget(
              entregaId: entrega.id,
              mostrarDetalleVentas: true,
            ),
          ),
          // Timeline visual de estados
          /* EntregaTimeline(entrega: entrega),
          const SizedBox(height: 16), */
          // Sección de Ventas Asignadas - Widget extraído
          VentasAsignadasCard(
            key: ValueKey('ventas_${entrega.id}_${entrega.ventas.length}'),
            entrega: entrega,
            provider: provider,
            onLlamarCliente: (tel) => PhoneUtils.llamarCliente(context, tel),
            onEnviarWhatsApp: (tel) => PhoneUtils.enviarWhatsApp(context, tel),
          ),
          const SizedBox(height: 16),
          // Historial de estados
          /* if (provider.historialEstados.isNotEmpty) ...[
            HistorialEstadosCard(estados: provider.historialEstados),
            const SizedBox(height: 16),
          ], */
          // Botones de acción - Widget extraído
          BotonesAccion(
            key: ValueKey('botones_${entrega.id}_${entrega.estado}'),
            entrega: entrega,
            provider: provider,
            onIniciarEntrega: (ctx, ent, prov) =>
                IniciarEntregaDialog.show(ctx, ent, prov),
            onMarcarLlegada: (ctx, ent, prov) =>
                MarcarLlegadaDialog.show(ctx, ent, prov),
            onMarcarEntregada: (ctx, ent, prov) =>
                MarcarEntregadaDialog.show(ctx, ent, prov),
            onReportarNovedad: (ctx, ent, prov) =>
                ReportarNovedadDialog.show(ctx, ent, prov),
            onConfirmarCargaLista: (ctx, ent, prov) =>
                ConfirmarCargaListaDialog.show(ctx, ent, prov),
            onEntregasTerminadas: (ctx, ent, prov) =>
                EntregasTerminadasDialog.show(ctx, ent, prov),
            onReintentarGps: () => _reintentarGpsTracking(provider, entrega),
          ),
          const SizedBox(height: 42),
        ],
      );
  }
}
