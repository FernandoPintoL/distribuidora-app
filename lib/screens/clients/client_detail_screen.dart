import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils.dart';
import 'client_form_screen.dart';
import 'direccion_form_screen_for_client.dart';

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
  bool _isLoading = false;
  late ClientProvider _clientProvider;

  @override
  void initState() {
    super.initState();

    try {
      debugPrint('📱 Initializing ClientDetailScreen state...');
      debugPrint('📋 Client ID: ${widget.client.id}, Name: ${widget.client.nombre}');

      _tabController = TabController(length: 2, vsync: this);
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
            content: Text('Error al cargar direcciones: ${addressError.toString()}'),
            backgroundColor: Colors.orange.shade700,
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
      appBar: AppBar(
        title: Text(_client!.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.teal.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditClient(),
              tooltip: 'Editar cliente',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
              tooltip: 'Eliminar cliente',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.green.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Información', icon: Icon(Icons.info_outline, size: 20)),
                Tab(text: 'Direcciones', icon: Icon(Icons.location_on_outlined, size: 20)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildDireccionesTab(),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.teal.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _agregarDireccion,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_location, size: 24),
        label: const Text(
          'Agregar Dirección',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                          color: Colors.black.withOpacity(0.2),
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
                          Colors.green.shade400,
                          Colors.green.shade600,
                          Colors.teal.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.green.shade50,
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
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Icon(
                        Icons.hourglass_empty,
                        color: Colors.white,
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
          if (_hasValidCoordinates()) _buildMapCard(),
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
                        backgroundColor: Colors.green.shade50,
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                    )
                    .toList(),
              ),
            ]),
          if (_client!.ventanasEntrega != null &&
              _client!.ventanasEntrega!.isNotEmpty)
            _buildInfoCard('Ventanas de entrega', [
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
      final principalAddress = _client!.direcciones!.cast<ClientAddress?>().firstWhere(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.teal.shade50],
              ),
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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

  /// Construye de forma segura la imagen de perfil o muestra fallback
  Widget _buildSafeProfileImage() {
    try {
      if (_client?.fotoPerfil == null || _client!.fotoPerfil!.isEmpty) {
        return const Icon(
          Icons.person,
          size: 58,
          color: Colors.green,
        );
      }
      return _buildProfileImage(_client!.fotoPerfil!);
    } catch (e, stackTrace) {
      debugPrint('❌ Error crítico al construir imagen de perfil: $e');
      debugPrint('Stack trace: $stackTrace');
      // En caso de cualquier error, mostrar el ícono por defecto
      return const Icon(
        Icons.person,
        size: 58,
        color: Colors.green,
      );
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
      child: const Icon(
        Icons.person_outline,
        size: 56,
        color: Colors.green,
      ),
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
                color: Colors.grey.shade600,
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

  Widget _buildEmptyDireccionesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay direcciones registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega la primera dirección para este cliente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDireccionCard(ClientAddress direccion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: direccion.esPrincipal
            ? Border.all(
                color: Colors.green.shade300,
                width: 2,
              )
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
                        gradient: direccion.esPrincipal
                            ? LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade600],
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade300, Colors.grey.shade400],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (direccion.esPrincipal ? Colors.green : Colors.grey)
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                          ),
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
                            Icon(Icons.star, size: 12, color: Colors.white),
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
                      Icon(Icons.map, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        [
                          if (direccion.ciudad != null) direccion.ciudad,
                          if (direccion.departamento != null)
                            direccion.departamento,
                        ].join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
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
                      Icon(Icons.gps_fixed,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'GPS: ${direccion.latitud!.toStringAsFixed(6)}, ${direccion.longitud!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _abrirEnMaps(
                            direccion.latitud!, direccion.longitud!),
                        child: Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue.shade600,
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
                      Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccion.observaciones!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!direccion.esPrincipal)
                      TextButton.icon(
                        onPressed: () => _marcarComoPrincipal(direccion),
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('Marcar como principal'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _editarDireccion(direccion),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _eliminarDireccion(direccion),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
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
        builder: (context) => DireccionFormScreenForClient(
          clientId: _client!.id,
        ),
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
    final url =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
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
    debugPrint('🖼️ Inicializando _ImageWithFallback con ${widget.urls.length} URLs');
  }

  void _tryNextUrl() {
    if (!mounted) return;

    if (_currentUrlIndex < widget.urls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        debugPrint('🔄 Intentando URL ${_currentUrlIndex + 1}/${widget.urls.length}: ${widget.urls[_currentUrlIndex]}');
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
                    debugPrint('✅ Imagen cargada exitosamente desde: ${widget.urls[_currentUrlIndex]}');
                  }
                });
              }
              return child;
            }
            // Mostrar indicador de carga
            return widget.loadingWidget;
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error cargando imagen desde: ${widget.urls[_currentUrlIndex]}');
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
