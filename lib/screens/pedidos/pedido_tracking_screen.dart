import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'dart:async';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/sla_status_widget.dart';
import '../../config/config.dart';

class PedidoTrackingScreen extends StatefulWidget {
  final Pedido pedido;

  const PedidoTrackingScreen({
    super.key,
    required this.pedido,
  });

  @override
  State<PedidoTrackingScreen> createState() => _PedidoTrackingScreenState();
}

class _PedidoTrackingScreenState extends State<PedidoTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _distanceUpdateTimer;

  @override
  void initState() {
    super.initState();
    _inicializarTracking();
  }

  @override
  void dispose() {
    _distanceUpdateTimer?.cancel();
    _mapController?.dispose();
    // Desuscribirse del tracking al salir
    context.read<TrackingProvider>().desuscribirse();
    super.dispose();
  }

  Future<void> _inicializarTracking() async {
    // Verificar que el pedido tenga tracking activo
    // ✅ ACTUALIZADO: Usar códigos de estado String en lugar de enum
    if (widget.pedido.estadoCodigo != 'EN_RUTA' &&
        widget.pedido.estadoCodigo != 'LLEGO') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El tracking solo está disponible cuando el pedido está en ruta'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Obtener el ID de la entrega del pedido
    // NOTA: Necesitaríamos agregar entregaId al modelo Pedido
    // Por ahora asumimos que usamos el pedido.id como entregaId
    final entregaId = widget.pedido.id;

    final trackingProvider = context.read<TrackingProvider>();
    await trackingProvider.suscribirseATracking(entregaId);

    // Calcular distancia inicial si hay ubicación
    _calcularDistancia();

    // Actualizar distancia cada 30 segundos
    _distanceUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _calcularDistancia(),
    );
  }

  void _calcularDistancia() {
    if (widget.pedido.direccionEntrega?.latitud != null &&
        widget.pedido.direccionEntrega?.longitud != null) {
      final trackingProvider = context.read<TrackingProvider>();

      if (trackingProvider.entregaIdActual != null) {
        trackingProvider.calcularDistancia(
          trackingProvider.entregaIdActual!,
          widget.pedido.direccionEntrega!.latitud!,
          widget.pedido.direccionEntrega!.longitud!,
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    final trackingProvider = context.read<TrackingProvider>();
    await trackingProvider.refresh();
    _calcularDistancia();
  }

  void _centrarMapa() {
    final trackingProvider = context.read<TrackingProvider>();
    final ubicacion = trackingProvider.ubicacionActual;

    if (ubicacion != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(ubicacion.latitud, ubicacion.longitud),
          15,
        ),
      );
    }
  }

  void _mostrarAmbosMarkers() {
    final trackingProvider = context.read<TrackingProvider>();
    final ubicacion = trackingProvider.ubicacionActual;
    final direccion = widget.pedido.direccionEntrega;

    if (ubicacion != null && direccion?.latitud != null && direccion?.longitud != null && _mapController != null) {
      // Calcular bounds correctamente
      final lat1 = ubicacion.latitud;
      final lon1 = ubicacion.longitud;
      final lat2 = direccion!.latitud!;
      final lon2 = direccion.longitud!;

      final southwestLat = lat1 < lat2 ? lat1 : lat2;
      final southwestLon = lon1 < lon2 ? lon1 : lon2;
      final northeastLat = lat1 > lat2 ? lat1 : lat2;
      final northeastLon = lon1 > lon2 ? lon1 : lon2;

      final bounds = LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Tracking en Tiempo Real',
        customGradient: AppGradients.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centrarMapa,
            tooltip: 'Centrar en camión',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _mostrarAmbosMarkers,
            tooltip: 'Ver todo',
          ),
        ],
      ),
      body: Consumer<TrackingProvider>(
        builder: (context, trackingProvider, _) {
          // Estado de carga inicial
          if (trackingProvider.isLoading && trackingProvider.ubicacionActual == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de error
          if (trackingProvider.errorMessage != null &&
              trackingProvider.ubicacionActual == null) {
            return _buildErrorState(trackingProvider.errorMessage!);
          }

          final ubicacion = trackingProvider.ubicacionActual;
          final distancia = trackingProvider.distanciaEstimada;

          // Sin ubicación disponible
          if (ubicacion == null) {
            return _buildNoLocationState();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Stack(
              children: [
                // Mapa
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(ubicacion.latitud, ubicacion.longitud),
                    zoom: 15,
                  ),
                  markers: _buildMarkers(ubicacion),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Mostrar ambos markers al cargar
                    Future.delayed(
                      const Duration(milliseconds: 500),
                      _mostrarAmbosMarkers,
                    );
                  },
                ),

                // Panel de información superior (con SLA si está disponible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    child: _buildInfoPanel(distancia, ubicacion),
                  ),
                ),

                // Panel de información del chofer y camión
                if (widget.pedido.chofer != null || widget.pedido.camion != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildChoferCamionPanel(),
                  ),

                // Indicador de polling activo
                if (trackingProvider.isPollingActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'En vivo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(UbicacionTracking ubicacion) {
    final markers = <Marker>{};

    // Marker del camión
    markers.add(
      Marker(
        markerId: const MarkerId('camion'),
        position: LatLng(ubicacion.latitud, ubicacion.longitud),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '🚚 Camión en camino',
          snippet: ubicacion.velocidadFormateada,
        ),
        rotation: ubicacion.rumbo ?? 0,
      ),
    );

    // Marker del destino
    if (widget.pedido.direccionEntrega?.latitud != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(
            widget.pedido.direccionEntrega!.latitud!,
            widget.pedido.direccionEntrega!.longitud!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '📍 Tu dirección',
            snippet: widget.pedido.direccionEntrega!.direccion,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildInfoPanel(DistanciaEstimada? distancia, UbicacionTracking ubicacion) {
    return Column(
      children: [
        // SLA Status Card - FASE 6 (si está disponible)
        // Nota: Este es un placeholder para cuando tengamos acceso a datos de entrega con SLA
        // En una implementación completa, el Pedido tendría acceso a la Entrega relacionada
        _buildSlaInfoCard(),

        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (distancia != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Distancia
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          distancia.distanciaFormateada,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Distancia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.grey.shade300,
                  ),

                  // Tiempo estimado
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          distancia.tiempoFormateado,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Tiempo estimado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.grey.shade300,
                  ),

                  // Velocidad
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ubicacion.velocidadFormateada,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Velocidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alerta si está cerca
            if (distancia.estaMuyCerca)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡El camión está muy cerca!',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (distancia.estaCerca)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El camión se está acercando',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // Sin información de distancia
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Calculando distancia...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
        ),
      ],
    );
  }

  /// Widget para mostrar información de SLA al cliente
  /// Mostrará el estado de entrega, ventana de entrega, y si está en tiempo
  Widget _buildSlaInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu entrega está en camino',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.pedido.direccionEntrega?.ciudad != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Entrega en: ${widget.pedido.direccionEntrega?.ciudad}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recuerda estar atento a tu teléfono',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoferCamionPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Entrega',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Chofer
          if (widget.pedido.chofer != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chofer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.pedido.chofer!.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.pedido.chofer!.telefono != null && widget.pedido.chofer!.telefono!.isNotEmpty)
                        Text(
                          widget.pedido.chofer!.telefono ?? "N/A",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  color: Colors.green,
                  onPressed: () {
                    // TODO: Implementar llamada telefónica
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Llamar a ${widget.pedido.chofer!.telefono}'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Camión
          if (widget.pedido.camion != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.local_shipping, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehículo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.pedido.camion!.descripcion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Placa: ${widget.pedido.camion!.placaFormateada}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoLocationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ubicación no disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'El tracking estará disponible cuando el chofer inicie la ruta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          const Text(
            'Error al cargar tracking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _inicializarTracking,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
