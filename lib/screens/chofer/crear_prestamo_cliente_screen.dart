import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/cliente.dart';
import '../../models/prestable.dart';
import '../../widgets/map_location_selector.dart';

/// Pantalla para crear nuevo préstamo a cliente
/// Formulario unificado con búsqueda de cliente y venta
class CrearPrestamoClienteScreen extends StatefulWidget {
  const CrearPrestamoClienteScreen({super.key});

  @override
  State<CrearPrestamoClienteScreen> createState() =>
      _CrearPrestamoClienteScreenState();
}

class _CrearPrestamoClienteScreenState extends State<CrearPrestamoClienteScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Datos del préstamo
  Cliente? _clienteSeleccionado;
  DateTime _fechaPrestamo = DateTime.now();
  DateTime? _fechaEsperadaDevolucion;
  int? _almacenSeleccionado; // Se cargará desde backend
  int? _choferSeleccionado; // Se cargará desde backend
  int? _vehiculoSeleccionado; // Se cargará desde backend
  String _observaciones = '';
  double _montoGarantia = 0;

  // Búsqueda y datos
  List<Producto> _prestables = [];
  Venta? _ventaBuscada;
  List<Map<String, dynamic>> _almacenes = []; // Se cargará del backend
  List<Map<String, dynamic>> _choferes = []; // Se cargará del backend
  List<Map<String, dynamic>> _vehiculos = []; // Se cargará del backend

  // Items agregados
  final List<Map<String, dynamic>> _items = [];

  // Estados
  bool _cargando = false;
  bool _cargandoPrestables = false;
  int? _usuarioActualId; // ID del usuario logueado

  // Controladores
  late TextEditingController _observacionesController;
  late TextEditingController _ventaIdController;
  late TextEditingController _cantidadController;
  final Map<int, TextEditingController> _cantidadControllers = {};

  @override
  void initState() {
    super.initState();
    _observacionesController = TextEditingController();
    _ventaIdController = TextEditingController();
    _cantidadController = TextEditingController();
    // ✅ Preseleccionar fecha de devolución 7 días después del préstamo
    _fechaEsperadaDevolucion = _fechaPrestamo.add(const Duration(days: 7));
    // ✅ Obtener usuario actual del provider
    _obtenerUsuarioActual();
    _cargarAlmacenes();
    _cargarPrestables();
    _cargarChoferes();
    _cargarVehiculos();
  }

  /// Obtener usuario actual del provider
  void _obtenerUsuarioActual() {
    try {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      _usuarioActualId = clientProvider.clientePerfil?.id;
      debugPrint('👤 Usuario actual: $_usuarioActualId');
    } catch (e) {
      debugPrint('❌ Error obteniendo usuario actual: $e');
    }
  }

  /// Cargar almacenes desde API y preseleccionar "Distribuidora"
  Future<void> _cargarAlmacenes() async {
    try {
      final response = await _apiService.get('/almacenes-prestables/index-json?per_page=100');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final almacenesList = data['data'] as List;

        List<Map<String, dynamic>> almacenesFormateados = [];
        int? distribuidoraId;

        for (var almacen in almacenesList) {
          final nombre = almacen['nombre'] as String;
          final id = almacen['id'] as int;

          almacenesFormateados.add({
            'id': id,
            'nombre': nombre,
          });

          // Buscar Distribuidora
          if (nombre.toLowerCase().contains('distribuidora')) {
            distribuidoraId = id;
          }
        }

        setState(() {
          _almacenes = almacenesFormateados;
          // Preseleccionar Distribuidora si existe, sino el primero
          _almacenSeleccionado = distribuidoraId ?? (_almacenes.isNotEmpty ? _almacenes.first['id'] as int : null);

          if (_almacenSeleccionado != null) {
            final nombre = _almacenes.firstWhere(
              (a) => a['id'] == _almacenSeleccionado,
            )['nombre'];
            debugPrint('✅ Almacén preseleccionado: $nombre (id=$_almacenSeleccionado)');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando almacenes: $e');
      // Fallback: usar Distribuidora con id=2
      setState(() {
        _almacenes = [
          {'id': 2, 'nombre': 'Distribuidora'},
        ];
        _almacenSeleccionado = 2;
      });
    }
  }

  /// Cargar prestables desde API
  Future<void> _cargarPrestables() async {
    setState(() {
      _cargandoPrestables = true;
    });

    try {
      final response = await _apiService.get('/prestables?per_page=200');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final prestablesData = data['data'] as Map<String, dynamic>;
        final prestablesList = prestablesData['data'] as List;
        setState(() {
          _prestables = prestablesList
              .map((p) => Producto.fromJson(p as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando prestables: $e');
      _mostrarError('Error cargando prestables');
    } finally {
      setState(() {
        _cargandoPrestables = false;
      });
    }
  }

  /// Cargar choferes desde API
  Future<void> _cargarChoferes() async {
    try {
      // Intentar cargar del endpoint público de choferes
      final response = await _apiService.get('/api/choferes/lista');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final choferesList = data['data'] as List? ?? [];

        setState(() {
          _choferes = choferesList
              .map((c) => {
                    'id': c['id'] as int,
                    'nombre': c['nombre'] as String? ?? c['name'] as String? ?? '',
                    'apellido': c['apellido'] as String? ?? '',
                  })
              .toList();

          // ✅ Preseleccionar al usuario actual si es chofer
          if (_usuarioActualId != null) {
            final esChoferActual = _choferes.any((c) => c['id'] == _usuarioActualId);
            if (esChoferActual) {
              _choferSeleccionado = _usuarioActualId;
              debugPrint('✅ Chofer preseleccionado: $_choferSeleccionado');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar choferes (opcional): $e');
      // Campo opcional, no mostrar error si falla la carga
      setState(() {
        _choferes = [];
      });
    }
  }

  /// Cargar vehículos desde API
  Future<void> _cargarVehiculos() async {
    try {
      final response = await _apiService.get('/vehiculos?per_page=100');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final vehiculosList = data['data'] as List;

        setState(() {
          _vehiculos = vehiculosList
              .map((v) => {
                    'id': v['id'] as int,
                    'placa': v['placa'] as String? ?? '',
                    'modelo': v['modelo'] as String? ?? '',
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando vehículos: $e');
    }
  }

  /// Buscar venta por ID y cargar cliente y detalles
  Future<void> _buscarVenta(int ventaId) async {
    setState(() {
      _cargando = true;
    });

    try {
      final ventasProvider = context.read<VentasProvider>();
      await ventasProvider.loadVentaDetalle(ventaId);

      final venta = ventasProvider.ventaDetalle;
      if (venta != null && venta.cliente != null) {
        setState(() {
          _ventaBuscada = venta;
          _clienteSeleccionado = venta.cliente;
          // Auto-calcular cantidades de prestables basado en venta
          _autoFillPrestablesDesdeVenta(venta);
        });

        // Log para debugging
        final direccionData = _obtenerDireccionCliente(venta);
        debugPrint('📍 Dirección del cliente: ${direccionData?['direccion'] ?? "No disponible"}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #${venta.numero} cargada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _mostrarError('Venta no encontrada o sin cliente');
      }
    } catch (e) {
      _mostrarError('Error buscando venta: $e');
      debugPrint('❌ Error buscando venta: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  /// Obtener dirección del cliente desde la venta o cliente
  Map<String, dynamic>? _obtenerDireccionCliente(Venta venta) {
    // Si la venta tiene dirección cliente con datos, usar esa
    if (venta.direccionCliente != null) {
      return {
        'direccion': venta.direccionCliente!.direccion ?? 'Sin dirección',
        'localidad_id': venta.direccionCliente!.localidad?.id,
        'localidad_nombre': venta.direccionCliente!.localidad?.nombre,
      };
    }

    // Si no, buscar en las direcciones del cliente
    if (venta.cliente != null && venta.cliente!.direcciones != null && venta.cliente!.direcciones!.isNotEmpty) {
      try {
        // Buscar dirección principal o usar la primera
        final direccion = venta.cliente!.direcciones!.firstWhere(
          (d) => d.esPrincipal == true,
          orElse: () => venta.cliente!.direcciones!.first,
        );

        return {
          'direccion': direccion.direccion ?? 'Sin dirección',
          'localidad_id': direccion.localidad?.id,
          'localidad_nombre': direccion.localidad?.nombre,
        };
      } catch (e) {
        debugPrint('❌ Error obteniendo dirección del cliente: $e');
        return null;
      }
    }

    return null;
  }

  /// Auto-llenar prestables desde los detalles de la venta
  /// Fórmula: embase = capacidad_canastilla * venta.cantidad
  void _autoFillPrestablesDesdeVenta(Venta venta) {
    _items.clear();

    for (var detalle in venta.detalles) {
      if (detalle.producto == null) continue;

      final producto = detalle.producto!;
      final cantidadDetalle = detalle.cantidad.toInt();

      // Buscar la canastilla en los prestables relacionados
      Prestable? canastilla;
      Prestable? embase;

      if (producto.prestables != null && producto.prestables!.isNotEmpty) {
        canastilla = producto.prestables!.firstWhere(
          (p) => p.tipo.toUpperCase() == 'CANASTILLA',
          orElse: () => Prestable(id: 0, nombre: '', codigo: '', tipo: ''),
        );

        // Buscar el embase asociado a la canastilla
        if (canastilla.id != 0) {
          embase = producto.prestables!.firstWhere(
            (p) => p.tipo.toUpperCase() == 'EMBASES',
            orElse: () => Prestable(id: 0, nombre: '', codigo: '', tipo: ''),
          );
        }
      }

      // Si encontramos la canastilla, agregarla como item
      if (canastilla != null && canastilla.id != 0) {
        final itemIndex = _items.length;
        _items.add({
          'prestable_id': canastilla.id,
          'prestable_nombre': canastilla.nombre,
          'cantidad': cantidadDetalle,
          'capacidad': canastilla.capacidad ?? 0, // ✅ Guardar capacidad para recálculos
          'tipo': 'CANASTILLA',
          'almacenes': [
            {
              'almacenes_prestables_id': _almacenSeleccionado,
              'cantidad': cantidadDetalle,
            }
          ],
        });
        // ✅ Crear controller para esta cantidad
        _cantidadControllers[itemIndex] = TextEditingController(text: cantidadDetalle.toString());

        // Si existe embase y canastilla tiene capacidad, calcular cantidad de embase
        if (embase != null && embase.id != 0 && canastilla.capacidad != null && canastilla.capacidad! > 0) {
          final cantidadEmbase = (canastilla.capacidad! * cantidadDetalle).toInt();

          if (cantidadEmbase > 0) {
            final embaseIndex = _items.length;
            _items.add({
              'prestable_id': embase.id,
              'prestable_nombre': embase.nombre,
              'cantidad': cantidadEmbase,
              'tipo': 'EMBASE',
              'canastilla_index': _items.length - 1, // ✅ Guardar índice de la canastilla relacionada
              'almacenes': [
                {
                  'almacenes_prestables_id': _almacenSeleccionado,
                  'cantidad': cantidadEmbase,
                }
              ],
            });
            // ✅ Crear controller para el embase
            _cantidadControllers[embaseIndex] = TextEditingController(text: cantidadEmbase.toString());
          }
        }
      }
    }

    debugPrint('📦 Agregados ${_items.length} items desde venta ${venta.numero}');
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _ventaIdController.dispose();
    _cantidadController.dispose();
    for (var controller in _cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Agregar un prestable a la lista de items
  void _agregarItem(int prestableId, String prestableNombre, int cantidad, int almacen) {
    setState(() {
      // Verificar si el prestable ya existe
      final index = _items.indexWhere((item) => item['prestable_id'] == prestableId);

      if (index >= 0) {
        // Actualizar cantidad si ya existe
        _items[index]['cantidad'] = cantidad;
        _cantidadControllers[index]?.text = cantidad.toString();
      } else {
        // Agregar nuevo item
        final newIndex = _items.length;
        _items.add({
          'prestable_id': prestableId,
          'prestable_nombre': prestableNombre,
          'cantidad': cantidad,
          'almacenes': [
            {
              'almacenes_prestables_id': almacen,
              'cantidad': cantidad,
            }
          ],
        });
        // ✅ Crear controller para esta cantidad
        _cantidadControllers[newIndex] = TextEditingController(text: cantidad.toString());
      }
    });
  }

  /// Remover item de la lista
  void _removerItem(int index) {
    setState(() {
      _items.removeAt(index);
      // ✅ Limpiar y reindexar los controllers
      _cantidadControllers[index]?.dispose();
      _cantidadControllers.remove(index);
      // Reindexar controllers después del índice removido
      final newControllers = <int, TextEditingController>{};
      _cantidadControllers.forEach((key, controller) {
        if (key > index) {
          newControllers[key - 1] = controller;
        } else {
          newControllers[key] = controller;
        }
      });
      _cantidadControllers.clear();
      _cantidadControllers.addAll(newControllers);
    });
  }

  /// Crear el préstamo
  Future<void> _crearPrestamo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteSeleccionado == null) {
      _mostrarError('Debes seleccionar un cliente');
      return;
    }

    if (_items.isEmpty) {
      _mostrarError('Debes agregar al menos un artículo');
      return;
    }

    // Validar que todas las cantidades sean > 0
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final cantidad = item['cantidad'] as int?;
      if (cantidad == null || cantidad <= 0) {
        final nombre = item['prestable_nombre'] as String;
        _mostrarError('La cantidad de "$nombre" debe ser mayor a 0');
        return;
      }
    }

    if (_almacenSeleccionado == null) {
      _mostrarError('Error: Almacén no disponible. Intenta recargando la pantalla.');
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _cargando = true;
    });

    try {
      final prestamosProvider = context.read<PrestamosProvider>();

      // Obtener dirección del cliente si existe venta
      Map<String, dynamic>? ubicacionData;
      if (_ventaBuscada != null) {
        final direccionData = _obtenerDireccionCliente(_ventaBuscada!);
        if (direccionData != null) {
          ubicacionData = {
            'direccion': direccionData['direccion'],
            'localidad_id': direccionData['localidad_id'],
            'es_ubicacion_manual': false,
          };
        }
      }

      // Preparar payload
      final payload = {
        'cliente_id': _clienteSeleccionado!.id,
        'almacenes_prestables_id': _almacenSeleccionado,
        'fecha_prestamo': _fechaPrestamo.toIso8601String().split('T')[0],
        'fecha_esperada_devolucion': _fechaEsperadaDevolucion?.toIso8601String().split('T')[0],
        'observaciones': _observaciones.isNotEmpty ? _observaciones : null,
        'monto_garantia': _montoGarantia > 0 ? _montoGarantia : null,
        'detalles': _items,
        'es_venta': false, // ✅ Préstamo a cliente sin venta específica
        'es_evento': false, // ✅ No es préstamo de evento
        if (_choferSeleccionado != null) 'chofer_id': _choferSeleccionado,
        if (_vehiculoSeleccionado != null) 'vehiculo_id': _vehiculoSeleccionado,
        if (ubicacionData != null) 'ubicacion': ubicacionData,
      };

      debugPrint('📤 Enviando préstamo: $payload');

      // Crear préstamo
      final resultado = await prestamosProvider.crearPrestamoCliente(payload);

      if (resultado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Préstamo creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _mostrarError(prestamosProvider.error ?? 'Error creando préstamo');
      }
    } catch (e) {
      _mostrarError('Error: $e');
      debugPrint('❌ Error creando préstamo: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  /// Mostrar error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Préstamo a Cliente'),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Búsqueda de cliente
            _buildClienteSearchField(),
            const SizedBox(height: 24),

            // Búsqueda por ID de venta (opcional)
            _buildBusquedaVentaSection(),
            const SizedBox(height: 24),

            // Formulario básico
            _buildFormularioBasico(),
            const SizedBox(height: 24),

            // Items
            _buildSeccionItems(),
            const SizedBox(height: 24),

            // Observaciones
            _buildObservacionesField(),
            const SizedBox(height: 24),

            // Botón crear
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  /// Card de venta buscada con soporte dark mode
  Widget _buildVentaBuscadaCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.colorScheme.primary.withOpacity(0.15)
            : context.colorScheme.primary.withOpacity(0.1),
        border: Border.all(
          color: isDark
              ? context.colorScheme.primary.withOpacity(0.5)
              : context.colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Venta #${_ventaBuscada!.numero}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text('Cliente: ${_clienteSeleccionado?.nombre ?? 'N/A'}'),
          Text('Items cargados: ${_items.length}'),
          Text(
            'Total: Bs. ${_ventaBuscada!.total.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  /// Card de cliente seleccionado con soporte dark mode
  Widget _buildClienteSeleccionadoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.colorScheme.primary.withOpacity(0.15)
            : context.colorScheme.primary.withOpacity(0.1),
        border: Border.all(
          color: isDark
              ? context.colorScheme.primary.withOpacity(0.5)
              : context.colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clienteSeleccionado!.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _clienteSeleccionado!.telefono ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de dirección del cliente
  Widget _buildDireccionCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final direccionData = _ventaBuscada != null ? _obtenerDireccionCliente(_ventaBuscada!) : null;

    if (direccionData == null) {
      return const SizedBox.shrink();
    }

    final direccion = direccionData['direccion'] as String?;
    final localidadNombre = direccionData['localidad_nombre'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.colorScheme.tertiary.withOpacity(0.15)
            : context.colorScheme.tertiary.withOpacity(0.1),
        border: Border.all(
          color: isDark
              ? context.colorScheme.tertiary.withOpacity(0.5)
              : context.colorScheme.tertiary,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: context.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dirección de Entrega',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              // Botón para ver en mapa
              Tooltip(
                message: 'Ver en mapa',
                child: IconButton(
                  icon: const Icon(Icons.map),
                  color: context.colorScheme.tertiary,
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _abrirMapaDireccion(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            direccion ?? 'Sin dirección',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (localidadNombre != null) ...[
            const SizedBox(height: 4),
            Chip(
              label: Text(
                localidadNombre,
                style: const TextStyle(fontSize: 11),
              ),
              avatar: CircleAvatar(
                backgroundColor: context.colorScheme.tertiary.withOpacity(0.3),
                radius: 12,
                child: Icon(
                  Icons.location_city,
                  size: 12,
                  color: context.colorScheme.tertiary,
                ),
              ),
              backgroundColor: isDark
                  ? context.colorScheme.tertiary.withOpacity(0.2)
                  : context.colorScheme.tertiary.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }

  /// Abrir mapa con la dirección del cliente
  void _abrirMapaDireccion() {
    if (_ventaBuscada == null) return;

    final direccionCliente = _ventaBuscada!.direccionCliente ??
        (_ventaBuscada!.cliente?.direcciones?.firstWhere(
          (d) => d.esPrincipal == true,
          orElse: () => _ventaBuscada!.cliente!.direcciones!.first,
        ));

    if (direccionCliente == null ||
        direccionCliente.latitud == null ||
        direccionCliente.longitud == null) {
      _mostrarError('❌ No hay coordenadas disponibles para esta dirección');
      return;
    }

    // Crear ubicación para el mapa
    final mapLocation = MapLocation(
      latitude: direccionCliente.latitud!,
      longitude: direccionCliente.longitud!,
      title: _clienteSeleccionado?.nombre ?? 'Cliente',
      subtitle: direccionCliente.direccion ?? 'Dirección',
      isSelected: false,
      razonSocial: _clienteSeleccionado?.razonSocial,
      telefono: _clienteSeleccionado?.telefono,
      fotoPerfil: _clienteSeleccionado?.fotoPerfil,
    );

    // Abrir mapa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationSelector(
          onLocationSelected: (latitude, longitude, address) {
            Navigator.pop(context);
          },
          additionalLocations: [mapLocation],
        ),
      ),
    );
  }

  /// Sección de búsqueda de venta (opcional)
  Widget _buildBusquedaVentaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔍 Buscar Venta (Opcional)',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ventaIdController,
                decoration: InputDecoration(
                  hintText: 'ID de venta para auto-llenar...',
                  prefixIcon: const Icon(Icons.receipt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: context.colorScheme.surface,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _cargando
                  ? null
                  : () {
                      final ventaId = int.tryParse(_ventaIdController.text);
                      if (ventaId != null) {
                        _buscarVenta(ventaId);
                      } else if (_ventaIdController.text.isNotEmpty) {
                        _mostrarError('ID de venta inválido');
                      }
                    },
              child: const Icon(Icons.search),
            ),
          ],
        ),
        if (_ventaBuscada != null) ...[
          const SizedBox(height: 12),
          _buildVentaBuscadaCard(),
          const SizedBox(height: 12),
          _buildDireccionCard(),
        ],
      ],
    );
  }

  /// Construcción del formulario básico (reutilizable en ambos tabs)
  Widget _buildFormularioBasico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Datos del Préstamo',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildClienteField(),
        const SizedBox(height: 16),
        _buildFechaPrestamo(),
        const SizedBox(height: 16),
        _buildFechaDevolucion(),
        const SizedBox(height: 16),
        _buildAlmacenField(),
        const SizedBox(height: 16),
        _buildChoferField(),
        const SizedBox(height: 16),
        _buildVehiculoField(),
        const SizedBox(height: 16),
        _buildMontoGarantia(),
      ],
    );
  }

  /// Sección de items
  Widget _buildSeccionItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📦 Artículos',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _mostrarDialogoAgregarItem(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Artículo'),
          ),
        ),
        const SizedBox(height: 16),
        if (_items.isNotEmpty)
          _buildListaItems()
        else
          Center(
            child: Text(
              'Sin artículos agregados',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  /// Observaciones
  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Observaciones',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacionesController,
          decoration: InputDecoration(
            hintText: 'Agregar observaciones (opcional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: context.colorScheme.surface,
          ),
          maxLines: 3,
          onChanged: (value) {
            _observaciones = value;
          },
        ),
      ],
    );
  }

  /// Botones de acción
  Widget _buildBotonesAccion() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _cargando ? null : _crearPrestamo,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Crear Préstamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Widget para buscar cliente (con búsqueda en tiempo real)
  Widget _buildClienteSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👤 Selecciona Cliente',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Consumer<ClientProvider>(
          builder: (context, clientProvider, _) {
            return Autocomplete<Cliente>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Cliente>.empty();
                }
                final results = await clientProvider.searchClients(
                  textEditingValue.text,
                  limit: 10,
                );
                // Convertir Client a Cliente
                return results.map((c) => Cliente(
                  id: c.id,
                  nombre: c.nombre,
                  telefono: c.telefono,
                  fotoPerfil: c.fotoPerfil,
                  razonSocial: c.razonSocial,
                  nit: c.nit,
                  localidadId: 0, // No available from Client
                )).toList();
              },
              onSelected: (Cliente selection) {
                setState(() {
                  _clienteSeleccionado = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nombre...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _clienteSeleccionado != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() {
                                _clienteSeleccionado = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.colorScheme.surface,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    child: SizedBox(
                      width: 300,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Cliente option = options.elementAt(index);
                          return ListTile(
                            title: Text(option.nombre),
                            subtitle: Text(option.telefono ?? ''),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (_clienteSeleccionado != null) ...[
          const SizedBox(height: 12),
          _buildClienteSeleccionadoCard(),
        ],
      ],
    );
  }

  /// Widget para seleccionar cliente (simple)
  Widget _buildClienteField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _mostrarDialogoSeleccionarCliente(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _clienteSeleccionado?.nombre ?? 'Seleccionar cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  /// Widget para seleccionar fecha del préstamo
  Widget _buildFechaPrestamo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _seleccionarFecha(
        titulo: 'Fecha del Préstamo',
        fechaInicial: _fechaPrestamo,
        onSeleccionar: (fecha) {
          setState(() {
            _fechaPrestamo = fecha;
          });
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha del Préstamo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fechaPrestamo.day}/${_fechaPrestamo.month}/${_fechaPrestamo.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  /// Widget para seleccionar fecha esperada de devolución
  Widget _buildFechaDevolucion() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _seleccionarFecha(
        titulo: 'Fecha Esperada de Devolución',
        fechaInicial: _fechaEsperadaDevolucion ?? _fechaPrestamo.add(const Duration(days: 7)),
        onSeleccionar: (fecha) {
          setState(() {
            _fechaEsperadaDevolucion = fecha;
          });
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha Esperada Devolución',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fechaEsperadaDevolucion != null
                        ? '${_fechaEsperadaDevolucion!.day}/${_fechaEsperadaDevolucion!.month}/${_fechaEsperadaDevolucion!.year}'
                        : 'Opcional',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar almacén preseleccionado
  Widget _buildAlmacenField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final almacenNombre = _almacenSeleccionado != null
        ? _almacenes
            .firstWhere(
              (a) => a['id'] == _almacenSeleccionado,
              orElse: () => {'nombre': 'Cargando...'},
            )['nombre']
        : 'Cargando almacenes...';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isDark
            ? context.colorScheme.primary.withOpacity(0.2)
            : context.colorScheme.primary.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warehouse,
            size: 20,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almacén (Preseleccionado)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  almacenNombre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: context.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Widget para ingresar monto de garantía
  Widget _buildMontoGarantia() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Monto de Garantía (Opcional)',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        _montoGarantia = double.tryParse(value) ?? 0;
      },
    );
  }

  /// Selector de chofer
  Widget _buildChoferField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<int>(
      value: _choferSeleccionado,
      decoration: InputDecoration(
        labelText: 'Chofer (Opcional)',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text(
            'Seleccionar chofer',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
        ..._choferes.map((chofer) {
          return DropdownMenuItem<int>(
            value: chofer['id'] as int,
            child: Text('${chofer['nombre']} ${chofer['apellido']}'),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _choferSeleccionado = value;
        });
      },
    );
  }

  /// Selector de vehículo
  Widget _buildVehiculoField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<int>(
      value: _vehiculoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Vehículo (Opcional)',
        prefixIcon: const Icon(Icons.directions_car_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text(
            'Seleccionar vehículo',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
        ..._vehiculos.map((vehiculo) {
          return DropdownMenuItem<int>(
            value: vehiculo['id'] as int,
            child: Text('${vehiculo['placa']} - ${vehiculo['modelo']}'),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _vehiculoSeleccionado = value;
        });
      },
    );
  }

  /// Widget para mostrar lista de items (editable)
  Widget _buildListaItems() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['prestable_nombre'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cantidadControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Cantidad',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    // Permitir edición sin restricciones
                                    if (value.isEmpty) {
                                      return;
                                    }

                                    final cantidad = int.tryParse(value);
                                    if (cantidad == null) {
                                      return;
                                    }

                                    // Actualizar cantidad
                                    _items[index]['cantidad'] = cantidad;

                                    // Actualizar almacenes
                                    if (item['almacenes'] is List && (item['almacenes'] as List).isNotEmpty) {
                                      final almacenes = item['almacenes'] as List;
                                      for (var almacen in almacenes) {
                                        almacen['cantidad'] = cantidad;
                                      }
                                    }

                                    // Si es CANASTILLA, recalcular embase
                                    if (item['tipo'] == 'CANASTILLA' &&
                                        item['capacidad'] != null &&
                                        item['capacidad'] > 0) {
                                      final capacidad = item['capacidad'] as int;
                                      final cantidadEmbase = cantidad * capacidad;

                                      // Buscar el embase relacionado
                                      if (index + 1 < _items.length) {
                                        final itemEmbase = _items[index + 1];
                                        if (itemEmbase['tipo'] == 'EMBASE') {
                                          _items[index + 1]['cantidad'] = cantidadEmbase;
                                          // ✅ Actualizar el controller del embase directamente
                                          _cantidadControllers[index + 1]?.text = cantidadEmbase.toString();

                                          // Actualizar almacenes del embase
                                          if (itemEmbase['almacenes'] is List &&
                                              (itemEmbase['almacenes'] as List).isNotEmpty) {
                                            final almacenesEmbase = itemEmbase['almacenes'] as List;
                                            for (var almacen in almacenesEmbase) {
                                              almacen['cantidad'] = cantidadEmbase;
                                            }
                                          }

                                          debugPrint(
                                            '🔄 Canastilla: $cantidad → Embase: $cantidadEmbase (capacidad: $capacidad)',
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removerItem(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mostrar diálogo para seleccionar cliente
  void _mostrarDialogoSeleccionarCliente() {
    final busquedaController = TextEditingController();
    List<Cliente> clientesFiltrados = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Seleccionar Cliente'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.isEmpty) {
                      setState(() {
                        clientesFiltrados = [];
                      });
                      return;
                    }

                    try {
                      final clientProvider =
                          context.read<ClientProvider>();
                      final resultados = await clientProvider.searchClients(
                        value,
                        limit: 20,
                      );
                      // Convertir Client a Cliente
                      setState(() {
                        clientesFiltrados = resultados
                            .map((c) => Cliente(
                              id: c.id,
                              nombre: c.nombre,
                              telefono: c.telefono,
                              fotoPerfil: c.fotoPerfil,
                              razonSocial: c.razonSocial,
                              nit: c.nit,
                              localidadId: 0,
                            ))
                            .toList();
                      });
                    } catch (e) {
                      debugPrint('Error buscando clientes: $e');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: clientesFiltrados.isEmpty
                      ? const Center(
                          child: Text('Escribe para buscar clientes'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return ListTile(
                              title: Text(cliente.nombre),
                              subtitle: Text(cliente.telefono ?? ''),
                              onTap: () {
                                setState(() {
                                  _clienteSeleccionado = cliente;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar diálogo para agregar item
  void _mostrarDialogoAgregarItem() {
    Producto? prestableSeleccionado;
    int cantidad = 1;
    int? almacenSeleccionado;
    final cantidadController = TextEditingController(text: '1');

    if (_prestables.isEmpty) {
      _mostrarError('Cargando prestables...');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar Artículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de prestables
                DropdownButton<Producto>(
                  isExpanded: true,
                  hint: const Text('Seleccionar Prestable'),
                  value: prestableSeleccionado,
                  items: _prestables.map((prestable) {
                    return DropdownMenuItem<Producto>(
                      value: prestable,
                      child: Text(prestable.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      prestableSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cantidad = int.tryParse(value) ?? 1;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('Seleccionar Almacén'),
                  value: almacenSeleccionado,
                  items: _almacenes.map((almacen) {
                    return DropdownMenuItem<int>(
                      value: almacen['id'] as int,
                      child: Text(almacen['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      almacenSeleccionado = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                cantidadController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: prestableSeleccionado != null &&
                      almacenSeleccionado != null
                  ? () {
                      _agregarItem(
                        prestableSeleccionado!.id,
                        prestableSeleccionado!.nombre,
                        cantidad,
                        almacenSeleccionado!,
                      );
                      cantidadController.dispose();
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar selector de fecha
  void _seleccionarFecha({
    required String titulo,
    required DateTime fechaInicial,
    required Function(DateTime) onSeleccionar,
  }) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      onSeleccionar(fecha);
    }
  }
}
