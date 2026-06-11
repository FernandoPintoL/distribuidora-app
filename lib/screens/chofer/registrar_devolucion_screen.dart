import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prestamos_provider.dart';
import '../../config/app_text_styles.dart';

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
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _fechaDevolucion = DateTime.now();
    _observacionesController = TextEditingController();
    _cantidadesDevoluciones = {};
    _cantidadesDanadas = {};

    // Inicializar mapa de cantidades
    _inicializarCantidades();
  }

  void _inicializarCantidades() {
    final detalles = widget.prestamo.detalles as List? ?? [];
    for (var i = 0; i < detalles.length; i++) {
      final detalle = detalles[i];
      final detalleId = detalle['id'] as int;
      final cantidadPrestada = (detalle['cantidad_prestada'] as int?) ?? 0;

      _cantidadesDevoluciones[detalleId] = 0;
      _cantidadesDanadas[detalleId] = 0;
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Devolución'),
      ),
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
              Text(
                'Items a Devolver',
                style: AppTextStyles.titleMedium(context),
              ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
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
      color: isDark ? Theme.of(context).cardColor : Colors.white,  // ✅ Modo oscuro
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha de Devolución',
              style: AppTextStyles.labelLarge(context),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                '${_fechaDevolucion.day}/${_fechaDevolucion.month}/${_fechaDevolucion.year}',
              ),
              trailing: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => _selectFecha(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFecha(BuildContext context) async {
    final picked = await showDatePicker(
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
        final detalleId = detalle['id'] as int;
        final cantidadPrestada = (detalle['cantidad_prestada'] as int?) ?? 0;
        final prestableName = detalle['prestable']?['nombre'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? Theme.of(context).cardColor : Colors.white,  // ✅ Modo oscuro
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prestableName,
                  style: AppTextStyles.labelLarge(context),
                ),
                Text(
                  'Prestado: $cantidadPrestada unidades',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Cantidad devuelta
                    Expanded(
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Devolviendo',
                          hintText: 'Cantidad en buen estado',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: isDark ? Colors.grey.shade800 : Colors.white,  // ✅ Modo oscuro
                          filled: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _cantidadesDevoluciones[detalleId] =
                                int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cantidad dañada
                    Expanded(
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dañados',
                          hintText: 'Cantidad dañada',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: isDark ? Colors.grey.shade800 : Colors.white,  // ✅ Modo oscuro
                          filled: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _cantidadesDanadas[detalleId] =
                                int.tryParse(value) ?? 0;
                          });
                        },
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: isDark ? Colors.grey.shade800 : Colors.white,  // ✅ Modo oscuro
        filled: true,
      ),
    );
  }

  Future<void> _registrarDevolucion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      final detalles = widget.prestamo.detalles as List? ?? [];
      final payload = {
        'fecha_devolucion': _fechaDevolucion.toString().split(' ')[0],
        'observaciones': _observacionesController.text,
        'detalles': detalles.map((detalle) {
          final detalleId = detalle['id'] as int;
          final keyName = _getKeyNameForDetalle();

          return {
            keyName: detalleId,
            'cantidad_devuelta':
                _cantidadesDevoluciones[detalleId] ?? 0,
            'cantidad_dañada_total': _cantidadesDanadas[detalleId] ?? 0,
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
        backgroundColor: Colors.green.shade600,  // ✅ Mejor visibilidad
        behavior: SnackBarBehavior.floating,  // ✅ Flotante para mejor UX
      ),
    );
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _mostrarError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $error'),
        backgroundColor: Colors.red.shade600,  // ✅ Mejor visibilidad
        behavior: SnackBarBehavior.floating,  // ✅ Flotante para mejor UX
      ),
    );
  }
}
