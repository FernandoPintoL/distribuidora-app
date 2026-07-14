import 'package:distribuidora/extensions/theme_extension.dart';
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
import 'widgets/fab_add_direccion_widget.dart';
import 'widgets/info_tab_widget.dart';
import 'widgets/direcciones_tab_widget.dart';
import 'widgets/visitas_tab_widget.dart';
import 'widgets/change_password_modal.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int _currentIndex = 0;
  Client? _client;
  List<ClientAddress>? _addresses;
  List<VisitaPreventistaCliente>? _visitas;
  bool _isLoading = false;
  bool _isLoadingVisitas = false;
  late ClientProvider _clientProvider;

  @override
  @override
  void initState() {
    super.initState();

    try {
      debugPrint('🔱 Initializing ClientDetailScreen state...');
      debugPrint(
        '📋 Client ID: ${widget.client.id}, Name: ${widget.client.nombre}',
      );

      _client = widget.client;

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
    super.dispose();
  }

  void _onNavigationItemTapped(int index) {
    setState(() => _currentIndex = index);

    if (index == 1 && _addresses == null) {
      _loadDirecciones();
    }

    if (index == 2 && _visitas == null) {
      _loadVisitas();
    }
  }

  /// Carga las direcciones del cliente de forma lazy (solo cuando se necesitan)
  Future<void> _loadDirecciones() async {
    if (!mounted) {
      debugPrint('âš ï¸ Widget no montado, cancelando carga de direcciones');
      return;
    }

    // Si ya estamos cargando, no hacer nada (evitar llamadas concurrentes)
    if (_isLoading) {
      debugPrint('âš ï¸ Ya se estÃ¡ cargando direcciones, omitiendo...');
      return;
    }

    // Si ya tenemos direcciones cargadas, solo continuar si _addresses es null
    // (esto permite recargas cuando _addresses se establece a null explÃ­citamente)
    if (_addresses != null) {
      debugPrint('âœ… Direcciones ya cargadas, omitiendo...');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('ðŸ”„ Cargando direcciones del cliente ID: ${_client!.id}');

      _addresses = await _clientProvider.getClientAddresses(_client!.id);
      debugPrint('ðŸ“ Direcciones cargadas: ${_addresses?.length ?? 0}');
    } catch (addressError) {
      debugPrint('âŒ Error cargando direcciones: $addressError');
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
        debugPrint('âœ… Carga de direcciones finalizada');
      }
    }
  }

  /// Carga las visitas del cliente de forma lazy (solo cuando se necesitan)
  Future<void> _loadVisitas() async {
    if (!mounted) {
      debugPrint('âš ï¸ Widget no montado, cancelando carga de visitas');
      return;
    }

    // Si ya estamos cargando, no hacer nada (evitar llamadas concurrentes)
    if (_isLoadingVisitas) {
      debugPrint('âš ï¸ Ya se estÃ¡ cargando visitas, omitiendo...');
      return;
    }

    // Si ya tenemos visitas cargadas, solo continuar si _visitas es null
    if (_visitas != null) {
      debugPrint('âœ… Visitas ya cargadas, omitiendo...');
      return;
    }

    setState(() => _isLoadingVisitas = true);

    try {
      debugPrint('ðŸ”„ Cargando visitas del cliente ID: ${_client!.id}');

      final visitaProvider = context.read<VisitaProvider>();

      // Log antes de la llamada
      debugPrint(
        'ðŸ“¤ Llamando a cargarVisitas(refresh: true, clienteId: ${_client!.id})',
      );

      await visitaProvider.cargarVisitas(refresh: true, clienteId: _client!.id);

      // Verificar si hay error en el provider
      if (visitaProvider.errorMessage != null) {
        debugPrint('âš ï¸ Error del provider: ${visitaProvider.errorMessage}');
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

      // Log detallado despuÃ©s de la llamada
      debugPrint('âœ… Respuesta del provider:');
      debugPrint('   - Visitas cargadas: ${_visitas?.length ?? 0}');
      debugPrint('   - isLoading: ${visitaProvider.isLoading}');
      debugPrint('   - errorMessage: ${visitaProvider.errorMessage}');
      if (_visitas != null && _visitas!.isNotEmpty) {
        debugPrint(
          '   - Primera visita: ${_visitas!.first.id} - ${_visitas!.first.tipoVisita.label}',
        );
      } else if (_visitas != null) {
        debugPrint(
          '   - La lista de visitas estÃ¡ vacÃ­a (posiblemente no hay visitas para este cliente)',
        );
      }
    } catch (visitaError) {
      debugPrint('âŒ Error cargando visitas: $visitaError');
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
        debugPrint('âœ… Carga de visitas finalizada');
      }
    }
  }

  /// Recarga todos los datos del cliente (usado después de editar)
  Future<void> _reloadClientData() async {
    if (!mounted) {
      debugPrint('âš ï¸ Widget no montado, cancelando recarga');
      return;
    }

    // Solo restablecer _addresses a null, NO establecer _isLoading aquÃ­
    // porque _loadDirecciones() lo maneja internamente
    setState(() {
      _addresses = null; // Forzar recarga
    });

    debugPrint('ðŸ”„ Recargando datos del cliente...');
    await _loadDirecciones();
  }

  Future<void> _navigateToEditClient() async {
    if (_client == null) return;

    // Navegar a la pantalla de ediciÃ³n y esperar el resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: _client),
      ),
    );

    // Si se editÃ³ exitosamente el cliente, recargar los datos
    if (result == true) {
      _reloadClientData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Scaffold(body: Center(child: Text('Cliente no encontrado')));
    }

    bool isDark = context.isDark;

    return Scaffold(
      appBar: CustomGradientAppBar(
        titleWidget: Text(
          _client!.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: AppTextStyles.headlineSmall(context).fontSize!,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<int>(
            color: Theme.of(context).colorScheme.surface,
            onSelected: (value) {
              if (value == 1) {
                showDialog(
                  context: context,
                  builder: (context) => ChangePasswordModal(client: _client!),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 18,
                      color: context.colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    const Text('Cambiar Contraseña'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
          Tooltip(
            message: 'Eliminar cliente',
            child: IconButton(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_outline),
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      InfoTabWidget(
                        client: _client,
                        onImageTap: () {
                          if (_client?.fotoPerfil != null &&
                              _client!.fotoPerfil!.isNotEmpty) {
                            final urls = ImageUtils.buildMultipleImageUrls(
                              _client!.fotoPerfil!,
                            );
                            if (urls.isNotEmpty) {
                              _showFullScreenImage(urls.first);
                            }
                          }
                        },
                        onEdit: _navigateToEditClient,
                        onCall:
                            _client?.telefono != null &&
                                _client!.telefono!.isNotEmpty
                            ? () => _makePhoneCall(_client!.telefono!)
                            : null,
                        onWhatsApp:
                            _client?.telefono != null &&
                                _client!.telefono!.isNotEmpty
                            ? () => _sendWhatsAppMessage(_client!.telefono!)
                            : null,
                      ),
                      DireccionesTabWidget(
                        addresses: _addresses,
                        onAdd: _agregarDireccion,
                        onEdit: _editarDireccion,
                        onDelete: _eliminarDireccion,
                        onSetPrincipal: _marcarComoPrincipal,
                        onRefresh: _reloadClientData,
                      ),
                      VisitasTabWidget(
                        visitas: _visitas,
                        client: _client,
                        onMarkVisita: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MarcarVisitaScreen(cliente: _client!),
                            ),
                          ).then((_) {
                            setState(() => _visitas = null);
                            _loadVisitas();
                          });
                        },
                        onRefresh: () async {
                          setState(() => _visitas = null);
                          await _loadVisitas();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 1
          ? Stack(
              children: [
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientMapScreen(client: _client!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Ver en Mapa'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _agregarDireccion,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Agregar Dirección'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Información',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Direcciones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Visitas'),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text(
          'Â¿EstÃ¡ seguro de que desea eliminar este cliente?',
        ),
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
              // BotÃ³n de cerrar
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
          'Â¿Deseas marcar esta dirección como principal?\n\n${direccion.direccion ?? ''}',
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
          'Estás seguro de eliminar esta dirección?\n\n${direccion.direccion ?? ''}',
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
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
}
