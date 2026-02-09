import 'package:flutter/material.dart';

/// ✅ NUEVO: Widget para mostrar información del entregador
/// Muestra quién realiza/realizará la entrega (puede ser diferente del chofer asignado)
class EntregadorInfo extends StatelessWidget {
  final String? entregador;
  final String? choferNombre;
  final bool isDarkMode;

  const EntregadorInfo({
    Key? key,
    required this.entregador,
    this.choferNombre,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no hay entregador y no hay chofer, no mostrar nada
    if ((entregador == null || entregador!.isEmpty) &&
        (choferNombre == null || choferNombre!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final nombre = (entregador != null && entregador!.isNotEmpty)
        ? entregador!
        : choferNombre ?? 'Sin asignar';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50],
        border: Border.all(
          color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entregador',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
