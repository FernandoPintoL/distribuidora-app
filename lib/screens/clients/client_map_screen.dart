import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_text_styles.dart';
import '../../config/config.dart';
import '../../models/models.dart';

class ClientMapScreen extends StatefulWidget {
  final Client client;

  const ClientMapScreen({super.key, required this.client});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  late LatLngBounds _bounds;
  bool _mapsLoaded = false;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    if (widget.client.direcciones == null ||
        widget.client.direcciones!.isEmpty) {
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
            title: direccion.esPrincipal
                ? '⭐ ${direccion.direccion}'
                : direccion.direccion,
            snippet:
                '${direccion.ciudad ?? ''}, ${direccion.departamento ?? ''}'
                    .trim(),
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
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
              },
              tooltip: _mapType == MapType.normal
                  ? 'Ver satélite'
                  : 'Ver mapa normal',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: Icon(
                _mapType == MapType.normal
                    ? Icons.satellite_alt
                    : Icons.map,
              ),
            )
          : null,
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
                      fontSize: AppTextStyles.bodyLarge(context).fontSize!,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asigna coordenadas GPS a las direcciones',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodyMedium(context).fontSize!,
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
                  mapType: _mapType,
                ),

                // Panel de información deslizable en la parte inferior
                DraggableScrollableSheet(
                  initialChildSize: 0.25,
                  minChildSize: 0.15,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Indicador de arrastre
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 16),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.outline.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Información del cliente
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del cliente
                                  Text(
                                    widget.client.nombre,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodyLarge(context)
                                          .fontSize!,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Razón social
                                  if (widget.client.razonSocial != null &&
                                      widget.client.razonSocial!.isNotEmpty)
                                    Text(
                                      widget.client.razonSocial!,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.bodySmall(context)
                                            .fontSize!,
                                        color: colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // Localidad
                                  if (widget.client.localidad != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_city,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.client.localidad!.nombre,
                                          style: TextStyle(
                                            fontSize: AppTextStyles.bodySmall(
                                              context,
                                            ).fontSize!,
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 16),

                                  // Título de direcciones
                                  Text(
                                    'Direcciones (${widget.client.direcciones?.length ?? 0})',
                                    style: TextStyle(
                                      fontSize: AppTextStyles.bodyMedium(context)
                                          .fontSize!,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),

                            // Lista de direcciones
                            if (widget.client.direcciones != null &&
                                widget.client.direcciones!.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    widget.client.direcciones!.length,
                                itemBuilder: (context, index) {
                                  final direccion =
                                      widget.client.direcciones![index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.3),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: direccion.esPrincipal
                                              ? Colors.green
                                              : colorScheme.outline
                                                  .withOpacity(0.2),
                                          width: direccion.esPrincipal
                                              ? 2
                                              : 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Dirección con icono de principal
                                          Row(
                                            children: [
                                              if (direccion.esPrincipal)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  child: Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber.shade700,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  direccion.direccion,
                                                  style: TextStyle(
                                                    fontSize: AppTextStyles
                                                        .bodySmall(context)
                                                        .fontSize!,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: colorScheme
                                                        .onSurface,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Observaciones
                                          if (direccion.observaciones !=
                                                  null &&
                                              direccion.observaciones!
                                                  .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Icon(
                                                    Icons.note,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(
                                                    width: 6,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      direccion
                                                          .observaciones!,
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppTextStyles
                                                                .labelSmall(
                                                              context,
                                                            ).fontSize!,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontStyle: FontStyle
                                                            .italic,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Sin direcciones registradas',
                                  style: TextStyle(
                                    fontSize:
                                        AppTextStyles.bodySmall(context)
                                            .fontSize!,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
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
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
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
                                fontSize: AppTextStyles.bodySmall(
                                  context,
                                ).fontSize!,
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
                        fontSize: AppTextStyles.bodySmall(context).fontSize!,
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
