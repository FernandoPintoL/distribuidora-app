import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/providers.dart';
import '../../../extensions/theme_extension.dart';

class ClienteInfoWidget extends StatelessWidget {
  final BuildContext parentContext;

  const ClienteInfoWidget({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = parentContext.colorScheme;
    final isDark = parentContext.isDark;

    final carritoProvider = parentContext.read<CarritoProvider>();
    final cliente = carritoProvider.clienteSeleccionado;

    if (cliente == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        // color: colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        cliente.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (cliente.telefono != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.phone_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          cliente.telefono ?? '-',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                ],
              ),
              if (cliente.puedeAtenerCredito == true) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cliente con crédito disponible',
                        style: TextStyle(
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          /**/
        ],
      ),
    );
  }
}
