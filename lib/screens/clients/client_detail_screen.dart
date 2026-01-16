import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import '../../services/url_launcher_service.dart';
import 'client_form_screen.dart';
import 'direccion_form_screen_for_client.dart';
import '../chofer/marcar_visita_screen.dart';
import 'client_map_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Client? _client;
  List<ClientAddress>? _addresses;
  List<VisitaPreventistaCliente>? _visitas;
  bool _isLoading = false;
  bool _isLoadingVisitas = false;
  late ClientProvider _clientProvider;

  @override
  void initState() {
    super.initState();

    try {
      debugPrint('📱 Initializing ClientDetailScreen state...');
      debugPrint(
        '📋 Client ID: ${widget.client.id}, Name: ${widget.client.nombre}',
      );

      _tabController = TabController(length: 3, vsync: this);
      _client = widget.client;

      // Agregar listener al TabController para detectar cambios de tab
      _tabController.addListener(() {
        if (!mounted) return;

        debugPrint('📑 Tab cambiado a índice: ${_tabController.index}');

        // Si cambiamos al tab de direcciones (índice 1) y aún no hemos cargado direcciones
        if (_tabController.index == 1 && _addresses == null) {
          debugPrint('🔄 Cargando direcciones por primera vez...');
          _loadDirecciones();
        }

        // Si cambiamos al tab de visitas (índice 2) y aún no hemos cargado visitas
        if (_tabController.index == 2 && _visitas == null) {
          debugPrint('🔄 Cargando visitas por primera vez...');
          _loadVisitas();
        }

        // Usar addPostFrameCallback para evitar setState durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {}); // Forzar rebuild para actualizar el FAB
          }
        });
      });

      // Obtener referencia al provider después del build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          debugPrint('⚠️ Widget no montado en addPostFrameCallback');
          return;
        }

        try {
          _clientProvider = context.read<ClientProvider>();
          debugPrint('✅ Provider obtenido y listo');
        } catch (e, stackTrace) {
          debugPrint('❌ Error obteniendo provider: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error crítico en initState: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carga las direcciones del cliente de forma lazy (solo cuando se necesitan)
  Future<void> _loadDirecciones() async {
    if (!mounted) {
      debugPrint('⚠️ Widget no montado, cancelando carga de direcciones');
      return;
    }

    // Si ya estamos cargando, no hacer nada (evitar llamadas concurrentes)
    if (_isLoading) {
      debugPrint('⚠️ Ya se está cargando direcciones, omitiendo...');
      return;
    }

    // Si ya tenemos direcciones cargadas, solo continuar si _addresses es null
    // (esto permite recargas cuando _addresses se establece a null explícitamente)
    if (_addresses != null) {
      debugPrint('✅ Direcciones ya cargadas, omitiendo...');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Cargando direcciones del cliente ID: ${_client!.id}');

      _addresses = await _clientProvider.getClientAddresses(_client!.id);
      debugPrint('📍 Direcciones cargadas: ${_addresses?.length ?? 0}');
    } catch (addressError) {
      debugPrint('❌ Error cargando direcciones: $addressError');
      _addresses = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar direcciones: ${addressError.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('✅ Carga de direcciones finalizada');
      }
    }
  }

  /// Carga las visitas del cliente de forma lazy (solo cuando se necesitan)
  Future<void> _loadVisitas() async {
    if (!mounted) {
      debugPrint('⚠️ Widget no montado, cancelando carga de visitas');
      return;
    }

    // Si ya estamos cargando, no hacer nada (evitar llamadas concurrentes)
    if (_isLoadingVisitas) {
      debugPrint('⚠️ Ya se está cargando visitas, omitiendo...');
      return;
    }

    // Si ya tenemos visitas cargadas, solo continuar si _visitas es null
    if (_visitas != null) {
      debugPrint('✅ Visitas ya cargadas, omitiendo...');
      return;
    }

    setState(() => _isLoadingVisitas = true);

    try {
      debugPrint('🔄 Cargando visitas del cliente ID: ${_client!.id}');

      final visitaProvider = context.read<VisitaProvider>();

      // Log antes de la llamada
      debugPrint(
        '📤 Llamando a cargarVisitas(refresh: true, clienteId: ${_client!.id})',
      );

      await visitaProvider.cargarVisitas(refresh: true, clienteId: _client!.id);

      // Verificar si hay error en el provider
      if (visitaProvider.errorMessage != null) {
        debugPrint('⚠️ Error del provider: ${visitaProvider.errorMessage}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${visitaProvider.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      _visitas = visitaProvider.visitas;

      // Log detallado después de la llamada
      debugPrint('✅ Respuesta del provider:');
      debugPrint('   - Visitas cargadas: ${_visitas?.length ?? 0}');
      debugPrint('   - isLoading: ${visitaProvider.isLoading}');
      debugPrint('   - errorMessage: ${visitaProvider.errorMessage}');
      if (_visitas != null && _visitas!.isNotEmpty) {
        debugPrint(
          '   - Primera visita: ${_visitas!.first.id} - ${_visitas!.first.tipoVisita.label}',
        );
      } else if (_visitas != null) {
        debugPrint(
          '   - La lista de visitas está vacía (posiblemente no hay visitas para este cliente)',
        );
      }
    } catch (visitaError) {
      debugPrint('❌ Error cargando visitas: $visitaError');
      _visitas = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar visitas: ${visitaError.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingVisitas = false);
        debugPrint('✅ Carga de visitas finalizada');
      }
    }
  }

  /// Recarga todos los datos del cliente (usado después de editar)
  Future<void> _reloadClientData() async {
    if (!mounted) {
      debugPrint('⚠️ Widget no montado, cancelando recarga');
      return;
    }

    // Solo restablecer _addresses a null, NO establecer _isLoading aquí
    // porque _loadDirecciones() lo maneja internamente
    setState(() {
      _addresses = null; // Forzar recarga
    });

    debugPrint('🔄 Recargando datos del cliente...');
    await _loadDirecciones();
  }

  Future<void> _navigateToEditClient() async {
    if (_client == null) return;

    // Navegar a la pantalla de edición y esperar el resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: _client),
      ),
    );

    // Si se editó exitosamente el cliente, recargar los datos
    if (result == true) {
      _reloadClientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Scaffold(body: Center(child: Text('Cliente no encontrado')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomGradientAppBar(
        titleWidget: Text(
          _client!.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        customGradient: AppGradients.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de acciones (Editar/Eliminar)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Editar cliente',
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToEditClient(),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mostrar botón Ver en Mapa solo en tab de Direcciones
                      if (_tabController.index == 1)
                        Tooltip(
                          message: 'Ver ubicaciones en mapa',
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ClientMapScreen(client: _client!),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text('Ver en Mapa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      if (_tabController.index == 1) const SizedBox(width: 12),
                      Tooltip(
                        message: 'Eliminar cliente',
                        child: ElevatedButton.icon(
                          onPressed: _showDeleteDialog,
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                // TabBar
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        text: 'Información',
                        icon: Icon(Icons.info_outline, size: 20),
                      ),
                      Tab(
                        text: 'Direcciones',
                        icon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                      Tab(text: 'Visitas', icon: Icon(Icons.history, size: 20)),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(),
                      _buildDireccionesTab(),
                      _buildVisitasTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Solo mostrar el FAB si estamos en la tab de direcciones
    if (_tabController.index != 1) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _agregarDireccion,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(Icons.add_location, size: 24, color: colorScheme.onPrimary),
        label: Text(
          'Agregar Dirección',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de perfil moderna mejorada
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sombra externa
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  // Borde decorativo
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: _buildSafeProfileImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Indicador de estado (opcional)
                  if (_isLoading)
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.hourglass_empty,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildInfoCard('Información Básica', [
            _buildInfoRow('Nombre', _client!.nombre),
            if (_client!.razonSocial != null)
              _buildInfoRow('Razón Social', _client!.razonSocial!),
            if (_client!.nit != null) _buildInfoRow('NIT', _client!.nit!),
            if (_client!.email != null) _buildInfoRow('Email', _client!.email!),
            if (_client!.telefono != null)
              _buildContactRow(
                'Teléfono',
                _client!.telefono!,
                onCall: () => _makePhoneCall(_client!.telefono!),
                onWhatsApp: () => _sendWhatsAppMessage(_client!.telefono!),
              ),
            if (_client!.localidad != null)
              _buildInfoRow('Localidad', _getLocalidadName()),
            if (_client!.codigoCliente != null &&
                _client!.codigoCliente!.isNotEmpty)
              _buildInfoRow('Código Cliente', _client!.codigoCliente!),
            _buildInfoRow('Activo', _client!.activo ? 'Sí' : 'No'),
          ]),
          const SizedBox(height: 16),
          // if (_hasValidCoordinates()) _buildMapCard(),
          const SizedBox(height: 16),
          if (_client!.categorias != null && _client!.categorias!.isNotEmpty)
            _buildInfoCard('Categorías', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _client!.categorias!
                    .map(
                      (c) => Chip(
                        label: Text(c.nombre ?? c.clave ?? 'Categoría'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          if (_client!.ventanasEntrega != null &&
              _client!.ventanasEntrega!.isNotEmpty)
            _buildInfoCard('Días de visitas', [
              Column(
                children: _client!.ventanasEntrega!
                    .map((v) => _buildDeliveryWindowRow(v))
                    .toList(),
              ),
            ]),
          const SizedBox(height: 16),
          if (_client!.observaciones != null)
            _buildInfoCard('Observaciones', [Text(_client!.observaciones!)]),
        ],
      ),
    );
  }

  bool _hasValidCoordinates() {
    // Primero verificar coordenadas del cliente principal
    if (_client!.latitud != null && _client!.longitud != null) {
      return true;
    }

    // Si no hay coordenadas en el cliente, verificar direcciones
    if (_addresses != null && _addresses!.isNotEmpty) {
      return _addresses!.any(
        (address) => address.latitud != null && address.longitud != null,
      );
    }

    return false;
  }

  LatLng? _getClientLocation() {
    // Primero intentar usar coordenadas del cliente principal
    if (_client!.latitud != null && _client!.longitud != null) {
      return LatLng(_client!.latitud!, _client!.longitud!);
    }

    // Si no hay coordenadas en el cliente, buscar en direcciones
    if (_addresses != null && _addresses!.isNotEmpty) {
      // Buscar dirección principal con coordenadas
      final principalAddress = _addresses!.cast<ClientAddress?>().firstWhere(
        (address) =>
            address?.esPrincipal == true &&
            address?.latitud != null &&
            address?.longitud != null,
        orElse: () => null,
      );

      if (principalAddress != null) {
        return LatLng(principalAddress.latitud!, principalAddress.longitud!);
      }

      // Si no hay dirección principal, usar la primera con coordenadas
      final addressWithCoords = _addresses!.cast<ClientAddress?>().firstWhere(
        (address) => address?.latitud != null && address?.longitud != null,
        orElse: () => null,
      );

      if (addressWithCoords != null) {
        return LatLng(addressWithCoords.latitud!, addressWithCoords.longitud!);
      }
    }

    return null;
  }

  Widget _buildMapCard() {
    final location = _getClientLocation();
    if (location == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ubicación',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4.0),
                bottomRight: Radius.circular(4.0),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('client_location'),
                    position: location,
                    infoWindow: InfoWindow(
                      title: _client!.nombre,
                      snippet: _getClientAddressString(),
                    ),
                  ),
                },
                mapType: MapType.normal,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  // Opcional: guardar controller para uso futuro
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del cliente
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cliente: ${_client!.nombre}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_client!.codigoCliente != null)
                            Text(
                              'Código: ${_client!.codigoCliente}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (_client!.localidad != null)
                            Text(
                              'Localidad: ${_getLocalidadName()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Coordenadas: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url =
                              'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Ver en Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getClientAddressString() {
    // Primero intentar usar dirección del cliente principal
    if (_client!.direcciones != null && _client!.direcciones!.isNotEmpty) {
      final principalAddress = _client!.direcciones!
          .cast<ClientAddress?>()
          .firstWhere(
            (address) => address?.esPrincipal == true,
            orElse: () => null,
          );

      if (principalAddress != null) {
        return principalAddress.direccion;
      }

      // Si no hay dirección principal, usar la primera
      return _client!.direcciones!.first.direccion;
    }

    // Si no hay direcciones en el cliente, usar las direcciones cargadas
    if (_addresses != null && _addresses!.isNotEmpty) {
      final principalAddress = _addresses!.cast<ClientAddress?>().firstWhere(
        (address) => address?.esPrincipal == true,
        orElse: () => null,
      );

      if (principalAddress != null) {
        return principalAddress.direccion;
      }

      return _addresses!.first.direccion;
    }

    return 'Dirección no disponible';
  }

  String _getLocalidadName() {
    if (_client!.localidad != null) {
      if (_client!.localidad is Map<String, dynamic>) {
        final localidadMap = _client!.localidad as Map<String, dynamic>;
        return localidadMap['nombre'] ?? 'Localidad desconocida';
      } else if (_client!.localidad is Localidad) {
        return (_client!.localidad as Localidad).nombre;
      }
    }
    return 'Sin localidad';
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryWindowRow(VentanaEntregaCliente v) {
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final day = (v.diaSemana >= 0 && v.diaSemana <= 6)
        ? days[v.diaSemana]
        : 'Día ${v.diaSemana}';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        Icons.access_time,
        color: v.activo ? Colors.green : Colors.grey,
      ),
      title: Text('$day: ${v.horaInicio} - ${v.horaFin}'),
      subtitle: v.activo
          ? null
          : const Text('Inactivo', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    String label,
    String value, {
    VoidCallback? onCall,
    VoidCallback? onWhatsApp,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(value),
                const Spacer(),
                if (onCall != null)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: onCall,
                    tooltip: 'Llamar',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                if (onWhatsApp != null)
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.green),
                    onPressed: onWhatsApp,
                    tooltip: 'WhatsApp',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text('¿Está seguro de que desea eliminar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteClient();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await _clientProvider.deleteClient(_client!.id);

    if (success) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Cliente eliminado exitosamente')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _clientProvider.errorMessage ?? 'Error al eliminar cliente',
          ),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // ✅ Usar el nuevo servicio robusto con reintentos
    final success = await UrlLauncherService.makePhoneCall(phoneNumber);

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No se pudo realizar la llamada. Intenta de nuevo o verifica el número.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber) async {
    // ✅ Usar el nuevo servicio robusto con reintentos
    final success = await UrlLauncherService.openWhatsApp(phoneNumber);

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  /// Construye de forma segura la imagen de perfil o muestra fallback
  Widget _buildSafeProfileImage() {
    try {
      if (_client?.fotoPerfil == null || _client!.fotoPerfil!.isEmpty) {
        return const Icon(Icons.person, size: 58, color: Colors.green);
      }
      return _buildProfileImage(_client!.fotoPerfil!);
    } catch (e, stackTrace) {
      debugPrint('❌ Error crítico al construir imagen de perfil: $e');
      debugPrint('Stack trace: $stackTrace');
      // En caso de cualquier error, mostrar el ícono por defecto
      return const Icon(Icons.person, size: 58, color: Colors.green);
    }
  }

  Widget _buildProfileImage(String imagePath) {
    // Validar que el imagePath no esté vacío
    if (imagePath.isEmpty) {
      debugPrint('⚠️ ImagePath está vacío, mostrando fallback');
      return _buildFallbackAvatar();
    }

    // Usar ImageUtils para construir URLs de manera robusta
    final urls = ImageUtils.buildMultipleImageUrls(imagePath);

    if (urls.isEmpty) {
      debugPrint('⚠️ No se pudieron generar URLs para la imagen: $imagePath');
      return _buildFallbackAvatar();
    }

    debugPrint('🔍 Intentando cargar imagen de perfil desde URLs: $urls');

    return GestureDetector(
      onTap: () {
        // Solo mostrar imagen en pantalla completa si hay una URL válida
        if (urls.isNotEmpty) {
          _showFullScreenImage(urls.first);
        }
      },
      child: _ImageWithFallback(
        urls: urls,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        fallbackWidget: _buildFallbackAvatar(),
        loadingWidget: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(56),
          ),
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(56),
      ),
      child: const Icon(Icons.person_outline, size: 56, color: Colors.green),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      ),
                    );
                  },
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDireccionesTab() {
    final colorScheme = Theme.of(context).colorScheme;

    // Si aún no hemos intentado cargar las direcciones
    if (_addresses == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando direcciones...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_addresses!.isEmpty) {
      return _buildEmptyDireccionesState();
    }

    return RefreshIndicator(
      onRefresh: _reloadClientData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses!.length,
        itemBuilder: (context, index) {
          final direccion = _addresses![index];
          return _buildDireccionCard(direccion);
        },
      ),
    );
  }

  Widget _buildVisitasTab() {
    // Si aún no hemos intentado cargar las visitas
    if (_visitas == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando visitas...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Verificar si hay ventanas_entrega configuradas
    final tieneVentanasEntrega = _client?.ventanasEntrega?.isNotEmpty ?? false;

    // Si no hay ventanas y no hay visitas
    if (!tieneVentanasEntrega && _visitas!.isEmpty) {
      return _buildEmptyVisitasState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _visitas = null);
        await _loadVisitas();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de plan de visitas de ESTA SEMANA (SIEMPRE mostrar si hay ventanas)
          if (tieneVentanasEntrega) _buildPlanSemanal(),

          // Si no hay ventanas pero hay visitas, mostrar solo historial
          if (!tieneVentanasEntrega && _visitas!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay días de visita programados para este cliente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Separador solo si hay ventanas y visitas
          if (tieneVentanasEntrega && _visitas!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 16),
          ],

          // Título del historial (solo si hay visitas)
          if (_visitas!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Historial Completo de Visitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '${_visitas!.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Historial de todas las visitas
            ..._visitas!.map((visita) => _buildVisitaCard(visita)),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenCumplimiento(
    int visitasCumplidas,
    int visitasProgramadas,
    int porcentajeCumplimiento,
    List<String> diasVisitados,
    List<String> diasPendientes,
  ) {
    final cumplido = porcentajeCumplimiento >= 100;
    final alerta = porcentajeCumplimiento < 50 && visitasProgramadas > 0;
    final color = cumplido
        ? Colors.green
        : alerta
        ? Colors.red
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progreso y porcentaje
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cumplimiento Semanal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$porcentajeCumplimiento%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: visitasProgramadas > 0
                  ? visitasCumplidas / visitasProgramadas
                  : 0,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),

          // Estadísticas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$visitasCumplidas de $visitasProgramadas días',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'visitados esta semana',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Alerta si hay días pendientes
          if (diasPendientes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Días pendientes:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...diasPendientes.map((dia) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $dia',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Resumen de visitados
          if (diasVisitados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visitados:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: diasVisitados.map((dia) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          dia,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSemanal() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];

    // Obtener información de la semana actual
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday % 7));
    final finSemana = inicioSemana.add(const Duration(days: 6));

    debugPrint(
      '📅 Semana actual: ${inicioSemana.toLocal().toIso8601String()} a ${finSemana.toLocal().toIso8601String()}',
    );

    // Obtener días visitados EN ESTA SEMANA
    final ventanasActivas = _client!.ventanasEntrega!
        .where((v) => v.activo)
        .toList();

    // Mapeo: para cada ventana, encontrar si hay visita exitosa ESTA SEMANA
    final Map<int, VisitaPreventistaCliente?> visitasPorDia = {};

    for (final ventana in ventanasActivas) {
      // Buscar visita exitosa para este día EN ESTA SEMANA
      final visita = _visitas!.where((visita) {
        final visitDate = visita.fechaHoraVisita;
        final visitDayIndex = visitDate.weekday % 7;

        // Verificar que sea:
        // 1. El día correcto (lunes, martes, etc.)
        // 2. Esta semana (entre inicioSemana y finSemana)
        // 3. Estado exitoso
        final esEseDia = visitDayIndex == ventana.diaSemana;
        final esEsaSemana =
            visitDate.isAfter(inicioSemana) &&
            visitDate.isBefore(finSemana.add(const Duration(days: 1)));
        final esExitoso =
            visita.estadoVisita == EstadoVisitaPreventista.EXITOSA;

        return esEseDia && esEsaSemana && esExitoso;
      }).firstOrNull;

      if (visita != null) {
        debugPrint('   ✓ Visitado el día ${ventana.diaSemana} esta semana');
      } else {
        debugPrint('   ✗ Pendiente el día ${ventana.diaSemana} esta semana');
      }

      visitasPorDia[ventana.diaSemana] = visita;
    }

    // Calcular cumplimiento
    int visitasCumplidas = visitasPorDia.values.where((v) => v != null).length;
    int visitasProgramadas = ventanasActivas.length;
    final porcentajeCumplimiento = visitasProgramadas > 0
        ? ((visitasCumplidas / visitasProgramadas) * 100).toInt()
        : 0;

    final cumplido = porcentajeCumplimiento >= 100;
    final alerta = porcentajeCumplimiento < 50 && visitasProgramadas > 0;
    final color = cumplido
        ? Colors.green
        : alerta
        ? Colors.red
        : Colors.orange;

    // Ordenar ventanas por día de semana
    final ventanasOrdenadas = [...ventanasActivas]
      ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));

    return Column(
      children: [
        // Encabezado con título
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_repeat,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan de Visitas - Esta Semana',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Cumplimiento: $visitasCumplidas de $visitasProgramadas días',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$porcentajeCumplimiento%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: visitasProgramadas > 0
                ? visitasCumplidas / visitasProgramadas
                : 0,
            minHeight: 10,
            backgroundColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 20),

        // Botón para marcar nueva visita
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarcarVisitaScreen(cliente: _client!),
                ),
              ).then((_) {
                // Al volver, recargar las visitas
                setState(() => _visitas = null);
                _loadVisitas();
              });
            },
            icon: const Icon(Icons.add_location),
            label: const Text('Marcar Nueva Visita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de días de esta semana
        ...ventanasOrdenadas.map((ventana) {
          final visita = visitasPorDia[ventana.diaSemana];
          final visitado = visita != null;
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

          // Colores adaptativos para modo oscuro
          final bgColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15))
              : (visitado ? Colors.green.shade50 : Colors.orange.shade50);

          final borderColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.4)
                    : Colors.orange.withOpacity(0.4))
              : (visitado ? Colors.green.shade200 : Colors.orange.shade200);

          final statusBgColor = isDark
              ? (visitado
                    ? Colors.green.withOpacity(0.25)
                    : Colors.orange.withOpacity(0.25))
              : (visitado ? Colors.green.shade100 : Colors.orange.shade100);

          final statusTextColor = isDark
              ? (visitado ? Colors.green.shade300 : Colors.orange.shade300)
              : (visitado ? Colors.green.shade700 : Colors.orange.shade700);

          final detailBgColor = isDark
              ? colorScheme.surface
              : Colors.white.withOpacity(0.7);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: visitado ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          visitado ? Icons.check_circle : Icons.schedule,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                days[ventana.diaSemana],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  visitado ? 'Visitado' : 'Pendiente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ventana.horaInicio} - ${ventana.horaFin}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (visitado && visita != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: detailBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: visitado
                                  ? Colors.green
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Visitado: ${dateFormat.format(visita.fechaHoraVisita)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (visita.tipoVisita != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getTipoVisitaIcon(visita.tipoVisita),
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tipo: ${visita.tipoVisita.label}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVentanasEntregaSection() {
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];

    // Obtener días visitados en esta semana
    final ventanasActivas = _client!.ventanasEntrega!
        .where((v) => v.activo)
        .toList();

    // Mapeo: para cada ventana, encontrar si hay visita exitosa
    final Map<int, VisitaPreventistaCliente?> visitasPorDia = {};

    debugPrint(
      '🔍 Buscando visitas para ${ventanasActivas.length} días programados',
    );
    debugPrint('📊 Total de visitas cargadas: ${_visitas!.length}');

    for (final ventana in ventanasActivas) {
      // Buscar visita exitosa para este día
      // Nota: En BD, dia_semana es 0=domingo a 6=sábado
      // En Dart, DateTime.weekday es 1=lunes a 7=domingo
      // Entonces weekday % 7 convierte a: 0=domingo, 1=lunes, ..., 6=sábado ✓
      final visita = _visitas!.where((visita) {
        final visitDate = visita.fechaHoraVisita;
        final visitDayIndex = visitDate.weekday % 7;
        return visitDayIndex == ventana.diaSemana &&
            visita.estadoVisita == EstadoVisitaPreventista.EXITOSA;
      }).firstOrNull;

      if (visita != null) {
        debugPrint(
          '   ✓ Encontrada visita para día ${ventana.diaSemana}: ${visita.fechaHoraVisita.toLocal()}',
        );
      } else {
        debugPrint(
          '   ✗ Sin visita exitosa para día programado ${ventana.diaSemana}',
        );
      }

      visitasPorDia[ventana.diaSemana] = visita;
    }

    // Calcular estadísticas
    int visitasCumplidas = visitasPorDia.values.where((v) => v != null).length;
    int visitasProgramadas = ventanasActivas.length;
    final porcentajeCumplimiento = visitasProgramadas > 0
        ? ((visitasCumplidas / visitasProgramadas) * 100).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Días Programados para Visita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tarjeta de Resumen de Cumplimiento
          _buildResumenVisitasCliente(ventanasActivas, visitasPorDia, days),
          const SizedBox(height: 16),

          // Leyenda
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          border: Border.all(color: Colors.green.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Visitado', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          border: Border.all(color: Colors.orange.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Pendiente', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('No prog.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenVisitasCliente(
    List<VentanaEntregaCliente> ventanasActivas,
    Map<int, VisitaPreventistaCliente?> visitasPorDia,
    List<String> days,
  ) {
    // Calcular estadísticas
    int visitasCumplidas = visitasPorDia.values.where((v) => v != null).length;
    int visitasProgramadas = ventanasActivas.length;
    final porcentajeCumplimiento = visitasProgramadas > 0
        ? ((visitasCumplidas / visitasProgramadas) * 100).toInt()
        : 0;

    final cumplido = porcentajeCumplimiento >= 100;
    final alerta = porcentajeCumplimiento < 50 && visitasProgramadas > 0;
    final color = cumplido
        ? Colors.green
        : alerta
        ? Colors.red
        : Colors.orange;

    // Ordenar ventanas por día de semana
    final ventanasOrdenadas = [...ventanasActivas]
      ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));

    return Column(
      children: [
        // Título
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan de Visitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    'Cumplimiento: $visitasCumplidas de $visitasProgramadas días ($porcentajeCumplimiento%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$porcentajeCumplimiento%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: visitasProgramadas > 0
                ? visitasCumplidas / visitasProgramadas
                : 0,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de días - ENFOQUE PRINCIPAL
        ...ventanasOrdenadas.map((ventana) {
          final visita = visitasPorDia[ventana.diaSemana];
          final visitado = visita != null;
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: visitado ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: visitado
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: visitado ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          visitado ? Icons.check_circle : Icons.schedule,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                days[ventana.diaSemana],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: visitado
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  visitado ? 'Visitado' : 'Pendiente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: visitado
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ventana.horaInicio} - ${ventana.horaFin}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (visitado && visita != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Visitado: ${dateFormat.format(visita.fechaHoraVisita)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (visita.tipoVisita != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getTipoVisitaIcon(visita.tipoVisita),
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tipo: ${visita.tipoVisita.label}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyDireccionesState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay direcciones registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega la primera dirección para este cliente',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _agregarDireccion,
              icon: const Icon(Icons.add_location),
              label: const Text('Agregar Primera Dirección'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVisitasState() {
    final tieneVentanasEntrega = _client?.ventanasEntrega?.isNotEmpty ?? false;
    final diasProgramados =
        _client?.ventanasEntrega?.where((v) => v.activo).length ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _visitas = null);
        await _loadVisitas();
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay visitas registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (tieneVentanasEntrega)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Este cliente tiene $diasProgramados día(s) de visita programado(s), pero aún no hay registros de visitas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El preventista aún no ha registrado visitas para este cliente en los días programados.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No hay visitas registradas y no hay días de visita programados para este cliente.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDireccionCard(ClientAddress direccion) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: direccion.esPrincipal
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editarDireccion(direccion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y badge principal
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: direccion.esPrincipal
                            ? Colors.green
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (direccion.esPrincipal
                                        ? Colors.green
                                        : colorScheme.primary)
                                    .withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        direccion.esPrincipal ? Icons.home : Icons.location_on,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        direccion.direccion,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (direccion.esPrincipal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Detalles de ubicación
                if (direccion.ciudad != null || direccion.departamento != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.map, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          [
                            if (direccion.ciudad != null) direccion.ciudad,
                            if (direccion.departamento != null)
                              direccion.departamento,
                          ].join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Coordenadas GPS
                if (direccion.latitud != null && direccion.longitud != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS: ${direccion.latitud!.toStringAsFixed(6)}, ${direccion.longitud!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _abrirEnMaps(
                            direccion.latitud!,
                            direccion.longitud!,
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Observaciones
                if (direccion.observaciones != null &&
                    direccion.observaciones!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            direccion.observaciones!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Divider(height: 24, color: Theme.of(context).dividerColor),

                // Acciones
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    if (!direccion.esPrincipal)
                      TextButton.icon(
                        onPressed: () => _marcarComoPrincipal(direccion),
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('Marcar como principal'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => _editarDireccion(direccion),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _eliminarDireccion(direccion),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _agregarDireccion() async {
    if (_client == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DireccionFormScreenForClient(clientId: _client!.id),
      ),
    );

    if (result == true) {
      _reloadClientData();
    }
  }

  Future<void> _editarDireccion(ClientAddress direccion) async {
    if (_client == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DireccionFormScreenForClient(
          clientId: _client!.id,
          direccion: direccion,
        ),
      ),
    );

    if (result == true) {
      _reloadClientData();
    }
  }

  Future<void> _marcarComoPrincipal(ClientAddress direccion) async {
    if (_client == null || direccion.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede marcar como principal esta dirección'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como Principal'),
        content: Text(
          '¿Deseas marcar esta dirección como principal?\n\n${direccion.direccion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await _clientProvider.setPrincipalAddress(
        _client!.id,
        direccion.id!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dirección marcada como principal'),
              backgroundColor: Colors.green,
            ),
          );
          _reloadClientData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _clientProvider.errorMessage ??
                    'Error al marcar como principal',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarDireccion(ClientAddress direccion) async {
    if (_client == null || direccion.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar esta dirección'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (direccion.esPrincipal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar la dirección principal. Marca otra como principal primero.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: Text(
          '¿Estás seguro de eliminar esta dirección?\n\n${direccion.direccion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await _clientProvider.deleteClientAddress(
        _client!.id,
        direccion.id!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dirección eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _reloadClientData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _clientProvider.errorMessage ?? 'Error al eliminar dirección',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirEnMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildVisitaCard(VisitaPreventistaCliente visita) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Fecha y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateFormat.format(visita.fechaHoraVisita),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  _buildEstadoBadge(visita.estadoVisita),
                ],
              ),
              const SizedBox(height: 16),

              // Tipo de visita
              Row(
                children: [
                  Icon(
                    _getTipoVisitaIcon(visita.tipoVisita),
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tipo: ${visita.tipoVisita.label}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ventana horaria
              Row(
                children: [
                  Icon(
                    visita.dentroVentanaHoraria
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 18,
                    color: visita.dentroVentanaHoraria
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    visita.dentroVentanaHoraria
                        ? 'Dentro de ventana horaria'
                        : 'Fuera de ventana horaria',
                    style: TextStyle(
                      fontSize: 13,
                      color: visita.dentroVentanaHoraria
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Observaciones
              if (visita.observaciones != null &&
                  visita.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visita.observaciones!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Divider(height: 24, color: Theme.of(context).dividerColor),

              // Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón ver ubicación
                  TextButton.icon(
                    onPressed: () =>
                        _abrirEnMaps(visita.latitud, visita.longitud),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Ver ubicación'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),

                  // Botón ver foto (si existe)
                  if (visita.fotoLocal != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _mostrarFotoVisita(visita.fotoLocal!),
                      icon: const Icon(Icons.photo, size: 18),
                      label: const Text('Ver foto'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoVisitaPreventista estado) {
    final color = estado == EstadoVisitaPreventista.EXITOSA
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado == EstadoVisitaPreventista.EXITOSA
                ? Icons.check_circle
                : Icons.cancel,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            estado.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTipoVisitaIcon(TipoVisitaPreventista tipo) {
    switch (tipo) {
      case TipoVisitaPreventista.COBRO:
        return Icons.payment;
      case TipoVisitaPreventista.TOMA_PEDIDO:
        return Icons.shopping_cart;
      case TipoVisitaPreventista.ENTREGA:
        return Icons.local_shipping;
      case TipoVisitaPreventista.SUPERVISION:
        return Icons.visibility;
      case TipoVisitaPreventista.OTRO:
        return Icons.more_horiz;
    }
  }

  void _mostrarFotoVisita(String fotoUrl) {
    // Construir URL completa de la imagen
    final imageUrls = ImageUtils.buildMultipleImageUrls(fotoUrl);

    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar la imagen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrls.first,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      ),
                    );
                  },
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget auxiliar que intenta cargar una imagen desde múltiples URLs
/// Si falla, muestra inmediatamente un ícono de perfil
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
  bool _hasError = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🖼️ Inicializando _ImageWithFallback con ${widget.urls.length} URLs',
    );
  }

  void _tryNextUrl() {
    if (!mounted) return;

    if (_currentUrlIndex < widget.urls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        debugPrint(
          '🔄 Intentando URL ${_currentUrlIndex + 1}/${widget.urls.length}: ${widget.urls[_currentUrlIndex]}',
        );
      });
    } else {
      setState(() {
        _hasError = true;
        debugPrint('❌ Todas las URLs fallaron, mostrando fallback');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya agotamos todas las URLs, mostrar fallback
    if (_hasError || _currentUrlIndex >= widget.urls.length) {
      return widget.fallbackWidget;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.width / 2),
        color: Colors.green.shade50,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.width / 2),
        child: Image.network(
          widget.urls[_currentUrlIndex],
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // Imagen cargada exitosamente
              if (!_imageLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _imageLoaded = true);
                    debugPrint(
                      '✅ Imagen cargada exitosamente desde: ${widget.urls[_currentUrlIndex]}',
                    );
                  }
                });
              }
              return child;
            }
            // Mostrar indicador de carga
            return widget.loadingWidget;
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              '❌ Error cargando imagen desde: ${widget.urls[_currentUrlIndex]}',
            );
            debugPrint('❌ Error: $error');

            // Intentar siguiente URL en el siguiente frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _tryNextUrl();
            });

            // Mientras tanto, mostrar fallback para evitar pantalla en blanco
            return widget.fallbackWidget;
          },
        ),
      ),
    );
  }
}
