import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils.dart';
import 'client_form_screen.dart';

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
  List<Map<String, dynamic>>? _salesHistory;
  bool _isLoading = false;
  late ClientProvider _clientProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _client = widget.client;
    // Obtener referencia segura al provider
    _clientProvider = context.read<ClientProvider>();
    Future.delayed(Duration.zero, () {
      _loadClientData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Cargar cliente actualizado
      final updatedClient = await _clientProvider.getClient(_client!.id);
      if (updatedClient != null && mounted) {
        setState(() => _client = updatedClient);
      }

      // Cargar direcciones
      _addresses = await _clientProvider.getClientAddresses(_client!.id);

      // Cargar historial de ventas
      try {
        _salesHistory = await _clientProvider.getClientSalesHistory(
          _client!.id,
        );
        // Si _salesHistory es null, asignar una lista vacía
        _salesHistory ??= [];
      } catch (historyError) {
        debugPrint('Error cargando historial de ventas: $historyError');
        _salesHistory = [];
      }
    } catch (e) {
      // Manejar errores si es necesario
      debugPrint('Error loading client data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      _loadClientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Scaffold(body: Center(child: Text('Cliente no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_client!.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditClient(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Información')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabController, children: [_buildInfoTab()]),
      /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new address
        },
        child: const Icon(Icons.add),
      ), */
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
                            child:
                                _client!.fotoPerfil != null &&
                                    _client!.fotoPerfil!.isNotEmpty
                                ? _buildProfileImage(_client!.fotoPerfil!)
                                : const Icon(
                                    Icons.person,
                                    size: 58,
                                    color: Colors.green,
                                  ),
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
      ClientAddress? principalAddress;
      try {
        principalAddress = _addresses!.firstWhere(
          (address) =>
              address.esPrincipal == true &&
              address.latitud != null &&
              address.longitud != null,
        );
      } catch (e) {
        principalAddress = null;
      }

      if (principalAddress != null) {
        return LatLng(principalAddress.latitud!, principalAddress.longitud!);
      }

      // Si no hay dirección principal, usar la primera con coordenadas
      ClientAddress? addressWithCoords;
      try {
        addressWithCoords = _addresses!.firstWhere(
          (address) => address.latitud != null && address.longitud != null,
        );
      } catch (e) {
        addressWithCoords = null;
      }

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
      ClientAddress? principalAddress;
      try {
        principalAddress = _client!.direcciones!.firstWhere(
          (address) => address.esPrincipal == true,
        );
      } catch (e) {
        principalAddress = null;
      }

      if (principalAddress != null) {
        return principalAddress.direccion;
      }

      // Si no hay dirección principal, usar la primera
      return _client!.direcciones!.first.direccion;
    }

    // Si no hay direcciones en el cliente, usar las direcciones cargadas
    if (_addresses != null && _addresses!.isNotEmpty) {
      ClientAddress? principalAddress;
      try {
        principalAddress = _addresses!.firstWhere(
          (address) => address.esPrincipal == true,
        );
      } catch (e) {
        principalAddress = null;
      }

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
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
      onTap: () => _showFullScreenImage(urls.first),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ImageWithFallback(
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
          // Indicador sutil de que es interactivo
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
            ),
          ),
        ],
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
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_currentUrlIndex >= widget.urls.length) {
      // Todas las URLs fallaron, mostrar fallback
      return widget.fallbackWidget;
    }

    if (_hasError) {
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.urls[_currentUrlIndex],
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // Imagen cargada exitosamente
                  if (mounted) {
                    Future.microtask(() => setState(() => _isLoading = false));
                  }
                  return child;
                }
                return widget.loadingWidget;
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  '❌ Error al cargar imagen desde: ${widget.urls[_currentUrlIndex]}',
                );
                debugPrint('❌ Error details: $error');

                // Usar Future.microtask para evitar llamar setState durante build
                Future.microtask(() {
                  if (mounted && _currentUrlIndex < widget.urls.length - 1) {
                    setState(() {
                      _currentUrlIndex++;
                      _hasError = false;
                    });
                    debugPrint('🔄 Intentando siguiente URL...');
                  } else if (mounted) {
                    setState(() {
                      _hasError = true;
                    });
                    debugPrint(
                      '⚠️ No hay más URLs disponibles, mostrando fallback',
                    );
                  }
                });

                // Si es la última URL, mostrar fallback inmediatamente
                if (_currentUrlIndex >= widget.urls.length - 1) {
                  return widget.fallbackWidget;
                }

                // Retornar loading widget mientras se intenta la siguiente URL
                return widget.loadingWidget;
              },
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: widget.loadingWidget,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
