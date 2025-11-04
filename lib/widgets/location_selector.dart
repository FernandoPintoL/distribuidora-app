import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_location_selector.dart';

class LocationSelector extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double?, double?, String?) onLocationSelected;
  final bool autoGetLocation;

  const LocationSelector({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.autoGetLocation = true,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    if (widget.autoGetLocation && (_latitude == null || _longitude == null)) {
      _getCurrentLocation();
    } else if (_latitude != null && _longitude != null) {
      _getAddressFromCoordinates(_latitude!, _longitude!);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      setState(() {
        _errorMessage = 'Permiso de ubicación denegado';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se necesita permiso de ubicación para obtener la posición actual',
            ),
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Permiso de ubicación denegado permanentemente';
      });
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _requestLocationPermission();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      await _getAddressFromCoordinates(_latitude!, _longitude!);

      // Esperar un poco para asegurar que la dirección se haya obtenido
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onLocationSelected(_latitude, _longitude, _address);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ubicación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
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
          _address = address;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Dirección no disponible';
      });
    }
  }

  void _openMapSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationSelector(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          onLocationSelected: (lat, lng, address) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
              _address = address;
            });
            widget.onLocationSelected(_latitude, _longitude, _address);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isLoading
                      ? 'Obteniendo ubicación...'
                      : 'Obtener ubicación actual',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _openMapSelector,
              icon: const Icon(Icons.map),
              tooltip: 'Seleccionar en mapa',
            ),
          ],
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        /* if (_address != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.outline
                      : Colors.grey[300]!,
                ),
              ),
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
                      _address!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), */
        if (_latitude != null && _longitude != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Coordenadas: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }
}
