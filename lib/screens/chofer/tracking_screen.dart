import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/chofer/real_time_tracking_widget.dart';
import '../../widgets/chofer/route_info_panel.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

/// Pantalla de tracking en tiempo real para choferes
/// Muestra ubicación en vivo, marcadores de entregas y estadísticas de ruta
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Position? _currentPosition;
  bool _isLoadingPosition = true;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingPosition = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingPosition = false;
      });
    } catch (e) {
      debugPrint('Error getting position: $e');
      setState(() {
        _isLoadingPosition = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Tracking en Vivo',
        customGradient: AppGradients.green,
        actions: [
          // Botón para refrescar ubicación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: GestureDetector(
                onTap: _getCurrentPosition,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.location_on, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Actualizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<EntregaProvider>(
        builder: (context, entregaProvider, _) {
          if (entregaProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (entregaProvider.entregas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay entregas pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Has completado todas tus entregas del día!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al Dashboard'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mapa de tracking en tiempo real
                RealTimeTrackingWidget(
                  entregas: entregaProvider.entregas,
                  updateInterval: const Duration(seconds: 10),
                ),
                const SizedBox(height: 8),

                // Panel de información de ruta
                RouteInfoPanel(
                  entregas: entregaProvider.entregas,
                  currentLatitude: _currentPosition?.latitude,
                  currentLongitude: _currentPosition?.longitude,
                ),

                const SizedBox(height: 16),

                // Información adicional
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leyenda del Mapa',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MapLegendItem(
                        color: Colors.blue,
                        label: 'Tu ubicación actual',
                      ),
                      const SizedBox(height: 8),
                      _MapLegendItem(
                        color: Colors.blue,
                        label: 'Asignada',
                      ),
                      const SizedBox(height: 8),
                      _MapLegendItem(
                        color: Colors.yellow,
                        label: 'En Camino',
                      ),
                      const SizedBox(height: 8),
                      _MapLegendItem(
                        color: Colors.orange,
                        label: 'Llegó',
                      ),
                      const SizedBox(height: 8),
                      _MapLegendItem(
                        color: Colors.red,
                        label: 'Novedad',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget para mostrar ítems de leyenda del mapa
class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendItem({
    Key? key,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
