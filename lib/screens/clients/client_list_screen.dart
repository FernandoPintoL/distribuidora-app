import 'package:distribuidora/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../services/url_launcher_service.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';
import 'client_map_screen.dart';
import '../login_screen.dart';
import '../chofer/marcar_visita_screen.dart';
import 'widgets/client_list_item.dart';
import 'widgets/filter_chip_widget.dart';

class ClientListScreen extends StatefulWidget {
  final VoidCallback?
  onBecomesVisible; // ✅ Callback cuando se selecciona esta pestaña

  const ClientListScreen({super.key, this.onBecomesVisible});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | active | inactive
  int? _selectedLocalidadId; // ✅ NUEVO: Filtro por localidad
  late ClientProvider _clientProvider;
  bool _isLoadingClients = false; // Flag para prevenir llamadas simultáneas
  bool _isLoadingMore = false; // Flag para carga de más clientes
  bool _hasInitialized = false; // ✅ Rastrear si ya hemos intentado cargar
  bool _isLoadingLocalidades = false; // ✅ NUEVO: Flag para carga de localidades

  // ✅ CONFIGURACIÓN DE PAGINACIÓN
  static const int PER_PAGE = 20; // Aumentado de 5 a 20 items por página
  static const int SCROLL_THRESHOLD =
      300; // Distancia en px para trigger de carga

  @override
  void initState() {
    super.initState();
    // Obtener referencia segura al provider
    _clientProvider = context.read<ClientProvider>();

    // Configurar listener para scroll infinito
    _scrollController.addListener(_onScroll);

    // ✅ Cargar localidades para el filtro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLocalidades();
      }
    });

    // ✅ OPTIMIZADO: No cargar clientes en initState
    // Los clientes se cargarán solo cuando el usuario navegue a esta pestaña
    // mediante didChangeWidget o cuando se haga pull-to-refresh
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // ✅ MEJORADO: Detector de scroll adaptable y más sensible
    final scrollPosition = _scrollController.position;
    final distanceFromBottom =
        scrollPosition.maxScrollExtent - scrollPosition.pixels;

    // Trigger cuando estamos a menos de SCROLL_THRESHOLD del final
    if (distanceFromBottom <= SCROLL_THRESHOLD) {
      if (!_isLoadingMore && _clientProvider.hasMorePages) {
        debugPrint(
          '📍 Scroll trigger: ${distanceFromBottom.toStringAsFixed(0)}px del final',
        );
        _loadMoreClientes();
      }
    }
  }

  bool? _activeFilterValue() {
    switch (_statusFilter) {
      case 'active':
        return true;
      case 'inactive':
        return false;
      default:
        return null;
    }
  }

  Future<void> _loadClients() async {
    if (!mounted) {
      debugPrint(' _loadClients: Widget no está montado, cancelando');
      return;
    }

    if (_isLoadingClients) {
      debugPrint(' _loadClients: Ya hay una carga en progreso, cancelando');
      return;
    }

    setState(() {
      _isLoadingClients = true;
    });
    debugPrint(' Iniciando carga de clientes...');

    try {
      await _clientProvider.loadClients(
        perPage: PER_PAGE, // ✅ Usar constante configurable
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
        localidadId: _selectedLocalidadId, // ✅ NUEVO: Filtro por localidad
      );
      debugPrint(
        '✅ Clientes cargados: ${_clientProvider.clients.length} de ${_clientProvider.totalItems}',
      );
      _logPaginationInfo();
    } catch (e) {
      debugPrint('❌ Error al cargar clientes: $e');
      // El error será manejado por el provider y mostrado en la UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
        });
      }
      debugPrint(' Finalizada carga de clientes');
    }
  }

  // ✅ NUEVO: Cargar localidades para el filtro
  Future<void> _loadLocalidades() async {
    if (!mounted || _isLoadingLocalidades) return;

    setState(() {
      _isLoadingLocalidades = true;
    });

    try {
      debugPrint('🌍 Cargando localidades...');
      await _clientProvider.loadLocalidades();
      debugPrint(
        '✅ Localidades cargadas: ${_clientProvider.localidades.length}',
      );
    } catch (e) {
      debugPrint('❌ Error al cargar localidades: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocalidades = false;
        });
      }
    }
  }

  void _safeLoadClients() {
    if (mounted) {
      _loadClients();
    }
  }

  Future<void> _safeRefreshClients() async {
    if (mounted) {
      await _loadClients();
    }
  }

  /// ✅ Método público para cargar clientes cuando se selecciona esta pestaña
  /// Carga solo si aún no hay clientes cargados
  void loadClientsIfNeeded() {
    if (mounted && _clientProvider.clients.isEmpty && !_isLoadingClients) {
      _safeLoadClients();
    }
  }

  Future<void> _loadMoreClientes() async {
    if (!mounted) {
      debugPrint('⚠️ _loadMoreClientes: Widget no está montado, cancelando');
      return;
    }

    if (_isLoadingMore || _isLoadingClients) {
      debugPrint(
        '⚠️ _loadMoreClientes: Ya hay una carga en progreso, cancelando',
      );
      return;
    }

    if (!_clientProvider.hasMorePages) {
      debugPrint('ℹ️ No hay más páginas para cargar');
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _clientProvider.currentPage + 1;
    debugPrint('📋 Cargando más clientes (página $nextPage)...');

    try {
      await _clientProvider.loadClients(
        page: nextPage,
        perPage: PER_PAGE, // ✅ Usar constante configurable
        append: true,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
        localidadId: _selectedLocalidadId, // ✅ NUEVO: Filtro por localidad
      );
      _logPaginationInfo();
      debugPrint(
        '✅ Más clientes cargados: ${_clientProvider.clients.length} de ${_clientProvider.totalItems}',
      );
    } catch (e) {
      debugPrint('❌ Error al cargar más clientes: $e');
      // El error será manejado por el provider y mostrado en la UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    if (mounted) {
      _safeLoadClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ OPTIMIZADO: NO cargar clientes automáticamente
    // Los clientes se cargarán SOLO cuando el usuario haga pull-to-refresh
    // Esto evita hacer requests innecesarias al abrir home_screen

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        color: colorScheme.surface,
        child: Column(
          children: [
            // Barra de búsqueda modernizada
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar clientes...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        /*prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),*/
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: _isLoadingClients
                                    ? null
                                    : _clearSearch,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _performSearch(),
                      enabled: !_isLoadingClients,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondary,
                        colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoadingClients ? null : _navigateToCreateClient,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nuevo',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Filtros modernizados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ModernFilterChip(
                            label: 'Todos',
                            isSelected: _statusFilter == 'all',
                            onTap: () {
                              setState(() => _statusFilter = 'all');
                              _safeLoadClients();
                            },
                            icon: Icons.people,
                          ),
                          const SizedBox(width: 8),
                          ModernFilterChip(
                            label: 'Activos',
                            isSelected: _statusFilter == 'active',
                            onTap: () {
                              setState(() => _statusFilter = 'active');
                              _safeLoadClients();
                            },
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          ModernFilterChip(
                            label: 'Inactivos',
                            isSelected: _statusFilter == 'inactive',
                            onTap: () {
                              setState(() => _statusFilter = 'inactive');
                              _safeLoadClients();
                            },
                            icon: Icons.cancel,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isLoadingClients
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                // colorScheme.secondary,
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.refresh, color: colorScheme.secondary),
                    onPressed: _isLoadingClients ? null : _safeLoadClients,
                    tooltip: 'Actualizar',
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ✅ NUEVO: Mostrar resumen de filtros aplicados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<ClientProvider>(
                builder: (context, clientProvider, _) {
                  final tieneSearchQuery = _searchQuery.isNotEmpty;
                  final tieneStatusFilter = _statusFilter != 'all';
                  final tieneLocalidadFilter = _selectedLocalidadId != null;
                  final totalFiltros =
                      (tieneSearchQuery ? 1 : 0) +
                      (tieneStatusFilter ? 1 : 0) +
                      (tieneLocalidadFilter ? 1 : 0);

                  final localidadNombre = _selectedLocalidadId != null
                      ? clientProvider.localidades
                            .firstWhere(
                              (l) => l.id == _selectedLocalidadId,
                              orElse: () => Localidad(
                                id: -1,
                                nombre: '',
                                codigo: '',
                                activo: true,
                              ),
                            )
                            .nombre
                      : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            totalFiltros == 0
                                ? 'Sin filtros activos'
                                : totalFiltros == 1
                                ? '1 filtro activo'
                                : '$totalFiltros filtros activos',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${clientProvider.clients.length} resultado${clientProvider.clients.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (totalFiltros > 0) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (tieneSearchQuery)
                              Chip(
                                label: Text(
                                  'Búsqueda: "$_searchQuery"',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onDeleted: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _safeLoadClients();
                                },
                              ),
                            if (tieneStatusFilter)
                              Chip(
                                label: Text(
                                  'Estado: ${_statusFilter == 'active' ? 'Activos' : 'Inactivos'}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onDeleted: () {
                                  setState(() => _statusFilter = 'all');
                                  _safeLoadClients();
                                },
                              ),
                            if (tieneLocalidadFilter)
                              Chip(
                                label: Text(
                                  'Localidad: $localidadNombre',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onDeleted: () {
                                  setState(() => _selectedLocalidadId = null);
                                  _safeLoadClients();
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Mostrar mensaje de carga si está cargando inicialmente
            if (_isLoadingClients && _clientProvider.clients.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: context.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text('Cargando clientes...'),
                    ],
                  ),
                ),
              )
            else
              // Clients list
              Expanded(
                child: Consumer<ClientProvider>(
                  builder: (context, clientProvider, child) {
                    if (clientProvider.isLoading &&
                        clientProvider.clients.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (clientProvider.errorMessage != null &&
                        clientProvider.clients.isEmpty) {
                      final colorScheme = Theme.of(context).colorScheme;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              clientProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoadingClients
                                  ? null
                                  : _safeLoadClients,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (clientProvider.clients.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay clientes',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isLoadingClients
                                  ? null
                                  : _safeLoadClients,
                              child: const Text('Cargar Clientes'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _isLoadingClients
                          ? () async {}
                          : _safeRefreshClients,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            clientProvider.clients.length +
                            (_isLoadingMore ? 1 : 0) +
                            (clientProvider.clients.isNotEmpty &&
                                    !_isLoadingMore &&
                                    clientProvider.hasMorePages
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          // ✅ NUEVO: Mostrar footer de paginación
                          if (index == clientProvider.clients.length &&
                              !_isLoadingMore &&
                              clientProvider.hasMorePages) {
                            final currentPage = clientProvider.currentPage;
                            final totalPages =
                                (clientProvider.totalItems / PER_PAGE).ceil();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Página $currentPage de $totalPages',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '⬇️ Desliza para cargar más clientes',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Mostrar indicador de carga al final
                          if (index == clientProvider.clients.length) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              context.colorScheme.secondary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Cargando más clientes...',
                                      style: TextStyle(
                                        color: context.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final client = clientProvider.clients[index];
                          return ClientListItem(
                            client: client,
                            onTap: () => _onClientTap(client),
                            onCall:
                                client.telefono != null &&
                                    client.telefono!.isNotEmpty
                                ? () => _makePhoneCall(client.telefono!)
                                : null,
                            onWhatsApp:
                                client.telefono != null &&
                                    client.telefono!.isNotEmpty
                                ? () => _sendWhatsAppMessage(client.telefono!)
                                : null,
                            onEdit: () => _navigateToEditClient(client),
                            onMarcarVisita: () =>
                                _navigateToMarcarVisita(client),
                            onViewMap: () => _navigateToClientMap(client),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      // ✅ FAB removido, botón "Nuevo Cliente" ahora está en AppBar
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _performSearch() {
    if (!mounted) return;
    // La búsqueda se realiza en el backend y puede filtrar por:
    // - Nombre del cliente
    // - Localidad
    // - Teléfono
    // - NIT/CI
    // - Código de cliente
    if (mounted) {
      _clientProvider.loadClients(
        perPage: PER_PAGE, // ✅ Usar constante configurable
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
      _logPaginationInfo();
    }
  }

  /// ✅ NUEVO: Registra información de paginación en los logs
  void _logPaginationInfo() {
    final currentPage = _clientProvider.currentPage;
    final totalItems = _clientProvider.totalItems;
    final totalPages = (totalItems / PER_PAGE).ceil();
    final hasMore = _clientProvider.hasMorePages;

    debugPrint(
      '📊 PAGINACIÓN: Página $currentPage de $totalPages | '
      'Items: ${_clientProvider.clients.length}/$totalItems | '
      'Hay más: ${hasMore ? 'SÍ ✅' : 'NO ⛔'}',
    );
  }

  void _onClientTap(Client client) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(client: client),
      ),
    );
  }

  /// Navegar directamente al formulario de edición (edición rápida)
  Future<void> _navigateToEditClient(Client client) async {
    if (!mounted) return;

    final result = await Navigator.pushNamed(
      context,
      '/client-form',
      arguments: client,
    );

    // Si se editó exitosamente, recargar la lista
    if (result == true && mounted) {
      _loadClients();
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // ✅ Usar el nuevo servicio robusto con reintentos
      final success = await UrlLauncherService.makePhoneCall(phoneNumber);

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ No se pudo realizar la llamada. Intenta de nuevo.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error al realizar llamada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber) async {
    try {
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      if (!formattedNumber.startsWith('+')) {
        if (!formattedNumber.startsWith('591')) {
          formattedNumber = '591$formattedNumber';
        }
      } else {
        formattedNumber = formattedNumber.substring(1);
      }

      final Uri launchUri = Uri.parse('https://wa.me/$formattedNumber');
      debugPrint('💬 WhatsApp a: $formattedNumber');

      if (!await canLaunchUrl(launchUri)) {
        if (!mounted) return;
        debugPrint('❌ WhatsApp no está disponible en este dispositivo');

        // Intentar abrir el navegador como fallback
        final webUri = Uri.parse(
          'https://web.whatsapp.com/send?phone=$formattedNumber',
        );
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp no está instalado en este dispositivo'),
          ),
        );
        return;
      }

      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error al abrir WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir WhatsApp: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToCreateClient() {
    debugPrint(' Iniciando navegación a ClientFormScreen');

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ClientFormScreen()));
  }

  void _navigateToMarcarVisita(Client client) {
    if (!mounted) return;
    debugPrint(
      '📍 Navegando a MarcarVisitaScreen para cliente: ${client.nombre}',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MarcarVisitaScreen(cliente: client),
      ),
    );
  }

  void _navigateToClientMap(Client client) {
    if (!mounted) return;
    debugPrint(
      '🗺️ Navegando a ClientMapScreen para cliente: ${client.nombre}',
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ClientMapScreen(client: client)),
    );
  }
}
