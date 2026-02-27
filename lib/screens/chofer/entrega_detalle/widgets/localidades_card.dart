import 'package:flutter/material.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/entrega.dart';
import '../../../../widgets/map_location_selector.dart';

/// ✅ NUEVO: Widget para mostrar localidades de una entrega
/// Muestra todas las localidades únicas de los clientes en las ventas de la entrega
class LocalidadesCard extends StatelessWidget {
  final Entrega entrega;
  final bool isDarkMode;

  const LocalidadesCard({
    Key? key,
    required this.entrega,
    required this.isDarkMode,
  }) : super(key: key);

  /// ✅ NUEVO 2026-02-17: Extraer ubicaciones de ventas para mostrar en mapa
  List<MapLocation> _obtenerUbicacionesVentas() {
    final ubicaciones = <MapLocation>[];

    if (entrega.ventas.isEmpty) {
      return ubicaciones;
    }

    // ✅ NUEVO: Crear MapLocation para cada venta con ubicación válida
    for (final venta in entrega.ventas) {
      if (venta.latitud != null && venta.longitud != null) {
        ubicaciones.add(
          MapLocation(
            latitude: venta.latitud!,
            longitude: venta.longitud!,
            title: venta.clienteNombre ?? 'Cliente #${venta.cliente}',
            subtitle: venta.numero,
            isSelected: false,
          ),
        );
      }
    }

    return ubicaciones;
  }

  /// ✅ NUEVO: Abrir mapa con todas las ubicaciones de ventas
  void _abrirMapaConUbicaciones(BuildContext context) {
    final ubicaciones = _obtenerUbicacionesVentas();

    if (ubicaciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No hay ubicaciones disponibles para mostrar en el mapa',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationSelector(
          onLocationSelected: (latitude, longitude, address) {
            // No hacer nada, solo visualizar
            Navigator.pop(context);
          },
          additionalLocations:
              ubicaciones, // ✅ NUEVO: Pasar ubicaciones de ventas
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay localidades, no mostrar nada
    if (entrega.localidades == null) {
      return const SizedBox.shrink();
    }

    final localidadesData = entrega.localidades!;
    final localidades = localidadesData['localidades'] as List? ?? [];
    final localidadesResumen =
        localidadesData['localidades_resumen'] as List? ?? [];
    final cantidadLocalidades =
        localidadesData['cantidad_localidades'] as int? ?? 0;
    final esConsolidada = localidadesData['es_consolidada'] as bool? ?? false;

    if (cantidadLocalidades == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.amber[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Localidades de Entrega',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 $cantidadLocalidades localidad${cantidadLocalidades > 1 ? 'es' : ''} ${esConsolidada ? '(Entrega consolidada)' : ''}',
                    style: TextStyle(
                      fontSize: AppTextStyles.bodySmall(context).fontSize!,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // ✅ NUEVO 2026-02-17: Botón para ver ubicaciones en mapa
            IconButton(
              icon: const Icon(Icons.map, size: 20),
              tooltip: 'Ver en mapa',
              onPressed: () => _abrirMapaConUbicaciones(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            ),
          ],
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar localidades como chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var localidad in localidades)
                      Chip(
                        label: Text(
                          localidad['nombre'] as String? ?? 'Sin nombre',
                        ),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.amber[100],
                          child: const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        backgroundColor: isDarkMode
                            ? Colors.amber[900]!.withValues(alpha: 0.3)
                            : Colors.amber[100],
                      ),
                  ],
                ),
                const Divider(),
                // Mostrar resumen de localidades con cantidad de ventas
                if (localidadesResumen.isNotEmpty) ...[
                  Text(
                    'Resumen por localidad:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var resumen in localidadesResumen)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resumen['localidad_nombre'] as String? ??
                                      'Sin nombre',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${resumen['cantidad_ventas']} venta${(resumen['cantidad_ventas'] as int?) != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.bodySmall(
                                      context,
                                    ).fontSize!,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mostrar clientes de esta localidad
                          if (resumen['clientes'] is List &&
                              (resumen['clientes'] as List).isNotEmpty)
                            Expanded(
                              child: Text(
                                (resumen['clientes'] as List)
                                    .cast<String>()
                                    .join(', '),
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSmall(
                                    context,
                                  ).fontSize!,
                                  color: isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
