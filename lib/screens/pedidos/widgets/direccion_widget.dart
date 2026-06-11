import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../config/config.dart';
import '../../../extensions/theme_extension.dart';
import '../../clients/direccion_form_screen_for_client.dart';

class DireccionWidget extends StatelessWidget {
  final BuildContext parentContext;
  final ClientAddress? direccionSeleccionada;
  final VoidCallback onMostrarSelectorDireccion;
  final Function(ClientAddress?) onDireccionChanged;
  final int cantidadDirecciones;

  const DireccionWidget({
    super.key,
    required this.parentContext,
    required this.direccionSeleccionada,
    required this.onMostrarSelectorDireccion,
    required this.onDireccionChanged,
    required this.cantidadDirecciones,
  });

  void _abrirFormularioDireccion() {
    final carritoProvider = parentContext.read<CarritoProvider>();
    final cliente = carritoProvider.clienteSeleccionado;

    if (cliente != null) {
      parentContext.read<NavigatorObserver>();
      Navigator.of(parentContext)
          .push(
            MaterialPageRoute(
              builder: (context) => DireccionFormScreenForClient(
                clientId: cliente.id,
              ),
            ),
          )
          .then((_) {
            onDireccionChanged(null);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;

    // SIN DIRECCIONES
    if (cantidadDirecciones == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dirección de Entrega',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sin dirección registrada',
                              style: parentContext.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registra una dirección para continuar',
                              style:
                                  parentContext.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _abrirFormularioDireccion,
                      icon: const Icon(Icons.add_location),
                      label: const Text('Registrar Dirección'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // UNA DIRECCIÓN
    if (cantidadDirecciones == 1) {
      return const SizedBox.shrink();
    }

    // 2+ DIRECCIONES
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección de Entrega',
          style: TextStyle(
            fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (direccionSeleccionada == null)
          GestureDetector(
            onTap: onMostrarSelectorDireccion,
            child: Card(
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Seleccionar dirección',
                        style: parentContext.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              Card(
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              direccionSeleccionada!.direccion ?? '',
                              style:
                                  parentContext.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (direccionSeleccionada!.ciudad != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ciudad: ${direccionSeleccionada!.ciudad}',
                                style: parentContext.textTheme.bodySmall
                                    ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMostrarSelectorDireccion,
                      icon: const Icon(Icons.edit),
                      label: const Text('Cambiar Dirección'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _abrirFormularioDireccion,
                      icon: const Icon(Icons.add_location),
                      label: const Text('+Crear Dirección'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
