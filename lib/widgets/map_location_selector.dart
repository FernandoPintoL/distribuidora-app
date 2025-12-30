import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class MapLocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double, double, String?) onLocationSelected;

  const MapLocationSelector({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationSelector> createState() => _MapLocationSelectorState();
}

class _MapLocationSelectorState extends State<MapLocationSelector> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  final Set<Marker> _markers = {};
  bool _isMapLoading = true;
  bool _hasMapError = false;
  bool _hasLocationPermission = false;
  MapType _mapType = MapType.normal;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : null;

    if (_selectedLocation != null) {
      _addMarker(_selectedLocation!);
      _getAddressFromCoordinates(_selectedLocation!);
    }

    // Verificar permisos de ubicación
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final hasPermission = await _locationService.requestLocationPermission();
    setState(() {
      _hasLocationPermission = hasPermission;
    });
    debugPrint('📍 Permisos de ubicación en mapa: $_hasLocationPermission');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Verificar si el mapa se cargó correctamente
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isMapLoading) {
        // Si después de 3 segundos aún está cargando, mostrar un mensaje de error
        setState(() {
          _isMapLoading = false;
          _hasMapError = true;
        });
      }
    });

    // Marcar que el mapa terminó de cargar
    setState(() {
      _isMapLoading = false;
      _hasMapError = false;
    });

    // Agregar un pequeño delay para asegurar que el mapa se cargue correctamente
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            _selectedLocation ?? const LatLng(-25.2637, -57.5759),
            15,
          ),
        );
      }
    });
  }

  void _reloadMap() {
    setState(() {
      _isMapLoading = true;
      _hasMapError = false;
    });

    // Forzar la recreación del mapa
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    });
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _addMarker(position);
    });
    _getAddressFromCoordinates(position);

    // Animar la cámara hacia la ubicación seleccionada
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 18));
  }

  void _addMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Ubicación seleccionada'),
      ),
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].join(', ');

        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Dirección no disponible';
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedAddress,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition =
        _selectedLocation ??
        const LatLng(
          -25.2637,
          -57.5759,
        ); // Posición inicial en Asunción, Paraguay

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          IconButton(
            onPressed: _toggleMapType,
            icon: Icon(
              _mapType == MapType.normal ? Icons.satellite : Icons.map,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: _mapType == MapType.normal ? 'Vista satelital' : 'Vista normal',
          ),
          if (_selectedLocation != null)
            TextButton(
              onPressed: _confirmLocation,
              child: Text(
                'Confirmar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 15,
                  ),
                  onTap: _onTap,
                  markers: _markers,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: _hasLocationPermission,
                  mapType: _mapType,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                  indoorViewEnabled: false,
                  liteModeEnabled: false,
                  padding: const EdgeInsets.all(0),
                ),
                if (_isMapLoading)
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando mapa...'),
                          SizedBox(height: 8),
                          Text(
                            'Si tarda demasiado, verifica tu conexión a internet',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_hasMapError)
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar el mapa',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Verifica tu conexión a internet y la configuración de Google Maps',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reloadMap,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_hasLocationPermission && !_isMapLoading && !_hasMapError)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Se requieren permisos de ubicación para ver tu posición actual',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.grey[100],
              child: Text(
                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
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
