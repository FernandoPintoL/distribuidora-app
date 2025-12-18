import 'package:flutter/material.dart';
import 'animated_action_button.dart';

/// Widget que proporciona acceso rápido a acciones frecuentes del chofer
/// Incluye botones para iniciar ruta óptima, ver mapa completo y escanear QR
class QuickActionsPanel extends StatelessWidget {
  final VoidCallback? onInitializeRoute;
  final VoidCallback? onViewAllDeliveriesMap;
  final VoidCallback? onScanQR;

  const QuickActionsPanel({
    Key? key,
    this.onInitializeRoute,
    this.onViewAllDeliveriesMap,
    this.onScanQR,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              '⚡ Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Grid de botones (3 columnas) con animaciones
            Row(
              children: [
                // Botón 1: Iniciar Ruta Óptima
                Expanded(
                  child: AnimatedActionButton(
                    icon: Icons.route,
                    label: 'Iniciar Ruta\nÓptima',
                    color: Colors.green,
                    onPressed: onInitializeRoute ?? () {},
                  ),
                ),
                const SizedBox(width: 12),

                // Botón 2: Ver Mapa Completo
                Expanded(
                  child: AnimatedActionButton(
                    icon: Icons.map,
                    label: 'Ver Todas\nen Mapa',
                    color: Colors.blue,
                    onPressed: onViewAllDeliveriesMap ?? () {},
                  ),
                ),
                const SizedBox(width: 12),

                // Botón 3: Escanear QR
                Expanded(
                  child: AnimatedActionButton(
                    icon: Icons.qr_code_2,
                    label: 'Escanear\nQR',
                    color: Colors.orange,
                    onPressed: onScanQR ?? () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
