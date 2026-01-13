import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/entrega_timeline.dart';
import '../../widgets/chofer/navigation_panel.dart';
import '../../widgets/chofer/animated_navigation_card.dart';
import '../../widgets/chofer/sla_status_widget.dart';
import '../../widgets/chofer/gps_tracking_status_widget.dart';
import '../../widgets/chofer/connection_health_widget.dart';
import '../../config/config.dart';
import '../../services/location_service.dart';

class EntregaDetalleScreen extends StatefulWidget {
  final int entregaId;

  const EntregaDetalleScreen({Key? key, required this.entregaId})
    : super(key: key);

  @override
  State<EntregaDetalleScreen> createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen> {
  bool _isRetryingGps = false; // Estado para reintentos de GPS
  bool _expandedTracking = false; // Estado para expandir/colapsar tracking

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

  /// Llamar al cliente
  Future<void> _llamarCliente(String? telefono) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: telefono);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        debugPrint('No se pudo abrir teléfono');
      }
    } catch (e) {
      debugPrint('Error al llamar: $e');
    }
  }

  /// Enviar WhatsApp al cliente
  Future<void> _enviarWhatsApp(String? telefono) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Limpiar teléfono (remover espacios, caracteres especiales)
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri whatsappUri = Uri.parse('https://wa.me/$telefonoLimpio');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('WhatsApp no disponible');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp no está instalado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al enviar WhatsApp: $e');
    }
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
    await provider.obtenerEntrega(widget.entregaId);
  }

  Future<void> _mostrarDialogoMarcarLlegada(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    if (!mounted) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar Llegada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('¿Confirmas que has llegado al destino?'),
            const SizedBox(height: 8),
            if (entrega.direccion != null)
              Text(
                entrega.direccion!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar Llegada'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      // Backend requiere exactamente EN_CAMINO para marcar llegada
      if (entrega.estado != 'EN_CAMINO') {
        debugPrint('⚠️ Estado incorrecto: ${entrega.estado}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La entrega debe estar EN_CAMINO. Estado actual: ${entrega.estadoLabel}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      try {
        // Obtener ubicación actual del dispositivo con reintentos
        debugPrint('📍 Obteniendo ubicación...');
        final locationService = LocationService();
        final position = await locationService.getCurrentLocationWithRetry(
          maxRetries: 3,
          retryDelay: const Duration(seconds: 1),
        );

        if (!mounted) return;

        if (position == null) {
          debugPrint('⚠️ No se pudo obtener la ubicación');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo obtener la ubicación. Verifica que el GPS esté habilitado.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Hacer API call sin mostrar dialog
        debugPrint('📤 Llamando API para marcar llegada...');
        final success = await provider.marcarLlegada(
          entrega.id,
          latitud: position.latitude,
          longitud: position.longitude,
        );

        if (!mounted) return;

        if (success) {
          debugPrint('✅ Llegada marcada correctamente');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Llegada marcada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Recargar detalle
          await _cargarDetalle(provider);
        } else {
          debugPrint('❌ Error: ${provider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Excepción: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// FASE 4: Mostrar dialog para iniciar entrega
  /// Se muestra solo cuando estado = LISTO_PARA_ENTREGA
  Future<void> _mostrarDialogoIniciarEntrega(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    if (!mounted) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('¿Confirmas que deseas iniciar la entrega?'),
            const SizedBox(height: 12),
            Text(
              'Se cambiar el estado a EN_RUTA y se iniciará el tracking de GPS.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (entrega.cliente != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.blue[900]?.withOpacity(0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.cliente!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Iniciar Entrega'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      // Mostrar loading dialog mientras se procesa
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        debugPrint('🚀 Iniciando entrega #${entrega.id}...');

        final success = await provider.iniciarEntrega(
          entrega.id,
          onSuccess: (mensaje) {
            debugPrint('✅ Entrega iniciada: $mensaje');
          },
          onError: (error) {
            debugPrint('❌ Error: $error');
          },
        );

        if (mounted) {
          Navigator.pop(context); // Cerrar loading

          if (success) {
            debugPrint('✅ Entrega iniciada correctamente');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '✅ Entrega iniciada correctamente. GPS tracking activo.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Recargar detalle
            await _cargarDetalle(provider);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: ${provider.errorMessage ?? 'Error desconocido'}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Excepción: $e');
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogoReportarNovedad(
    BuildContext context,
    Entrega entrega,
    EntregaProvider provider,
  ) async {
    if (!mounted) return;

    final motivoController = TextEditingController();
    final descripcionController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Novedad'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo *',
                  hintText: 'Ej: Cliente ausente, Dirección incorrecta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Detalles adicionales...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: motivoController.text.isEmpty
                ? null
                : () {
                    Navigator.pop(context, true);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      // Mostrar loading mientras se procesa
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await provider.reportarNovedad(
          entrega.id,
          motivo: motivoController.text,
          descripcion: descripcionController.text.isNotEmpty
              ? descripcionController.text
              : null,
        );

        if (mounted) {
          Navigator.pop(context); // Cerrar loading

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Novedad reportada correctamente'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            // Recargar detalle
            await _cargarDetalle(provider);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${provider.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        motivoController.dispose();
        descripcionController.dispose();
      }
    } else {
      motivoController.dispose();
      descripcionController.dispose();
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
          return Consumer<EntregaProvider>(
            builder: (context, provider, _) {
              debugPrint(
                '🏗️ [CONSUMER_BUILD] entregaActual=${provider.entregaActual?.id}, provider_id=${provider.hashCode}',
              );

              if (provider.entregaActual == null) {
                return _buildErrorContentWithDebug(provider);
              }

              return _buildContent(provider);
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

    return RefreshIndicator(
      onRefresh: () => _cargarDetalle(provider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          _EstadoCard(entrega: entrega),
          const SizedBox(height: 16),

          // GPS Tracking Status - Solo si tracking activo o estado es EN_TRANSITO
          if (provider.isTracking ||
              entrega.estadoEntregaCodigo == 'EN_TRANSITO') ...[
            Card(
              elevation: 2,
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: provider.isTracking ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información de Rastreo',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.isTracking
                                ? '✅ GPS Activo'
                                : '⏸️ GPS Inactivo',
                            style: TextStyle(
                              fontSize: 12,
                              color: provider.isTracking
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: _expandedTracking,
                onExpansionChanged: (expanded) {
                  setState(() => _expandedTracking = expanded);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 16,
                      children: [
                        // GPS Tracking Status Details
                        GpsTrackingStatusWidget(
                          isTracking: provider.isTracking,
                          ultimaUbicacion: provider.ultimaUbicacion,
                          destinoLatitud: entrega.latitudeDestino,
                          destinoLongitud: entrega.longitudeDestino,
                          distanciaRecorrida: provider.distanciaRecorrida,
                          compact: false,
                          onRetry: () =>
                              _reintentarGpsTracking(provider, entrega),
                          isRetrying: _isRetryingGps,
                        ),
                        // Connection Health - Solo si tracking activo
                        if (provider.isTracking)
                          ConnectionHealthWidget(
                            isTracking: provider.isTracking,
                            ultimaUbicacion: provider.ultimaUbicacion,
                            onRetryGps: () =>
                                _reintentarGpsTracking(provider, entrega),
                          ),
                        // Divider antes de navegación
                        const Divider(),
                        // Panel de navegación
                        NavigationPanel(
                          clientName: entrega.cliente ?? 'Cliente',
                          address:
                              entrega.direccion ?? 'Dirección no disponible',
                          destinationLatitude: entrega.latitudeDestino,
                          destinationLongitude: entrega.longitudeDestino,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // SLA Status - FASE 6
          if (entrega.fechaEntregaComprometida != null) ...[
            SlaStatusWidget(
              fechaEntregaComprometida: entrega.fechaEntregaComprometida,
              ventanaEntregaIni: entrega.ventanaEntregaIni,
              ventanaEntregaFin: entrega.ventanaEntregaFin,
              estado: entrega.estado,
              compact: false,
            ),
            const SizedBox(height: 16),
          ],
          // Información general (incluye fechas y tiempos)
          _InformacionGeneralCard(entrega: entrega),
          const SizedBox(height: 16),
          // Timeline visual de estados
          /* EntregaTimeline(entrega: entrega),
          const SizedBox(height: 16), */
          // Sección de Ventas Asignadas
          _VentasAsignadasCard(
            entrega: entrega,
            provider: provider,
            onLlamarCliente: _llamarCliente,
            onEnviarWhatsApp: _enviarWhatsApp,
          ),
          const SizedBox(height: 16),
          // Historial de estados
          /* if (provider.historialEstados.isNotEmpty) ...[
            _HistorialEstadosCard(estados: provider.historialEstados),
            const SizedBox(height: 16),
          ], */
          // Botones de acción
          _BotonesAccion(
            entrega: entrega,
            provider: provider,
            onIniciarEntrega: _mostrarDialogoIniciarEntrega,
            onMarcarLlegada: _mostrarDialogoMarcarLlegada,
            onReportarNovedad: _mostrarDialogoReportarNovedad,
            onReintentarGps: () => _reintentarGpsTracking(provider, entrega),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  final Entrega entrega;

  const _EstadoCard({Key? key, required this.entrega}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColorEstado(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado Actual',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(entrega.estadoIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado() {
    // Usar primero el color del estado desde la BD (estado_entrega.color)
    final colorHex = entrega.estadoEntregaColor;

    if (colorHex != null && colorHex.isNotEmpty && colorHex.startsWith('#')) {
      try {
        return Color(int.parse('0xff${colorHex.substring(1)}'));
      } catch (e) {
        debugPrint('❌ Error parseando color: $colorHex - $e');
      }
    }

    // Fallback: usar colores hardcodeados si no viene desde la BD
    const colores = {
      'PROGRAMADO': Color(0xFFeab308),
      'ASIGNADA': Color(0xFF3b82f6),
      'EN_CAMINO': Color(0xFFf97316),
      'EN_TRANSITO': Color(0xFFf97316),
      'LLEGO': Color(0xFFeab308),
      'ENTREGADO': Color(0xFF22c55e),
      'PREPARACION_CARGA': Color(0xFFf97316),
      'EN_CARGA': Color(0xFFf97316),
      'LISTO_PARA_ENTREGA': Color(0xFFeab308),
      'NOVEDAD': Color(0xFFef4444),
      'RECHAZADO': Color(0xFFef4444),
      'CANCELADA': Color(0xFF6b7280),
    };
    return colores[entrega.estado] ?? Colors.grey;
  }
}

class _InformacionGeneralCard extends StatefulWidget {
  final Entrega entrega;

  const _InformacionGeneralCard({Key? key, required this.entrega})
    : super(key: key);

  @override
  State<_InformacionGeneralCard> createState() =>
      _InformacionGeneralCardState();
}

class _InformacionGeneralCardState extends State<_InformacionGeneralCard> {
  bool _expandirDetalles = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado compacto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles de Entrega',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                if (widget.entrega.observaciones != null &&
                    widget.entrega.observaciones!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandirDetalles = !_expandirDetalles;
                      });
                    },
                    child: Icon(
                      _expandirDetalles
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de información compacta
            LayoutBuilder(
              builder: (context, constraints) {
                // Determinar cantidad de columnas según ancho disponible
                final numCols = constraints.maxWidth > 500 ? 3 : 2;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ID Entrega
                    _CompactInfoChip(
                      icon: Icons.confirmation_number,
                      label: '#${widget.entrega.id}',
                      value: widget.entrega.numeroEntrega ?? 'N/A',
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),

                    // Chofer
                    if (widget.entrega.chofer != null)
                      _CompactInfoChip(
                        icon: Icons.person,
                        label: 'Chofer',
                        value: widget.entrega.chofer!.nombreCompleto,
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      )
                    else
                      _CompactInfoChip(
                        icon: Icons.person_off,
                        label: 'Chofer',
                        value: 'No asignado',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),

                    // Vehículo
                    if (widget.entrega.vehiculo != null)
                      _CompactInfoChip(
                        icon: Icons.directions_car,
                        label: 'Auto',
                        value: widget.entrega.vehiculo!.placaFormato,
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      )
                    else
                      _CompactInfoChip(
                        icon: Icons.directions_car,
                        label: 'Auto',
                        value: 'No asignado',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),

                    // Capacidad (si existe)
                    if (widget.entrega.vehiculo != null &&
                        widget.entrega.vehiculo!.capacidadKg != null)
                      _CompactInfoChip(
                        icon: Icons.balance,
                        label: 'Capacidad',
                        value:
                            '${widget.entrega.vehiculo!.capacidadKg.toString()} kg',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),

                    // Teléfono del chofer (si existe)
                    if (widget.entrega.chofer != null &&
                        widget.entrega.chofer!.telefono != null &&
                        widget.entrega.chofer!.telefono!.isNotEmpty)
                      _CompactInfoChip(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: widget.entrega.chofer!.telefono ?? 'N/A',
                        isDarkMode: isDarkMode,
                        colorScheme: colorScheme,
                      ),
                  ],
                );
              },
            ),

            // Sección de Fechas y Tiempos
            if (widget.entrega.fechaAsignacion != null ||
                widget.entrega.fechaInicio != null ||
                widget.entrega.fechaEntrega != null) ...[
              const SizedBox(height: 16),
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              Text(
                'Cronograma',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.entrega.fechaAsignacion != null)
                    _CompactDateChip(
                      icon: Icons.calendar_today,
                      label: 'Asignada',
                      date: widget.entrega.fechaAsignacion!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),
                  if (widget.entrega.fechaInicio != null)
                    _CompactDateChip(
                      icon: Icons.play_circle,
                      label: 'Inicio',
                      date: widget.entrega.fechaInicio!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                    ),
                  if (widget.entrega.fechaEntrega != null)
                    _CompactDateChip(
                      icon: Icons.check_circle,
                      label: 'Entregada',
                      date: widget.entrega.fechaEntrega!,
                      isDarkMode: isDarkMode,
                      colorScheme: colorScheme,
                      isSuccess: true,
                    ),
                ],
              ),
            ],

            // Observaciones expandibles
            if (widget.entrega.observaciones != null &&
                widget.entrega.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandirDetalles = !_expandirDetalles;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Observaciones',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    Icon(
                      _expandirDetalles
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (_expandirDetalles) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    widget.entrega.observaciones!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar información clave
class _CompactInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;
  final ColorScheme colorScheme;

  const _CompactInfoChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.08),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.15)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar fechas
class _CompactDateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final bool isDarkMode;
  final ColorScheme colorScheme;
  final bool isSuccess;

  const _CompactDateChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.date,
    required this.isDarkMode,
    required this.colorScheme,
    this.isSuccess = false,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    // Formato: "15 Dic, 14:30"
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} $month, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isSuccess
        ? (isDarkMode ? Colors.green[900] : Colors.green[100])
        : (isDarkMode
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.08));

    final borderColor = isSuccess
        ? (isDarkMode ? Colors.green[600]! : Colors.green[300]!)
        : (isDarkMode
            ? colorScheme.outline.withValues(alpha: 0.15)
            : colorScheme.outline.withValues(alpha: 0.1));

    final accentColor = isSuccess
        ? (isDarkMode ? Colors.green[400] : Colors.green[700])
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                  fontSize: 11,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HistorialEstadosCard extends StatelessWidget {
  final List<EntregaEstadoHistorial> estados;

  const _HistorialEstadosCard({Key? key, required this.estados})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Estados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estados.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final estado = estados[index];
                final bgColor = isDarkMode
                    ? Colors.blue[900]
                    : Colors.blue[100];
                final textColor = isDarkMode
                    ? Colors.blue[300]
                    : Colors.blue[900];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${estado.estadoAnterior} → ${estado.estadoNuevo}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estado.createdAt.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),
                      if (estado.comentario != null &&
                          estado.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          estado.comentario!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  final Entrega entrega;
  final EntregaProvider provider;
  final Function(BuildContext, Entrega, EntregaProvider) onIniciarEntrega;
  final Function(BuildContext, Entrega, EntregaProvider) onMarcarLlegada;
  final Function(BuildContext, Entrega, EntregaProvider) onReportarNovedad;
  final VoidCallback? onReintentarGps; // Callback para reintentar GPS

  const _BotonesAccion({
    Key? key,
    required this.entrega,
    required this.provider,
    required this.onIniciarEntrega,
    required this.onMarcarLlegada,
    required this.onReportarNovedad,
    this.onReintentarGps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar si el estado es LISTO_PARA_ENTREGA
    final esListoParaEntrega =
        entrega.estadoEntregaCodigo == 'LISTO_PARA_ENTREGA' ||
        (entrega.estadoEntregaCodigo == null &&
            entrega.estado == 'LISTO_PARA_ENTREGA');

    return Column(
      spacing: 8,
      children: [
        // FASE 4: Botón "Iniciar Entrega" - Se muestra SOLO cuando estado = LISTO_PARA_ENTREGA
        if (esListoParaEntrega)
          _BotonAccion(
            label: 'Iniciar Entrega',
            icon: Icons.play_circle,
            color: Colors.green,
            onPressed: () {
              onIniciarEntrega(context, entrega, provider);
            },
          ),
        // Botón original "Iniciar Ruta" - para compatibilidad con otros estados
        if (entrega.puedeIniciarRuta && !esListoParaEntrega)
          _BotonAccion(
            label: 'Iniciar Ruta',
            icon: Icons.navigation,
            color: Colors.green,
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed('/chofer/iniciar-ruta', arguments: entrega.id);
            },
          ),
        if (entrega.puedeMarcarLlegada)
          _BotonAccion(
            label: 'Marcar Llegada',
            icon: Icons.location_on,
            color: Colors.orange,
            onPressed: () async {
              await onMarcarLlegada(context, entrega, provider);
            },
          ),
        /* if (entrega.puedeReportarNovedad)
          _BotonAccion(
            label: 'Reportar Novedad',
            icon: Icons.warning,
            color: Colors.red,
            onPressed: () async {
              await onReportarNovedad(context, entrega, provider);
            },
          ), */

        // Botón para reintentar GPS si no está activo
        if (onReintentarGps != null &&
            !provider.isTracking &&
            (entrega.estadoEntregaCodigo == 'EN_TRANSITO' ||
                entrega.estado == 'EN_CAMINO' ||
                entrega.estado == 'LLEGO'))
          _BotonAccion(
            label: 'Reintentar GPS',
            icon: Icons.gps_fixed,
            color: Colors.blue,
            onPressed: onReintentarGps!,
          ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _BotonAccion({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Widget para mostrar ventas asignadas a la entrega
/// Tiene UI especial cuando el estado es PREPARACION_CARGA o EN_CARGA
class _VentasAsignadasCard extends StatefulWidget {
  final Entrega entrega;
  final EntregaProvider provider;
  final Function(String?) onLlamarCliente;
  final Function(String?) onEnviarWhatsApp;

  const _VentasAsignadasCard({
    Key? key,
    required this.entrega,
    required this.provider,
    required this.onLlamarCliente,
    required this.onEnviarWhatsApp,
  }) : super(key: key);

  @override
  State<_VentasAsignadasCard> createState() => _VentasAsignadasCardState();
}

class _VentasAsignadasCardState extends State<_VentasAsignadasCard> {
  late Map<int, bool> _ventasConfirmadas;
  late Map<int, bool> _cargandoVenta; // Rastrear qué venta está cargando
  bool _procesandoConfirmacion =
      false; // Flag para evitar múltiples ejecuciones

  @override
  void initState() {
    super.initState();
    _ventasConfirmadas = {};
    _cargandoVenta = {};
    // Inicializar estado de confirmación de ventas basándose en el estado logístico
    for (var venta in widget.entrega.ventas) {
      // Una venta está confirmada si su código de estado es PENDIENTE_ENVIO
      _ventasConfirmadas[venta.id] =
          (venta.estadoLogisticoCodigo == 'PENDIENTE_ENVIO');
      // debugPrint('[INIT_SYNC] Venta #${venta.numero}: ${_ventasConfirmadas[venta.id]} (estado: ${venta.estadoLogisticoCodigo})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ IMPORTANTE: Usar siempre los datos más recientes del provider
    // para que se actualice el UI cuando se confirme una venta
    final entregaActual = widget.provider.entregaActual ?? widget.entrega;

    final esPreparacion = entregaActual.estado == 'PREPARACION_CARGA';
    final esEnCarga = entregaActual.estado == 'EN_CARGA';
    final esModoCarga = esPreparacion || esEnCarga;

    if (entregaActual.ventas.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVentas = entregaActual.ventas.length;
    final ventasConfirmadas = _ventasConfirmadas.values.where((v) => v).length;
    final porcentaje = (ventasConfirmadas / totalVentas * 100).toStringAsFixed(
      0,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: isDarkMode ? Colors.blue[400] : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ventas Asignadas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (esModoCarga) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$ventasConfirmadas/$totalVentas cargadas ($porcentaje%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (esModoCarga)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ventasConfirmadas == totalVentas
                          ? (isDarkMode ? Colors.green[900] : Colors.green[100])
                          : (isDarkMode
                                ? Colors.orange[900]
                                : Colors.orange[100]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ventasConfirmadas == totalVentas
                          ? '✅ Completo'
                          : '⏳ En progreso',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ventasConfirmadas == totalVentas
                            ? (isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[900])
                            : (isDarkMode
                                  ? Colors.orange[300]
                                  : Colors.orange[900]),
                      ),
                    ),
                  ),
              ],
            ),

            if (esModoCarga) ...[
              const SizedBox(height: 16),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalVentas > 0 ? ventasConfirmadas / totalVentas : 0,
                  minHeight: 6,
                  backgroundColor: isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ventasConfirmadas == totalVentas
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Lista de ventas con productos colapsables
            // ✅ Usar entregaActual para obtener datos más recientes
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entregaActual.ventas.length,
              itemBuilder: (context, index) {
                final venta = entregaActual.ventas[index];
                final confirmada = _ventasConfirmadas[venta.id] ?? false;
                final cargando = _cargandoVenta[venta.id] ?? false;

                // Determinar color del borde según estado
                final isEnRuta = venta.estadoLogisticoCodigo == 'EN_RUTA';
                final borderColor = isEnRuta
                    ? (isDarkMode ? Colors.green[600]! : Colors.green[200]!)
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!);
                final borderWidth = isEnRuta ? 2.0 : 1.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: isEnRuta ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: borderColor, width: borderWidth),
                  ),
                  child: ExpansionTile(
                    leading: esModoCarga
                        ? cargando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue,
                                    ),
                                  ),
                                )
                              : Checkbox(
                                  value: confirmada,
                                  onChanged: (value) {
                                    final nuevoEstado = value ?? false;
                                    _procesarConfirmacionVenta(
                                      context,
                                      nuevoEstado,
                                      venta,
                                    );
                                  },
                                )
                        : Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 20,
                          ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título y estado EN_RUTA si aplica
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Venta #${venta.numero}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDarkMode
                                      ? Colors.grey[100]
                                      : Colors.grey[900],
                                ),
                              ),
                            ),
                            if (isEnRuta)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.green[900]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.green[600]!
                                        : Colors.green[400]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_run,
                                      size: 12,
                                      color: isDarkMode
                                          ? Colors.green[400]
                                          : Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'En Ruta',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.green[400]
                                            : Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Cliente con botones de contacto
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venta.clienteNombre ?? 'Cliente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  // Teléfono si está disponible
                                  if (venta.clienteTelefono != null &&
                                      venta.clienteTelefono!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      venta.clienteTelefono!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDarkMode
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Botones de contacto
                            if (venta.clienteTelefono != null &&
                                venta.clienteTelefono!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.phone),
                                  iconSize: 16,
                                  color: Colors.green,
                                  tooltip: 'Llamar',
                                  onPressed: () => widget.onLlamarCliente(
                                    venta.clienteTelefono,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.chat),
                                  iconSize: 16,
                                  color: Colors.green[600],
                                  tooltip: 'WhatsApp',
                                  onPressed: () => widget.onEnviarWhatsApp(
                                    venta.clienteTelefono,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildUbicacionBadge(entregaActual),
                      ],
                    ),
                    subtitle: SizedBox(
                      width: 135,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BS ${venta.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[100]
                                  : Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 16,
                            child: _buildEstadoLogisticoBadge(venta),
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 16,
                            child: _buildEstadoPagoBadge(venta.estadoPago),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      // Detalles/Productos de la venta
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SLA Info para la venta - FASE 6
                            if (entregaActual.fechaEntregaComprometida !=
                                null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.blue[900]
                                      : Colors.blue[50],
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.blue[700]!
                                        : Colors.blue[200]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: isDarkMode
                                              ? Colors.blue[400]
                                              : Colors.blue[600],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Información de Entrega',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.blue[300]
                                                : Colors.blue[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (entregaActual.ventanaEntregaIni !=
                                            null &&
                                        entregaActual.ventanaEntregaFin !=
                                            null)
                                      Text(
                                        'Ventana: ${entregaActual.ventanaEntregaIni!.hour.toString().padLeft(2, '0')}:${entregaActual.ventanaEntregaIni!.minute.toString().padLeft(2, '0')} - ${entregaActual.ventanaEntregaFin!.hour.toString().padLeft(2, '0')}:${entregaActual.ventanaEntregaFin!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Encabezado de detalles
                            Text(
                              'Productos',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            // Lista de productos
                            if (venta.detalles.isNotEmpty)
                              ...venta.detalles.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final detalle = entry.value;
                                final isLast = idx == venta.detalles.length - 1;

                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Cantidad
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.blue[900]
                                                : Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${detalle.cantidad % 1 == 0 ? detalle.cantidad.toInt() : detalle.cantidad}x',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.blue[300]
                                                    : Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Info del producto
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detalle.producto?.nombre ??
                                                    'Producto desconocido',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.grey[100]
                                                      : Colors.grey[900],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (detalle
                                                      .producto
                                                      ?.descripcion !=
                                                  null)
                                                Text(
                                                  'SKU: ${detalle.producto!.descripcion}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDarkMode
                                                        ? Colors.grey[500]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Precio
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'BS ${detalle.subtotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.grey[100]
                                                    : Colors.grey[900],
                                              ),
                                            ),
                                            Text(
                                              'BS ${detalle.precioUnitario.toStringAsFixed(2)} c/u',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode
                                                    ? Colors.grey[500]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }).toList()
                            else
                              Text(
                                'Sin productos',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            // Resumen
                            if (venta.detalles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'BS ${venta.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.grey[100]
                                            : Colors.grey[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              /* Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    'BS ${venta.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ), */
                            ],
                            // Botón de confirmación de entrega para esta venta
                            // ✅ Solo mostrar si entrega y venta están EN_RUTA
                            const SizedBox(height: 16),
                            if (entregaActual.estadoEntregaCodigo ==
                                    'EN_RUTA' &&
                                venta.estadoLogisticoCodigo == 'EN_RUTA')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // Detener tracking de GPS antes de navegar
                                    await widget.provider.detenerTracking();
                                    if (context.mounted) {
                                      Navigator.of(context).pushNamed(
                                        '/chofer/confirmar-entrega',
                                        arguments: {
                                          'entrega_id': entregaActual.id,
                                          'venta_id': venta.id,
                                        },
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Confirmar Esta Entrega'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Botón de confirmación de carga (solo en modo carga)
            if (esModoCarga &&
                ventasConfirmadas > 0 &&
                ventasConfirmadas == totalVentas) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mostrarDialogoConfirmarCarga(context);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirmar Carga Completa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Resumen de totales
            if (entregaActual.ventas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total a Entregar',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BS ${entregaActual.ventas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cantidad de Ventas',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entregaActual.ventas.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar el estado de pago como un badge
  Widget _buildEstadoPagoBadge(String estadoPago) {
    const estadoColores = {
      'PENDIENTE': {
        'color': Color(0xFFef4444),
        'label': 'Pendiente',
        'icon': '⏳',
      },
      'PAGADO': {'color': Color(0xFF22c55e), 'label': 'Pagado', 'icon': '✓'},
      'PARCIAL': {'color': Color(0xFFf97316), 'label': 'Parcial', 'icon': '⚠'},
      'CANCELADO': {
        'color': Color(0xFF6b7280),
        'label': 'Cancelado',
        'icon': '✗',
      },
    };

    final config =
        estadoColores[estadoPago] ??
        {'color': Colors.grey, 'label': estadoPago, 'icon': '?'};

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? (config['color'] as Color).withOpacity(0.25)
            : (config['color'] as Color).withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: config['color'] as Color, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config['icon'] as String,
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  config['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: config['color'] as Color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadoLogisticoBadge(Venta venta) {
    // Usar color e icono del backend si están disponibles, sino usar defaults
    Color color = Colors.grey;
    if (venta.estadoLogisticoColor != null) {
      try {
        // Convertir hex string a Color
        final hexColor = venta.estadoLogisticoColor!.replaceFirst('#', '');
        color = Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        color = Colors.grey;
      }
    }

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDarkMode
            ? color.withOpacity(0.25)
            : color.withOpacity(0.15);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                venta.estadoLogisticoIcon ?? '📦',
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  venta.estadoLogistico,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget para mostrar el indicador de ubicación de entrega
  Widget _buildUbicacionBadge(Entrega entrega) {
    // Verificar si hay ubicación desde coordenadas o desde dirección
    final tieneUbicacion =
        (entrega.latitudeDestino != null && entrega.longitudeDestino != null) ||
        (entrega.direccion != null && entrega.direccion!.isNotEmpty);

    print(
      '[UI_UBICACION] lat=${entrega.latitudeDestino}, lng=${entrega.longitudeDestino}, dir=${entrega.direccion}, tieneUbicacion=$tieneUbicacion',
    );

    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        final bgColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[900] : Colors.green[100])
            : (isDarkMode ? Colors.red[900] : Colors.red[100]);

        final borderColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[700] : Colors.green[600])
            : (isDarkMode ? Colors.red[700] : Colors.red[600]);

        final textColor = tieneUbicacion
            ? (isDarkMode ? Colors.green[300] : Colors.green[700])
            : (isDarkMode ? Colors.red[300] : Colors.red[700]);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor!, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tieneUbicacion ? '📍' : '❌',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tieneUbicacion ? 'Ubicación' : 'Sin ubicación',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Procesar confirmación de venta cargada
  /// Muestra loading inline en el checkbox y actualiza la pantalla cuando termina
  Future<void> _procesarConfirmacionVenta(
    BuildContext context,
    bool nuevoEstado,
    Venta venta,
  ) async {
    debugPrint(
      '🔄 Procesando confirmación de venta #${venta.id}, nuevo estado: $nuevoEstado',
    );

    // Log detallado de IDs siendo usados
    debugPrint(
      '[CONFIRM_DEBUG] entrega.id=${widget.entrega.id}, venta.id=${venta.id}, venta.numero=${venta.numero}',
    );
    debugPrint(
      '[CONFIRM_DEBUG] Todas las ventas en la entrega: ${widget.entrega.ventas.map((v) => 'ID:${v.id}(#${v.numero})').join(', ')}',
    );

    // Log del estado logístico actual
    debugPrint(
      '[CONFIRM_DEBUG] Estado logístico actual de venta: ${venta.estadoLogistico} (ID: ${venta.estadoLogisticoId})',
    );

    // Verificar que el widget aún está montado
    if (!mounted) {
      debugPrint('⚠️ Widget no montado');
      return;
    }

    // Establecer loading en esta venta
    setState(() {
      _cargandoVenta[venta.id] = true;
    });

    try {
      bool exito = false;

      debugPrint('📤 Llamando API...');
      if (nuevoEstado) {
        // Confirmar venta como cargada
        exito = await widget.provider.confirmarVentaCargada(
          widget.entrega.id,
          venta.id,
        );
      } else {
        // Desmarcar venta como cargada
        exito = await widget.provider.desmarcarVentaCargada(
          widget.entrega.id,
          venta.id,
        );
      }

      debugPrint('✅ API respondió: exito=$exito');

      if (!mounted) {
        debugPrint('⚠️ Widget no montado después de API');
        return;
      }

      if (exito) {
        // Recargar la entrega completa para reflejar todos los cambios
        debugPrint('🔄 Recargando entrega completa...');
        await widget.provider.obtenerEntrega(widget.entrega.id);

        if (!mounted) return;

        // Log del estado logístico DESPUÉS de recargar
        if (widget.provider.entregaActual != null) {
          final ventaActualizada = widget.provider.entregaActual!.ventas
              .firstWhereOrNull((v) => v.id == venta.id);
          if (ventaActualizada != null) {
            debugPrint(
              '[CONFIRM_DEBUG] ✅ Estado logístico actualizado: ${ventaActualizada.estadoLogistico} (ID: ${ventaActualizada.estadoLogisticoId})',
            );
          }

          // Sincronizar estado de confirmación de todas las ventas basándose en el estado logístico
          // Una venta se considera confirmada si su código de estado es PENDIENTE_ENVIO
          setState(() {
            for (var v in widget.provider.entregaActual!.ventas) {
              // Si el código del estado logístico es PENDIENTE_ENVIO, la venta fue confirmada
              _ventasConfirmadas[v.id] =
                  (v.estadoLogisticoCodigo == 'PENDIENTE_ENVIO');
              debugPrint(
                '[CHECKBOX_SYNC] Venta #${v.numero}: ${_ventasConfirmadas[v.id]} (estado: ${v.estadoLogisticoCodigo})',
              );
            }
          });
        }

        // Mostrar SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? 'Venta #${venta.numero} cargada ✓'
                  : 'Venta #${venta.numero} desmarcada ✓',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint('❌ Error en confirmación: ${widget.provider.errorMessage}');

        // Mostrar SnackBar de error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción: $e');

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
      // Detener el loading
      if (mounted) {
        setState(() {
          _cargandoVenta[venta.id] = false;
        });
      }
      debugPrint('✅ Confirmación completada');
    }
  }

  void _mostrarDialogoConfirmarCarga(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga Completa'),
        content: const Text(
          'Todas las ventas han sido marcadas como cargadas. '
          '¿Confirmas que la carga está lista para entregar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Guardar context antes de pop() para evitar widget deactivado
              final currentContext = context;
              Navigator.pop(currentContext); // Cerrar el AlertDialog

              try {
                debugPrint('📤 Confirmando carga completa...');
                final exito = await widget.provider.confirmarCargoCompleto(
                  widget.entrega.id,
                );

                debugPrint('✅ Respuesta carga completa: exito=$exito');

                if (mounted) {
                  if (exito) {
                    // Recargar la entrega para reflejar cambios
                    debugPrint('🔄 Recargando entrega...');
                    await widget.provider.obtenerEntrega(widget.entrega.id);

                    if (mounted) {
                      // Log de estados de las ventas después de la confirmación
                      if (widget.provider.entregaActual != null) {
                        debugPrint(
                          '[CARGO_DEBUG] Todos los estados de ventas después de confirmar carga:',
                        );
                        for (var v in widget.provider.entregaActual!.ventas) {
                          debugPrint(
                            '[CARGO_DEBUG] Venta #${v.numero}: ${v.estadoLogistico} (ID: ${v.estadoLogisticoId})',
                          );
                        }

                        // Sincronizar estado de confirmación de todas las ventas basándose en el estado logístico
                        setState(() {
                          for (var v in widget.provider.entregaActual!.ventas) {
                            _ventasConfirmadas[v.id] =
                                (v.estadoLogisticoCodigo == 'PENDIENTE_ENVIO');
                          }
                        });
                      }

                      // Usar context guardado y verificar que mounted
                      if (mounted && currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Carga confirmada correctamente. Estado: Listo para entrega',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } else {
                    // Usar context guardado y verificar mounted
                    if (mounted && currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                debugPrint('❌ Error confirmando carga: $e');

                if (mounted && currentContext.mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error inesperado: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
