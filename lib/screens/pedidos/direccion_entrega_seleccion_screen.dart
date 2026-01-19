import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class DireccionEntregaSeleccionScreen extends StatefulWidget {
  // ✅ Aceptar clienteId opcional para cuando accesa un preventista
  final int? clienteId;

  const DireccionEntregaSeleccionScreen({super.key, this.clienteId});

  @override
  State<DireccionEntregaSeleccionScreen> createState() =>
      _DireccionEntregaSeleccionScreenState();
}

class _DireccionEntregaSeleccionScreenState
    extends State<DireccionEntregaSeleccionScreen> {
  ClientAddress? _direccionSeleccionada;
  bool _isLoading = true;
  Client? _cliente;
  String? _errorMessage;
  bool _esPreventista = false;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    final authProvider = context.read<AuthProvider>();
    final clientProvider = context.read<ClientProvider>();
    final carritoProvider = context.read<CarritoProvider>();

    debugPrint(
      '🚚 Cargando direcciones cliente en carrito ${carritoProvider.getClienteSeleccionadoId()} | ${authProvider.user?.id}',
    );

    // print("🔄 Cargando direcciones de entrega... ${clientProvider)}");
    debugPrint('🔄 Auth User Roles: ${authProvider.user?.roles}');
    debugPrint('🔄 Auth User ID: ${authProvider.user?.id}');

    if (authProvider.user?.id != null) {
      Client? cliente;

      debugPrint('🔄 Usuario autenticado ID: ${authProvider.user?.id}');

      // ✅ Verificar si es preventista o cliente
      final roles = authProvider.user?.roles ?? [];
      final esPreventista = roles.any(
        (role) => role.toLowerCase().contains('preventista'),
      );
      _esPreventista = esPreventista;

      if (esPreventista && carritoProvider.getClienteSeleccionadoId() != null) {
        // ✅ PREVENTISTA: Obtener direcciones del cliente específico
        debugPrint(
          '👤 [PREVENTISTA] Cargando direcciones del cliente #${carritoProvider.getClienteSeleccionadoId()}',
        );
        debugPrint('🔄 Auth User Roles: ${authProvider.user?.roles}');
        cliente = await clientProvider.getClient(
          carritoProvider.getClienteSeleccionadoId()!,
        );
      } else if (!esPreventista) {
        // ✅ CLIENTE: Obtener su propio perfil
        debugPrint('👥 [CLIENTE] Cargando mi perfil con mis direcciones');
        cliente = await clientProvider.getClientPerfil();
        carritoProvider.setClienteSeleccionado(cliente);
        debugPrint('✅ Cliente cargado: ${cliente?.nombre}');
        debugPrint('🔄 Cliente ID: ${cliente?.id}');
        debugPrint('puede tener credito ?: ${cliente?.puedeAtenerCredito}');
        debugPrint(
          '🔄 Cliente direcciones: ${cliente?.direcciones?.length ?? 0}',
        );
        debugPrint(
          '🔄 id direccion : ${cliente?.direcciones?.isNotEmpty == true ? cliente?.direcciones?.first.id : 'N/A'}',
        );
      } else {
        // ❌ Preventista pero sin clienteId
        _errorMessage = 'No se proporcionó el cliente a consultar';
      }

      setState(() {
        _cliente = cliente;
        _errorMessage = clientProvider.errorMessage;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'No se pudo identificar al usuario';
        _isLoading = false;
      });
    }
  }

  void _continuarAlSiguientePaso() {
    if (_direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una dirección de entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegar a la pantalla de selección de fecha/hora
    Navigator.pushNamed(
      context,
      '/fecha-hora-entrega',
      arguments: _direccionSeleccionada,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Dirección de Entregas',
        customGradient: AppGradients.blue,
        actions: [
          // ✅ Solo mostrar botón de gestión si es cliente (no preventista)
          if (!_esPreventista)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Gestionar direcciones',
              onPressed: () {
                Navigator.pushNamed(context, '/mis-direcciones').then((_) {
                  // Recargar direcciones al volver
                  _cargarDirecciones();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cliente == null
          ? Center(
              child: Text(
                _errorMessage ?? 'No se pudo cargar la información del cliente',
              ),
            )
          : Builder(
              builder: (context) {
                final cliente = _cliente!;
                final direcciones = cliente.direcciones ?? [];

                if (direcciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _esPreventista
                              ? 'El cliente no tiene direcciones registradas'
                              : 'No tienes direcciones registradas',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _esPreventista
                              ? 'El cliente debe agregar una dirección para continuar'
                              : 'Agrega una dirección para continuar',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        // ✅ Solo mostrar botón si es CLIENTE (no preventista)
                        if (!_esPreventista) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/direccion-form',
                              ).then((_) {
                                _cargarDirecciones();
                              });
                            },
                            icon: const Icon(Icons.add_location),
                            label: const Text('Agregar Dirección'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header con información (dinámico según rol)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _esPreventista
                                ? 'Selecciona dirección de entrega para ${cliente.nombre ?? 'el cliente'}'
                                : 'Selecciona dónde deseas recibir tu pedido',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _esPreventista
                                ? 'Elige una dirección del cliente para entregar el pedido'
                                : 'Elige una de tus direcciones guardadas',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          // ✅ Mostrar badge si es preventista
                          if (_esPreventista) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                border: Border.all(color: Colors.orange),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo Preventista',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Lista de direcciones
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: direcciones.length,
                        itemBuilder: (context, index) {
                          final direccion = direcciones[index];
                          final isSelected =
                              _direccionSeleccionada?.id == direccion.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _direccionSeleccionada = direccion;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icono de selección
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 16),

                                    // Información de la dirección
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                direccion.esPrincipal
                                                    ? Icons.home
                                                    : Icons.location_on,
                                                size: 20,
                                                color: direccion.esPrincipal
                                                    ? Colors.blue
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  direccion.direccion,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (direccion.esPrincipal)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Principal',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                          // Mostrar coordenadas GPS si están disponibles
                                          if (direccion.latitud != null &&
                                              direccion.longitud != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.gps_fixed,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ubicación GPS registrada',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],

                                          if (direccion.observaciones != null &&
                                              direccion
                                                  .observaciones!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Obs: ${direccion.observaciones}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Botón continuar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _direccionSeleccionada != null
                                ? _continuarAlSiguientePaso
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
