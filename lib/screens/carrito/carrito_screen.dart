import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/carrito/index.dart';
import '../../widgets/carrito/carrito_total_bar.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import 'carrito_helpers.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  @override
  void initState() {
    super.initState();
    // Calcular precios con rangos cuando se abre la pantalla
    Future.delayed(Duration.zero, () {
      final carritoProvider = context.read<CarritoProvider>();
      if (carritoProvider.isNotEmpty) {
        carritoProvider.calcularCarritoConRangos();
      }
    });
  }

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
                    final detalleConRango = carritoProvider.obtenerDetalleConRango(item.producto.id);

                    return CarritoItemCard(
                      item: item,
                      detalleConRango: detalleConRango,
                      onIncrement: () {
                        carritoProvider.incrementarCantidad(item.producto.id);
                        mostrarErrorSiExiste(
                          context,
                          carritoProvider,
                          duracion: 3,
                        );
                        // Recalcular con rangos después de cambiar cantidad
                        carritoProvider.calcularCarritoConRangos();
                      },
                      onDecrement: () {
                        carritoProvider.decrementarCantidad(item.producto.id);
                        // Recalcular con rangos después de cambiar cantidad
                        carritoProvider.calcularCarritoConRangos();
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
                        // Recalcular con rangos después de eliminar
                        carritoProvider.calcularCarritoConRangos();
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
                        // Recalcular con rangos después de cambiar cantidad
                        carritoProvider.calcularCarritoConRangos();
                      },
                      onAgregarParaAhorrar: () {
                        if (detalleConRango?.proximoRango != null) {
                          carritoProvider.agregarParaAhorrar(
                            item.producto.id,
                            detalleConRango!.proximoRango!.faltaCantidad,
                          );
                        }
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
