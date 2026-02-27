import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/entrega_provider.dart';
import '../../models/venta.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class IniciarRutaScreen extends StatefulWidget {
  final int entregaId;

  const IniciarRutaScreen({
    Key? key,
    required this.entregaId,
  }) : super(key: key);

  @override
  State<IniciarRutaScreen> createState() => _IniciarRutaScreenState();
}

class _IniciarRutaScreenState extends State<IniciarRutaScreen> {
  Position? _posicionActual;
  bool _obtenienoPosicion = false;
  String? _errorPosicion;

  late GoogleMapController _mapController;
  Set<Marker> _marcadores = {};
  bool _mostrarMapa = false;
  MapType _mapType = MapType.normal;
  int? _ventaSeleccionadaId;

  @override
  void initState() {
    super.initState();
    _obtenerPosicion();
  }

  Future<void> _obtenerPosicion() async {
    setState(() {
      _obtenienoPosicion = true;
      _errorPosicion = null;
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final resultado = await Geolocator.requestPermission();
        if (resultado == LocationPermission.denied) {
          setState(() {
            _errorPosicion = 'Permiso de ubicación denegado';
            _obtenienoPosicion = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorPosicion = 'Permiso de ubicación permanentemente denegado';
          _obtenienoPosicion = false;
        });
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _posicionActual = posicion;
        _obtenienoPosicion = false;
        _mostrarMapa = true;
      });

      // Cargar marcadores de ventas
      if (mounted) {
        _cargarMarcadoresVentas();
      }
    } catch (e) {
      setState(() {
        _errorPosicion = 'Error al obtener ubicación: ${e.toString()}';
        _obtenienoPosicion = false;
      });
    }
  }

  void _cargarMarcadoresVentas() {
    final provider = context.read<EntregaProvider>();

    if (provider.entregaActual == null) {
      debugPrint('❌ No hay entrega cargada');
      return;
    }

    final entrega = provider.entregaActual!;
    final marcadores = <Marker>{};

    // Marcador de la ubicación actual (chofer)
    if (_posicionActual != null) {
      marcadores.add(
        Marker(
          markerId: const MarkerId('chofer_actual'),
          position: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
          infoWindow: const InfoWindow(
            title: '📍 Tu Ubicación',
            snippet: 'Ubicación actual del chofer',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Marcadores para cada venta
    for (int i = 0; i < entrega.ventas.length; i++) {
      final venta = entrega.ventas[i];

      if (venta.latitud != null && venta.longitud != null) {
        marcadores.add(
          Marker(
            markerId: MarkerId('venta_${venta.id}'),
            position: LatLng(venta.latitud!, venta.longitud!),
            infoWindow: InfoWindow(
              title: 'Venta #${venta.numero}',
              snippet: '${venta.clienteNombre ?? "Cliente"}\nTotal: \$${venta.total.toStringAsFixed(2)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i % 3 == 0
                  ? BitmapDescriptor.hueRed
                  : i % 3 == 1
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueYellow,
            ),
            onTap: () {
              setState(() {
                _ventaSeleccionadaId = venta.id;
              });
            },
          ),
        );

        debugPrint('[MAPA] Venta #${venta.numero}: (${venta.latitud}, ${venta.longitud})');
      }
    }

    setState(() {
      _marcadores = marcadores;
    });

    debugPrint('[MAPA] Cargados ${marcadores.length} marcadores');

    // Centrar el mapa en la primera venta (si existe)
    if (entrega.ventas.isNotEmpty && entrega.ventas.first.latitud != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(entrega.ventas.first.latitud!, entrega.ventas.first.longitud!),
          14,
        ),
      );
    }
  }

  Future<void> _iniciarRuta() async {
    if (_posicionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe obtener la ubicación')),
      );
      return;
    }

    final provider = context.read<EntregaProvider>();

    final exito = await provider.iniciarRuta(
      widget.entregaId,
      latitud: _posicionActual!.latitude,
      longitud: _posicionActual!.longitude,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ruta iniciada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EntregaProvider>();
    Venta? ventaSeleccionada;
    if (_ventaSeleccionadaId != null && provider.entregaActual != null) {
      try {
        ventaSeleccionada = provider.entregaActual!.ventas
            .firstWhere((v) => v.id == _ventaSeleccionadaId);
      } catch (e) {
        ventaSeleccionada = null;
      }
    }

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Iniciar Ruta',
        customGradient: AppGradients.green,
      ),
      body: Stack(
        children: [
          // Mapa full screen
          if (_mostrarMapa && _posicionActual != null)
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
                    14,
                  ),
                );
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
                zoom: 14,
              ),
              markers: _marcadores,
              mapType: _mapType,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_obtenienoPosicion)
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _obtenienoPosicion
                        ? 'Obteniendo ubicación...'
                        : _errorPosicion ?? 'No hay ubicación disponible',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Botón para cambiar mapType (arriba a la derecha)
          if (_mostrarMapa)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    _mapType = _mapType == MapType.normal
                        ? MapType.satellite
                        : MapType.normal;
                  });
                },
                tooltip: _mapType == MapType.normal ? 'Cambiar a Satélite' : 'Cambiar a Normal',
                child: Icon(
                  _mapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                ),
              ),
            ),

          // Panel de información de venta seleccionada (arriba)
          if (_ventaSeleccionadaId != null && ventaSeleccionada != null)
            Positioned(
              top: 16,
              left: 16,
              right: 72,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Venta #${ventaSeleccionada.numero}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ventaSeleccionada.clienteNombre ?? 'Cliente',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _ventaSeleccionadaId = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            '\$${ventaSeleccionada.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (ventaSeleccionada.latitud != null &&
                          ventaSeleccionada.longitud != null)
                        Text(
                          '📍 ${ventaSeleccionada.latitud!.toStringAsFixed(4)}, ${ventaSeleccionada.longitud!.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Botones en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<EntregaProvider>(
              builder: (context, provider, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    spacing: 8,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _iniciarRuta,
                          icon: const Icon(Icons.navigation),
                          label: Text(
                            provider.isLoading ? 'Iniciando...' : 'Iniciar Ruta',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoFila({
    Key? key,
    required this.label,
    required this.valor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
