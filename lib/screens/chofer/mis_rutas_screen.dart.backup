import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ruta.dart';
import '../../providers/ruta_provider.dart';
import '../../services/websocket_service.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class MisRutasScreen extends StatefulWidget {
  const MisRutasScreen({Key? key}) : super(key: key);

  @override
  State<MisRutasScreen> createState() => _MisRutasScreenState();
}

class _MisRutasScreenState extends State<MisRutasScreen> {
  late RutaProvider _rutaProvider;
  String _filtroEstado = 'todas'; // todas, planificada, en_progreso, completada

  @override
  void initState() {
    super.initState();
    _rutaProvider = context.read<RutaProvider>();

    // Inicializar listeners de WebSocket para rutas
    _rutaProvider.inicializarListenersRutas(
      onRutaNueva: _mostrarNotificacionRutaNueva,
      onRutaModificada: _mostrarNotificacionRutaModificada,
      onParadaActualizada: _mostrarNotificacionParadaActualizada,
    );
  }

  /// Mostrar notificación cuando se asigna una ruta nueva
  void _mostrarNotificacionRutaNueva() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('📍 Nueva ruta asignada',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionRutaModificada() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child:
                  Text('📝 Ruta modificada', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarNotificacionParadaActualizada() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('📦 Parada actualizada',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mis Rutas',
        customGradient: AppGradients.green,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<RutaProvider>(
              builder: (context, rutaProvider, _) {
                final wsService = WebSocketService();
                return StreamBuilder<bool>(
                  stream: wsService.connectionStream,
                  builder: (context, snapshot) {
                    final connected = snapshot.data ?? false;
                    return Tooltip(
                      message: connected ? 'Conectado' : 'Desconectado',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: connected ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              connected ? 'En línea' : 'Sin conexión',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<RutaProvider>(
        builder: (context, rutaProvider, _) {
          // Filtrar rutas
          List<Ruta> rutasFiltradas = rutaProvider.rutas;
          if (_filtroEstado != 'todas') {
            rutasFiltradas = rutasFiltradas
                .where((r) => r.estado == _filtroEstado)
                .toList();
          }

          return Column(
            children: [
              // Chips de filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildFilterChip('Todas', 'todas', rutaProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Planificadas', 'planificada', rutaProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'En Progreso', 'en_progreso', rutaProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Completadas', 'completada', rutaProvider),
                  ],
                ),
              ),

              // Lista de rutas
              if (rutasFiltradas.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay rutas $_filtroEstado',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las nuevas rutas aparecerán aquí',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: rutasFiltradas.length,
                    itemBuilder: (context, index) {
                      final ruta = rutasFiltradas[index];
                      return _buildRutaCard(ruta, context);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, RutaProvider rutaProvider) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = value;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.7),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRutaCard(Ruta ruta, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ExpansionTile(
        title: Row(
          children: [
            // Icono de estado
            _buildEstadoIcon(ruta),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${ruta.cantidadParadas} paradas • ${ruta.distanciaKm?.toStringAsFixed(1) ?? 'N/A'} km',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Badge de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEstadoColor(ruta.estado),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ruta.estadoTexto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de Vehículo
                _buildInfoRow(
                  icon: Icons.directions_car,
                  label: 'Vehículo',
                  value: ruta.vehiculoPlaca,
                ),
                const Divider(),

                // Información de horarios
                if (ruta.horaSalida != null)
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Hora Salida',
                    value: _formatTime(ruta.horaSalida),
                  ),
                if (ruta.horaLlegada != null)
                  _buildInfoRow(
                    icon: Icons.check_circle,
                    label: 'Hora Llegada',
                    value: _formatTime(ruta.horaLlegada),
                  ),
                if (ruta.tiempoEstimadoMinutos != null)
                  _buildInfoRow(
                    icon: Icons.schedule,
                    label: 'Tiempo Estimado',
                    value: '${ruta.tiempoEstimadoMinutos} min',
                  ),

                const SizedBox(height: 12),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _abrirDetalleRuta(ruta),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalles'),
                    ),
                    if (ruta.estaPlanificada)
                      ElevatedButton.icon(
                        onPressed: () =>
                            _iniciarRuta(ruta),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIcon(Ruta ruta) {
    IconData icon;
    Color color;

    if (ruta.estaPlanificada) {
      icon = Icons.schedule;
      color = Colors.blue;
    } else if (ruta.estaEnProgreso) {
      icon = Icons.directions_run;
      color = Colors.orange;
    } else {
      icon = Icons.check_circle;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'planificada':
        return Colors.blue;
      case 'en_progreso':
        return Colors.orange;
      case 'completada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value ?? 'N/A',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _abrirDetalleRuta(Ruta ruta) {
    context.read<RutaProvider>().establecerRutaActual(ruta);
    // TODO: Navegar a RutaDetalleScreen(rutaId: ruta.id)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abriendo detalles de ${ruta.codigo}')),
    );
  }

  void _iniciarRuta(Ruta ruta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando ruta ${ruta.codigo}...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Llamar a API para marcar ruta como "en_progreso"
  }
}
