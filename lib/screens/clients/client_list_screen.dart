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
import '../login_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | active | inactive
  late ClientProvider _clientProvider;
  bool _isLoadingClients = false; // Flag para prevenir llamadas simultáneas
  bool _isLoadingMore = false; // Flag para carga de más clientes

  @override
  void initState() {
    super.initState();
    // Obtener referencia segura al provider
    _clientProvider = context.read<ClientProvider>();

    // Configurar listener para scroll infinito
    _scrollController.addListener(_onScroll);

    // Cargar automáticamente al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cuando está a 200px del final, cargar más
      if (!_isLoadingMore && _clientProvider.hasMorePages) {
        _loadMoreClients();
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
        perPage: 5, // Cargar solo 5 clientes por página
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
      debugPrint(
        '✅ Clientes cargados: ${_clientProvider.clients.length} de ${_clientProvider.totalItems}',
      );
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

  void _safeLoadClients() {
    if (mounted) {
      _loadClients();
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _safeRefreshClients() async {
    if (mounted) {
      await _loadClients();
    }
  }

  Future<void> _loadMoreClients() async {
    if (!mounted) {
      debugPrint('⚠️ _loadMoreClients: Widget no está montado, cancelando');
      return;
    }

    if (_isLoadingMore || _isLoadingClients) {
      debugPrint(
        '⚠️ _loadMoreClients: Ya hay una carga en progreso, cancelando',
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
    debugPrint(
      '📋 Cargando más clientes (página ${_clientProvider.currentPage + 1})...',
    );

    try {
      await _clientProvider.loadClients(
        page: _clientProvider.currentPage + 1,
        perPage: 5, // Cargar solo 5 clientes por página
        append: true,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      /* appBar: CustomGradientAppBar(
        title: 'Clientes',
        customGradient: AppGradients.blue,
        actions: [
          RefreshAction(
            isLoading: _isLoadingClients,
            onRefresh: _safeLoadClients,
          ),
        ],
      ), */
      body: Container(
        color: colorScheme.surface,
        child: Column(
          children: [
            // Barra de búsqueda modernizada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar clientes...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: _isLoadingClients ? null : _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
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
                          _buildModernFilterChip(
                            label: 'Todos',
                            isSelected: _statusFilter == 'all',
                            onTap: () {
                              setState(() => _statusFilter = 'all');
                              _safeLoadClients();
                            },
                            icon: Icons.people,
                          ),
                          const SizedBox(width: 8),
                          _buildModernFilterChip(
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
                          _buildModernFilterChip(
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
                ],
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
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando clientes...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                            const Text(
                              'No hay clientes',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
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
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
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
                                              Colors.blue.shade600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Cargando más clientes...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _isLoadingClients ? null : () => _navigateToCreateClient(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: _isLoadingClients ? 'Cargando...' : 'Nuevo cliente',
          icon: _isLoadingClients
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                )
              : Icon(Icons.add, size: 24, color: colorScheme.onPrimary),
          label: Text(
            'Nuevo Cliente',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color chipColor = color ?? colorScheme.primary;
    final Color lightColor =
        Color.lerp(chipColor, colorScheme.surface, 0.3) ?? chipColor;
    final Color darkColor =
        Color.lerp(chipColor, colorScheme.onSurface, 0.2) ?? chipColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [lightColor, darkColor])
              : null,
          color: isSelected ? null : colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
        perPage: 5, // Cargar solo 5 clientes por página
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
    }
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
            content: Text('❌ No se pudo realizar la llamada. Intenta de nuevo.'),
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
        final webUri = Uri.parse('https://web.whatsapp.com/send?phone=$formattedNumber');
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
}

class ClientListItem extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEdit;

  const ClientListItem({
    super.key,
    required this.client,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar con gradiente
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            client.fotoPerfil != null &&
                                client.fotoPerfil!.isNotEmpty
                            ? _buildProfileImage(context, client.fotoPerfil!)
                            : Container(
                                color: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildClientInfo(colorScheme)],
                  ),
                ),

                // Acciones y estado
                _buildActionsAndStatus(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        Text(
          client.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Razón Social
        if (client.razonSocial != null && client.razonSocial!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              client.razonSocial!,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Teléfono y Email
        Row(
          children: [
            if (client.telefono != null && client.telefono!.isNotEmpty) ...[
              Icon(Icons.phone, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                client.telefono!,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),

        if (client.email != null && client.email!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.email, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    client.email!,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Localidad y Código
        if (client.localidad != null ||
            (client.codigoCliente != null && client.codigoCliente!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (client.localidad != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _getLocalidadName(client.localidad),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (client.codigoCliente != null &&
                      client.codigoCliente!.isNotEmpty)
                    const SizedBox(width: 8),
                ],
                if (client.codigoCliente != null &&
                    client.codigoCliente!.isNotEmpty)
                  Text(
                    'Cód: ${client.codigoCliente}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

        // Categorías
        if (client.categorias != null && client.categorias!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: client.categorias!
                  .take(2)
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.nombre ?? c.clave ?? 'Cat',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionsAndStatus(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: client.activo
                  ? [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]
                  : [colorScheme.error, colorScheme.error.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (client.activo ? colorScheme.primary : colorScheme.error)
                    .withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            client.activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: client.activo ? colorScheme.onPrimary : colorScheme.onError,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Botón de edición rápida
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.tertiary,
                colorScheme.tertiary.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.edit, color: colorScheme.onTertiary, size: 18),
            onPressed: onEdit,
            tooltip: 'Editar',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),

        // Acciones (llamar y WhatsApp)
        if (client.telefono != null && client.telefono!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onCall != null)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.call,
                      color: colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                    onPressed: onCall,
                    tooltip: 'Llamar',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              if (onWhatsApp != null) ...[
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.message,
                      color: colorScheme.onPrimaryContainer,
                      size: 18,
                    ),
                    onPressed: onWhatsApp,
                    tooltip: 'WhatsApp',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context, String imagePath) {
    // Validar que el imagePath no esté vacío
    if (imagePath.isEmpty) {
      debugPrint('⚠️ ImagePath está vacío, mostrando fallback');
      return _buildFallbackIcon(context);
    }

    // Usar ImageUtils para construir URLs de manera robusta
    final urls = ImageUtils.buildMultipleImageUrls(imagePath);

    if (urls.isEmpty) {
      debugPrint('⚠️ No se pudieron generar URLs para la imagen: $imagePath');
      return _buildFallbackIcon(context);
    }

    debugPrint('🔍 Intentando cargar imagen de perfil desde URLs: $urls');

    final colorScheme = Theme.of(context).colorScheme;
    return _ImageWithFallback(
      urls: urls,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      fallbackWidget: _buildFallbackIcon(context),
      loadingWidget: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer, size: 28),
    );
  }

  String _getLocalidadName(dynamic localidad) {
    if (localidad == null) return '';

    if (localidad is String) {
      return localidad;
    }

    if (localidad is Map<String, dynamic>) {
      return localidad['nombre'] ?? localidad.toString();
    }

    // Si es un objeto Localidad
    try {
      return localidad.nombre ?? '';
    } catch (e) {
      return localidad.toString();
    }
  }
}

/// Widget auxiliar que intenta cargar una imagen desde múltiples URLs
class _ImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallbackWidget;
  final Widget loadingWidget;

  const _ImageWithFallback({
    required this.urls,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackWidget,
    required this.loadingWidget,
  });

  @override
  State<_ImageWithFallback> createState() => _ImageWithFallbackState();
}

class _ImageWithFallbackState extends State<_ImageWithFallback> {
  int _currentUrlIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentUrlIndex >= widget.urls.length) {
      // Todas las URLs fallaron, mostrar fallback
      return widget.fallbackWidget;
    }

    return Image.network(
      widget.urls[_currentUrlIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Imagen cargada exitosamente
          return child;
        }
        return widget.loadingWidget;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '❌ Error al cargar imagen desde: ${widget.urls[_currentUrlIndex]}',
        );
        debugPrint('❌ Error details: $error');

        // Diferir setState para evitar llamar durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentUrlIndex < widget.urls.length - 1) {
            setState(() {
              _currentUrlIndex++;
            });
            debugPrint('🔄 Intentando siguiente URL...');
          } else {
            debugPrint('⚠️ No hay más URLs disponibles, mostrando fallback');
          }
        });

        // Si es la última URL, mostrar fallback inmediatamente
        if (_currentUrlIndex >= widget.urls.length - 1) {
          return widget.fallbackWidget;
        }

        // Retornar loading widget mientras se intenta la siguiente URL
        return widget.loadingWidget;
      },
    );
  }
}
