import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../widgets/custom_time_picker_dialog.dart';
import '../../config/config.dart';

class FechaHoraEntregaScreen extends StatefulWidget {
  final ClientAddress? direccion; // Nullable para soportar PICKUP

  const FechaHoraEntregaScreen({super.key, this.direccion});

  @override
  State<FechaHoraEntregaScreen> createState() => _FechaHoraEntregaScreenState();
}

class _FechaHoraEntregaScreenState extends State<FechaHoraEntregaScreen> {
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final TextEditingController _observacionesController =
      TextEditingController();

  // Detectar si es PICKUP (dirección es null) o DELIVERY (dirección no es null)
  bool get esPickup => widget.direccion == null;

  @override
  void initState() {
    super.initState();
    // Establecer valores por defecto: fecha de hoy y horario de 09:00 a 17:00
    final now = DateTime.now();
    _fechaSeleccionada = DateTime(now.year, now.month, now.day);
    _horaInicio = const TimeOfDay(hour: 9, minute: 0);
    _horaFin = const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day); // Hoy es el mínimo
    final DateTime lastDate = now.add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona la fecha de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      helpText: 'Hora de inicio preferida',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null && mounted) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  Future<void> _seleccionarHoraFin() async {
    final TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: _horaFin ?? TimeOfDay.now(),
      helpText: 'Hora de fin preferida',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null && mounted) {
      setState(() {
        _horaFin = picked;
      });
    }
  }

  void _continuarAlResumen() {
    // Navegar a la pantalla de resumen con tipoEntrega
    Navigator.pushNamed(
      context,
      '/resumen-pedido',
      arguments: {
        'tipoEntrega': esPickup ? 'PICKUP' : 'DELIVERY',
        'direccion': widget.direccion, // null para PICKUP, ClientAddress para DELIVERY
        'fechaProgramada': _fechaSeleccionada,
        'horaInicio': _horaInicio,
        'horaFin': _horaFin,
        'observaciones': _observacionesController.text.trim(),
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    return '$diaSemana, $dia de $mes de $anio';
  }

  String _formatearHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: esPickup ? 'Fecha y Hora de Retiro' : 'Fecha y Hora de Entrega',
        customGradient: AppGradients.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esPickup
                        ? '¿Cuándo deseas retirar tu pedido?'
                        : '¿Cuándo deseas recibir tu pedido?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    esPickup
                        ? 'Agenda la fecha y hora preferida para tu retiro'
                        : 'Selecciona fecha y rango horario (opcional)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar dirección SOLO si es DELIVERY
                  if (!esPickup)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dirección de entrega',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.direccion!.direccion,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Mostrar info de almacén SI es PICKUP
                  if (esPickup)
                    Card(
                      color: Colors.orange.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: Colors.orange.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lugar de Retiro',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Almacén Principal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Selección de fecha
                  const Text(
                    'Fecha programada',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _fechaSeleccionada != null
                                  ? _formatearFecha(_fechaSeleccionada!)
                                  : 'Seleccionar fecha (opcional)',
                              style: TextStyle(
                                fontSize: 16,
                                color: _fechaSeleccionada != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Horario preferido
                  const Text(
                    'Horario preferido (opcional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Especifica un rango horario para coordinar mejor la entrega',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Hora inicio
                      Expanded(
                        child: InkWell(
                          onTap: _seleccionarHoraInicio,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Desde',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _horaInicio != null
                                          ? _formatearHora(_horaInicio!)
                                          : '--:--',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _horaInicio != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Hora fin
                      Expanded(
                        child: InkWell(
                          onTap: _seleccionarHoraFin,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hasta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _horaFin != null
                                          ? _formatearHora(_horaFin!)
                                          : '--:--',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _horaFin != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Observaciones
                  const Text(
                    'Observaciones (opcional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Ej: Llamar antes de llegar, tocar el timbre, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Fecha y horario son referenciales. El tiempo exacto se coordinará una vez aprobada tu proforma.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
              onPressed: _continuarAlResumen,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar al Resumen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
