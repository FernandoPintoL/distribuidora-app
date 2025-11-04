import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';

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
      });
    } catch (e) {
      setState(() {
        _errorPosicion = 'Error al obtener ubicación: ${e.toString()}';
        _obtenienoPosicion = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Ruta'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucción
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se capturará tu ubicación GPS actual para iniciar la ruta',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Estado de ubicación
            if (_obtenienoPosicion) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Obteniendo ubicación...'),
                  ],
                ),
              ),
            ] else if (_errorPosicion != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorPosicion!,
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _obtenerPosicion,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_posicionActual != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green[600]),
                          const SizedBox(width: 12),
                          const Text(
                            'Ubicación capturada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoFila(
                        label: 'Latitud',
                        valor: _posicionActual!.latitude.toStringAsFixed(6),
                      ),
                      const SizedBox(height: 8),
                      _InfoFila(
                        label: 'Longitud',
                        valor: _posicionActual!.longitude.toStringAsFixed(6),
                      ),
                      const SizedBox(height: 8),
                      _InfoFila(
                        label: 'Precisión',
                        valor: '${_posicionActual!.accuracy.toStringAsFixed(2)} m',
                      ),
                      const SizedBox(height: 8),
                      _InfoFila(
                        label: 'Altitud',
                        valor: '${_posicionActual!.altitude.toStringAsFixed(2)} m',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Botones
            Consumer<EntregaProvider>(
              builder: (context, provider, _) {
                return Column(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _iniciarRuta,
                        icon: const Icon(Icons.navigation),
                        label: Text(provider.isLoading ? 'Iniciando...' : 'Iniciar Ruta'),
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
                );
              },
            ),
          ],
        ),
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
