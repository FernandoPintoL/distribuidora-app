import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/prestamos_provider.dart';
import '../../services/api_service.dart';

/// Pantalla para crear nuevo préstamo a cliente
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
  Map<String, dynamic>? _clienteSeleccionado;
  DateTime _fechaPrestamo = DateTime.now();
  DateTime? _fechaEsperadaDevolucion;
  int? _almacenSeleccionado;
  String _observaciones = '';
  double _montoGarantia = 0;

  // Listas de datos
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _prestables = [];
  final List<Map<String, dynamic>> _almacenes = [
    {'id': 1, 'nombre': 'Almacén Central'},
    {'id': 2, 'nombre': 'Almacén Distribuidora'},
    {'id': 3, 'nombre': 'Almacén Regional'},
  ];

  // Items agregados
  final List<Map<String, dynamic>> _items = [];

  // Estados
  bool _cargando = false;
  bool _cargandoDatos = true;

  // Controladores
  late TextEditingController _observacionesController;
  late TextEditingController _busquedaClienteController;
  late TextEditingController _busquedaPrestableController;

  @override
  void initState() {
    super.initState();
    _observacionesController = TextEditingController();
    _busquedaClienteController = TextEditingController();
    _busquedaPrestableController = TextEditingController();
    _cargarDatos();
  }

  /// Cargar clientes y prestables
  Future<void> _cargarDatos() async {
    setState(() {
      _cargandoDatos = true;
    });

    try {
      // Cargar clientes
      final clientesResponse = await _apiService.get('/clientes?per_page=100');
      if (clientesResponse.statusCode == 200) {
        final data = clientesResponse.data as Map<String, dynamic>;
        final clientesData = data['data'] as Map<String, dynamic>;
        final clientesList = clientesData['data'] as List;
        setState(() {
          _clientes = clientesList.cast<Map<String, dynamic>>();
        });
      }

      // Cargar prestables
      final prestablesResponse = await _apiService.get('/prestables?per_page=100');
      if (prestablesResponse.statusCode == 200) {
        final data = prestablesResponse.data as Map<String, dynamic>;
        final prestablesData = data['data'] as Map<String, dynamic>;
        final prestablesList = prestablesData['data'] as List;
        setState(() {
          _prestables = prestablesList.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos: $e');
      _mostrarError('Error cargando datos');
    } finally {
      setState(() {
        _cargandoDatos = false;
      });
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _busquedaClienteController.dispose();
    _busquedaPrestableController.dispose();
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
      } else {
        // Agregar nuevo item
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
      }
    });
  }

  /// Remover item de la lista
  void _removerItem(int index) {
    setState(() {
      _items.removeAt(index);
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

    if (_almacenSeleccionado == null) {
      _mostrarError('Debes seleccionar un almacén');
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _cargando = true;
    });

    try {
      final prestamosProvider = context.read<PrestamosProvider>();

      // Preparar payload
      final payload = {
        'cliente_id': _clienteSeleccionado!['id'],
        'almacenes_prestables_id': _almacenSeleccionado,
        'fecha_prestamo': _fechaPrestamo.toIso8601String().split('T')[0],
        'fecha_esperada_devolucion': _fechaEsperadaDevolucion?.toIso8601String().split('T')[0],
        'observaciones': _observaciones.isNotEmpty ? _observaciones : null,
        'monto_garantia': _montoGarantia > 0 ? _montoGarantia : null,
        'detalles': _items,
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
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : _cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Datos básicos
                    Text(
                      '📋 Datos del Préstamo',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Cliente
                    _buildClienteField(),
                    const SizedBox(height: 16),

                    // Fecha préstamo
                    _buildFechaPrestamo(),
                    const SizedBox(height: 16),

                    // Fecha esperada devolución
                    _buildFechaDevolucion(),
                    const SizedBox(height: 16),

                    // Almacén
                    _buildAlmacenField(),
                    const SizedBox(height: 16),

                    // Monto garantía
                    _buildMontoGarantia(),
                    const SizedBox(height: 24),

                    // Sección: Items
                    Text(
                      '📦 Artículos',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Botón agregar item
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoAgregarItem(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Artículo'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de items
                    if (_items.isNotEmpty)
                      _buildListaItems()
                    else
                      Center(
                        child: Text(
                          'Sin artículos agregados',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Sección: Observaciones
                    Text(
                      '📝 Observaciones',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
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
                    const SizedBox(height: 24),

                    // Botón crear
                    SizedBox(
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Widget para seleccionar cliente
  Widget _buildClienteField() {
    final clienteNombre = _clienteSeleccionado != null
        ? '${_clienteSeleccionado!['nombre']} ${_clienteSeleccionado!['apellido'] ?? ''}'
        : 'Seleccionar cliente';

    return GestureDetector(
      onTap: () => _mostrarDialogoSeleccionarCliente(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clienteNombre,
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
          border: Border.all(color: Colors.grey.shade400),
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
                      color: Colors.grey.shade600,
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
          border: Border.all(color: Colors.grey.shade400),
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
                      color: Colors.grey.shade600,
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

  /// Widget para seleccionar almacén
  Widget _buildAlmacenField() {
    // TODO: Cargar almacenes desde API o provider
    const List<Map<String, dynamic>> almacenes = [
      {'id': 1, 'nombre': 'Almacén Central'},
      {'id': 2, 'nombre': 'Almacén Distribuidora'},
      {'id': 3, 'nombre': 'Almacén Regional'},
    ];

    return DropdownButtonFormField<int>(
      value: _almacenSeleccionado,
      decoration: InputDecoration(
        labelText: 'Almacén',
        prefixIcon: const Icon(Icons.warehouse),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      items: almacenes.map((almacen) {
        return DropdownMenuItem<int>(
          value: almacen['id'] as int,
          child: Text(almacen['nombre'] as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _almacenSeleccionado = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Debes seleccionar un almacén';
        }
        return null;
      },
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

  /// Widget para mostrar lista de items
  Widget _buildListaItems() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item['prestable_nombre']),
            subtitle: Text('Cantidad: ${item['cantidad']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removerItem(index),
            ),
          ),
        );
      },
    );
  }

  /// Mostrar diálogo para seleccionar cliente
  void _mostrarDialogoSeleccionarCliente() {
    List<Map<String, dynamic>> clientesFiltrados = _clientes;

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
                  controller: _busquedaClienteController,
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      clientesFiltrados = _clientes.where((cliente) {
                        final nombre = (cliente['nombre'] as String?)
                                ?.toLowerCase() ??
                            '';
                        final apellido = (cliente['apellido'] as String?)
                                ?.toLowerCase() ??
                            '';
                        return nombre.contains(value.toLowerCase()) ||
                            apellido.contains(value.toLowerCase());
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: clientesFiltrados.isEmpty
                      ? const Center(
                          child: Text('No hay clientes encontrados'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return ListTile(
                              title: Text(
                                '${cliente['nombre']} ${cliente['apellido'] ?? ''}',
                              ),
                              subtitle: Text(cliente['email'] ?? ''),
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
    int? prestableSeleccionado;
    String? prestableNombre;
    int cantidad = 1;
    int? almacenSeleccionado;
    final cantidadController = TextEditingController(text: '1');

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
                DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('Seleccionar Prestable'),
                  value: prestableSeleccionado,
                  items: _prestables.map((prestable) {
                    return DropdownMenuItem<int>(
                      value: prestable['id'] as int,
                      child: Text(prestable['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      prestableSeleccionado = value;
                      if (value != null) {
                        final prestable =
                            _prestables.firstWhere((p) => p['id'] == value);
                        prestableNombre = prestable['nombre'] as String;
                      }
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
                      almacenSeleccionado != null &&
                      prestableNombre != null
                  ? () {
                      _agregarItem(
                        prestableSeleccionado!,
                        prestableNombre!,
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
