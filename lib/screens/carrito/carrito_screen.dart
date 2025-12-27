import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/carrito/index.dart';
import '../../widgets/carrito/carrito_total_bar.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import 'carrito_helpers.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mi Carrito',
        customGradient: AppGradients.blue,
        actions: [
          Consumer<CarritoProvider>(
            builder: (context, carritoProvider, _) {
              if (carritoProvider.isEmpty) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Vaciar carrito',
                onPressed: () => mostrarDialogoVaciarCarrito(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.isEmpty) {
            return CarritoEmptyState(
              onViewProducts: () => Navigator.pop(context),
            );
          }

          return Column(
            children: [
              // Mostrar mensaje de error si existe
              if (carritoProvider.errorMessage != null)
                CarritoErrorBanner(
                  message: carritoProvider.errorMessage!,
                  onClose: () => carritoProvider.limpiarError(),
                ),

              // Lista de items del carrito
              Expanded(
                child: ListView.builder(
                  itemCount: carritoProvider.items.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final item = carritoProvider.items[index];
                    return CarritoItemCard(
                      item: item,
                      onIncrement: () {
                        carritoProvider.incrementarCantidad(item.producto.id);
                        mostrarErrorSiExiste(
                          context,
                          carritoProvider,
                          duracion: 3,
                        );
                      },
                      onDecrement: () {
                        carritoProvider.decrementarCantidad(item.producto.id);
                      },
                      onRemove: () {
                        carritoProvider.eliminarProducto(item.producto.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.producto.nombre} eliminado del carrito',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onUpdateCantidad: (nuevaCantidad) {
                        carritoProvider.actualizarCantidad(
                          item.producto.id,
                          nuevaCantidad,
                        );
                        mostrarErrorSiExiste(
                          context,
                          carritoProvider,
                          duracion: 3,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.isEmpty) return const SizedBox.shrink();

          return CarritoTotalBar(
            total: carritoProvider.total,
            isLoading: carritoProvider.isLoading,
            onCheckout: () => continuarCompra(context),
          );
        },
      ),
    );
  }
}
