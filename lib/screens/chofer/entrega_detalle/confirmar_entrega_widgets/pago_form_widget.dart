import 'package:flutter/material.dart';
import 'models.dart';
import '../../../../config/app_text_styles.dart';

// ✅ WIDGET: Formulario para Agregar Pago
class PagoFormWidget extends StatefulWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>> tiposPago;
  final bool cargandoTiposPago;
  final int? tipoPagoSeleccionado;
  final TextEditingController montoController;
  final TextEditingController referenciaController;
  final Function(int? value) onTipoPagoChanged;
  final Function(List<PagoEntrega> pagosActualizados) onPagoAdido;
  final Function() buildSugerenciaPago;
  final List<PagoEntrega> pagosActuales;
  final Function(VoidCallback) setState;

  const PagoFormWidget({
    Key? key,
    required this.isDarkMode,
    required this.tiposPago,
    required this.cargandoTiposPago,
    required this.tipoPagoSeleccionado,
    required this.montoController,
    required this.referenciaController,
    required this.onTipoPagoChanged,
    required this.onPagoAdido,
    required this.buildSugerenciaPago,
    required this.pagosActuales,
    required this.setState,
  }) : super(key: key);

  @override
  State<PagoFormWidget> createState() => _PagoFormWidgetState();
}

class _PagoFormWidgetState extends State<PagoFormWidget> {
  @override
  Widget build(BuildContext context) {
    // Obtener tipos disponibles (no usados aún)
    final tiposDisponibles = _obtenerTiposPagoDisponibles();

    return Column(
      children: [
        // Sugerencia inteligente
        if (widget.pagosActuales.isNotEmpty) ...[
          widget.buildSugerenciaPago(),
          const SizedBox(height: 16),
        ],

        // Formulario para agregar nuevo pago
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '➕ Agregar Nuevo Pago',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 12),

              // Selector de tipo de pago
              if (widget.cargandoTiposPago)
                const Center(child: CircularProgressIndicator())
              else if (tiposDisponibles.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: widget.tipoPagoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Pago',
                    hintText: 'Selecciona método',
                    prefixIcon: const Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  items: tiposDisponibles.map((tipo) {
                    return DropdownMenuItem<int>(
                      value: tipo['id'] as int,
                      child: Text(tipo['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: widget.onTipoPagoChanged,
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ Pago Completo Registrado',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'No hay más tipos de pago disponibles',
                              style: TextStyle(
                                fontSize: AppTextStyles.bodySmall(context)
                                    .fontSize!,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Campo de monto
              if (tiposDisponibles.isNotEmpty) ...[
                TextField(
                  controller: widget.montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto (Bs.)',
                    hintText: 'Ej: 100.50',
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),

                // Campo de referencia (opcional)
                TextField(
                  controller: widget.referenciaController,
                  decoration: InputDecoration(
                    labelText: 'Referencia (Opcional)',
                    hintText: 'Ej: Depósito #12345 o Cheque #789',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón para agregar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.tipoPagoSeleccionado == null ||
                            widget.montoController.text.isEmpty
                        ? null
                        : () => _agregarPago(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _agregarPago(BuildContext context) {
    try {
      final monto = double.parse(widget.montoController.text);
      if (monto <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto debe ser mayor a 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final nuevoPago = PagoEntrega(
        tipoPagoId: widget.tipoPagoSeleccionado!,
        monto: monto,
        referencia: widget.referenciaController.text.isNotEmpty
            ? widget.referenciaController.text
            : null,
      );

      final pagosActualizados = [...widget.pagosActuales, nuevoPago];
      widget.onPagoAdido(pagosActualizados);

      widget.montoController.clear();
      widget.referenciaController.clear();
      widget.onTipoPagoChanged(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pago agregado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _obtenerTiposPagoDisponibles() {
    if (widget.pagosActuales.isEmpty) {
      return widget.tiposPago;
    }
    // Filtrar tipos ya usados
    final tiposUsados = widget.pagosActuales.map((p) => p.tipoPagoId).toSet();
    return widget.tiposPago
        .where((tipo) => !tiposUsados.contains(tipo['id']))
        .toList();
  }
}
