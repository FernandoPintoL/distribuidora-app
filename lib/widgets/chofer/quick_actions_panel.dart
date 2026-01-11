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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cardColor,
      shadowColor: isDarkMode
          ? Colors.black.withAlpha((0.5 * 255).toInt())
          : Colors.grey.withAlpha((0.3 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Acciones Rápidas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),

                // Botón 3: Escanear QR
                Expanded(
                  child: AnimatedActionButton(
                    icon: Icons.qr_code_2,
                    label: 'Escanear\nQR',
                    color: Colors.purple,
                    onPressed: onScanQR ?? () {},
                    isDarkMode: isDarkMode,
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
