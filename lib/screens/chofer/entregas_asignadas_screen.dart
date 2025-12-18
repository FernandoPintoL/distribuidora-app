import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/distance_badge.dart';
import '../../config/config.dart';

class EntregasAsignadasScreen extends StatefulWidget {
  const EntregasAsignadasScreen({Key? key}) : super(key: key);

  @override
  State<EntregasAsignadasScreen> createState() =>
      _EntregasAsignadasScreenState();
}

class _EntregasAsignadasScreenState extends State<EntregasAsignadasScreen> {
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _cargarEntregas();
  }

  Future<void> _cargarEntregas() async {
    final provider = context.read<EntregaProvider>();
    await provider.obtenerEntregasAsignadas(estado: _filtroEstado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: CustomGradientAppBar(
        title: 'Entregas Asignadas',
        customGradient: AppGradients.green,
      ), */
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.entregas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay entregas ni envios',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las entregas y envios aparecerán aquí cuando se asignen',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _cargarEntregas,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.entregas.length,
              itemBuilder: (context, index) {
                final entrega = provider.entregas[index];
                return _EntregaCard(entrega: entrega);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EntregaCard extends StatefulWidget {
  final Entrega entrega;

  const _EntregaCard({Key? key, required this.entrega}) : super(key: key);

  @override
  State<_EntregaCard> createState() => _EntregaCardState();
}

class _EntregaCardState extends State<_EntregaCard> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    _initializeMapLocation();
  }

  Future<void> _initializeMapLocation() async {
    try {
      // Solicitar permiso de ubicación si es necesario
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.deniedForever &&
          permission != LocationPermission.denied) {
        // Obtener posición actual
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _addMarkers();
          _isLoadingMap = false;
        });
      } else {
        setState(() {
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

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
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );

    // Marcador de la entrega (naranja/rojo)
    // Ubicación ficticia cercana para demostración
    final deliveryLocation = LatLng(
      _currentLocation!.latitude + 0.01,
      _currentLocation!.longitude + 0.01,
    );

    markers.add(
      Marker(
        markerId: MarkerId('entrega_${widget.entrega.id}'),
        position: deliveryLocation,
        infoWindow: InfoWindow(
          title: '${widget.entrega.tipoWorkIcon} Entrega #${widget.entrega.id}',
          snippet: widget.entrega.cliente ?? 'Cliente',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorEstado(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.entrega.tipoWorkIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTituloTrabajo(widget.entrega),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.entrega.numero ?? '#${widget.entrega.id}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini Mapa
          if (_isLoadingMap)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_currentLocation != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: SizedBox(
                    height: 150,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                    ),
                  ),
                ),
                // Badge con distancia y tiempo
                Positioned(
                  top: 12,
                  right: 12,
                  child: DistanceBadge(
                    distanceKm: 2.5, // Placeholder - en production calcular real
                    estimatedMinutes: 8,
                  ),
                ),
              ],
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: const Center(
                child: Text('Ubicación no disponible'),
              ),
            ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente
                if (widget.entrega.cliente != null &&
                    widget.entrega.cliente!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Cliente',
                    value: widget.entrega.cliente!,
                  ),
                  const SizedBox(height: 8),
                ],
                // Dirección
                if (widget.entrega.direccion != null &&
                    widget.entrega.direccion!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: widget.entrega.direccion!,
                  ),
                  const SizedBox(height: 8),
                ],
                // Información de fecha
                if (widget.entrega.fechaAsignacion != null) ...[
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Asignada',
                    value: widget.entrega.formatFecha(
                        widget.entrega.fechaAsignacion),
                  ),
                  const SizedBox(height: 8),
                ],
                // Observaciones
                if (widget.entrega.observaciones != null &&
                    widget.entrega.observaciones!.isNotEmpty) ...[
                  const Text(
                    'Observaciones:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.entrega.observaciones!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 8,
              children: [
                _BotonAccion(
                  label: 'Ver Detalles',
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/chofer/entrega-detalle',
                      arguments: widget.entrega.id,
                    );
                  },
                ),
                _BotonAccion(
                  label: 'Cómo llegar',
                  icon: Icons.map,
                  color: Colors.orange,
                  onPressed: _openInGoogleMaps,
                ),
                if (widget.entrega.puedeIniciarRuta)
                  _BotonAccion(
                    label: 'Iniciar Ruta',
                    icon: Icons.navigation,
                    color: Colors.green,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/chofer/iniciar-ruta',
                        arguments: widget.entrega.id,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado() {
    final colorHex = widget.entrega.estadoColor;
    // Convertir hex a Color
    return Color(int.parse('0xff${colorHex.substring(1)}'));
  }

  String _getTituloTrabajo(Entrega entrega) {
    if (entrega.trabajoType == 'entrega') {
      return 'Entrega Directa #${entrega.id}';
    } else if (entrega.trabajoType == 'envio') {
      return 'Envío #${entrega.id}';
    }
    return 'Trabajo #${entrega.id}';
  }

  /// Abrir ubicación en Google Maps
  Future<void> _openInGoogleMaps() async {
    final address = widget.entrega.direccion ?? '';
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dirección no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/$address',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_currentLocation != null) {
      _mapController.dispose();
    }
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _BotonAccion({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
