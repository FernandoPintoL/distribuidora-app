import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/models.dart';

class DireccionesTabWidget extends StatelessWidget {
  final List<ClientAddress>? addresses;
  final VoidCallback? onAdd;
  final Function(ClientAddress)? onEdit;
  final Function(ClientAddress)? onDelete;
  final Function(ClientAddress)? onSetPrincipal;
  final Future<void> Function()? onRefresh;

  const DireccionesTabWidget({
    super.key,
    required this.addresses,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onSetPrincipal,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (addresses == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando direcciones...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (addresses!.isEmpty) {
      return _buildEmptyDireccionesState(context);
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? (() => Future.value()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: addresses!.length,
        itemBuilder: (context, index) {
          final direccion = addresses![index];
          return _DireccionCardWidget(
            direccion: direccion,
            onEdit: onEdit,
            onDelete: onDelete,
            onSetPrincipal: onSetPrincipal,
          );
        },
      ),
    );
  }

  Widget _buildEmptyDireccionesState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay direcciones registradas',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega la primera dirección para este cliente',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location),
              label: const Text('Agregar Primera Dirección'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DireccionCardWidget extends StatelessWidget {
  final ClientAddress direccion;
  final Function(ClientAddress)? onEdit;
  final Function(ClientAddress)? onDelete;
  final Function(ClientAddress)? onSetPrincipal;

  const _DireccionCardWidget({
    required this.direccion,
    this.onEdit,
    this.onDelete,
    this.onSetPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: direccion.esPrincipal
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onEdit?.call(direccion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: direccion.esPrincipal
                            ? Colors.green
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (direccion.esPrincipal
                                        ? Colors.green
                                        : colorScheme.primary)
                                    .withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        direccion.esPrincipal ? Icons.home : Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            direccion.observaciones!.toUpperCase() ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "📍${direccion.localidad!.nombre}" ?? '',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (direccion.esPrincipal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Principal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Divider(height: 12, color: Theme.of(context).dividerColor),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    if (!direccion.esPrincipal)
                      TextButton.icon(
                        onPressed: () => onSetPrincipal?.call(direccion),
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('Marcar como principal'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => onEdit?.call(direccion),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondaryContainer,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => onDelete?.call(direccion),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    //   ver en google maps con _abrirEnMaps
                    TextButton.icon(
                      onPressed: () => _abrirEnMaps(
                        direccion.latitud ?? 0,
                        direccion.longitud ?? 0,
                      ),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Ver en Google Maps'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirEnMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
