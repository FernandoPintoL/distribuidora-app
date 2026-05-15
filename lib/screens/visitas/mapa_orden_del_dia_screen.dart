import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/orden_del_dia.dart';
import '../../config/config.dart';

class MapaOrdenDelDiaScreen extends StatefulWidget {
  final List<ClienteOrdenDelDia> clientes;

  const MapaOrdenDelDiaScreen({super.key, required this.clientes});

  @override
  State<MapaOrdenDelDiaScreen> createState() => _MapaOrdenDelDiaScreenState();
}

class _MapaOrdenDelDiaScreenState extends State<MapaOrdenDelDiaScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  MapType _mapType = MapType.normal;
  ClienteOrdenDelDia? _clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final cliente in widget.clientes) {
      final lat = cliente.direccion.latitud;
      final lng = cliente.direccion.longitud;

      if (lat == null || lng == null) continue;

      final hue = cliente.visitado
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueYellow;

      markers.add(
        Marker(
          markerId: MarkerId('cliente_${cliente.clienteId}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: cliente.nombre,
            snippet: cliente.direccion.direccion ?? 'Sin dirección',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            setState(() => _clienteSeleccionado = cliente);
          },
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;

    final positions = _markers.map((m) => m.position).toList();

    if (positions.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(positions[0], 15),
      );
      return;
    }

    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (final pos in positions) {
      minLat = pos.latitude < minLat ? pos.latitude : minLat;
      maxLat = pos.latitude > maxLat ? pos.latitude : maxLat;
      minLng = pos.longitude < minLng ? pos.longitude : minLng;
      maxLng = pos.longitude > maxLng ? pos.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitados = widget.clientes
        .where((c) => c.visitado && c.direccion.latitud != null && c.direccion.longitud != null)
        .length;
    final pendientes = _markers.length - visitados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Visitas'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppGradients.teal),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _mapType == MapType.satellite
                  ? Icons.map_outlined
                  : Icons.satellite_alt,
              color: Colors.white,
            ),
            tooltip: 'Cambiar vista',
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.satellite
                    ? MapType.normal
                    : MapType.satellite;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 10,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), _fitMarkersInView);
            },
            markers: _markers,
            mapType: _mapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Leyenda (arriba a la derecha)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Visitado',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pendiente',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Barra de estadísticas (abajo)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$visitados visitados',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$pendientes pendientes',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        'Total: ${_markers.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_clienteSeleccionado != null) ...[
                    const SizedBox(height: 12),
                    _buildClienteDetailCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteDetailCard() {
    final cliente = _clienteSeleccionado!;
    return GestureDetector(
      onTap: () {}, // Evita cerrar la tarjeta al tocar dentro
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cliente.visitado ? Colors.green : Colors.amber,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cliente.direccion.direccion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          cliente.direccion.direccion!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _clienteSeleccionado = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (cliente.visitado && cliente.visitadoALas != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.done_all, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Visitado a las ${cliente.visitadoALas}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
