import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/client.dart';
import '../../widgets/carrito/index.dart';
import '../../widgets/carrito/carrito_total_bar.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../products/producto_detalle_screen.dart' as producto;
import 'carrito_helpers.dart';

class CarritoScreen extends StatefulWidget {
  final Client? clientePreseleccionado;

  const CarritoScreen({super.key, this.clientePreseleccionado});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  @override
  void initState() {
    super.initState();

    // 🔑 FASE 3: Calcular precios CON RANGOS cuando se abre la pantalla
    // Usamos calcularCarritoConRangosAhora() porque es la PRIMERA vez
    // (no usamos debounce para la carga inicial)
    Future.delayed(Duration.zero, () {
      final clientProvider = context.read<ClientProvider>();

      // ✅ Si hay cliente pre-seleccionado, cargar sus datos automáticamente
      if (widget.clientePreseleccionado != null) {
        debugPrint(
          '📦 Cliente pre-seleccionado: ${widget.clientePreseleccionado!.nombre}',
        );
        // Cargar los datos del cliente pre-seleccionado
        clientProvider.loadClients(
          search: widget.clientePreseleccionado!.nombre,
          active: true,
          perPage: 1,
        );
      }
      // ✅ SIMPLIFICADO: Ya no cargar 20 clientes iniciales
      // Se cargan solo cuando el usuario presiona búsqueda

      final carritoProvider = context.read<CarritoProvider>();
      if (carritoProvider.isNotEmpty) {
        carritoProvider.calcularCarritoConRangosAhora();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Mi Carritos',
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
      body: Consumer2<CarritoProvider, ClientProvider>(
        builder: (context, carritoProvider, clientProvider, _) {
          if (carritoProvider.isEmpty) {
            return CarritoEmptyState(
              onViewProducts: () => Navigator.pop(context),
            );
          }

          // Verificar si el usuario es preventista
          bool isPreventista = false;
          try {
            final authProvider = context.read<AuthProvider>();
            final userRoles = authProvider.user?.roles ?? [];
            isPreventista = userRoles.any(
              (role) => role.toLowerCase() == 'preventista',
            );
          } catch (e) {
            debugPrint('❌ Error al verificar rol en CarritoScreen: $e');
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ✅ NUEVO: Banner cuando se está editando una proforma
                if (carritoProvider.editandoProforma)
                  CarritoEditandoProformaBanner(carritoProvider: carritoProvider,),

                // ✅ NUEVO: Selector de cliente (solo para preventista)
                CarritoClienteSelector(carritoProvider: carritoProvider, clientProvider: clientProvider,),

                // Mostrar mensaje de error si existe
                if (carritoProvider.errorMessage != null)
                  CarritoErrorBanner(
                    message: carritoProvider.errorMessage!,
                    onClose: () => carritoProvider.limpiarError(),
                  ),

                // Lista de items del carrito (ahora con shrinkWrap en SingleChildScrollView)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: carritoProvider.items.length,
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 90, // 🔑 NUEVO: Espacio para el CarritoTotalBar
                    left: 0,
                    right: 0,
                  ),
                  itemBuilder: (context, index) {
                    final item = carritoProvider.items[index];
                    final detalleConRango = carritoProvider
                        .obtenerDetalleConRango(item.producto.id);

                    return Column(
                      children: [
                        CarritoItemCard(
                          item: item,
                          detalleConRango: detalleConRango,
                          isPreventista: isPreventista,
                          onIncrement: () {
                            carritoProvider.incrementarCantidad(
                              item.producto.id,
                            );
                            mostrarErrorSiExiste(
                              context,
                              carritoProvider,
                              duracion: 3,
                            );
                            // Recalcular con rangos después de cambiar cantidad
                            carritoProvider.calcularCarritoConRangos();
                          },
                          onDecrement: () {
                            carritoProvider.decrementarCantidad(
                              item.producto.id,
                            );
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
                          // ✅ NUEVO: Callback para navegar a producto_detalle_screen
                          onProductoTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    producto.ProductoDetalleScreen(
                                      producto: item.producto,
                                    ),
                              ),
                            );
                          },
                        ),
                        // ✅ NUEVO: Mostrar detalles del combo si tiene items seleccionados
                        if (item.producto.esCombo &&
                            item.comboItemsSeleccionados != null &&
                            item.comboItemsSeleccionados!.isNotEmpty)
                          CarritoComboDetalles(item: item),
                      ],
                    );
                  },
                ),
              ],
            ),
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
      // ✅ NUEVO: FloatingActionButton para agregar más productos
      floatingActionButton: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          // Solo mostrar FAB si el carrito no está vacío
          if (carritoProvider.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              debugPrint(
                '➕ Abriendo pantalla de productos para agregar más items',
              );
              Navigator.pushNamed(context, '/products');
            },
            tooltip: 'Agregar más productos',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
