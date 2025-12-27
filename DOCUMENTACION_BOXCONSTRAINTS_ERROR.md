# Error: BoxConstraints has non-normalized height constraints en Flutter

## Descripción General

Este es un error que ocurre cuando Flutter detecta que un widget tiene restricciones de altura inválidas o no normalizadas. El error típicamente aparece cuando se llama a `showTimePicker()` o `showDatePicker()` en ciertos contextos.

**Ubicación común en tu código:**
- `fecha_hora_entrega_screen.dart` (líneas 62, 78)
- `client_form_screen.dart` (líneas 1240, 1254)

---

## 1. LAS 3 CAUSAS PRINCIPALES

### Causa 1: Dialog dentro de un SingleChildScrollView sin constraints adecuados
**Probabilidad en tu caso: ALTA**

Cuando `showTimePicker()` se llama desde un contexto que está dentro de un `SingleChildScrollView`, Flutter intenta renderizar el dialog pero el parent widget no tiene constraints de altura definidas claramente.

**Tu código vulnerable:**
```dart
// En fecha_hora_entrega_screen.dart
Scaffold(
  body: SingleChildScrollView(  // <-- Aquí está el problema
    child: Column(
      children: [
        // ... otros widgets
        InkWell(
          onTap: _seleccionarHoraInicio,  // <-- showTimePicker se llama aquí
          child: Container(...),
        ),
      ],
    ),
  ),
)
```

**Por qué ocurre:**
- `SingleChildScrollView` no tiene altura definida inicialmente
- Cuando `showTimePicker()` se renderiza, no sabe qué constraints usar
- Flutter lanza el error: "height is Infinity, which violates the constraint <= X"

---

### Causa 2: Dialog dentro de un AlertDialog con Column sin constraints
**Probabilidad en tu caso: MEDIA**

En `client_form_screen.dart` línea 1208, tienes un `AlertDialog` con `Column(mainAxisSize: MainAxisSize.min)` que contiene botones con `showTimePicker()`.

**Tu código vulnerable:**
```dart
// En client_form_screen.dart (línea 1208)
AlertDialog(
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ... widgets
      OutlinedButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,  // <-- El context es del AlertDialog
            initialTime: start,
          );
        },
      ),
    ],
  ),
)
```

**Por qué ocurre:**
- El `AlertDialog` tiene un tamaño específico
- Cuando se abre `showTimePicker`, compite por el espacio de pantalla
- Las restricciones heredadas del AlertDialog no son compatibles

---

### Causa 3: Dimensiones infinitas en widgets padres
**Probabilidad en tu caso: BAJA**

Cuando un widget padre tiene altura `infinite` (Infinity) y un child intenta expandirse.

**Ejemplo:**
```dart
SizedBox(
  height: double.infinity,  // Altura infinita
  child: Column(
    children: [
      InkWell(
        onTap: _abrirTimePicker,  // Error si llama showTimePicker
      ),
    ],
  ),
)
```

**Por qué ocurre:**
- El parent widget propaga restricciones infinitas al dialog
- Flutter no puede normalizar las constraints

---

## 2. CUATRO SOLUCIONES PRÁCTICAS

### Solución 1: Usar `barrierDismissible` y `useRootNavigator: true`
**Dificultad: Fácil | Compatibilidad: Excelente**

Esta es la **solución más rápida y directa**. Asegura que el dialog se renderiza en el context correcto.

```dart
Future<void> _seleccionarHoraInicio() async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    helpText: 'Hora de inicio preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    // Agregar estas líneas:
    useRootNavigator: true,  // <-- CLAVE
    barrierDismissible: true,  // Permite cerrar al tocar afuera
  );

  if (picked != null) {
    setState(() {
      _horaInicio = picked;
    });
  }
}
```

**Por qué funciona:**
- `useRootNavigator: true` coloca el dialog en el context de la App root, evitando conflictos con ScrollViews
- Asegura que el dialog tenga las constraints correctas de toda la pantalla

---

### Solución 2: Envolver showTimePicker en un Future.delayed para diferir la ejecución
**Dificultad: Media | Compatibilidad: Muy Buena**

A veces el problema ocurre porque el widget tree está siendo construido. Diferir la ejecución puede resolverlo.

```dart
Future<void> _seleccionarHoraInicio() async {
  // Diferir la ejecución para permitir que el widget tree se estabilice
  await Future.delayed(const Duration(milliseconds: 100));

  if (!mounted) return;  // Verificar que el widget aún existe

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    useRootNavigator: true,
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
```

**Por qué funciona:**
- Permite que Flutter complete el ciclo de construcción actual
- Reduce conflictos de constraints entre widgets
- El `mounted` check evita memory leaks

---

### Solución 3: Extraer el dialog a un widget custom con context específico
**Dificultad: Alta | Compatibilidad: Excelente | Mantenibilidad: Mejor**

Crear un widget separado que maneje los diálogos de tiempo de forma aislada.

**Crear nuevo archivo: `lib/widgets/time_picker_dialog.dart`**
```dart
import 'package:flutter/material.dart';

class TimePickerButton extends StatelessWidget {
  final TimeOfDay? initialTime;
  final String label;
  final Function(TimeOfDay) onTimePicked;

  const TimePickerButton({
    Key? key,
    this.initialTime,
    required this.label,
    required this.onTimePicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _selectTime(context),
      child: Text(label),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      useRootNavigator: true,  // Crítico
    );

    if (picked != null) {
      onTimePicked(picked);
    }
  }
}
```

**Usar en tu código:**
```dart
// En client_form_screen.dart
TimePickerButton(
  initialTime: start,
  label: 'Inicio: ${_formatTimeOfDay(start)}',
  onTimePicked: (picked) {
    setLocalState(() => start = picked);
  },
)
```

**Ventajas:**
- Aislamiento del contexto de diálogo
- Reutilizable en múltiples pantallas
- Más fácil de testear
- Mejor mantenibilidad

---

### Solución 4: Reemplazar AlertDialog por Dialog personalizado con Navigator.push
**Dificultad: Muy Alta | Compatibilidad: Excelente | Para casos extremos**

Si ninguna solución anterior funciona, reemplazar el AlertDialog tradicional por un Dialog customizado con su propio Navigator:

```dart
Future<void> _showCustomTimePickerDialog() async {
  final result = await Navigator.of(context).push<TimeOfDay>(
    MaterialPageRoute<TimeOfDay>(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Seleccionar Hora'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: SizedBox(
              width: double.infinity,
              height: 400,
              child: TimePicker(
                initialTime: TimeOfDay.now(),
                onTimeChanged: (time) {
                  Navigator.of(context).pop(time);
                },
              ),
            ),
          ),
        );
      },
    ),
  );

  if (result != null) {
    setState(() {
      _horaInicio = result;
    });
  }
}
```

**Ventajas:**
- Control total sobre las constraints
- Sem conflictos con diálogos heredados
- Mejor control de lifecycle

---

## 3. SOLUCIÓN MÁS PROBABLE PARA TU CASO

### Diagnóstico: CAUSA 1 es la más probable

Basado en tu código:

1. **Ubicación:**
   - `fecha_hora_entrega_screen.dart` línea 155-261
   - El `showTimePicker()` se llama desde dentro de un `SingleChildScrollView`

2. **Síntomas:**
   ```
   Error: BoxConstraints has non-normalized height constraints
   Error: height is Infinity or NaN
   ```

3. **Solución recomendada: Opción 1 + Opción 2 (Combinadas)**

### CÓDIGO CORREGIDO para `fecha_hora_entrega_screen.dart`:

```dart
// ANTES (vulnerable)
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

// DESPUÉS (corregido)
Future<void> _seleccionarHoraInicio() async {
  // Pequeño delay para estabilizar el widget tree
  await Future.delayed(const Duration(milliseconds: 50));

  if (!mounted) return;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    helpText: 'Hora de inicio preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    useRootNavigator: true,  // CRÍTICO: Renderiza en el context raíz
  );

  if (picked != null && mounted) {
    setState(() {
      _horaInicio = picked;
    });
  }
}

// Aplicar lo mismo a _seleccionarHoraFin()
Future<void> _seleccionarHoraFin() async {
  await Future.delayed(const Duration(milliseconds: 50));

  if (!mounted) return;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaFin ?? TimeOfDay.now(),
    helpText: 'Hora de fin preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    useRootNavigator: true,
  );

  if (picked != null && mounted) {
    setState(() {
      _horaFin = picked;
    });
  }
}
```

---

### CÓDIGO CORREGIDO para `client_form_screen.dart` (línea 1240):

```dart
// ANTES (vulnerable)
OutlinedButton(
  onPressed: () async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start,
    );
    if (picked != null)
      setLocalState(() => start = picked);
  },
  child: Text('Inicio: ${_formatTimeOfDay(start)}'),
),

// DESPUÉS (corregido)
OutlinedButton(
  onPressed: () async {
    await Future.delayed(const Duration(milliseconds: 50));

    // El context en un AlertDialog StatefulBuilder puede ser problemático
    // Por eso usamos el Navigator más externo con useRootNavigator
    final picked = await showTimePicker(
      context: context,
      initialTime: start,
      useRootNavigator: true,  // CRÍTICO
    );
    if (picked != null && mounted)
      setLocalState(() => start = picked);
  },
  child: Text('Inicio: ${_formatTimeOfDay(start)}'),
),

// Aplicar lo mismo a la hora Fin (línea 1254)
OutlinedButton(
  onPressed: () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final picked = await showTimePicker(
      context: context,
      initialTime: end,
      useRootNavigator: true,  // CRÍTICO
    );
    if (picked != null && mounted)
      setLocalState(() => end = picked);
  },
  child: Text('Fin: ${_formatTimeOfDay(end)}'),
),
```

---

## Resumen de Cambios Recomendados

| Archivo | Línea | Cambio |
|---------|-------|--------|
| `fecha_hora_entrega_screen.dart` | 62 | Agregar `useRootNavigator: true` + `Future.delayed` |
| `fecha_hora_entrega_screen.dart` | 78 | Agregar `useRootNavigator: true` + `Future.delayed` |
| `client_form_screen.dart` | 1240 | Agregar `useRootNavigator: true` + `Future.delayed` |
| `client_form_screen.dart` | 1254 | Agregar `useRootNavigator: true` + `Future.delayed` |

---

## Prevención Futura

1. **Siempre usar `useRootNavigator: true`** en `showTimePicker()` y `showDatePicker()`
2. **Mantener los ScrollViews simples** sin widgets complejos anidados
3. **Usar `mounted` checks** después de operaciones asincrónicas
4. **Probar en diferentes tamaños de pantalla** para detectar conflictos de constraints

---

## Referencias
- Flutter Issue: https://github.com/flutter/flutter/issues/
- Material Design Time Picker: https://api.flutter.dev/flutter/material/showTimePicker.html
- BoxConstraints Documentation: https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html
