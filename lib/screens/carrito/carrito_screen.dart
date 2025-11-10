import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/carrito/index.dart';
import 'carrito_helpers.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
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
                        mostrarErrorSiExiste(context, carritoProvider, duracion: 3);
                      },
                      onDecrement: () {
                        carritoProvider.decrementarCantidad(item.producto.id);
                      },
                      onRemove: () {
                        carritoProvider.eliminarProducto(item.producto.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.producto.nombre} eliminado del carrito'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onUpdateCantidad: (nuevaCantidad) {
                        carritoProvider.actualizarCantidad(
                          item.producto.id,
                          nuevaCantidad,
                        );
                        mostrarErrorSiExiste(context, carritoProvider, duracion: 3);
                      },
                    );
                  },
                ),
              ),

              // Resumen de totales
              CarritoResumenTotales(
                subtotal: carritoProvider.subtotal,
                impuesto: carritoProvider.impuesto,
                costoEnvio: carritoProvider.costoEnvio,
                descuento: carritoProvider.montoDescuento,
                porcentajeDescuento: carritoProvider.porcentajeDescuento,
                tieneDescuento: carritoProvider.tieneDescuento,
                codigoDescuento: carritoProvider.codigoDescuento,
                validandoDescuento: carritoProvider.validandoDescuento,
                calculandoEnvio: carritoProvider.calculandoEnvio,
                onAplicarDescuento: (codigo) async {
                  final success = await carritoProvider.aplicarDescuento(codigo);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cupón "$codigo" aplicado correctamente'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  return success;
                },
                onRemoverDescuento: () => carritoProvider.removerDescuento(),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.isEmpty) return const SizedBox.shrink();

          return CarritoActionButtons(
            isLoading: carritoProvider.isLoading,
            isSaving: carritoProvider.guardandoCarrito,
            onContinuarCompra: () => continuarCompra(context),
            onGuardarCarrito: () async {
              final success = await carritoProvider.guardarCarrito();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Carrito guardado correctamente'
                          : carritoProvider.errorMessage ?? 'Error al guardar carrito',
                    ),
                    backgroundColor: success ? Colors.green : Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            onConvertirProforma: () async {
              final proforma = await carritoProvider.convertirAProforma();
              if (context.mounted) {
                if (proforma != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Proforma creada: ${proforma['numero']}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        carritoProvider.errorMessage ?? 'Error al crear proforma',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}
