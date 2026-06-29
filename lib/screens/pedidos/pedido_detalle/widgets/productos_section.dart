import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../config/app_text_styles.dart';

class ProductosSection extends StatelessWidget {
  final Pedido pedido;
  final BuildContext parentContext;

  const ProductosSection({
    super.key,
    required this.pedido,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(parentContext).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos',
            style: TextStyle(
              fontSize: AppTextStyles.headlineSmall(parentContext).fontSize!,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...pedido.items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Imagen
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.producto?.imagenPrincipal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.producto!.imagenPrincipal!.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image),
                              ),
                            )
                          : const Icon(Icons.image, size: 32),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.producto?.nombre ?? 'Producto',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: ${item.cantidad}',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: AppTextStyles.bodyMedium(
                                parentContext,
                              ).fontSize!,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bs. ${item.precioUnitario.toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: AppTextStyles.bodySmall(
                                parentContext,
                              ).fontSize!,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtotal
                    Text(
                      'Bs. ${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTextStyles.bodyLarge(parentContext).fontSize!,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
