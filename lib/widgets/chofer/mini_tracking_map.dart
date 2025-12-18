import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../models/entrega.dart';

/// Widget que muestra un mini mapa con la ubicación del chofer y entregas cercanas
/// Se actualiza con la ubicación actual cada 10 segundos
class MiniTrackingMap extends StatefulWidget {
  final List<Entrega> entregas;
  final VoidCallback? onMapTap;

  const MiniTrackingMap({
    Key? key,
    required this.entregas,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<MiniTrackingMap> createState() => _MiniTrackingMapState();
}

class _MiniTrackingMapState extends State<MiniTrackingMap> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Obtener ubicación actual del chofer
  Future<void> _initializeLocation() async {
    try {
      // Solicitar permiso de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Permiso de ubicación denegado';
            _isLoading = false;
          });
        }
        return;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
          _addMarkers();
        });
      }

      // Actualizar ubicación cada 10 segundos
      // Cancelar subscripción anterior si existe
      _positionStreamSubscription?.cancel();

      // Crear nueva subscripción y almacenarla
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Solo actualizar si se movió 10 metros
        ),
      ).listen((Position position) {
        // Verificar que el widget sigue montado antes de llamar setState
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _addMarkers();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al obtener ubicación: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Agregar marcadores al mapa
  void _addMarkers() {
    if (_currentLocation == null) return;

    Set<Marker> markers = {};

    // Marcador de ubicación actual (azul)
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(
          title: '📍 Tu Ubicación',
          snippet: 'Posición actual del chofer',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    // Marcadores de entregas cercanas (máximo 3)
    for (int i = 0; i < widget.entregas.take(3).length; i++) {
      final entrega = widget.entregas[i];
      // Aquí usaríamos la ubicación de la entrega si estuviera disponible
      // Por ahora, creamos una ubicación ficticia cercana
      final random = (i + 1) * 0.01; // Pequeño offset para cada marcador
      final markerLocation = LatLng(
        _currentLocation!.latitude + random,
        _currentLocation!.longitude + random,
      );

      markers.add(
        Marker(
          markerId: MarkerId('entrega_${entrega.id}'),
          position: markerLocation,
          infoWindow: InfoWindow(
            title: '${entrega.tipoWorkIcon} Entrega #${entrega.id}',
            snippet: entrega.cliente ?? 'Cliente',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getColorForEstado(entrega.estado),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Obtener color del marcador según el estado
  double _getColorForEstado(String estado) {
    switch (estado) {
      case 'ASIGNADA':
        return BitmapDescriptor.hueOrange;
      case 'EN_CAMINO':
        return BitmapDescriptor.hueYellow;
      case 'ENTREGADO':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Centrar el mapa en la ubicación actual
    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16),
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
          height: 200,
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
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red[50],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
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
          height: 200,
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

    return GestureDetector(
      onTap: widget.onMapTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            // Mapa
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 16,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),
              ),
            ),

            // Badge con información
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.entregas.length} entregas cercanas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón para ampliar mapa
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                onPressed: widget.onMapTap,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.expand, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancelar la subscripción del stream de posición
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
