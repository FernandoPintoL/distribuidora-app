# Ejemplos de Código Corregidos - BoxConstraints Error en TimePicker

## Ejemplo 1: Solución Simple (Recomendada para ti)

Esta es la solución que probablemente necesitas aplicar inmediatamente a tu código.

### Archivo: `lib/screens/pedidos/fecha_hora_entrega_screen.dart`

**Cambios necesarios:**

```dart
// Reemplazar estas dos funciones (líneas 61-91)

// ❌ ANTES - Vulnerable a BoxConstraints error
Future<void> _seleccionarHoraInicio() async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    helpText: 'Hora de inicio preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );

  if (picked != null) {
    setState(() {
      _horaInicio = picked;
    });
  }
}

Future<void> _seleccionarHoraFin() async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaFin ?? TimeOfDay.now(),
    helpText: 'Hora de fin preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );

  if (picked != null) {
    setState(() {
      _horaFin = picked;
    });
  }
}

// ✅ DESPUÉS - Corregido
Future<void> _seleccionarHoraInicio() async {
  // Diferir para estabilizar widget tree
  await Future.delayed(const Duration(milliseconds: 50));

  // Verificar que el widget aún está montado
  if (!mounted) return;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    helpText: 'Hora de inicio preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    useRootNavigator: true,  // <-- CLAVE: Renderiza en context raíz
  );

  if (picked != null && mounted) {
    setState(() {
      _horaInicio = picked;
    });
  }
}

Future<void> _seleccionarHoraFin() async {
  // Diferir para estabilizar widget tree
  await Future.delayed(const Duration(milliseconds: 50));

  // Verificar que el widget aún está montado
  if (!mounted) return;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaFin ?? TimeOfDay.now(),
    helpText: 'Hora de fin preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    useRootNavigator: true,  // <-- CLAVE: Renderiza en context raíz
  );

  if (picked != null && mounted) {
    setState(() {
      _horaFin = picked;
    });
  }
}
```

---

## Ejemplo 2: Solución con Widget Personalizado

Si quieres una solución más limpia y reutilizable, crea un widget custom.

### Archivo a crear: `lib/widgets/time_picker_button_widget.dart`

```dart
import 'package:flutter/material.dart';

/// Widget reutilizable para seleccionar hora sin errores de BoxConstraints
class TimePickerButtonWidget extends StatelessWidget {
  final TimeOfDay? initialTime;
  final String label;
  final String? helpText;
  final Function(TimeOfDay) onTimeSelected;
  final bool enabled;

  const TimePickerButtonWidget({
    Key? key,
    this.initialTime,
    required this.label,
    this.helpText,
    required this.onTimeSelected,
    this.enabled = true,
  }) : super(key: key);

  Future<void> _selectTime(BuildContext context) async {
    // Estabilizar widget tree
    await Future.delayed(const Duration(milliseconds: 50));

    if (!context.mounted) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      helpText: helpText,
      useRootNavigator: true,  // Crítico para evitar BoxConstraints error
    );

    if (picked != null && context.mounted) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _selectTime(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: enabled ? null : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black : Colors.grey,
              ),
            ),
            if (!enabled)
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
```

**Usar en tu código:**

```dart
// En fecha_hora_entrega_screen.dart, reemplazar InkWell en línea 281 y 328

// ❌ ANTES
InkWell(
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

// ✅ DESPUÉS
TimePickerButtonWidget(
  initialTime: _horaInicio,
  label: _horaInicio != null
      ? 'Desde: ${_formatearHora(_horaInicio!)}'
      : 'Desde: --:--',
  helpText: 'Hora de inicio preferida',
  onTimeSelected: (time) {
    setState(() {
      _horaInicio = time;
    });
  },
)
```

---

## Ejemplo 3: Solución para AlertDialog (client_form_screen.dart)

Para el dialog de ventanas de entrega (línea 1208).

### Código corregido:

```dart
// En _showVentanaDialog (línea 1192-1318)

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
                          // Estabilizar widget tree ANTES de mostrar TimePicker
                          await Future.delayed(
                            const Duration(milliseconds: 50),
                          );

                          if (!context.mounted) return;

                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start,
                            useRootNavigator: true,  // CRÍTICO
                          );

                          if (picked != null && context.mounted) {
                            setLocalState(() => start = picked);
                          }
                        },
                        child: Text('Inicio: ${_formatTimeOfDay(start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // Estabilizar widget tree ANTES de mostrar TimePicker
                          await Future.delayed(
                            const Duration(milliseconds: 50),
                          );

                          if (!context.mounted) return;

                          final picked = await showTimePicker(
                            context: context,
                            initialTime: end,
                            useRootNavigator: true,  // CRÍTICO
                          );

                          if (picked != null && context.mounted) {
                            setLocalState(() => end = picked);
                          }
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
```

---

## Ejemplo 4: Solución Avanzada - Custom Time Picker Screen

Si necesitas máximo control, reemplaza el dialog por una pantalla custom.

### Archivo a crear: `lib/screens/time_picker_screen.dart`

```dart
import 'package:flutter/material.dart';

class TimePickerScreen extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const TimePickerScreen({
    Key? key,
    required this.initialTime,
    required this.title,
  }) : super(key: key);

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Selector de horas
                NumberPicker(
                  value: _selectedHour,
                  minValue: 0,
                  maxValue: 23,
                  onChanged: (value) {
                    setState(() => _selectedHour = value);
                  },
                ),
                const SizedBox(width: 20),
                const Text(':', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 20),
                // Selector de minutos
                NumberPicker(
                  value: _selectedMinute,
                  minValue: 0,
                  maxValue: 59,
                  step: 5,
                  onChanged: (value) {
                    setState(() => _selectedMinute = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Componente reusable para seleccionar números
class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final int step;
  final Function(int) onChanged;

  const NumberPicker({
    Key? key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: value < maxValue
              ? () => onChanged(value + step)
              : null,
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: value > minValue
              ? () => onChanged(value - step)
              : null,
        ),
      ],
    );
  }
}
```

**Uso:**

```dart
// En lugar de showTimePicker
final TimeOfDay? picked = await Navigator.of(context).push<TimeOfDay>(
  MaterialPageRoute(
    builder: (context) => TimePickerScreen(
      initialTime: _horaInicio ?? TimeOfDay.now(),
      title: 'Seleccionar Hora',
    ),
  ),
);

if (picked != null) {
  setState(() {
    _horaInicio = picked;
  });
}
```

---

## Tabla Comparativa de Soluciones

| Solución | Dificultad | Tiempo Implementación | Mantenibilidad | Recomendado Para |
|----------|-----------|----------------------|-----------------|------------------|
| Ejemplo 1 (Simple) | Fácil | 5 min | Buena | Tu caso actual |
| Ejemplo 2 (Widget Custom) | Media | 10 min | Excelente | Proyectos grandes |
| Ejemplo 3 (AlertDialog) | Fácil | 5 min | Buena | Dialog actual |
| Ejemplo 4 (Pantalla Custom) | Difícil | 30 min | Excelente | Control total |

---

## Checklist de Implementación

- [ ] Aplicar Ejemplo 1 a `fecha_hora_entrega_screen.dart`
- [ ] Aplicar Ejemplo 3 a `client_form_screen.dart`
- [ ] Probar en dispositivo físico
- [ ] Probar en emulador
- [ ] Verificar que no hay errores en console
- [ ] Crear widget reutilizable (opcional, Ejemplo 2)
- [ ] Documentar cambios en commit
