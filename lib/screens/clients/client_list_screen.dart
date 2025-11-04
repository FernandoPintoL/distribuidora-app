import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils.dart';
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
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | active | inactive
  late ClientProvider _clientProvider;
  bool _isLoadingClients = false; // Flag para prevenir llamadas simultáneas

  @override
  void initState() {
    super.initState();
    // Obtener referencia segura al provider
    _clientProvider = context.read<ClientProvider>();
    // Cargar automáticamente al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
      debugPrint(' Clientes cargados exitosamente');
    } catch (e) {
      debugPrint(' Error al cargar clientes: ');
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
      debugPrint(' _loadMoreClients: Widget no está montado, cancelando');
      return;
    }

    if (_isLoadingClients) {
      debugPrint(' _loadMoreClients: Ya hay una carga en progreso, cancelando');
      return;
    }

    setState(() {
      _isLoadingClients = true;
    });
    debugPrint(' Iniciando carga de más clientes...');

    try {
      await _clientProvider.loadClients(
        page: _clientProvider.currentPage + 1,
        append: true,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        active: _activeFilterValue(),
      );
      debugPrint(' Más clientes cargados exitosamente');
    } catch (e) {
      debugPrint(' Error al cargar más clientes: ');
      // El error será manejado por el provider y mostrado en la UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
        });
      }
      debugPrint(' Finalizada carga de más clientes');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
          // Mostrar indicador de carga en el AppBar si está cargando
          if (_isLoadingClients)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _safeLoadClients,
              tooltip: 'Recargar lista',
            ),
          /*Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.canCreateClients) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _isLoadingClients
                      ? null
                      : () => _navigateToCreateClient(),
                  tooltip: _isLoadingClients ? 'Cargando...' : 'Nuevo cliente',
                );
              }
              return const SizedBox.shrink();
            },
          ),*/
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Buscar por nombre, localidad, teléfono, NIT, código cliente...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoadingClients ? null : _performSearch,
                  tooltip: 'Buscar',
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isLoadingClients ? null : _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              enabled: !_isLoadingClients, // Deshabilitar durante carga
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _statusFilter == 'all',
                  onSelected: (val) {
                    setState(() => _statusFilter = 'all');
                    _safeLoadClients();
                  },
                ),
                FilterChip(
                  label: const Text('Activos'),
                  selected: _statusFilter == 'active',
                  onSelected: (val) {
                    setState(() => _statusFilter = 'active');
                    _safeLoadClients();
                  },
                ),
                FilterChip(
                  label: const Text('Inactivos'),
                  selected: _statusFilter == 'inactive',
                  onSelected: (val) {
                    setState(() => _statusFilter = 'inactive');
                    _safeLoadClients();
                  },
                ),
              ],
            ),
          ),

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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            clientProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
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
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                    child: Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !clientProvider.isLoading &&
                                  clientProvider.hasMorePages &&
                                  !_isLoadingClients) {
                                _loadMoreClients();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              itemCount: clientProvider.clients.length,
                              itemBuilder: (context, index) {
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
                                      ? () => _sendWhatsAppMessage(
                                          client.telefono!,
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ),
                        if (clientProvider.isLoading &&
                            clientProvider.clients.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoadingClients ? null : () => _navigateToCreateClient(),
        backgroundColor: _isLoadingClients ? Colors.grey : null,
        tooltip: _isLoadingClients ? 'Cargando...' : 'Nuevo cliente',
        child: _isLoadingClients
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo realizar la llamada')),
      );
    }
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber) async {
    // Asegurarse de que el número tenga el formato correcto (sin espacios ni caracteres especiales)
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (!formattedNumber.startsWith('+')) {
      // Si no tiene código de país, asumimos que es Bolivia (+591)
      if (!formattedNumber.startsWith('591')) {
        formattedNumber = '591$formattedNumber';
      }
    } else {
      // Si ya tiene +, quitamos el + y dejamos solo los números
      formattedNumber = formattedNumber.substring(1);
    }

    final Uri launchUri = Uri.parse('https://wa.me/$formattedNumber');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
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

  const ClientListItem({
    super.key,
    required this.client,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: client.fotoPerfil != null && client.fotoPerfil!.isNotEmpty
                ? _buildProfileImage(client.fotoPerfil!)
                : const Icon(Icons.person, color: Colors.green),
          ),
        ),
        title: Text(
          client.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.razonSocial != null && client.razonSocial!.isNotEmpty)
              Text('Razón Social: ${client.razonSocial}'),
            if (client.email != null && client.email!.isNotEmpty)
              Text(client.email!),
            if (client.telefono != null && client.telefono!.isNotEmpty)
              Text('Tel: ${client.telefono}'),
            if (client.nit != null && client.nit!.isNotEmpty)
              Text('CI/NIT: ${client.nit}'),
            if (client.localidad != null)
              Text('Localidad: ${_getLocalidadName(client.localidad)}'),
            if (client.codigoCliente != null &&
                client.codigoCliente!.isNotEmpty)
              Text('Código: ${client.codigoCliente}'),
            if (client.categorias != null && client.categorias!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: client.categorias!
                      .map((c) => Chip(
                            label: Text(c.nombre ?? c.clave ?? 'Cat'),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
        trailing: client.telefono != null && client.telefono!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCall != null)
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: onCall,
                      tooltip: 'Llamar',
                      iconSize: 20,
                    ),
                  if (onWhatsApp != null)
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.green),
                      onPressed: onWhatsApp,
                      tooltip: 'WhatsApp',
                      iconSize: 20,
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: client.activo
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      client.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: client.activo ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: client.activo
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  client.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: client.activo ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildProfileImage(String imagePath) {
    // Validar que el imagePath no esté vacío
    if (imagePath.isEmpty) {
      debugPrint('⚠️ ImagePath está vacío, mostrando fallback');
      return _buildFallbackIcon();
    }

    // Usar ImageUtils para construir URLs de manera robusta
    final urls = ImageUtils.buildMultipleImageUrls(imagePath);

    if (urls.isEmpty) {
      debugPrint('⚠️ No se pudieron generar URLs para la imagen: $imagePath');
      return _buildFallbackIcon();
    }

    debugPrint('🔍 Intentando cargar imagen de perfil desde URLs: $urls');

    return _ImageWithFallback(
      urls: urls,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      fallbackWidget: _buildFallbackIcon(),
      loadingWidget: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.green,
        size: 28,
      ),
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
