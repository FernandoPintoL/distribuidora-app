import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

/// Muestra un mensaje de error si existe en el CarritoProvider
void mostrarErrorSiExiste(
  BuildContext context,
  CarritoProvider carritoProvider, {
  int duracion = 3,
}) {
  if (carritoProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(carritoProvider.errorMessage!),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: duracion),
      ),
    );
  }
}

/// Muestra un diálogo de confirmación para vaciar el carrito
void mostrarDialogoVaciarCarrito(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<CarritoProvider>().limpiarCarrito();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carrito vaciado'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

/// Navega a la pantalla de selección de dirección de entrega
void continuarCompra(BuildContext context) {
  // Verificar que el carrito no esté vacío
  final carritoProvider = context.read<CarritoProvider>();

  if (carritoProvider.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El carrito está vacío'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Navegar a selección de dirección de entrega
  Navigator.pushNamed(context, '/direccion-entrega-seleccion');
}
