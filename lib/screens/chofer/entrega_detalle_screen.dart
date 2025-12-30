import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../models/venta.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/entrega_timeline.dart';
import '../../widgets/chofer/navigation_panel.dart';
import '../../widgets/chofer/animated_navigation_card.dart';
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
  late EntregaProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<EntregaProvider>();
    _cargarDetalle();
    // Iniciar escucha de WebSocket para actualizaciones en tiempo real
    _provider.iniciarEscuchaWebSocket();
  }

  @override
  void dispose() {
    // Detener escucha de WebSocket
    _provider.detenerEscuchaWebSocket();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    await _provider.obtenerEntrega(widget.entregaId);
  }

  Future<void> _mostrarDialogoMarcarLlegada(
    BuildContext context,
    Entrega entrega,
  ) async {
    if (!mounted) return;

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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
        final success = await _provider.marcarLlegada(
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
          await _cargarDetalle();
        } else {
          debugPrint('❌ Error: ${_provider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${_provider.errorMessage ?? 'Error desconocido'}',
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

  Future<void> _mostrarDialogoReportarNovedad(
    BuildContext context,
    Entrega entrega,
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
        final success = await _provider.reportarNovedad(
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
            await _cargarDetalle();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${_provider.errorMessage}'),
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
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Detalle de Entrega',
        customGradient: AppGradients.green,
      ),
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.entregaActual == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Error al cargar entrega'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarDetalle,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final entrega = provider.entregaActual!;

          return RefreshIndicator(
            onRefresh: _cargarDetalle,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estado
                _EstadoCard(entrega: entrega),
                const SizedBox(height: 16),
                // Información general
                _InformacionGeneralCard(entrega: entrega),
                const SizedBox(height: 16),
                // Fecha y tiempos
                _FechasCard(entrega: entrega),
                const SizedBox(height: 16),
                // Timeline visual de estados
                EntregaTimeline(entrega: entrega),
                const SizedBox(height: 16),
                // Sección de Ventas Asignadas
                _VentasAsignadasCard(entrega: entrega, provider: provider),
                const SizedBox(height: 16),
                // Panel de navegación con animación de entrada
                AnimatedNavigationCard(
                  clientName: entrega.cliente ?? 'Cliente',
                  address: entrega.direccion ?? 'Dirección no disponible',
                  child: NavigationPanel(
                    clientName: entrega.cliente ?? 'Cliente',
                    address: entrega.direccion ?? 'Dirección no disponible',
                    destinationLatitude: entrega.latitudeDestino,
                    destinationLongitude: entrega.longitudeDestino,
                  ),
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
                  onMarcarLlegada: _mostrarDialogoMarcarLlegada,
                  onReportarNovedad: _mostrarDialogoReportarNovedad,
                ),
              ],
            ),
          );
        },
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

class _InformacionGeneralCard extends StatelessWidget {
  final Entrega entrega;

  const _InformacionGeneralCard({Key? key, required this.entrega})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.confirmation_number,
              label: 'ID Entrega',
              value: '#${entrega.id}',
            ),
            const Divider(),
            if (entrega.chofer != null)
              _InfoItem(
                icon: Icons.local_shipping,
                label: 'Chofer',
                value: entrega.chofer!.nombreCompleto,
              )
            else if (entrega.choferId != null)
              _InfoItem(
                icon: Icons.local_shipping,
                label: 'Chofer',
                value: '#${entrega.choferId}',
              )
            else
              _InfoItem(
                icon: Icons.local_shipping,
                label: 'Chofer',
                value: 'No asignado',
              ),
            if (entrega.chofer != null &&
                entrega.chofer!.telefono.isNotEmpty) ...[
              const Divider(),
              _InfoItem(
                icon: Icons.phone,
                label: 'Teléfono Chofer',
                value: entrega.chofer!.telefono,
              ),
            ],
            const Divider(),
            if (entrega.vehiculo != null)
              _InfoItem(
                icon: Icons.directions_car,
                label: 'Vehículo',
                value:
                    '${entrega.vehiculo!.placaFormato} - ${entrega.vehiculo!.descripcion}',
              )
            else if (entrega.vehiculoId != null)
              _InfoItem(
                icon: Icons.directions_car,
                label: 'Vehículo',
                value: '#${entrega.vehiculoId}',
              )
            else
              _InfoItem(
                icon: Icons.directions_car,
                label: 'Vehículo',
                value: 'No asignado',
              ),
            if (entrega.vehiculo != null &&
                entrega.vehiculo!.capacidadKg != null) ...[
              const Divider(),
              _InfoItem(
                icon: Icons.balance,
                label: 'Capacidad',
                value: '${entrega.vehiculo!.capacidadKg} kg',
              ),
            ],
            if (entrega.observaciones != null &&
                entrega.observaciones!.isNotEmpty) ...[
              const Divider(),
              _InfoItem(
                icon: Icons.notes,
                label: 'Observaciones',
                value: entrega.observaciones!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FechasCard extends StatelessWidget {
  final Entrega entrega;

  const _FechasCard({Key? key, required this.entrega}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fechas y Tiempos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (entrega.fechaAsignacion != null) ...[
              _InfoItem(
                icon: Icons.calendar_today,
                label: 'Asignada',
                value: entrega.formatFecha(entrega.fechaAsignacion),
              ),
              const Divider(),
            ],
            if (entrega.fechaInicio != null) ...[
              _InfoItem(
                icon: Icons.play_circle,
                label: 'Inicio de Ruta',
                value: entrega.formatFecha(entrega.fechaInicio),
              ),
              const Divider(),
            ],
            if (entrega.fechaEntrega != null) ...[
              _InfoItem(
                icon: Icons.check_circle,
                label: 'Entregado',
                value: entrega.formatFecha(entrega.fechaEntrega),
              ),
            ],
            if (entrega.fechaAsignacion == null &&
                entrega.fechaInicio == null &&
                entrega.fechaEntrega == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin fechas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
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
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${estado.estadoAnterior} → ${estado.estadoNuevo}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estado.createdAt.toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      if (estado.comentario != null &&
                          estado.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          estado.comentario!,
                          style: const TextStyle(fontSize: 12),
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
  final Function(BuildContext, Entrega) onMarcarLlegada;
  final Function(BuildContext, Entrega) onReportarNovedad;

  const _BotonesAccion({
    Key? key,
    required this.entrega,
    required this.onMarcarLlegada,
    required this.onReportarNovedad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        if (entrega.puedeIniciarRuta)
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
              await onMarcarLlegada(context, entrega);
            },
          ),
        if (entrega.puedeConfirmarEntrega)
          _BotonAccion(
            label: 'Confirmar Entrega',
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed('/chofer/confirmar-entrega', arguments: entrega.id);
            },
          ),
        /* if (entrega.puedeReportarNovedad)
          _BotonAccion(
            label: 'Reportar Novedad',
            icon: Icons.warning,
            color: Colors.red,
            onPressed: () async {
              await onReportarNovedad(context, entrega);
            },
          ), */
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  const _VentasAsignadasCard({
    Key? key,
    required this.entrega,
    required this.provider,
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
    // Inicializar estado de confirmación de ventas
    for (var venta in widget.entrega.ventas) {
      _ventasConfirmadas[venta.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPreparacion = widget.entrega.estado == 'PREPARACION_CARGA';
    final esEnCarga = widget.entrega.estado == 'EN_CARGA';
    final esModoCarga = esPreparacion || esEnCarga;

    if (widget.entrega.ventas.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVentas = widget.entrega.ventas.length;
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
                const Icon(Icons.local_shipping, color: Colors.blue),
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
                            color: Colors.grey[600],
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
                          ? Colors.green[100]
                          : Colors.orange[100],
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
                            ? Colors.green[900]
                            : Colors.orange[900],
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
                  backgroundColor: Colors.grey[300],
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.entrega.ventas.length,
              itemBuilder: (context, index) {
                final venta = widget.entrega.ventas[index];
                final confirmada = _ventasConfirmadas[venta.id] ?? false;
                final cargando = _cargandoVenta[venta.id] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
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
                        Text(
                          'Venta #${venta.numero}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          venta.clienteNombre ?? 'Cliente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildUbicacionBadge(widget.entrega),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BS ${venta.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildEstadoPagoBadge(venta.estadoPago),
                      ],
                    ),
                    children: [
                      // Detalles/Productos de la venta
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${detalle.cantidad}x',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.blue,
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
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
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
                                                    color: Colors.grey[500],
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
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'BS ${detalle.precioUnitario.toStringAsFixed(2)} c/u',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
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
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            // Resumen
                            if (venta.detalles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'BS ${venta.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (venta.impuesto > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Impuesto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'BS ${venta.impuesto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    'BS ${venta.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
            if (widget.entrega.ventas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
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
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BS ${widget.entrega.ventas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.entrega.ventas.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: config['color'] as Color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config['icon'] as String, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: config['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar el indicador de ubicación de entrega
  Widget _buildUbicacionBadge(Entrega entrega) {
    final tieneUbicacion = entrega.latitudeDestino != null && entrega.longitudeDestino != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tieneUbicacion ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tieneUbicacion ? Colors.green[600]! : Colors.red[600]!,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tieneUbicacion ? '📍' : '❌',
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            tieneUbicacion ? 'Ubicación' : 'Sin ubicación',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tieneUbicacion ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
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
              Navigator.pop(context); // Cerrar el AlertDialog

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Carga confirmada correctamente. Estado: Listo para entrega',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${widget.provider.errorMessage ?? 'Error desconocido'}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('❌ Error confirmando carga: $e');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
