import 'package:flutter/material.dart';
import '../../widgets/custom_time_picker_dialog.dart';
import '../../extensions/theme_extension.dart';

/// Modal para seleccionar fecha y hora de entrega/retiro
/// Se abre como Dialog y retorna Map con fecha, horaInicio, horaFin, observaciones
class FechaHoraSelectorModal extends StatefulWidget {
  final DateTime? fechaInicial;
  final TimeOfDay? horaInicioInicial;
  final TimeOfDay? horaFinInicial;
  final String? observacionesInicial;
  final bool esPreventista;

  const FechaHoraSelectorModal({
    super.key,
    this.fechaInicial,
    this.horaInicioInicial,
    this.horaFinInicial,
    this.observacionesInicial,
    this.esPreventista = false,
  });

  @override
  State<FechaHoraSelectorModal> createState() => _FechaHoraSelectorModalState();
}

class _FechaHoraSelectorModalState extends State<FechaHoraSelectorModal> {
  late DateTime? _fechaSeleccionada;
  late TimeOfDay? _horaInicio;
  late TimeOfDay? _horaFin;
  late TextEditingController _observacionesController;
  late bool _usarFechaPersonalizada;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    _fechaSeleccionada =
        widget.fechaInicial ?? DateTime(now.year, now.month, now.day);
    _horaInicio = widget.horaInicioInicial ?? const TimeOfDay(hour: 9, minute: 0);
    _horaFin = widget.horaFinInicial ?? const TimeOfDay(hour: 17, minute: 0);
    _observacionesController =
        TextEditingController(text: widget.observacionesInicial ?? '');

    // ✅ Determinar si la fecha seleccionada es personalizada (no es hoy/mañana/lunes)
    _usarFechaPersonalizada = _fechaSeleccionada != null
        ? !_esFechaEstandar(_fechaSeleccionada!)
        : false;
  }

  // ✅ Verificar si la fecha es estándar (Hoy, Mañana o Lunes)
  bool _esFechaEstandar(DateTime fecha) {
    final fechasDisponibles = _obtenerFechasDisponibles();
    return fechasDisponibles.values.any((f) =>
        f.year == fecha.year &&
        f.month == fecha.month &&
        f.day == fecha.day);
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Obtener fechas válidas (Hoy, Mañana, Lunes si aplica)
  Map<String, DateTime> _obtenerFechasDisponibles() {
    final DateTime now = DateTime.now();
    final DateTime hoy = DateTime(now.year, now.month, now.day);
    final DateTime manana = hoy.add(const Duration(days: 1));

    final Map<String, DateTime> fechas = {'Hoy': hoy};

    // Mañana: 1=Lunes, 2=Martes, ..., 6=Sábado, 7=Domingo
    if (manana.weekday < 6) {
      // Si mañana es Lunes-Viernes, agregarlo
      fechas['Mañana'] = manana;
    } else if (manana.weekday == 6) {
      // Si mañana es Sábado, agregar Lunes (2 días después)
      fechas['Lunes'] = hoy.add(const Duration(days: 3));
    } else if (manana.weekday == 7) {
      // Si mañana es Domingo, agregar Lunes (1 día después de domingo)
      fechas['Lunes'] = hoy.add(const Duration(days: 2));
    }

    return fechas;
  }

  Future<void> _seleccionarFecha() async {
    final fechasDisponibles = _obtenerFechasDisponibles();
    final colorScheme = Theme.of(context).colorScheme;

    if (!mounted) return;

    // Mostrar diálogo con opciones de fechas disponibles
    final resultado = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📅 Selecciona fecha de entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...fechasDisponibles.entries.map((entry) {
              final nombreFecha = entry.key;
              final fecha = entry.value;
              final diasSemana = [
                'Lunes',
                'Martes',
                'Miércoles',
                'Jueves',
                'Viernes',
                'Sábado',
                'Domingo',
              ];
              final nombreDia = diasSemana[fecha.weekday - 1];
              final fechaFormato =
                  '${fecha.day}/${fecha.month}/${fecha.year}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, fecha),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _fechaSeleccionada?.year == fecha.year &&
                            _fechaSeleccionada?.month == fecha.month &&
                            _fechaSeleccionada?.day == fecha.day
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                  ),
                  child: Column(
                    children: [
                      Text(
                        nombreFecha,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fechaSeleccionada?.year == fecha.year &&
                                  _fechaSeleccionada?.month == fecha.month &&
                                  _fechaSeleccionada?.day == fecha.day
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$nombreDia, $fechaFormato',
                        style: TextStyle(
                          fontSize: 12,
                          color: _fechaSeleccionada?.year == fecha.year &&
                                  _fechaSeleccionada?.month == fecha.month &&
                                  _fechaSeleccionada?.day == fecha.day
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            // ✅ Botón para fecha personalizada (solo si es preventista)
            if (widget.esPreventista) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _seleccionarFechaPersonalizada();
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Otra fecha'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: colorScheme.tertiary.withOpacity(0.3),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setState(() {
        _fechaSeleccionada = resultado;
        _usarFechaPersonalizada = false;
      });
    }
  }

  // ✅ Seleccionar fecha personalizada (solo preventistas)
  Future<void> _seleccionarFechaPersonalizada() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona una fecha personalizada',
    );

    if (picked != null && mounted) {
      setState(() {
        _fechaSeleccionada = picked;
        _usarFechaPersonalizada = true;
      });
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    final TimeOfDay? picked = await showCustomTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      helpText: 'Hora de inicio',
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
      helpText: 'Hora de fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null && mounted) {
      setState(() {
        _horaFin = picked;
      });
    }
  }

  void _guardar() {
    Navigator.pop(context, {
      'fecha': _fechaSeleccionada,
      'horaInicio': _horaInicio,
      'horaFin': _horaFin,
      'observaciones': _observacionesController.text.trim(),
    });
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
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fecha y Hora',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona la fecha y hora de entrega/retiro',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seleccionar Fecha
                    Row(
                      children: [
                        Text(
                          'Fecha',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        // ✅ Toggle para fecha personalizada (solo preventistas)
                        if (widget.esPreventista)
                          Row(
                            children: [
                              Text(
                                'Otra fecha',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _usarFechaPersonalizada,
                                onChanged: (value) {
                                  setState(() {
                                    _usarFechaPersonalizada = value;
                                    if (value) {
                                      _seleccionarFechaPersonalizada();
                                    } else {
                                      // Volver a la primera fecha estándar (hoy)
                                      final now = DateTime.now();
                                      _fechaSeleccionada =
                                          DateTime(now.year, now.month, now.day);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _usarFechaPersonalizada
                          ? _seleccionarFechaPersonalizada
                          : _seleccionarFecha,
                      child: Card(
                        color: colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outline
                                .withOpacity(isDark ? 0.3 : 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _fechaSeleccionada != null
                                      ? _formatearFecha(_fechaSeleccionada!)
                                      : 'Seleccionar fecha',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seleccionar Hora Inicio y Fin
                    Text(
                      'Rango Horario',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _seleccionarHoraInicio,
                            child: Card(
                              color: colorScheme.surfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: colorScheme.outline
                                      .withOpacity(isDark ? 0.3 : 0.2),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Desde',
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _horaInicio != null
                                              ? _formatearHora(_horaInicio!)
                                              : '--:--',
                                          style:
                                              context.textTheme.titleMedium
                                                  ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _seleccionarHoraFin,
                            child: Card(
                              color: colorScheme.surfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: colorScheme.outline
                                      .withOpacity(isDark ? 0.3 : 0.2),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hasta',
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _horaFin != null
                                              ? _formatearHora(_horaFin!)
                                              : '--:--',
                                          style:
                                              context.textTheme.titleMedium
                                                  ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Observaciones
                    Text(
                      'Observaciones (Opcional)',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _observacionesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Agregua notas o instrucciones especiales...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(isDark ? 0.3 : 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
