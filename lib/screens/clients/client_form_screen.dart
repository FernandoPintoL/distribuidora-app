import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/profile_photo_selector.dart';
import '../../widgets/select_search.dart';
import '../../widgets/location_selector.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';
import 'dart:io';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _observationsController = TextEditingController();

  int? _selectedLocationId;
  bool _isActive = true;
  bool _createUser = true;
  List<ClientAddress> _addresses = [];
  List<Localidad> _localidades = [];
  File? _selectedProfilePhoto;
  File? _ciAnversoFile;
  File? _ciReversoFile;

  // Preferencias de entrega y categorías
  List<VentanaEntregaCliente> _ventanasEntrega = [];
  List<CategoriaCliente> _categoriasCatalogo = [];
  final Set<int> _selectedCategoriasIds = {};

  // Campos de ubicación GPS
  double? _latitude;
  double? _longitude;
  final _locationObservationsController = TextEditingController();
  late ClientProvider _clientProvider;

  // Estados de carga
  bool _isLoadingLocalidades = false;
  bool _isSavingClient = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _clientProvider = context.read<ClientProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLocalidades();
        _loadCategorias();
        if (_isEditing) {
          _loadClientData(); // Ya carga todas las relaciones desde el backend
        }
      }
    });
  }

  void _loadClientData() {
    try {
      // Obtener cliente del widget que fue pasado
      final clientArgument = widget.client!;
      debugPrint('📝 Cargando datos del cliente ID: ${clientArgument.id}');

      // Hacer una llamada al API para obtener el cliente COMPLETO con todas las relaciones
      // esto es importante porque el cliente pasado como argumento podría no tener todas las relaciones
      _clientProvider.getClient(clientArgument.id).then((clientCompleto) {
        if (clientCompleto == null) {
          debugPrint('❌ Error: No se pudo cargar el cliente desde el API');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al cargar los datos del cliente'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        debugPrint('✅ Cliente completo cargado desde API');

        // Usar el cliente completo que viene del API con TODAS las relaciones
        _nameController.text = clientCompleto.nombre;
        _businessNameController.text = clientCompleto.razonSocial ?? '';
        _nitController.text = clientCompleto.nit ?? '';
        _emailController.text = clientCompleto.email ?? '';
        _phoneController.text = clientCompleto.telefono ?? '';
        _selectedLocationId = clientCompleto.localidadId;
        _isActive = clientCompleto.activo;
        _createUser = clientCompleto.userId != null;
        _observationsController.text = clientCompleto.observaciones ?? '';

        // Cargar direcciones
        if (clientCompleto.direcciones != null) {
          _addresses = List<ClientAddress>.from(clientCompleto.direcciones!);
          debugPrint('📍 Direcciones cargadas: ${_addresses.length}');
        } else {
          _addresses = [];
          debugPrint('📍 No hay direcciones para este cliente');
        }

        // Cargar categorías seleccionadas del cliente
        if (clientCompleto.categorias != null && clientCompleto.categorias!.isNotEmpty) {
          _selectedCategoriasIds
            ..clear()
            ..addAll(clientCompleto.categorias!.map((c) => c.id));
          debugPrint('🏷️ Categorías del cliente cargadas: ${_selectedCategoriasIds.length}');
        } else {
          debugPrint('📝 El cliente no tiene categorías asignadas');
        }

        // Cargar ventanas de entrega del cliente
        if (clientCompleto.ventanasEntrega != null && clientCompleto.ventanasEntrega!.isNotEmpty) {
          _ventanasEntrega = List.from(clientCompleto.ventanasEntrega!);
          debugPrint('⏰ Ventanas de entrega cargadas: ${_ventanasEntrega.length}');
        } else {
          debugPrint('📝 El cliente no tiene ventanas de entrega configuradas');
        }

        // Cargar primera dirección si existe
        if (_addresses.isNotEmpty) {
          final firstAddress = _addresses.first;
          _addressController.text = firstAddress.direccion;
          _latitude = firstAddress.latitud;
          _longitude = firstAddress.longitud;

          final dirObs = firstAddress.observaciones;
          if (dirObs != null && dirObs.isNotEmpty) {
            _locationObservationsController.text = dirObs;
          }

          debugPrint('📍 Primera dirección cargada: ${firstAddress.direccion}');
        }

        if (mounted) {
          setState(() {
            // Disparar rebuild para mostrar los datos cargados
          });
        }

        debugPrint('✅ Datos del cliente cargados exitosamente con TODAS las relaciones');
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar datos del cliente: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del cliente: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadLocalidades() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocalidades = true;
    });

    try {
      debugPrint('🌍 Cargando localidades...');
      await _clientProvider.loadLocalidades();

      if (mounted) {
        setState(() {
          _localidades = _clientProvider.localidades;
          _isLoadingLocalidades = false;
          _isInitialized = true;
        });
        debugPrint('✅ Localidades cargadas: ${_localidades.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar localidades: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoadingLocalidades = false;
          _isInitialized = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar localidades: ${e.toString()}'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadCategorias() async {
    try {
      debugPrint('🏷️ Cargando categorías...');
      await _clientProvider.loadCategoriasCliente();

      if (!mounted) return;

      setState(() {
        _categoriasCatalogo = _clientProvider.categoriasCliente;
        debugPrint('✅ Categorías cargadas: ${_categoriasCatalogo.length}');

        // Seleccionar por defecto la categoría APP al crear (no editar)
        if (!_isEditing && _selectedCategoriasIds.isEmpty) {
          try {
            final appCat = _categoriasCatalogo.cast<CategoriaCliente?>().firstWhere(
              (c) =>
                  (c?.clave?.toUpperCase() == 'APP') ||
                  (c?.nombre?.toUpperCase() == 'APP'),
              orElse: () => null,
            );
            if (appCat != null) {
              _selectedCategoriasIds.add(appCat.id);
              debugPrint('✅ Categoría APP seleccionada por defecto');
            } else {
              debugPrint('⚠️ No se encontró categoría APP');
            }
          } catch (e) {
            debugPrint('⚠️ Error al seleccionar categoría APP: $e');
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar categorías: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: ${e.toString()}'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSavingClient) {
          debugPrint(
            'Intento de navegación hacia atrás durante guardado, bloqueado',
          );
          return false;
        }
        // Permitir la navegación hacia atrás normalmente
        return true;
      },
      child: Scaffold(
        appBar: CustomGradientAppBar(
          title: _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
          customGradient: _isEditing ? AppGradients.orange : AppGradients.green,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: _isSavingClient
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : [Colors.white, Colors.grey.shade100],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSavingClient ? null : _saveClient,
                icon: _isSavingClient
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.save, color: _isEditing ? Colors.orange.shade700 : Colors.green.shade700),
                label: Text(
                  _isSavingClient ? 'Guardando...' : 'Guardar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isSavingClient ? Colors.white : (_isEditing ? Colors.orange.shade700 : Colors.green.shade700),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isEditing
                  ? [
                      Colors.orange.shade50,
                      Colors.white,
                    ]
                  : [
                      Colors.green.shade50,
                      Colors.white,
                    ],
            ),
          ),
          child: _isInitialized
              ? Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto de perfil
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: ProfilePhotoSelector(
                              currentPhotoUrl: widget.client?.fotoPerfil,
                              onPhotoSelected: (file) {
                                setState(() {
                                  _selectedProfilePhoto = file;
                                });
                              },
                            ),
                          ),
                        ),

                        // Información básica
                        _buildSection(
                          title: 'Información Básica',
                          icon: Icons.person,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration(
                                labelText: 'Nombre *',
                                hintText: 'Ingrese el nombre completo',
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _businessNameController,
                              decoration: _buildInputDecoration(
                                labelText: 'Razón Social',
                                hintText: 'Ingrese la razón social (opcional)',
                                prefixIcon: Icons.business,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Información de contacto
                        _buildSection(
                          title: 'Información de Contacto',
                          icon: Icons.contact_phone,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: _buildInputDecoration(
                                labelText: 'Correo Electrónico',
                                hintText: 'correo@ejemplo.com',
                                prefixIcon: Icons.email,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _buildInputDecoration(
                                labelText: 'Teléfono',
                                hintText: '+1234567890',
                                prefixIcon: Icons.phone,
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Ubicación
                        _buildSection(
                          title: 'Ubicación',
                          icon: Icons.location_on,
                          children: [
                            // Location Selector con GPS
                            LocationSelector(
                              initialLatitude: _latitude,
                              initialLongitude: _longitude,
                              onLocationSelected: (lat, lng, address) {
                                setState(() {
                                  _latitude = lat;
                                  _longitude = lng;
                                  // Cargar la dirección obtenida del GPS en el campo de dirección
                                  if (address != null &&
                                      address.isNotEmpty &&
                                      address != 'Dirección no disponible' &&
                                      _addressController.text.isEmpty) {
                                    _addressController.text = address;
                                  }
                                });
                              },
                              autoGetLocation: true,
                            ),
                            const SizedBox(height: 16),
                            // Localidad selector (mantener el existente)
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: SelectSearch<Localidad>(
                                label: 'Localidad',
                                items: _localidades,
                                value: _selectedLocationId != null
                                    ? _localidades.cast<Localidad?>().firstWhere(
                                        (localidad) =>
                                            localidad?.id == _selectedLocationId,
                                        orElse: () => null,
                                      )
                                    : null,
                                displayString: (localidad) => localidad.nombre,
                                onChanged: (localidad) {
                                  setState(() {
                                    _selectedLocationId = localidad?.id;
                                  });
                                },
                                hintText: 'Buscar localidad...',
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: _buildInputDecoration(
                                labelText: 'Dirección',
                                hintText: 'Ingrese la dirección completa',
                                prefixIcon: Icons.home,
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            // Campo para observaciones del lugar
                            TextFormField(
                              controller: _locationObservationsController,
                              decoration: _buildInputDecoration(
                                labelText: 'Observaciones del lugar',
                                hintText: 'Ingrese observaciones sobre la ubicación del cliente',
                                prefixIcon: Icons.note,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Preferencias de entrega
                        _buildSection(
                          title: 'Dias de Visitas',
                          icon: Icons.access_time,
                          children: [
                            if (_ventanasEntrega.isNotEmpty)
                              Column(
                                children: _ventanasEntrega.asMap().entries.map((
                                  entry,
                                ) {
                                  final i = entry.key;
                                  final v = entry.value;
                                  final days = [
                                    'Dom',
                                    'Lun',
                                    'Mar',
                                    'Mié',
                                    'Jue',
                                    'Vie',
                                    'Sáb',
                                  ];
                                  final day =
                                      (v.diaSemana >= 0 && v.diaSemana <= 6)
                                      ? days[v.diaSemana]
                                      : 'Día ${v.diaSemana}';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.calendar_today,
                                        color: v.activo
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      title: Text(
                                        '$day: ${v.horaInicio} - ${v.horaFin}',
                                      ),
                                      subtitle: v.activo
                                          ? null
                                          : const Text(
                                              'Inactivo',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _ventanasEntrega.removeAt(i);
                                          });
                                        },
                                      ),
                                      onTap: () => _showVentanaDialog(
                                        initial: v,
                                        index: i,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Text(
                                'Agrega los días y horarios preferidos para visitas.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => _showVentanaDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar dia de visita'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Categorías del cliente
                        _buildSection(
                          title: 'Categorías',
                          icon: Icons.category,
                          children: [
                            if (_categoriasCatalogo.isEmpty)
                              const Text(
                                'No hay categorías disponibles',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categoriasCatalogo.map((cat) {
                                  final selected = _selectedCategoriasIds
                                      .contains(cat.id);
                                  return FilterChip(
                                    label: Text(
                                      cat.nombre ??
                                          cat.clave ??
                                          'Cat ${cat.id}',
                                    ),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedCategoriasIds.add(cat.id);
                                        } else {
                                          _selectedCategoriasIds.remove(cat.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        // Configuración
                        _buildSection(
                          title: 'Configuración',
                          icon: Icons.settings,
                          children: [
                            // Solo mostrar el switch de estado al editar
                            if (_isEditing) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isActive ? Colors.green.shade200 : Colors.red.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isActive
                                              ? [Colors.green.shade400, Colors.green.shade600]
                                              : [Colors.red.shade400, Colors.red.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _isActive ? Icons.check_circle : Icons.cancel,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Estado del Cliente',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isActive ? 'Activo' : 'Inactivo',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      onChanged: (value) => setState(() => _isActive = value),
                                      activeColor: Colors.green.shade600,
                                      inactiveThumbColor: Colors.red.shade400,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              // Al crear, mostrar que será activo por defecto (sin opción a cambiar)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade50, Colors.green.shade100],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green.shade400, Colors.green.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Estado del Cliente',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Activo por defecto',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Crear Usuario',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Crear cuenta de usuario para acceso a la app',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _createUser,
                                  onChanged: (value) =>
                                      setState(() => _createUser = value),
                                  activeThumbColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando datos del formulario...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_isLoadingLocalidades)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Cargando localidades...',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: _isEditing ? Colors.orange.shade600 : Colors.green.shade600,
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isEditing ? Colors.orange.shade600 : Colors.green.shade600,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: _isEditing ? Colors.orange.shade700 : Colors.green.shade700,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isEditing
                    ? [Colors.orange.shade50, Colors.orange.shade100]
                    : [Colors.green.shade50, Colors.teal.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isEditing
                          ? [Colors.orange.shade400, Colors.orange.shade600]
                          : [Colors.green.shade400, Colors.teal.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isEditing ? Colors.orange : Colors.green).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClient() async {
    debugPrint('Iniciando _saveClient - isEditing: $_isEditing');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Validación del formulario fallida');
      return;
    }

    setState(() {
      _isSavingClient = true;
    });

    _showLoadingDialog('Guardando cliente...');

    bool success = false;
    try {
      if (_isEditing) {
        success = await _clientProvider.updateClient(
          widget.client!.id,
          nombre: _nameController.text,
          razonSocial: _businessNameController.text.isEmpty
              ? null
              : _businessNameController.text,
          nit: _nitController.text.isEmpty ? null : _nitController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          telefono: _phoneController.text.isEmpty
              ? null
              : _phoneController.text,
          activo: _isActive,
          observaciones: _observationsController.text.isEmpty
              ? null
              : _observationsController.text,
          fotoPerfil: _selectedProfilePhoto,
          limiteCredito: 0.0,
          latitud: _latitude,
          longitud: _longitude,
          localidadId: _selectedLocationId,
          ventanasEntrega: _ventanasEntrega,
          categoriasIds: _selectedCategoriasIds.isNotEmpty
              ? _selectedCategoriasIds.toList()
              : null,
          //crear usuario solo si se seleccionó y no está editando
          crearUsuario: _createUser,
          direcciones: _addressController.text.isNotEmpty
              ? [
                  ClientAddress(
                    id: null,
                    direccion: _addressController.text,
                    observaciones:
                        _locationObservationsController.text.isNotEmpty
                        ? _locationObservationsController.text
                        : null,
                    ciudad: null, // Se puede agregar después si es necesario
                    departamento:
                        null, // Se puede agregar después si es necesario
                    codigoPostal:
                        null, // Se puede agregar después si es necesario
                    esPrincipal: true,
                    activa: true,
                    latitud: _latitude, // ✅ Coordenadas GPS en la dirección
                    longitud: _longitude, // ✅ Coordenadas GPS en la dirección
                  ),
                ]
              : [],
        );
      } else {
        success = await _clientProvider.createClient(
          nombre: _nameController.text,
          razonSocial: _businessNameController.text.isEmpty
              ? null
              : _businessNameController.text,
          nit: _nitController.text.isEmpty ? null : _nitController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          telefono: _phoneController.text.isEmpty
              ? null
              : _phoneController.text,
          activo: _isActive,
          observaciones: _observationsController.text.isEmpty
              ? null
              : _observationsController.text,
          latitud: _latitude,
          longitud: _longitude,
          localidadId: _selectedLocationId,
          //crear usuario solo si se seleccionó y no está editando
          crearUsuario: _createUser,
          direcciones: _addressController.text.isNotEmpty
              ? [
                  ClientAddress(
                    id: null,
                    direccion: _addressController.text,
                    observaciones:
                        _locationObservationsController.text.isNotEmpty
                        ? _locationObservationsController.text
                        : null,
                    ciudad: null, // Se puede agregar después si es necesario
                    departamento:
                        null, // Se puede agregar después si es necesario
                    codigoPostal:
                        null, // Se puede agregar después si es necesario
                    esPrincipal: true,
                    activa: true,
                    latitud: _latitude, // ✅ Coordenadas GPS en la dirección
                    longitud: _longitude, // ✅ Coordenadas GPS en la dirección
                  ),
                ]
              : [],
          ventanasEntrega: _ventanasEntrega,
          categoriasIds: _selectedCategoriasIds.isNotEmpty
              ? _selectedCategoriasIds.toList()
              : null,
          fotoPerfil: _selectedProfilePhoto,
        );
      }
    } catch (e) {
      debugPrint('Error en _saveClient: $e');
      success = false;
    } finally {
      // Asegurarse de cerrar el diálogo y actualizar el estado
      if (mounted) {
        _hideLoadingDialog();
        setState(() {
          _isSavingClient = false;
        });

        if (success) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Cliente actualizado exitosamente'
                    : 'Cliente creado exitosamente',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          // Navegar de regreso después de un breve retraso
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(
                context,
              ).pop(true); // Retornar true para indicar éxito
            }
          });
        } else {
          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al guardar cliente',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Reintentar',
                onPressed: _saveClient,
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _showLoadingDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          );
        },
      );
    }
  }

  void _hideLoadingDialog() {
    if (mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        debugPrint('Error al cerrar diálogo: $e');
      }
    }
  }

  // Dialog para agregar/editar ventanas de entrega
  Future<void> _showVentanaDialog({
    VentanaEntregaCliente? initial,
    int? index,
  }) async {
    int day = initial?.diaSemana ?? 1;
    TimeOfDay start =
        _parseTime(initial?.horaInicio) ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end =
        _parseTime(initial?.horaFin) ?? const TimeOfDay(hour: 12, minute: 0);
    bool active = initial?.activo ?? true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                '${index == null ? 'Agregar' : 'Editar'} dia de visita',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: const InputDecoration(
                      labelText: 'Día de la semana',
                    ),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('Domingo')),
                      const DropdownMenuItem(value: 1, child: Text('Lunes')),
                      const DropdownMenuItem(value: 2, child: Text('Martes')),
                      const DropdownMenuItem(
                        value: 3,
                        child: Text('Miércoles'),
                      ),
                      const DropdownMenuItem(value: 4, child: Text('Jueves')),
                      const DropdownMenuItem(value: 5, child: Text('Viernes')),
                      const DropdownMenuItem(value: 6, child: Text('Sábado')),
                    ],
                    onChanged: (val) => setLocalState(() => day = val ?? day),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (picked != null)
                              setLocalState(() => start = picked);
                          },
                          child: Text('Inicio: ${_formatTimeOfDay(start)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (picked != null)
                              setLocalState(() => end = picked);
                          },
                          child: Text('Fin: ${_formatTimeOfDay(end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: active,
                    onChanged: (val) => setLocalState(() => active = val),
                    title: const Text('Activo'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validación simple hora inicio < fin
                    final startMinutes = start.hour * 60 + start.minute;
                    final endMinutes = end.hour * 60 + end.minute;
                    if (endMinutes <= startMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La hora de fin debe ser mayor que la de inicio',
                          ),
                        ),
                      );
                      return;
                    }

                    final nueva = VentanaEntregaCliente(
                      diaSemana: day,
                      horaInicio: _formatTimeOfDay(start),
                      horaFin: _formatTimeOfDay(end),
                      activo: active,
                    );
                    setState(() {
                      if (index == null) {
                        _ventanasEntrega.add(nueva);
                      } else {
                        _ventanasEntrega[index] = nueva;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _nitController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}
