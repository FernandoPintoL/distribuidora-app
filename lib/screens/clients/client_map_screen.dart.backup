import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/models.dart';

class ClientMapScreen extends StatefulWidget {
  final Client client;

  const ClientMapScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  late LatLngBounds _bounds;
  bool _mapsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    if (widget.client.direcciones == null || widget.client.direcciones!.isEmpty) {
      return;
    }

    double minLat = widget.client.direcciones!.first.latitud ?? 0;
    double maxLat = minLat;
    double minLng = widget.client.direcciones!.first.longitud ?? 0;
    double maxLng = minLng;

    for (int i = 0; i < widget.client.direcciones!.length; i++) {
      final direccion = widget.client.direcciones![i];

      if (direccion.latitud == null || direccion.longitud == null) continue;

      final lat = direccion.latitud!;
      final lng = direccion.longitud!;

      // Actualizar bounds
      minLat = minLat > lat ? lat : minLat;
      maxLat = maxLat < lat ? lat : maxLat;
      minLng = minLng > lng ? lng : minLng;
      maxLng = maxLng < lng ? lng : maxLng;

      // Crear marcador
      _markers.add(
        Marker(
          markerId: MarkerId('direccion_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: direccion.esPrincipal ? '⭐ ${direccion.direccion}' : direccion.direccion,
            snippet: '${direccion.ciudad ?? ''}, ${direccion.departamento ?? ''}'.trim(),
          ),
          icon: direccion.esPrincipal
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Calcular bounds con padding
    _bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapsLoaded = true;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Esperar un frame para que el mapa se dibuje
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _mapsLoaded && _markers.isNotEmpty) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(_bounds, 100),
        );
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicaciones de ${widget.client.nombre}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _markers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay coordenadas disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asigna coordenadas GPS a las direcciones',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Mapa
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.client.direcciones?.first.latitud ?? 0,
                      widget.client.direcciones?.first.longitud ?? 0,
                    ),
                    zoom: 15,
                  ),
                  markers: _markers,
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                ),

                // Leyenda en la esquina inferior izquierda
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Otras direcciones',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Contador de direcciones en la esquina superior derecha
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_markers.length} ubicación${_markers.length > 1 ? 'es' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
