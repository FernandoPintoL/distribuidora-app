import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/config.dart';
import '../../extensions/theme_extension.dart';
import '../../models/client.dart';
import '../../providers/providers.dart';
import '../widgets.dart';
import '../../screens/clients/client_form_screen.dart';
import '../../screens/clients/client_detail_screen.dart';
import 'carrito_credit_info_card.dart';

class CarritoClienteSelector extends StatefulWidget {
  final CarritoProvider carritoProvider;
  final ClientProvider clientProvider;

  const CarritoClienteSelector({
    super.key,
    required this.carritoProvider,
    required this.clientProvider,
  });

  @override
  State<CarritoClienteSelector> createState() => _CarritoClienteSelectorState();
}

class _CarritoClienteSelectorState extends State<CarritoClienteSelector> {
  late TextEditingController _searchClienteController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _busquedaActiva = false;

  @override
  void initState() {
    super.initState();
    _searchClienteController = TextEditingController();

    _searchClienteController.addListener(() {
      debugPrint(
        '📝 Campo de búsqueda cambió: "${_searchClienteController.text}"',
      );
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
    final searchText = _searchClienteController.text.trim();

    debugPrint('🔍 ===== INICIANDO _realizarBusquedaLocal =====');
    debugPrint('📝 Texto de búsqueda: "$searchText"');
    debugPrint(
      '🏢 ClientProvider disponible: ${widget.clientProvider != null}',
    );

    try {
      // ✅ Marcar búsqueda como activa
      setState(() => _busquedaActiva = true);

      if (searchText.isNotEmpty) {
        debugPrint('🔍 Ejecutando búsqueda con término: "$searchText"');
        await widget.clientProvider.loadClients(
          search: searchText,
          active: true,
          perPage: 20,
        );
        debugPrint('✅ Búsqueda realizada por BOTÓN: "$searchText"');
      } else {
        // Si el campo está vacío, cargar los primeros 20 clientes
        debugPrint('📋 Búsqueda vacía, cargando primeros 20 clientes');
        await widget.clientProvider.loadClients(
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
            debugPrint(
              '📂 Focus solicitado al campo de búsqueda (después del rebuild)',
            );
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
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    // AppTextStyles.bodySmall() ya incluye MediaQuery.textScaleFactor internamente
    final baseFontSize = AppTextStyles.bodySmall(context).fontSize ?? 14;
    final iconSize = baseFontSize * 1.3;
    final smallIconSize = baseFontSize;

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
      padding: EdgeInsets.symmetric(
        horizontal: baseFontSize * 1.1,
        vertical: baseFontSize * 0.8,
      ),
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
              Icon(Icons.person_outline, color: colorScheme.primary),
              SizedBox(width: baseFontSize * 0.5),
              Text(
                'Creando pedido para:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Crear cliente'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: baseFontSize * 0.8,
                    vertical: baseFontSize * 0.5,
                  ),
                  textStyle: TextStyle(fontWeight: FontWeight.w500),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: Size(0, baseFontSize * 2.2),
                ),
                onPressed: () async {
                  final resultado = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ClientFormScreen(),
                    ),
                  );
                  if (resultado == true && mounted) {
                    await widget.clientProvider.loadClients(
                      search: '',
                      active: true,
                      perPage: 20,
                    );
                    setState(() => _busquedaActiva = false);
                    debugPrint('✅ Cliente creado.');
                  }
                },
              ),
            ],
          ),
          SizedBox(height: baseFontSize * 0.5),
          // ✅ NUEVO: Deshabilitar dropdown cuando se está editando una proforma
          if (widget.carritoProvider.editandoProforma)
            // Mostrar cliente de forma read-only cuando se edita
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: baseFontSize * 0.8,
                vertical: baseFontSize * 0.8,
              ),
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
                  Icon(Icons.lock_outline),
                  SizedBox(width: baseFontSize * 0.5),
                  Expanded(
                    child: Text(
                      widget.carritoProvider.clienteSeleccionado?.nombre ??
                          'Cliente no especificado',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'No se puede cambiar el cliente en modo edición',
                    child: Icon(Icons.info_outline),
                  ),
                ],
              ),
            )
          else
            // ✅ DropdownSearch con búsqueda manual (botón + Enter)
            Consumer<ClientProvider>(
              builder: (context, clientProviderConsumer, _) {
                debugPrint(
                  '🔄 Rebuilding DropdownSearch with ${clientProviderConsumer.clients.length} clients',
                );

                // ✅ SIMPLIFICADO: TextField en lugar de DropdownSearch
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchClienteController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        // ✅ NUEVO: Ejecutar búsqueda al presionar Enter del teclado
                        onSubmitted: (value) {
                          debugPrint('⌨️ Enter presionado en el teclado');
                          _realizarBusquedaLocal();
                        },
                        decoration: InputDecoration(
                          hintText:
                              widget.carritoProvider.tieneClienteSeleccionado
                              ? '${widget.carritoProvider.clienteSeleccionado?.nombre} ✅'
                              : 'Escribe y presiona Enter o 🔍',
                          // prefixIcon: const Icon(Icons.search),
                          suffixIcon: Consumer<ClientProvider>(
                            builder: (context, clientProviderInner, _) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ✅ Botón de búsqueda
                                    IconButton(
                                      icon: clientProviderInner.isLoading
                                          ? SizedBox(
                                              width: iconSize,
                                              height: iconSize,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                            )
                                          : Icon(Icons.search),
                                      onPressed: clientProviderInner.isLoading
                                          ? null
                                          : () {
                                              debugPrint(
                                                '🔍 Botón presionado: "${_searchClienteController.text}"',
                                              );
                                              _realizarBusquedaLocal();
                                            },
                                      tooltip: 'Buscar',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: baseFontSize * 0.8,
                            vertical: baseFontSize * 0.8,
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
                    SizedBox(width: baseFontSize * 0.5),
                    // ✅ Botón para ver detalle del cliente seleccionado (fuera del input)
                    if (widget.carritoProvider.tieneClienteSeleccionado)
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientDetailScreen(
                                client:
                                    widget.carritoProvider.clienteSeleccionado!,
                              ),
                            ),
                          );
                          debugPrint(
                            '➡️ Navegando a detalle de ${widget.carritoProvider.clienteSeleccionado!.nombre}',
                          );
                        },
                        tooltip: 'Ver detalle del cliente',
                      ),
                  ],
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
                  padding: EdgeInsets.only(top: baseFontSize * 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ NUEVO: Título de resultados
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: baseFontSize * 0.3,
                          vertical: baseFontSize * 0.5,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_search,
                              color: colorScheme.primary,
                            ),
                            SizedBox(width: baseFontSize * 0.5),
                            Text(
                              'Resultados de búsqueda',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: baseFontSize * 0.5),
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
                                  widget.carritoProvider.setClienteSeleccionado(
                                    client,
                                  );
                                  _searchClienteController.clear();
                                  // ✅ Desactivar búsqueda después de seleccionar
                                  setState(() => _busquedaActiva = false);
                                  debugPrint(
                                    '✅ Cliente seleccionado desde resultados: ${client.nombre}',
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${client.nombre}$creditBadge',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            SizedBox(
                                              height: baseFontSize * 0.25,
                                            ),
                                            if (client.telefono != null &&
                                                client.telefono!.isNotEmpty)
                                              Text(
                                                client.telefono!,
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // ✅ NUEVO: Botón para ver detalle del cliente
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward_ios,
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
                                          debugPrint(
                                            '➡️ Navegando a detalle de ${client.nombre}',
                                          );
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
                  padding: EdgeInsets.only(top: baseFontSize * 0.5),
                  child: Container(
                    padding: EdgeInsets.all(baseFontSize * 0.8),
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
                        ),
                        SizedBox(width: baseFontSize * 0.5),
                        Expanded(
                          child: Text(
                            'No se encontraron clientes que coincidan con "${_searchClienteController.text}"',
                            style: TextStyle(
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
        ],
      ),
    );
  }
}
