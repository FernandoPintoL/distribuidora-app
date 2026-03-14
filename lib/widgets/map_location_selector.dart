import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';

// ✅ NUEVO 2026-03-12: Helper para convertir color hex a hue de BitmapDescriptor
double _hexToHue(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return BitmapDescriptor.hueRed; // Default red if no color provided
  }

  try {
    // Remover # si existe
    final cleanHex = hexColor.replaceFirst('#', '');
    final rgb = int.parse(cleanHex, radix: 16);

    // Extraer componentes RGB
    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;

    // Convertir RGB a HSL
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final h = _calculateHue(r, g, b, max, min);

    return h;
  } catch (e) {
    debugPrint('❌ Error convirtiendo color hex a hue: $hexColor - $e');
    return BitmapDescriptor.hueRed;
  }
}

// ✅ Helper para calcular hue en HSL
double _calculateHue(double r, double g, double b, double max, double min) {
  final delta = max - min;

  double hue = 0.0;
  if (delta != 0) {
    if (max == r) {
      hue = 60 * ((g - b) / delta % 6);
    } else if (max == g) {
      hue = 60 * ((b - r) / delta + 2);
    } else {
      hue = 60 * ((r - g) / delta + 4);
    }
  }

  // Normalizar a rango 0-359.999
  if (hue < 0) hue += 360;
  return hue;
}

// ✅ NUEVO 2026-02-18: Modelo para representar un punto de ubicación en el mapa
class MapLocation {
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final bool isSelected; // ✅ Para diferenciar la ubicación seleccionada
  // ✅ MEJORADO: Campos adicionales para mostrar más información en el mapa
  final String? razonSocial;
  final String? telefono;
  final int? ventaId;
  final String? markerColor; // ✅ NUEVO 2026-03-12: Color hex para el pin en el mapa (ej: "#FF6B6B")

  MapLocation({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.isSelected = false,
    this.razonSocial,
    this.telefono,
    this.ventaId,
    this.markerColor,
  });
}

class MapLocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double, double, String?) onLocationSelected;
  final List<MapLocation>? additionalLocations; // ✅ NUEVO 2026-02-18: Ubicaciones adicionales (ventas)
  final Function(int ventaId)? onVentaSelected; // ✅ NUEVO: Callback cuando se toca una venta en el mapa

  const MapLocationSelector({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.additionalLocations, // ✅ NUEVO
    this.onVentaSelected, // ✅ NUEVO
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
  /// ✅ MEJORADO: Mostrar información completa (cliente, razón social, teléfono, venta, ID)
  void _addAdditionalMarker(MapLocation location) {
    final markerId = MarkerId('venta_${location.hashCode}');

    // ✅ NUEVO 2026-02-17: Guardar el ID del primer marker para mostrar infoWindow automáticamente
    _markerIdToShowInfoWindow ??= markerId.value;

    // ✅ Construir snippet compacto en una sola línea (sin saltos de línea)
    final snippetParts = <String>[];

    if (location.razonSocial != null && location.razonSocial!.isNotEmpty) {
      snippetParts.add('🏢 ${location.razonSocial}');
    }

    if (location.telefono != null && location.telefono!.isNotEmpty) {
      snippetParts.add('📱 ${location.telefono}');
    }

    if (location.subtitle != null && location.subtitle!.isNotEmpty) {
      snippetParts.add('📦 ${location.subtitle}');
    }

    if (location.ventaId != null) {
      snippetParts.add('🔑 ${location.ventaId}');
    }

    // ✅ Usar separador '|' sin saltos de línea para mejor compatibilidad
    final snippet = snippetParts.isEmpty ? 'Sin información' : snippetParts.join(' | ');

    // ✅ NUEVO 2026-03-12: Convertir color hex a hue para el pin
    final markerHue = _hexToHue(location.markerColor);

    _markers.add(
      Marker(
        markerId: markerId,
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: '👤 ${location.title}',
          snippet: snippet,
          onTap: () {
            debugPrint(
              '📍 Cliente: ${location.title} | Razón Social: ${location.razonSocial} | \n'
              'Teléfono: ${location.telefono} | Venta: ${location.subtitle} | ID: ${location.ventaId} | Color: ${location.markerColor}',
            );

            // ✅ NUEVO: Llamar callback si existe ventaId y se proporcionó onVentaSelected
            if (location.ventaId != null && widget.onVentaSelected != null) {
              widget.onVentaSelected!(location.ventaId!);
            }
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
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

    // ✅ NUEVO 2026-03-12: Calcular cantidad de ubicaciones adicionales (ventas)
    final cantidadVentas = widget.additionalLocations?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mapa de Entregas'),
            const SizedBox(width: 12),
            // ✅ NUEVO: Badge con cantidad de ventas
            if (cantidadVentas > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cantidadVentas ${cantidadVentas == 1 ? 'venta' : 'ventas'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
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
