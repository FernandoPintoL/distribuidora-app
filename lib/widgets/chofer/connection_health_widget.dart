import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import 'dart:math';

/// Widget que muestra el estado de salud de conectividad completo
/// Incluye: WebSocket, GPS y Batería
class ConnectionHealthWidget extends StatefulWidget {
  final bool isTracking;
  final Position? ultimaUbicacion;
  final VoidCallback? onRetryGps; // Callback para reintentar GPS

  const ConnectionHealthWidget({
    Key? key,
    required this.isTracking,
    required this.ultimaUbicacion,
    this.onRetryGps,
  }) : super(key: key);

  @override
  State<ConnectionHealthWidget> createState() => _ConnectionHealthWidgetState();
}

class _ConnectionHealthWidgetState extends State<ConnectionHealthWidget> {
  late Battery _battery;
  int _batteryLevel = 0;
  late Timer _batteryUpdateTimer;

  @override
  void initState() {
    super.initState();
    _battery = Battery();
    _initBattery();
  }

  void _initBattery() async {
    try {
      // Obtener nivel inicial de batería
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }

      // Actualizar nivel de batería cada 10 segundos
      _batteryUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final level = await _battery.batteryLevel;
          if (mounted) {
            setState(() {
              _batteryLevel = level;
            });
          }
        } catch (e) {
          debugPrint('Error actualizando batería: $e');
        }
      });
    } catch (e) {
      debugPrint('Error inicializando batería: $e');
    }
  }

  @override
  void dispose() {
    _batteryUpdateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 20,
                  color: _getOverallHealthColor(),
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado de Conectividad',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // WebSocket Status
            _buildConnectionRow(
              context,
              icon: Icons.wifi,
              label: 'WebSocket',
              status: 'Conectado', // TODO: Obtener del service real
              color: Colors.green,
              subtitle: 'En vivo',
            ),

            const SizedBox(height: 12),

            // GPS Status
            _buildConnectionRow(
              context,
              icon: Icons.gps_fixed,
              label: 'GPS',
              status: _getGpsStatus(),
              color: _getGpsStatusColor(),
              subtitle: _getGpsSubtitle(),
            ),

            const SizedBox(height: 12),

            // Batería Status
            _buildConnectionRow(
              context,
              icon: _getBatteryIcon(),
              label: 'Batería',
              status: '$_batteryLevel%',
              color: _getBatteryColor(),
              subtitle: _getBatterySubtitle(),
            ),

            // Botón de reintentar si hay problemas con GPS
            if (_getGpsStatusColor() == Colors.red && widget.onRetryGps != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onRetryGps,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construir fila de estado de conexión
  Widget _buildConnectionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String status,
    required Color color,
    required String subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ======================== MÉTODOS HELPER ========================

  /// Obtener color de salud general
  Color _getOverallHealthColor() {
    // Si hay problemas críticos, rojo
    if (_batteryLevel < 10 || !widget.isTracking) {
      return Colors.red;
    }
    // Si hay advertencias, amarillo
    if (_batteryLevel < 20 || _getGpsStatusColor() == Colors.amber) {
      return Colors.amber;
    }
    // Si todo está bien, verde
    return Colors.green;
  }

  /// Obtener estado GPS
  String _getGpsStatus() {
    if (!widget.isTracking) {
      return 'Inactivo';
    }
    if (widget.ultimaUbicacion == null) {
      return 'Sin señal';
    }
    if (widget.ultimaUbicacion!.accuracy < 20) {
      return 'Excelente';
    }
    if (widget.ultimaUbicacion!.accuracy < 50) {
      return 'Aceptable';
    }
    return 'Pobre';
  }

  /// Obtener color de estado GPS
  Color _getGpsStatusColor() {
    if (!widget.isTracking || widget.ultimaUbicacion == null) {
      return Colors.grey;
    }

    final timeDiff = DateTime.now().difference(widget.ultimaUbicacion!.timestamp);

    // Si pasó más de 60 segundos sin actualizar, es un problema crítico
    if (timeDiff.inSeconds > 60) {
      return Colors.red;
    }

    // Si está desactualizado (30-60s), es una advertencia
    if (timeDiff.inSeconds > 30) {
      return Colors.amber;
    }

    // Basarse en precisión
    if (widget.ultimaUbicacion!.accuracy < 20) {
      return Colors.green;
    }
    if (widget.ultimaUbicacion!.accuracy < 50) {
      return Colors.amber;
    }
    return Colors.red;
  }

  /// Obtener subtítulo de GPS
  String _getGpsSubtitle() {
    if (!widget.isTracking) {
      return 'Detenido';
    }
    if (widget.ultimaUbicacion == null) {
      return 'Sin señal';
    }

    final accuracy = widget.ultimaUbicacion!.accuracy.toStringAsFixed(1);
    final timeDiff = DateTime.now().difference(widget.ultimaUbicacion!.timestamp);

    if (timeDiff.inSeconds < 15) {
      return '$accuracy m';
    }
    if (timeDiff.inSeconds < 30) {
      return '$accuracy m • ${timeDiff.inSeconds}s';
    }
    return '${timeDiff.inSeconds}s atrás';
  }

  /// Obtener ícono de batería
  IconData _getBatteryIcon() {
    if (_batteryLevel > 50) {
      return Icons.battery_full;
    }
    if (_batteryLevel > 20) {
      return Icons.battery_5_bar;
    }
    return Icons.battery_alert;
  }

  /// Obtener color de batería
  Color _getBatteryColor() {
    if (_batteryLevel > 50) {
      return Colors.green;
    }
    if (_batteryLevel > 20) {
      return Colors.amber;
    }
    return Colors.red;
  }

  /// Obtener subtítulo de batería
  String _getBatterySubtitle() {
    if (_batteryLevel > 50) {
      return 'Normal';
    }
    if (_batteryLevel > 20) {
      return 'Baja';
    }
    return 'Crítica';
  }
}

/// Widget auxiliar para fila de estado (no utilizado ahora, pero disponible para extensiones)
class _ConnectionHealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color color;

  const _ConnectionHealthRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
