import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/entrega.dart';

/// Widget que muestra tracking en tiempo real del chofer
/// Actualiza ubicación y marcadores dinámicamente mientras se desplaza
class RealTimeTrackingWidget extends StatefulWidget {
  final List<Entrega> entregas;
  final Duration updateInterval;

  const RealTimeTrackingWidget({
    Key? key,
    required this.entregas,
    this.updateInterval = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  State<RealTimeTrackingWidget> createState() => _RealTimeTrackingWidgetState();
}

class _RealTimeTrackingWidgetState extends State<RealTimeTrackingWidget> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _errorMessage;
  late Stream<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      // Solicitar permiso de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado permanentemente';
          _isLoading = false;
        });
        return;
      }

      // Obtener posición inicial
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateMarkersAndPolylines();
        _isLoading = false;
      });

      // Escuchar cambios de ubicación en tiempo real
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Actualizar si se movió 5 metros
          timeLimit: widget.updateInterval,
        ),
      );

      _positionStream.listen((Position position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _updateMarkersAndPolylines();
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar tracking: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error en tracking: $e');
    }
  }

  void _updateMarkersAndPolylines() {
    if (_currentLocation == null) return;

    Set<Marker> markers = {};
    List<LatLng> routePoints = [];

    // Marcador de ubicación actual (azul)
    markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(
          title: '📍 Mi Ubicación',
          snippet: 'Tu posición actual',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    routePoints.add(_currentLocation!);

    // Marcadores de entregas pendientes
    final pendingEntregas = widget.entregas
        .where((e) => e.estado != 'ENTREGADO' && e.estado != 'CANCELADA')
        .toList();

    for (int i = 0; i < pendingEntregas.length; i++) {
      final entrega = pendingEntregas[i];
      // Generar ubicación ficticia basada en índice para demostración
      final markerLocation = LatLng(
        _currentLocation!.latitude + ((i + 1) * 0.007),
        _currentLocation!.longitude + ((i + 1) * 0.007),
      );

      routePoints.add(markerLocation);

      // Color según estado
      final hue = _getColorHueForEstado(entrega.estado);

      markers.add(
        Marker(
          markerId: MarkerId('entrega_${entrega.id}'),
          position: markerLocation,
          infoWindow: InfoWindow(
            title: '${entrega.tipoWorkIcon} #${entrega.id}',
            snippet: '${entrega.cliente ?? 'Cliente'} - ${entrega.estadoLabel}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }

    // Polilínea conectando la ruta
    Set<Polyline> polylines = {};
    if (routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.green,
          width: 4,
          geodesic: true,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  double _getColorHueForEstado(String estado) {
    switch (estado) {
      case 'ASIGNADA':
        return BitmapDescriptor.hueBlue;
      case 'EN_CAMINO':
        return BitmapDescriptor.hueYellow;
      case 'LLEGO':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  void _centerMap() {
    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red[50],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_currentLocation == null) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Text('Ubicación no disponible'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        children: [
          // Mapa
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 350,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
              ),
            ),
          ),

          // Botón para centrar en ubicación actual
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              onPressed: _centerMap,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, size: 20),
            ),
          ),

          // Badge con información de entregas
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.entregas.length} entregas',
                    style: const TextStyle(
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
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
