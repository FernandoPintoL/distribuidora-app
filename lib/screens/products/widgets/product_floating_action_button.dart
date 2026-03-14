import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_text_styles.dart';
import '../../../providers/providers.dart';

/// Widget que construye el botón flotante para el carrito
class ProductFloatingActionButton extends StatelessWidget {
  const ProductFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<AuthProvider, CarritoProvider>(
      builder: (context, authProvider, carritoProvider, child) {
        // Si hay items en el carrito, mostrar botón para ir al carrito
        if (carritoProvider.items.isNotEmpty) {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/carrito');
            },
            elevation: 6,
            highlightElevation: 8,
            backgroundColor: colorScheme.primary,
            icon: const Icon(Icons.shopping_cart),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            label: Text(
              'Carrito (${carritoProvider.items.length})',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppTextStyles.bodyMedium(context).fontSize!,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        // Si el usuario puede crear productos, mostrar botón de agregar
        if (authProvider.canCreateProducts) {
          return FloatingActionButton(
            onPressed: () {
              // TODO: Navigate to create product screen
            },
            elevation: 6,
            highlightElevation: 8,
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
