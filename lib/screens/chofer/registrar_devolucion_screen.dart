import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prestamos_provider.dart';
import '../../config/app_text_styles.dart';
import '../../utils/date_picker_utils.dart';

/// Pantalla para registrar devoluciones de préstamos
class RegistrarDevolucionScreen extends StatefulWidget {
  final dynamic prestamo;
  final String tipo; // 'cliente', 'evento', 'proveedor'

  const RegistrarDevolucionScreen({
    super.key,
    required this.prestamo,
    required this.tipo,
  });

  @override
  State<RegistrarDevolucionScreen> createState() =>
      _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends State<RegistrarDevolucionScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _fechaDevolucion;
  late TextEditingController _observacionesController;
  late Map<int, int> _cantidadesDevoluciones;
  late Map<int, int> _cantidadesDanadas;
  late Map<int, TextEditingController> _controladorDevoluciones;
  late Map<int, TextEditingController> _controladorDanados;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _fechaDevolucion = DateTime.now();
    _observacionesController = TextEditingController();
    _cantidadesDevoluciones = {};
    _cantidadesDanadas = {};
    _controladorDevoluciones = {};
    _controladorDanados = {};

    _inicializarCantidades();
  }

  void _inicializarCantidades() {
    final detalles = widget.prestamo.detalles as List? ?? [];
    for (var detalle in detalles) {
      _cantidadesDevoluciones[detalle.id] = 0;
      _cantidadesDanadas[detalle.id] = 0;
      _controladorDevoluciones[detalle.id] = TextEditingController(text: '0');
      _controladorDanados[detalle.id] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    for (var controller in _controladorDevoluciones.values) {
      controller.dispose();
    }
    for (var controller in _controladorDanados.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _actualizarDevolucion(int detalleId, String value) {
    final cantidad = int.tryParse(value) ?? 0;
    setState(() {
      _cantidadesDevoluciones[detalleId] = cantidad;
    });
    _actualizarParCanastillaEmbases(detalleId, cantidad, _controladorDevoluciones, _cantidadesDevoluciones);
  }

  void _actualizarDanados(int detalleId, String value) {
    final cantidadDanada = int.tryParse(value) ?? 0;
    final cantidadDevueltaActual = _cantidadesDevoluciones[detalleId] ?? 0;
    final totalAnterior = cantidadDevueltaActual + (_cantidadesDanadas[detalleId] ?? 0);

    // ✅ NUEVO: Ajustar "Devolviendo" automáticamente
    // Si el usuario ingresa dañados, se descuentan del total anterior
    final nuevaCantidadDevuelta = totalAnterior - cantidadDanada;

    setState(() {
      _cantidadesDanadas[detalleId] = cantidadDanada;
      _cantidadesDevoluciones[detalleId] = max(0, nuevaCantidadDevuelta); // No puede ser negativo
    });

    // Actualizar el controller visual de "Devolviendo"
    _controladorDevoluciones[detalleId]?.text = max(0, nuevaCantidadDevuelta).toString();

    _actualizarParCanastillaEmbases(detalleId, cantidadDanada, _controladorDanados, _cantidadesDanadas);
  }

  void _actualizarParCanastillaEmbases(
    int detalleId,
    int cantidad,
    Map<int, TextEditingController> controllers,
    Map<int, int> cantidades,
  ) {
    final detalles = widget.prestamo.detalles as List? ?? [];

    dynamic detalleActual;
    for (var d in detalles) {
      if (d.id == detalleId) {
        detalleActual = d;
        break;
      }
    }

    if (detalleActual == null) return;

    final tipoPrestable = detalleActual.prestable?.tipo?.toUpperCase() ?? '';
    final int capacidad = detalleActual.prestable?.capacidad?.toInt() ?? 1;

    print('DEBUG: tipoPrestable=$tipoPrestable, capacidad=$capacidad');
    print('DEBUG: Todos los prestables:');
    for (var d in detalles) {
      print('  - ${d.prestable?.nombre} (tipo: ${d.prestable?.tipo})');
    }

    if (tipoPrestable == 'CANASTILLA') {
      print('DEBUG: Es canastilla, buscando embase...');
      for (var detalle in detalles) {
        final tipoOtro = detalle.prestable?.tipo?.toUpperCase() ?? '';
        if (tipoOtro == 'EMBASES') {
          print('DEBUG: Encontrado embase: ${detalle.prestable?.nombre}');
          final nuevoValor = cantidad * capacidad;
          setState(() {
            cantidades[detalle.id] = nuevoValor;
          });
          controllers[detalle.id]?.text = nuevoValor.toString();
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Devolución')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha de devolución
              _buildFechaDevolucion(context),
              const SizedBox(height: 20),

              // Detalles para devolver
              Text('Items a Devolver'),
              const SizedBox(height: 12),
              _buildDetallesDevolucion(),
              const SizedBox(height: 20),

              // Observaciones
              _buildObservaciones(),
              const SizedBox(height: 24),

              // Botón de envío
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _registrarDevolucion,
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _enviando ? 'Registrando...' : 'Registrar Devolución',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaDevolucion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha de Devolución'),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text(
                '${_fechaDevolucion.day}/${_fechaDevolucion.month}/${_fechaDevolucion.year}',
              ),
              trailing: Icon(Icons.edit),
              onTap: () => _selectFecha(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFecha(BuildContext context) async {
    final picked = await DatePickerUtils.showThemedDatePicker(
      context: context,
      initialDate: _fechaDevolucion,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _fechaDevolucion = picked;
      });
    }
  }

  Widget _buildDetallesDevolucion() {
    final detalles = widget.prestamo.detalles as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: detalles.asMap().entries.map((entry) {
        final index = entry.key;
        final detalle = entry.value;
        final detalleId = detalle.id;
        final cantidadPrestada = detalle.cantidadPrestada;
        final prestableName = detalle.prestable?.nombre ?? 'N/A';
        final capacidad_prestable = detalle.prestable?.capacidad ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark
              ? Theme.of(context).cardColor
              : Colors.white, // ✅ Modo oscuro
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prestableName),
                Text('Capacidad: $capacidad_prestable unidades'),
                Text('Prestado: $cantidadPrestada unidades'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Cantidad devuelta
                    Expanded(
                      child: TextFormField(
                        controller: _controladorDevoluciones[detalleId],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Devolviendo',
                          hintText: 'Cantidad en buen estado',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) => _actualizarDevolucion(detalleId, value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cantidad dañada
                    Expanded(
                      child: TextFormField(
                        controller: _controladorDanados[detalleId],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dañados',
                          hintText: 'Cantidad dañada',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) => _actualizarDanados(detalleId, value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObservaciones() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: _observacionesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observaciones',
        hintText: 'Agregar observaciones sobre la devolución (opcional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: isDark
            ? Colors.grey.shade800
            : Colors.white, // ✅ Modo oscuro
        filled: true,
      ),
    );
  }

  Future<void> _registrarDevolucion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      final detalles = widget.prestamo.detalles as List? ?? [];

      // Construir payload con ID del préstamo según tipo
      final payload = {
        // ✅ ID del préstamo según tipo (requerido por API)
        _getPrestamIdKey(): widget.prestamo.id,
        'fecha_devolucion': _fechaDevolucion.toString().split(' ')[0],
        'observaciones': _observacionesController.text,
        // ✅ NUEVO: Flag para devolución automática por almacén
        'devolucion_automatica': true,
        'detalles': detalles.map((detalle) {
          final detalleId = detalle.id;
          final keyName = _getKeyNameForDetalle();
          final cantidadDevuelta = _cantidadesDevoluciones[detalleId] ?? 0; // Solo los buenos
          final cantidadDanada = _cantidadesDanadas[detalleId] ?? 0; // Solo los dañados

          // ✅ NUEVO: Enviar almacenes que ya vienen en el modelo
          final almacenesDelDetalle = detalle.almacenes ?? [];

          // Distribuir cantidad a devolver SECUENCIALMENTE entre almacenes (FIFO)
          // Se completa un almacén antes de pasar al siguiente
          final devolucionAlmacenes = <Map<String, dynamic>>[];
          if (almacenesDelDetalle.isNotEmpty && cantidadDevuelta > 0) {
            int cantidadRestante = cantidadDevuelta;

            for (final almacen in almacenesDelDetalle) {
              if (cantidadRestante <= 0) break;

              final cantidadPrestada = (almacen.cantidad as int);
              final cantidadDeEsteAlmacen = (cantidadRestante > cantidadPrestada
                  ? cantidadPrestada
                  : cantidadRestante);

              devolucionAlmacenes.add({
                'almacenes_prestables_id': almacen.almacenesPrestasblesId,
                'cantidad_devuelta': cantidadDeEsteAlmacen,
                'cantidad_dañada_total': 0,  // Se asignará al último almacén
                'es_proveedor': almacen.esProveedor,
              });

              cantidadRestante -= cantidadDeEsteAlmacen;
            }

            // ✅ Asignar dañadas al ÚLTIMO almacén que recibió devoluciones
            if (cantidadDanada > 0 && devolucionAlmacenes.isNotEmpty) {
              devolucionAlmacenes.last['cantidad_dañada_total'] = cantidadDanada;
            }
          }

          return {
            keyName: detalleId,
            'cantidad_devuelta': cantidadDevuelta,
            'cantidad_dañada_parcial': 0,
            'cantidad_dañada_total': cantidadDanada,
            if (devolucionAlmacenes.isNotEmpty)
              'devolucion_almacenes': devolucionAlmacenes,
          };
        }).toList(),
      };

      final provider = context.read<PrestamosProvider>();
      bool success = false;

      switch (widget.tipo) {
        case 'cliente':
          success = await provider.registrarDevolucionCliente(
            widget.prestamo.id,
            payload,
          );
          break;
        case 'evento':
          success = await provider.registrarDevolucionEvento(
            widget.prestamo.id,
            payload,
          );
          break;
        case 'proveedor':
          success = await provider.registrarDevolucionProveedor(
            widget.prestamo.id,
            payload,
          );
          break;
      }

      setState(() => _enviando = false);

      if (success) {
        _mostrarExito(context);
      } else {
        _mostrarError(context, provider.error ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() => _enviando = false);
      _mostrarError(context, e.toString());
    }
  }

  /// Obtiene la clave para el ID del préstamo según el tipo
  String _getPrestamIdKey() {
    switch (widget.tipo) {
      case 'cliente':
        return 'prestamo_cliente_id';
      case 'evento':
        return 'prestamo_evento_id';
      case 'proveedor':
        return 'prestamo_proveedor_id';
      default:
        return 'prestamo_cliente_id';
    }
  }

  /// Obtiene la clave para el ID del detalle del préstamo según el tipo
  String _getKeyNameForDetalle() {
    switch (widget.tipo) {
      case 'cliente':
        return 'prestamo_cliente_detalle_id';
      case 'evento':
        return 'prestamo_evento_detalle_id';
      case 'proveedor':
        return 'prestamo_proveedor_detalle_id';
      default:
        return 'prestamo_cliente_detalle_id';
    }
  }

  void _mostrarExito(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Devolución registrada exitosamente'),
        backgroundColor: Colors.green.shade600, // ✅ Mejor visibilidad
        behavior: SnackBarBehavior.floating, // ✅ Flotante para mejor UX
      ),
    );
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _mostrarError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $error'),
        backgroundColor: Colors.red.shade600, // ✅ Mejor visibilidad
        behavior: SnackBarBehavior.floating, // ✅ Flotante para mejor UX
      ),
    );
  }
}
