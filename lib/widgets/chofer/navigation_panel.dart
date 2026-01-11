import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Panel de navegación con opciones para dirigirse a un destino
/// Proporciona acceso a Google Maps, Waze y navegación integrada
class NavigationPanel extends StatelessWidget {
  final String clientName;
  final String address;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final VoidCallback? onOpenInAppNavigation;

  const NavigationPanel({
    Key? key,
    required this.clientName,
    required this.address,
    this.destinationLatitude,
    this.destinationLongitude,
    this.onOpenInAppNavigation,
  }) : super(key: key);

  /// Abrir ubicación en Google Maps
  Future<void> _openInGoogleMaps() async {
    if (destinationLatitude == null || destinationLongitude == null) {
      // Fallback: buscar por dirección
      final url = Uri.parse(
        'https://www.google.com/maps/search/$address',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Abrir ubicación en Waze
  Future<void> _openInWaze() async {
    if (destinationLatitude == null || destinationLongitude == null) {
      return;
    }

    final url = Uri.parse(
      'https://waze.com/ul?ll=$destinationLatitude,$destinationLongitude&navigate=yes',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

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
            // Encabezado
            Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navegación',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      /* Text(
                        clientName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ), */
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dirección
            /* Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16), */

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Google Maps
                _NavigationIconButton(
                  icon: Icons.map,
                  label: 'Google Maps',
                  color: Colors.blue,
                  onPressed: _openInGoogleMaps,
                ),

                // Botón Waze (solo si tenemos coordenadas)
                if (destinationLatitude != null && destinationLongitude != null)
                  _NavigationIconButton(
                    icon: Icons.navigation_rounded,
                    label: 'Waze',
                    color: Colors.amber[700]!,
                    onPressed: _openInWaze,
                  ),

                // Botón navegación integrada (si está disponible)
                if (onOpenInAppNavigation != null)
                  _NavigationIconButton(
                    icon: Icons.location_on,
                    label: 'App',
                    color: Colors.green,
                    onPressed: onOpenInAppNavigation!,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Nota de información
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toca cualquier opción para abrir la navegación',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón individual de navegación con IconButton
class _NavigationIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _NavigationIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      spacing: 4,
      children: [
        // IconButton con fondo circular
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            onPressed: onPressed,
            iconSize: 28,
            splashRadius: 28,
          ),
        ),
        // Label debajo del icono
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
