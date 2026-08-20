import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extensions/theme_extension.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../services/api_service.dart';
import '../../models/venta.dart';
import '../../models/prestable.dart';

/// Pantalla para crear nuevo préstamo a evento
/// Formulario unificado con búsqueda de ventas múltiples
class CrearPrestamoEventoScreen extends StatefulWidget {
  const CrearPrestamoEventoScreen({super.key});

  @override
  State<CrearPrestamoEventoScreen> createState() =>
      _CrearPrestamoEventoScreenState();
}

class _CrearPrestamoEventoScreenState
    extends State<CrearPrestamoEventoScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Datos del préstamo
  DateTime _fechaPrestamo = DateTime.now();
  DateTime? _fechaEsperadaDevolucion;
  int? _almacenSeleccionado;
  int? _choferSeleccionado;
  int? _vehiculoSeleccionado;
  String _montoGarantia = '0';

  // Datos del evento
  String _nombreEvento = '';
  String _encargadoEvento = '';
  String _direccionEvento = '';
  String _telefonoUno = '';
  String _telefonoDos = '';

  // Búsqueda y datos
  Venta? _ventaBuscada;
  List<Venta> _ventasSeleccionadas = [];
  List<Map<String, dynamic>> _almacenes = [];
  List<Map<String, dynamic>> _choferes = [];
  List<Map<String, dynamic>> _vehiculos = [];

  // Items agregados (prestables)
  final List<Map<String, dynamic>> _items = [];

  // Estados
  bool _cargando = false;
  int? _usuarioActualId;
  bool _esChoferActual = false;

  // Controladores
  late TextEditingController _ventaIdController;
  late TextEditingController _nombreEventoController;
  late TextEditingController _encargadoEventoController;
  late TextEditingController _direccionEventoController;
  late TextEditingController _telefonoUnoController;
  late TextEditingController _telefonoDosController;
  late TextEditingController _montoGarantiaController;
  final Map<int, TextEditingController> _cantidadControllers = {};

  @override
  void initState() {
    super.initState();
    _ventaIdController = TextEditingController();
    _nombreEventoController = TextEditingController();
    _encargadoEventoController = TextEditingController();
    _direccionEventoController = TextEditingController();
    _telefonoUnoController = TextEditingController();
    _telefonoDosController = TextEditingController();
    _montoGarantiaController = TextEditingController(text: '0');

    _fechaEsperadaDevolucion = _fechaPrestamo.add(const Duration(days: 7));
    _obtenerUsuarioActual();
    _cargarAlmacenes();
    _cargarChoferes();
    _cargarVehiculos();
  }

  /// Obtener usuario actual desde API
  void _obtenerUsuarioActual() {
    try {
      _apiService.get('/user').then((response) {
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final id = data['id'] ?? data['data']?['id'] ?? data['user']?['id'];
          final name = data['name'] ??
              data['data']?['name'] ??
              data['user']?['name'];

          setState(() {
            _usuarioActualId = id as int?;
            debugPrint('👤 Usuario actual: $_usuarioActualId ($name)');
          });

          // ✅ Después de obtener el usuario, recargar choferes para auto-seleccionar
          if (_usuarioActualId != null) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _autoSeleccionarChoferSiEsNecesario();
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error obteniendo usuario: $e');
    }
  }

  /// Auto-seleccionar chofer si el usuario actual es un chofer
  void _autoSeleccionarChoferSiEsNecesario() {
    if (_usuarioActualId != null && _choferes.isNotEmpty) {
      final choferActual = _choferes
          .where((c) => c['id'] == _usuarioActualId)
          .firstOrNull;

      if (choferActual != null) {
        setState(() {
          _choferSeleccionado = choferActual['id'] as int;
          _esChoferActual = true;
          debugPrint('✅ Chofer auto-seleccionado: $_choferSeleccionado');
        });
      }
    }
  }

  /// Cargar almacenes del backend
  void _cargarAlmacenes() {
    try {
      _apiService
          .get('/almacenes-prestables/index-json')
          .then((response) {
        if (response.statusCode == 200) {
          final data = response.data;
          final almacenesData = data is List ? data : data['data'] as List;

          // Buscar el almacén "Distribuidora" por defecto
          final distribuidora = almacenesData.firstWhere(
            (a) =>
                (a['nombre'] as String?)?.toLowerCase().contains('distribuidora') ==
                true,
            orElse: () => null,
          );

          setState(() {
            _almacenes = almacenesData
                .map((a) => {
                      'id': a['id'] as int,
                      'nombre': a['nombre'] as String? ?? '',
                    })
                .toList();

            if (distribuidora != null) {
              _almacenSeleccionado = distribuidora['id'] as int;
              debugPrint(
                '✅ Almacén Distribuidora preseleccionado: $_almacenSeleccionado',
              );
            }
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Error cargando almacenes: $e');
    }
  }

  /// Cargar choferes del backend
  void _cargarChoferes() {
    try {
      _apiService.get('/choferes/lista').then((response) {
        if (response.statusCode == 200) {
          final data = response.data;
          final choferesData = data is List ? data : data['data'] as List;

          setState(() {
            _choferes = choferesData
                .map((c) => {
                      'id': c['id'] as int,
                      'nombre':
                          '${c['nombre'] ?? ''} ${c['apellido'] ?? ''}'.trim(),
                    })
                .toList();

            debugPrint('✅ Choferes cargados: ${_choferes.length}');
          });

          // ✅ Auto-seleccionar después de cargar si el usuario actual es chofer
          _autoSeleccionarChoferSiEsNecesario();
        }
      });
    } catch (e) {
      debugPrint('❌ Error cargando choferes: $e');
    }
  }

  /// Cargar vehículos del backend
  void _cargarVehiculos() {
    try {
      // Usar endpoint específico que retorna solo vehículos activos
      _apiService.get('/vehiculos?activo=1').then((response) {
        if (response.statusCode == 200) {
          final data = response.data;
          final vehiculosData = data is List
              ? data
              : (data['data'] is List ? data['data'] : []) as List;

          setState(() {
            _vehiculos = vehiculosData
                .map((v) => {
                      'id': v['id'] as int,
                      'placa': v['placa'] as String? ?? '',
                      'marca': v['marca'] as String? ?? '',
                      'modelo': v['modelo'] as String? ?? '',
                    })
                .toList();

            debugPrint('✅ Vehículos cargados: ${_vehiculos.length}');
          });
        } else {
          debugPrint('⚠️ Status code: ${response.statusCode}');
        }
      });
    } catch (e) {
      debugPrint('❌ Error cargando vehículos: $e');
    }
  }

  /// Buscar venta por ID
  Future<void> _buscarVenta(int ventaId) async {
    if (ventaId <= 0) {
      _mostrarError('ID de venta inválido');
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final ventasProvider = context.read<VentasProvider>();
      await ventasProvider.loadVentaDetalle(ventaId);

      final venta = ventasProvider.ventaDetalle;
      if (venta != null) {
        // Verificar si ya está seleccionada
        if (_ventasSeleccionadas.any((v) => v.id == venta.id)) {
          _mostrarError('Esta venta ya está seleccionada');
          setState(() => _cargando = false);
          return;
        }

        setState(() {
          _ventasSeleccionadas.add(venta);
          // Auto-llenar prestables desde la venta
          _autoFillPrestablesDesdeVenta(venta);
        });

        _ventaIdController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #${venta.numero} agregada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _mostrarError('Venta no encontrada');
      }
    } catch (e) {
      _mostrarError('Error buscando venta: $e');
      debugPrint('❌ Error buscando venta: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  /// Auto-llenar prestables desde los detalles de la venta
  void _autoFillPrestablesDesdeVenta(Venta venta) {
    for (var detalle in venta.detalles) {
      if (detalle.producto == null) continue;

      final producto = detalle.producto!;
      final cantidadDetalle = detalle.cantidad.toInt();

      if (producto.prestables != null && producto.prestables!.isNotEmpty) {
        // Buscar canastilla
        final canastilla = producto.prestables!.firstWhere(
          (p) => p.tipo.toUpperCase() == 'CANASTILLA',
          orElse: () => Prestable(id: 0, nombre: '', codigo: '', tipo: ''),
        );

        if (canastilla.id != 0) {
          final itemIndex = _items.length;
          _items.add({
            'prestable_id': canastilla.id,
            'prestable_nombre': canastilla.nombre,
            'cantidad': cantidadDetalle,
            'capacidad': canastilla.capacidad ?? 0,
            'tipo': 'CANASTILLA',
            'almacenes': [
              {
                'almacenes_prestables_id': _almacenSeleccionado,
                'cantidad': cantidadDetalle,
              },
            ],
          });
          _cantidadControllers[itemIndex] =
              TextEditingController(text: cantidadDetalle.toString());

          // Buscar embases asociados
          final embases = producto.prestables!.where(
            (p) => p.tipo.toUpperCase() == 'EMBASES',
          );

          for (var embase in embases) {
            final cantidadEmbase =
                ((canastilla.capacidad ?? 0) * cantidadDetalle).toInt();

            if (cantidadEmbase > 0) {
              final embaseIndex = _items.length;
              _items.add({
                'prestable_id': embase.id,
                'prestable_nombre': embase.nombre,
                'cantidad': cantidadEmbase,
                'tipo': 'EMBASE',
                'almacenes': [
                  {
                    'almacenes_prestables_id': _almacenSeleccionado,
                    'cantidad': cantidadEmbase,
                  },
                ],
              });
              _cantidadControllers[embaseIndex] =
                  TextEditingController(text: cantidadEmbase.toString());
            }
          }
        }
      }
    }
  }

  /// Remover venta de la lista
  void _removerVenta(int ventaId) {
    setState(() {
      _ventasSeleccionadas.removeWhere((v) => v.id == ventaId);
      // TODO: Limpiar prestables asociados a esta venta
    });
  }

  /// Remover item de la lista
  void _removerItem(int index) {
    setState(() {
      _items.removeAt(index);
      _cantidadControllers[index]?.dispose();
      _cantidadControllers.remove(index);
    });
  }

  /// Crear el préstamo
  Future<void> _crearPrestamo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nombreEvento.isEmpty) {
      _mostrarError('El nombre del evento es requerido');
      return;
    }

    if (_items.isEmpty) {
      _mostrarError('Debes agregar al menos un artículo');
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final cantidad = item['cantidad'] as int?;
      if (cantidad == null || cantidad <= 0) {
        _mostrarError('Todas las cantidades deben ser mayores a 0');
        return;
      }
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
        'nombre_evento': _nombreEvento,
        'encargado_evento': _encargadoEvento.isNotEmpty ? _encargadoEvento : null,
        'direccion_evento': _direccionEvento.isNotEmpty ? _direccionEvento : null,
        'telefono_uno': _telefonoUno.isNotEmpty ? _telefonoUno : null,
        'telefono_dos': _telefonoDos.isNotEmpty ? _telefonoDos : null,
        'almacenes_prestables_id': _almacenSeleccionado,
        'chofer_id': _choferSeleccionado,
        'vehiculo_id': _vehiculoSeleccionado,
        'fecha_prestamo': _fechaPrestamo.toIso8601String().split('T')[0],
        'fecha_esperada_devolucion': _fechaEsperadaDevolucion
            ?.toIso8601String()
            .split('T')[0],
        'monto_garantia': _montoGarantia.isNotEmpty && double.tryParse(_montoGarantia)! > 0
            ? double.parse(_montoGarantia)
            : null,
        'detalles': _items,
        'es_venta': false,
        'es_evento': true,
        'ventas_ids': _ventasSeleccionadas.map((v) => v.id).toList(),
      };

      debugPrint('📤 Enviando préstamo a evento: $payload');

      // Crear préstamo
      final resultado = await prestamosProvider.crearPrestamoEvento(payload);

      if (resultado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Préstamo a evento creado exitosamente'),
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
      debugPrint('❌ Error creando préstamo a evento: $e');
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
        content: Text('❌ $mensaje'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _ventaIdController.dispose();
    _nombreEventoController.dispose();
    _encargadoEventoController.dispose();
    _direccionEventoController.dispose();
    _telefonoUnoController.dispose();
    _telefonoDosController.dispose();
    _montoGarantiaController.dispose();
    for (var controller in _cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Préstamo a Evento'),
        backgroundColor: context.colorScheme.primary,
      ),
      body: _cargando && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============ DATOS DEL EVENTO ============
                    _buildSectionHeader('Datos del Evento'),
                    TextFormField(
                      controller: _nombreEventoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Evento *',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) =>
                          _nombreEvento = value?.trim() ?? '',
                      validator: (value) => value?.isEmpty ?? true
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _encargadoEventoController,
                      decoration: const InputDecoration(
                        labelText: 'Encargado del Evento',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) =>
                          _encargadoEvento = value?.trim() ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionEventoController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección del Evento',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onSaved: (value) =>
                          _direccionEvento = value?.trim() ?? '',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _telefonoUnoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono 1',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) =>
                                _telefonoUno = value?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _telefonoDosController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono 2',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) =>
                                _telefonoDos = value?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ============ BÚSQUEDA DE VENTAS ============
                    _buildSectionHeader('Ventas Asociadas'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ventaIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID de Venta',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            final ventaId =
                                int.tryParse(_ventaIdController.text) ?? 0;
                            _buscarVenta(ventaId);
                          },
                          child: const Text('Buscar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_ventasSeleccionadas.isNotEmpty) ...[
                      ..._ventasSeleccionadas.map((venta) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('Venta #${venta.numero}'),
                            subtitle: Text(venta.cliente?.nombre ?? 'Sin cliente'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removerVenta(venta.id),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // ============ DATOS OPERATIVOS ============
                    _buildSectionHeader('Datos Operativos'),
                    _buildChoferField(),
                    const SizedBox(height: 12),
                    _buildVehiculoField(),
                    const SizedBox(height: 12),
                    _buildAlmacenField(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Préstamo',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            initialValue:
                                _fechaPrestamo.toIso8601String().split('T')[0],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Devolución',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            initialValue: _fechaEsperadaDevolucion
                                ?.toIso8601String()
                                .split('T')[0],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _montoGarantiaController,
                      decoration: const InputDecoration(
                        labelText: 'Monto Garantía',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) =>
                          _montoGarantia = value?.trim() ?? '0',
                    ),
                    const SizedBox(height: 24),

                    // ============ PRESTABLES ============
                    _buildSectionHeader(
                      'Prestables (${_items.length})',
                    ),
                    if (_items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Sin prestables agregados',
                            style: context.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._buildListaItems(),
                    const SizedBox(height: 24),

                    // ============ BOTONES ============
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: _cargando ? null : _crearPrestamo,
                          child: _cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Crear Préstamo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Construir header de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: context.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Construir campo de chofer
  Widget _buildChoferField() {
    return DropdownButtonFormField<int>(
      value: _choferSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Chofer',
        border: OutlineInputBorder(),
      ),
      items: _choferes
          .map((c) => DropdownMenuItem(
                value: c['id'] as int,
                child: Text(c['nombre'] as String),
              ))
          .toList(),
      onChanged: (value) =>
          setState(() => _choferSeleccionado = value),
    );
  }

  /// Construir campo de vehículo
  Widget _buildVehiculoField() {
    return DropdownButtonFormField<int>(
      value: _vehiculoSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Vehículo',
        border: OutlineInputBorder(),
      ),
      items: _vehiculos
          .map((v) => DropdownMenuItem(
                value: v['id'] as int,
                child: Text('${v['placa']} - ${v['modelo']}'),
              ))
          .toList(),
      onChanged: (value) =>
          setState(() => _vehiculoSeleccionado = value),
    );
  }

  /// Construir campo de almacén
  Widget _buildAlmacenField() {
    return DropdownButtonFormField<int>(
      value: _almacenSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Almacén *',
        border: OutlineInputBorder(),
      ),
      items: _almacenes
          .map((a) => DropdownMenuItem(
                value: a['id'] as int,
                child: Text(a['nombre'] as String),
              ))
          .toList(),
      onChanged: (value) =>
          setState(() => _almacenSeleccionado = value),
      validator: (value) => value == null ? 'Almacén requerido' : null,
    );
  }

  /// Construir lista de items con cantidad editable
  List<Widget> _buildListaItems() {
    return _items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final controller = _cantidadControllers[index];

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['prestable_nombre'] as String,
                          style: context.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tipo: ${item['tipo']}',
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removerItem(index),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final cantidad = int.tryParse(value);
                  if (cantidad != null && cantidad > 0) {
                    setState(() {
                      _items[index]['cantidad'] = cantidad;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
