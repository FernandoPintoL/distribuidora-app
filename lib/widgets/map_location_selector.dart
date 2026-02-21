import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';

// ✅ NUEVO 2026-02-18: Modelo para representar un punto de ubicación en el mapa
class MapLocation {
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final bool isSelected; // ✅ Para diferenciar la ubicación seleccionada

  MapLocation({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.isSelected = false,
  });
}

class MapLocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double, double, String?) onLocationSelected;
  final List<MapLocation>? additionalLocations; // ✅ NUEVO 2026-02-18: Ubicaciones adicionales (ventas)

  const MapLocationSelector({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.additionalLocations, // ✅ NUEVO
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
  // ✅ NUEVO 2026-02-17: Almacenar markerId para mostrar infoWindow automáticamente
  String? _markerIdToShowInfoWindow;

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

    // ✅ NUEVO 2026-02-18: Agregar marcadores de ubicaciones adicionales (ventas)
    if (widget.additionalLocations != null && widget.additionalLocations!.isNotEmpty) {
      for (final location in widget.additionalLocations!) {
        _addAdditionalMarker(location);
      }
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
        // ✅ MEJORADO 2026-02-17: Si hay ubicaciones adicionales, animar a los bounds de todos
        if (widget.additionalLocations != null && widget.additionalLocations!.isNotEmpty) {
          // Crear lista de todas las posiciones (adicionales + seleccionada si existe)
          final positions = <LatLng>[
            for (final loc in widget.additionalLocations!)
              LatLng(loc.latitude, loc.longitude),
          ];

          // Agregar posición seleccionada si existe
          if (_selectedLocation != null) {
            positions.add(_selectedLocation!);
          }

          // Calcular bounds y animar
          final bounds = _calculateBounds(positions);
          if (bounds != null) {
            _animateCameraToBounds(bounds);
          }

          // ✅ NUEVO 2026-02-17: Mostrar infoWindow automáticamente para todos los markers
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && _markerIdToShowInfoWindow != null) {
              _mapController.showMarkerInfoWindow(MarkerId(_markerIdToShowInfoWindow!));
              debugPrint('📍 InfoWindow abierto automáticamente para: $_markerIdToShowInfoWindow');
            }
          });
        } else {
          // Comportamiento original: animar a ubicación seleccionada o default
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              _selectedLocation ?? const LatLng(-25.2637, -57.5759),
              15,
            ),
          );
        }
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
    // ✅ ACTUALIZADO 2026-02-18: Mantener marcadores adicionales al agregar selección
    // Limpiar SOLO el marcador de selección anterior, no todos
    _markers.removeWhere((m) => m.markerId.value == 'selected_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Ubicación seleccionada'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  /// ✅ NUEVO 2026-02-18: Agregar marcador para ubicaciones adicionales (ventas)
  /// ✅ MEJORADO 2026-02-17: Mostrar información completa (cliente + venta) con mejor formato
  void _addAdditionalMarker(MapLocation location) {
    final markerId = MarkerId('venta_${location.hashCode}');

    // ✅ NUEVO 2026-02-17: Guardar el ID del primer marker para mostrar infoWindow automáticamente
    _markerIdToShowInfoWindow ??= markerId.value;

    _markers.add(
      Marker(
        markerId: markerId,
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: '👤 ${location.title}',
          snippet: '📦 ${location.subtitle}',
          onTap: () {
            debugPrint('📍 Ubicación: ${location.title} | Venta: ${location.subtitle}');
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  /// ✅ NUEVO 2026-02-17: Calcular bounds para mostrar todos los markers
  LatLngBounds? _calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) return null;

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat > pos.latitude ? pos.latitude : minLat;
      maxLat = maxLat < pos.latitude ? pos.latitude : maxLat;
      minLng = minLng > pos.longitude ? pos.longitude : minLng;
      maxLng = maxLng < pos.longitude ? pos.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// ✅ NUEVO 2026-02-17: Animar cámara a los bounds de todos los markers
  void _animateCameraToBounds(LatLngBounds bounds) {
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100 = padding
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
