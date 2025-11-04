import 'package:flutter/material.dart';
import '../models/carrito.dart';

/// Banner de advertencia para carritos por expirar
///
/// Muestra alerta cuando un carrito guardado está cercano a su fecha de expiración (30 días)
/// Se muestra cuando faltan 3 días o menos para expirar
class ExpirationWarningBanner extends StatelessWidget {
  final Carrito carrito;
  final int diasFaltantes;
  final VoidCallback? onRenew;
  final VoidCallback? onDismiss;

  const ExpirationWarningBanner({
    super.key,
    required this.carrito,
    required this.diasFaltantes,
    this.onRenew,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ícono y título
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Carrito por expirar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diasFaltantes == 1
                            ? 'Expira mañana'
                            : 'Expira en $diasFaltantes días',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              'Los carritos guardados expiran después de 30 días sin cambios. '
              'Renueva este carrito para mantenerlo activo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
            ),
            const SizedBox(height: 12),

            // Progress indicator visual
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - (diasFaltantes / 3), // 3 días es nuestro límite de alerta
                backgroundColor: Colors.orange.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade700,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Descartar'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton.icon(
                  onPressed: onRenew,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renovar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
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

/// Banner simplificado para mostrar dentro de una tarjeta
class ExpirationBadge extends StatelessWidget {
  final int diasFaltantes;

  const ExpirationBadge({
    super.key,
    required this.diasFaltantes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: diasFaltantes <= 1 ? Colors.red.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: diasFaltantes <= 1 ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: diasFaltantes <= 1 ? Colors.red.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            diasFaltantes <= 1
                ? '¡Expira hoy!'
                : 'Expira en ${diasFaltantes}d',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: diasFaltantes <= 1
                      ? Colors.red.shade700
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
