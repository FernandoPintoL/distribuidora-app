import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Client? clientePreseleccionado;

  const CarritoScreen({super.key, this.clientePreseleccionado});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late TextEditingController _searchClienteController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchClienteController = TextEditingController();

    // ✅ Capturar Enter en el campo de búsqueda
    _searchFocusNode.onKey = (node, event) {
      if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
        _ejecutarBusquedaDesdeEnter();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    // 🔑 FASE 3: Calcular precios CON RANGOS cuando se abre la pantalla
    // Usamos calcularCarritoConRangosAhora() porque es la PRIMERA vez
    // (no usamos debounce para la carga inicial)
    Future.delayed(Duration.zero, () {
      // ✅ Si hay cliente pre-seleccionado, cargar sus datos automáticamente
      if (widget.clientePreseleccionado != null) {
        final clientProvider = context.read<ClientProvider>();
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

      final carritoProvider = context.read<CarritoProvider>();
      if (carritoProvider.isNotEmpty) {
        carritoProvider.calcularCarritoConRangosAhora();
      }
    });
  }

  @override
  void dispose() {
    _searchClienteController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ✅ Función para ejecutar búsqueda desde Enter
  Future<void> _ejecutarBusquedaDesdeEnter() async {
    final clientProvider = context.read<ClientProvider>();
    final searchText = _searchClienteController.text.trim();

    if (searchText.isNotEmpty) {
      await clientProvider.loadClients(
        search: searchText,
        active: true,
        perPage: 20,
      );
      debugPrint('🔍 Búsqueda realizada por ENTER: "$searchText"');
    }
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

          // Verificar si el usuario es preventista
          bool isPreventista = false;
          try {
            final authProvider = context.read<AuthProvider>();
            final userRoles = authProvider.user?.roles ?? [];
            isPreventista = userRoles.any((role) =>
                role.toLowerCase() == 'preventista');
          } catch (e) {
            debugPrint('❌ Error al verificar rol en CarritoScreen: $e');
          }

          return Column(
            children: [
              // ✅ NUEVO: Banner cuando se está editando una proforma
              if (carritoProvider.editandoProforma)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFF2196F3),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_document,
                        color: const Color(0xFF2196F3),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Editando Proforma',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${carritoProvider.proformaEditando?.numero ?? 'N/A'} (ID: ${carritoProvider.proformaEditandoId ?? 'N/A'})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                      isPreventista: isPreventista,
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
      // ✅ NUEVO: FloatingActionButton para agregar más productos
      floatingActionButton: Consumer<CarritoProvider>(
        builder: (context, carritoProvider, _) {
          // Solo mostrar FAB si el carrito no está vacío
          if (carritoProvider.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              debugPrint('➕ Abriendo pantalla de productos para agregar más items');
              Navigator.pushNamed(context, '/products');
            },
            tooltip: 'Agregar más productos',
            child: const Icon(Icons.add),
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
          // ✅ NUEVO: Deshabilitar dropdown cuando se está editando una proforma
          if (carritoProvider.editandoProforma)
            // Mostrar cliente de forma read-only cuando se edita
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceVariant.withOpacity(0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      carritoProvider.clienteSeleccionado?.nombre ?? 'Cliente no especificado',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'No se puede cambiar el cliente en modo edición',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            // ✅ DropdownSearch con búsqueda manual (botón + Enter)
            Consumer<ClientProvider>(
              builder: (context, clientProviderConsumer, _) {
                debugPrint('🔄 Rebuilding DropdownSearch with ${clientProviderConsumer.clients.length} clients');

                // Función local para realizar búsqueda (por botón)
                Future<void> _realizarBusquedaLocal() async {
                  final searchText = _searchClienteController.text.trim();
                  if (searchText.isNotEmpty) {
                    await clientProvider.loadClients(
                      search: searchText,
                      active: true,
                      perPage: 20,
                    );
                    debugPrint('🔍 Búsqueda realizada por BOTÓN: "$searchText"');
                  }
                }

                return DropdownSearch<Client>(
                  key: ValueKey('dropdown_${clientProviderConsumer.clients.length}'),
                  asyncItems: (String filter) async {
                    // ✅ NO hacer búsquedas en tiempo real
                    // Solo mostrar resultados después de búsqueda manual (botón o Enter)
                    // Si hay clientes en la lista, mostrarlos; si no, devolver lista vacía
                    return clientProvider.clients;
                  },
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
                      _searchClienteController.clear();
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
                      controller: _searchClienteController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Escribe y presiona Enter o 🔍',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Consumer<ClientProvider>(
                          builder: (context, clientProviderInner, _) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: IconButton(
                                icon: clientProviderInner.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                onPressed: clientProviderInner.isLoading
                                    ? null
                                    : () {
                                        // ✅ Búsqueda al hacer click en el botón
                                        _realizarBusquedaLocal();
                                      },
                                tooltip: 'Buscar clientes (Enter)',
                              ),
                            );
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                );
              },
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
                          // ✅ NUEVO: Tarjeta mejorada de información de crédito
                          if (carritoProvider
                              .clienteSeleccionado!
                              .puedeAtenerCredito)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildCreditInfoCard(
                                carritoProvider.clienteSeleccionado!,
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

  // ✅ NUEVO: Widget para mostrar información de crédito de forma mejorada
  Widget _buildCreditInfoCard(Client cliente) {
    final limiteCredito = cliente.limiteCredito ?? 0.0;
    // ✅ CORRECTO: Usar creditoUtilizado (campo que retorna el backend)
    final creditoUtilizado = cliente.creditoUtilizado ?? 0.0;
    final creditoDisponible = limiteCredito - creditoUtilizado;
    final porcentajeUsado = limiteCredito > 0 ? (creditoUtilizado / limiteCredito) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Límite de crédito
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Límite de Crédito',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Bs. ${limiteCredito.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // ✅ NUEVO: Mostrar crédito utilizado si está disponible
          if (cliente.creditoUtilizado != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crédito Utilizado',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade600,
                  ),
                ),
                Text(
                  'Bs. ${creditoUtilizado.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Barra de progreso visual
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentajeUsado / 100,
                minHeight: 6,
                backgroundColor: Colors.green.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  porcentajeUsado > 80
                      ? Colors.red.shade500
                      : porcentajeUsado > 50
                      ? Colors.orange.shade500
                      : Colors.green.shade500,
                ),
              ),
            ),
          ],

          // Fila 3: Disponible
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponible',
                style: TextStyle(
                  fontSize: 11,
                  color: creditoDisponible > 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Bs. ${creditoDisponible.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: creditoDisponible > 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
