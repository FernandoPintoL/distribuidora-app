import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/cliente.dart';

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
  String _observaciones = '';
  double _montoGarantia = 0;

  // Búsqueda y datos
  List<Producto> _prestables = [];
  Venta? _ventaBuscada;
  List<Map<String, dynamic>> _almacenes = []; // Se cargará del backend

  // Items agregados
  final List<Map<String, dynamic>> _items = [];

  // Estados
  bool _cargando = false;
  bool _cargandoPrestables = false;

  // Controladores
  late TextEditingController _observacionesController;
  late TextEditingController _ventaIdController;
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _observacionesController = TextEditingController();
    _ventaIdController = TextEditingController();
    _cantidadController = TextEditingController();
    _cargarAlmacenes();
    _cargarPrestables();
  }

  /// Cargar almacenes desde API y preseleccionar "Distribuidora"
  Future<void> _cargarAlmacenes() async {
    try {
      final response = await _apiService.get('/almacenes-prestables/index-json?per_page=100');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final almacenesList = data['data'] as List;

        setState(() {
          _almacenes = almacenesList
              .map((a) => {
                    'id': a['id'] as int,
                    'nombre': a['nombre'] as String,
                  })
              .toList();

          // Buscar y preseleccionar "Distribuidora"
          final distribuidora = _almacenes.firstWhere(
            (a) => a['nombre'].toLowerCase().contains('distribuidora'),
            orElse: () => _almacenes.isNotEmpty ? _almacenes.first : {},
          );

          if (distribuidora.isNotEmpty) {
            _almacenSeleccionado = distribuidora['id'] as int;
            debugPrint('✅ Almacén Distribuidora preseleccionado: ${distribuidora['nombre']} (id=${distribuidora['id']})');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando almacenes: $e');
      // No mostrar error, continuar con fallback
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

  /// Auto-llenar prestables desde los detalles de la venta
  /// Fórmula: embase = capacidad_producto * venta.cantidad
  void _autoFillPrestablesDesdeVenta(Venta venta) {
    _items.clear();

    for (var detalle in venta.detalles) {
      if (detalle.producto == null) continue;

      final producto = detalle.producto!;
      final cantidadDetalle = detalle.cantidad.toInt();

      // Agregar item principal con cantidad del detalle
      _items.add({
        'prestable_id': producto.id,
        'prestable_nombre': producto.nombre,
        'cantidad': cantidadDetalle,
        'almacenes': [
          {
            'almacenes_prestables_id': _almacenSeleccionado,
            'cantidad': cantidadDetalle,
          }
        ],
      });

      // Si el producto tiene capacidad, calcular embase
      // Fórmula: embase = capacidad * cantidad_venta
      if (producto.capacidad != null && producto.capacidad! > 0) {
        final cantidadEmbase = (producto.capacidad! * cantidadDetalle).toInt();

        if (cantidadEmbase > 0) {
          _items.add({
            'prestable_id': producto.id,
            'prestable_nombre': '${producto.nombre} - Embase',
            'cantidad': cantidadEmbase,
            'almacenes': [
              {
                'almacenes_prestables_id': _almacenSeleccionado,
                'cantidad': cantidadEmbase,
              }
            ],
          });
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
      _mostrarError('Error: Almacén no disponible. Intenta recargando la pantalla.');
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
        'cliente_id': _clienteSeleccionado!.id,
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Venta #${_ventaBuscada!.numero}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
          ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
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
          ),
        ],
      ],
    );
  }

  /// Widget para seleccionar cliente (simple)
  Widget _buildClienteField() {
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

  /// Widget para mostrar almacén preseleccionado
  Widget _buildAlmacenField() {
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
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50,
      ),
      child: Row(
        children: [
          const Icon(Icons.warehouse, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almacén (Preseleccionado)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
          const Icon(Icons.check_circle, color: Colors.green),
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
