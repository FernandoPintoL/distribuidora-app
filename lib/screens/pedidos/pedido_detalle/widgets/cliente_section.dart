import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';
import 'client_info_item_widget.dart';

class ClienteSection extends StatelessWidget {
  final Client cliente;
  final BuildContext parentContext;

  const ClienteSection({
    super.key,
    required this.cliente,
    required this.parentContext,
  });

  String _getLocalidadNombre(Client cliente) {
    if (cliente.localidad != null) {
      if (cliente.localidad is Map) {
        return (cliente.localidad as Map)['nombre'] ?? 'No disponible';
      }
      try {
        return cliente.localidad.nombre ?? 'No disponible';
      } catch (e) {
        return 'No disponible';
      }
    }
    return 'No disponible';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(parentContext).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Cliente',
                            style: TextStyle(
                              fontSize: AppTextStyles.bodyMedium(
                                parentContext,
                              ).fontSize!,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cliente.nombre,
                            style: TextStyle(
                              fontSize: AppTextStyles.headlineSmall(
                                parentContext,
                              ).fontSize!,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Fila 1: Teléfono y Ciudad
                Row(
                  children: [
                    Expanded(
                      child: ClientInfoItemWidget(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: cliente.telefono ?? 'No disponible',
                        parentContext: parentContext,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClientInfoItemWidget(
                        icon: Icons.location_on,
                        label: 'Localidad',
                        value: _getLocalidadNombre(cliente),
                        parentContext: parentContext,
                      ),
                    ),
                  ],
                ),
                // Fila 2: Estado y Crédito
                if (cliente.puedeAtenerCredito || !cliente.activo) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClientInfoItemWidget(
                          icon: Icons.check_circle,
                          label: 'Estado',
                          value: cliente.activo ? 'Activo' : 'Inactivo',
                          valueColor: cliente.activo ? Colors.green : Colors.red,
                          parentContext: parentContext,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
