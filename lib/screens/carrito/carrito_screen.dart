import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../providers/providers.dart';
import '../../models/client.dart';
import '../../widgets/carrito/index.dart';
import '../../widgets/carrito/carrito_total_bar.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
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
    // 🔑 FASE 3: Calcular precios CON RANGOS cuando se abre la pantalla
    // Usamos calcularCarritoConRangosAhora() porque es la PRIMERA vez
    // (no usamos debounce para la carga inicial)
    Future.delayed(Duration.zero, () {
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
      body: Consumer2<CarritoProvider, ClientProvider>(
        builder: (context, carritoProvider, clientProvider, _) {
          if (carritoProvider.isEmpty) {
            return CarritoEmptyState(
              onViewProducts: () => Navigator.pop(context),
            );
          }

          return Column(
            children: [
              // ✅ NUEVO: Selector de cliente (solo para preventista)
              _buildClienteSelectorSection(
                context,
                carritoProvider,
                clientProvider,
              ),

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

  /// ✅ NUEVO: Construir sección de selector de cliente con soporte a modo oscuro
  Widget _buildClienteSelectorSection(
    BuildContext context,
    CarritoProvider carritoProvider,
    ClientProvider clientProvider,
  ) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    // Verificar si es preventista
    bool isPreventista = false;
    try {
      final authProvider = context.read<AuthProvider>();
      final userRoles = authProvider.user?.roles ?? [];
      isPreventista = userRoles.any(
        (role) =>
            role.toLowerCase() == 'preventista' ||
            role.toLowerCase() == 'Preventista',
      );
    } catch (e) {
      debugPrint('❌ Error verificando rol de preventista: $e');
    }

    // Si no es preventista, no mostrar selector
    if (!isPreventista) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withOpacity(isDark ? 0.3 : 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Creando pedido para:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ✅ Dropdown con búsqueda usando dropdown_search
          DropdownSearch<Client>(
            items: clientProvider.clients.where((c) => c.activo).toList(),
            selectedItem: carritoProvider.clienteSeleccionado,
            itemAsString: (client) {
              final creditBadge = client.puedeAtenerCredito
                  ? ' ✅ Crédito'
                  : ' ❌ Sin crédito';
              final phone =
                  client.telefono != null && client.telefono!.isNotEmpty
                  ? ' (${client.telefono})'
                  : '';
              return '${client.nombre}$phone$creditBadge';
            },
            onChanged: (cliente) {
              if (cliente != null) {
                carritoProvider.setClienteSeleccionado(cliente);
                debugPrint('✅ Cliente seleccionado: ${cliente.nombre}');
                debugPrint('✅ Cliente seleccionado: ${cliente.id}');
                debugPrint(
                  '✅ Puede atender crédito: ${cliente.puedeAtenerCredito}',
                );
              }
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(8),
                elevation: 8,
                backgroundColor: colorScheme.surface,
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
                        : colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre y badge de crédito
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ✅ Badge de crédito disponible
                          if (item.puedeAtenerCredito)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(
                                  isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green.shade500,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Crédito',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Teléfono
                      if (item.telefono != null && item.telefono!.isNotEmpty)
                        Text(
                          item.telefono!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      // Límite de crédito si está disponible
                      if (item.puedeAtenerCredito &&
                          item.limiteCredito != null &&
                          item.limiteCredito! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Límite: Bs. ${item.limiteCredito!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Seleccionar cliente...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ),
          // Mostrar cliente seleccionado con info de crédito
          if (carritoProvider.tieneClienteSeleccionado)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.green.withOpacity(isDark ? 0.4 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '✓ ${carritoProvider.clienteSeleccionado!.nombre}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // ✅ Mostrar estado de crédito
                          if (carritoProvider
                              .clienteSeleccionado!
                              .puedeAtenerCredito)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Con crédito disponible - Límite: Bs. ${carritoProvider.clienteSeleccionado!.limiteCredito?.toStringAsFixed(2) ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Sin crédito disponible - Solo pago al contado',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
