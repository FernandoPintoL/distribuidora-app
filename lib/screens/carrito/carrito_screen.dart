import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../providers/providers.dart';
import '../../models/client.dart';
import '../../models/carrito_item.dart';
import '../../widgets/carrito/index.dart';
import '../../widgets/carrito/carrito_total_bar.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../clients/client_form_screen.dart';
import '../clients/client_detail_screen.dart';
import '../products/producto_detalle_screen.dart' as producto;
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
  // ✅ Flag para saber si hay una búsqueda activa
  bool _busquedaActiva = false;

  @override
  void initState() {
    super.initState();
    _searchClienteController = TextEditingController();

    // ✅ El Enter se maneja en onSubmitted del TextField
    _searchClienteController.addListener(() {
      debugPrint('📝 Campo de búsqueda cambió: "${_searchClienteController.text}"');
    });

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
  void dispose() {
    _searchClienteController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ✅ Función para realizar búsqueda
  Future<void> _realizarBusquedaLocal() async {
    final clientProvider = context.read<ClientProvider>();
    final searchText = _searchClienteController.text.trim();

    debugPrint('🔍 ===== INICIANDO _realizarBusquedaLocal =====');
    debugPrint('📝 Texto de búsqueda: "$searchText"');
    debugPrint('🏢 ClientProvider disponible: ${clientProvider != null}');

    try {
      // ✅ Marcar búsqueda como activa
      setState(() => _busquedaActiva = true);

      if (searchText.isNotEmpty) {
        debugPrint('🔍 Ejecutando búsqueda con término: "$searchText"');
        await clientProvider.loadClients(
          search: searchText,
          active: true,
          perPage: 20,
        );
        debugPrint('✅ Búsqueda realizada por BOTÓN: "$searchText"');
      } else {
        // Si el campo está vacío, cargar los primeros 20 clientes
        debugPrint('📋 Búsqueda vacía, cargando primeros 20 clientes');
        await clientProvider.loadClients(
          search: '',
          active: true,
          perPage: 20,
        );
        debugPrint('✅ Cargando primeros 20 clientes (búsqueda vacía)');
      }

      // ✅ NUEVO: Solicitar focus DESPUÉS del rebuild para que el dropdown se abra
      // mostrando el loading o los resultados
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).requestFocus(_searchFocusNode);
            debugPrint('📂 Focus solicitado al campo de búsqueda (después del rebuild)');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error en _realizarBusquedaLocal: $e');
    }
    debugPrint('🔍 ===== FIN _realizarBusquedaLocal =====');
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
            isPreventista = userRoles.any((role) =>
                role.toLowerCase() == 'preventista');
          } catch (e) {
            debugPrint('❌ Error al verificar rol en CarritoScreen: $e');
          }

          return SingleChildScrollView(
            child: Column(
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
                          // ✅ NUEVO: Callback para navegar a producto_detalle_screen
                          onProductoTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => producto.ProductoDetalleScreen(
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
                          _buildComboDetallesCarrito(item),
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

                // ✅ SIMPLIFICADO: TextField en lugar de DropdownSearch
                return TextField(
                  controller: _searchClienteController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  // ✅ NUEVO: Ejecutar búsqueda al presionar Enter del teclado
                  onSubmitted: (value) {
                    debugPrint('⌨️ Enter presionado en el teclado');
                    _realizarBusquedaLocal();
                  },
                  decoration: InputDecoration(
                    hintText: carritoProvider.tieneClienteSeleccionado
                        ? '${carritoProvider.clienteSeleccionado?.nombre} ✅'
                        : 'Escribe y presiona Enter o 🔍',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Consumer<ClientProvider>(
                      builder: (context, clientProviderInner, _) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ Botón para recargar
                              IconButton(
                                icon: clientProviderInner.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                onPressed: clientProviderInner.isLoading
                                    ? null
                                    : () async {
                                        _searchClienteController.clear();
                                        await clientProvider.loadClients(
                                          search: '',
                                          active: true,
                                          perPage: 20,
                                        );
                                        setState(() => _busquedaActiva = false);
                                        debugPrint('🔄 Recargando primeros 20 clientes');
                                      },
                                tooltip: 'Recargar lista',
                              ),
                              // ✅ Botón de búsqueda
                              IconButton(
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
                                        debugPrint(
                                            '🔍 Botón presionado: "${_searchClienteController.text}"');
                                        _realizarBusquedaLocal();
                                      },
                                tooltip: 'Buscar',
                              ),
                              // ✅ Botón crear cliente
                              IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: () async {
                                  final resultado =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClientFormScreen(),
                                    ),
                                  );
                                  if (resultado == true && mounted) {
                                    await clientProvider.loadClients(
                                      search: '',
                                      active: true,
                                      perPage: 20,
                                    );
                                    setState(() => _busquedaActiva = false);
                                    debugPrint('✅ Cliente creado.');
                                  }
                                },
                                tooltip: 'Nuevo cliente',
                              ),
                            ],
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
                );
              },
            ),
          // ✅ NUEVO: Mostrar resultados de búsqueda O mensaje cuando no hay clientes
          Consumer<ClientProvider>(
            builder: (context, clientProvider, _) {
              // Si no hay búsqueda activa, no mostrar el listado
              if (!_busquedaActiva) {
                return const SizedBox.shrink();
              }

              // Si está cargando, no mostrar nada (el loading está en el emptyBuilder del dropdown)
              if (clientProvider.isLoading) {
                return const SizedBox.shrink();
              }

              // Si hay clientes, mostrar la lista para seleccionar
              if (clientProvider.clients.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ NUEVO: Título de resultados
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resultados de búsqueda',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${clientProvider.clients.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ✅ Contenedor con listado
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: clientProvider.clients.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                          itemBuilder: (context, index) {
                            final client = clientProvider.clients[index];
                            final creditBadge = client.puedeAtenerCredito
                                ? ' ✅ Crédito'
                                : ' ❌ Sin crédito';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  carritoProvider.setClienteSeleccionado(client);
                                  _searchClienteController.clear();
                                  // ✅ Desactivar búsqueda después de seleccionar
                                  setState(() => _busquedaActiva = false);
                                  debugPrint('✅ Cliente seleccionado desde resultados: ${client.nombre}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${client.nombre}$creditBadge',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (client.telefono != null &&
                                                client.telefono!.isNotEmpty)
                                              Text(
                                                client.telefono!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // ✅ NUEVO: Botón para ver detalle del cliente
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ClientDetailScreen(
                                                client: client,
                                              ),
                                            ),
                                          );
                                          debugPrint('➡️ Navegando a detalle de ${client.nombre}');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Si no hay clientes, mostrar mensaje solo si está búsqueda activa
              if (!clientProvider.isLoading &&
                  clientProvider.clients.isEmpty &&
                  _busquedaActiva) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No se encontraron clientes que coincidan con "${_searchClienteController.text}"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
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
                    // ✅ NUEVO: Botón para ver detalle del cliente seleccionado
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.green.shade500,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailScreen(
                              client:
                                  carritoProvider.clienteSeleccionado!,
                            ),
                          ),
                        );
                        debugPrint(
                            '➡️ Navegando a detalle de ${carritoProvider.clienteSeleccionado!.nombre}');
                      },
                      tooltip: 'Ver detalle del cliente',
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

  /// ✅ NUEVO: Mostrar detalles de componentes del combo en el carrito
  Widget _buildComboDetallesCarrito(CarritoItem item) {
    final comboItems = item.comboItemsSeleccionados ?? [];
    final comboItemsDelProducto = item.producto.comboItems ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    String? obtenerNombreComboItem(int comboItemId) {
      try {
        return comboItemsDelProducto
            .firstWhere((c) => c.id == comboItemId)
            .productoNombre;
      } catch (e) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.amber.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Componentes - ${item.cantidad} combo${item.cantidad > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.amber.shade200),
              ),
            ),
            child: Column(
              children: comboItems.asMap().entries.map((entry) {
                final index = entry.key;
                final comboItem = entry.value;
                // ✅ Convertir cantidad de forma segura (puede ser int o double)
                final cantidadRaw = comboItem['cantidad'] ?? 1;
                final cantidad = cantidadRaw is int ? cantidadRaw : (cantidadRaw as num).toInt();
                final comboItemId = comboItem['combo_item_id'] ?? 0;
                final nombreProducto =
                    obtenerNombreComboItem(comboItemId) ?? 'Producto';
                final isLast = index == comboItems.length - 1;

                // Mostrar cantidad total si el combo tiene cantidad > 1
                final cantidadTotal = cantidad * item.cantidad;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.amber.shade100,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• $nombreProducto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${comboItem['producto_id']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${cantidadTotal}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (item.cantidad > 1)
                            Text(
                              '($cantidad×${item.cantidad})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
