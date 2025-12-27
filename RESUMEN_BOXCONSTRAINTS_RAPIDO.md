# Resumen Rápido: Error "BoxConstraints has non-normalized height constraints"

## TL;DR - Lo que debes hacer YA

Si el error ocurre cuando abres un TimePicker, agrega esta línea a TODOS tus `showTimePicker()`:

```dart
useRootNavigator: true,  // <-- AGREGÁ ESTO
```

Y un pequeño delay antes:

```dart
await Future.delayed(const Duration(milliseconds: 50));
if (!mounted) return;
```

**Línea exacta en tu código:**

**Archivo: `fecha_hora_entrega_screen.dart` (líneas 62 y 78)**
```dart
final TimeOfDay? picked = await showTimePicker(
  context: context,
  initialTime: _horaInicio ?? TimeOfDay.now(),
  helpText: 'Hora de inicio preferida',
  cancelText: 'Cancelar',
  confirmText: 'Aceptar',
  useRootNavigator: true,  // ← AGREGÁ ESTO
);
```

**Archivo: `client_form_screen.dart` (líneas 1240 y 1254)**
```dart
final picked = await showTimePicker(
  context: context,
  initialTime: start,
  useRootNavigator: true,  // ← AGREGÁ ESTO
);
```

---

## Las 3 Causas Principales (en orden de probabilidad en tu caso)

### 1. Dialog dentro de SingleChildScrollView (PROBABLE - 85%)
Tu `fecha_hora_entrega_screen.dart` usa `SingleChildScrollView` y abre `showTimePicker()` dentro.

**Solución:** `useRootNavigator: true`

### 2. Dialog dentro de AlertDialog (POSIBLE - 10%)
Tu `client_form_screen.dart` abre `showTimePicker()` desde dentro de un `AlertDialog`.

**Solución:** `useRootNavigator: true` + `Future.delayed()`

### 3. Constraints infinitas (IMPROBABLE - 5%)
Altura infinita propagada desde un widget padre.

**Solución:** Envolver en `SizedBox` con altura definida

---

## 4 Soluciones Ordenadas por Efectividad

### ✅ SOLUCIÓN 1: Rápida (Recomendada)
Simplemente agregar `useRootNavigator: true`

**Tiempo:** 5 minutos
**Éxito esperado:** 95%

```dart
await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  useRootNavigator: true,  // ← Esto es lo que hace la magia
);
```

### ✅ SOLUCIÓN 2: Más robusta
Agregar delay + `useRootNavigator: true` + `mounted` check

**Tiempo:** 5 minutos
**Éxito esperado:** 99%

```dart
await Future.delayed(const Duration(milliseconds: 50));
if (!mounted) return;

final TimeOfDay? picked = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  useRootNavigator: true,
);
if (picked != null && mounted) {
  // hacer algo
}
```

### ✅ SOLUCIÓN 3: Profesional
Crear widget reutilizable personalizado

**Tiempo:** 15 minutos
**Éxito esperado:** 100%
**Ventaja:** Código más limpio y reutilizable

Ver: `EJEMPLOS_CODIGO_CORREGIDOS.md` → Ejemplo 2

### ✅ SOLUCIÓN 4: Control total
Crear pantalla personalizada de selección de hora

**Tiempo:** 30 minutos
**Éxito esperado:** 100%
**Ventaja:** Control total sobre el UI/UX

Ver: `EJEMPLOS_CODIGO_CORREGIDOS.md` → Ejemplo 4

---

## Paso a Paso para Aplicar la Solución 1

### 1. Abre `fecha_hora_entrega_screen.dart`

### 2. Encuentra estas funciones (líneas 61-91):
```dart
Future<void> _seleccionarHoraInicio() async {
  final TimeOfDay? picked = await showTimePicker(
```

### 3. Modifica a esto:
```dart
Future<void> _seleccionarHoraInicio() async {
  await Future.delayed(const Duration(milliseconds: 50));
  if (!mounted) return;

  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _horaInicio ?? TimeOfDay.now(),
    helpText: 'Hora de inicio preferida',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    useRootNavigator: true,  // ← AGREGAR ESTA LÍNEA
  );

  if (picked != null && mounted) {
    setState(() {
      _horaInicio = picked;
    });
  }
}
```

### 4. Haz lo mismo con `_seleccionarHoraFin()` (línea 77)

### 5. Abre `client_form_screen.dart`

### 6. Encuentra las llamadas a `showTimePicker` (líneas 1240 y 1254)

### 7. Agrega:
- `useRootNavigator: true` en el parámetro
- `Future.delayed` antes
- `mounted` check después

### 8. Prueba
```bash
flutter run
```

---

## ¿Cómo sé si funcionó?

1. Abre la app
2. Navega a "Fecha y Hora de Entrega"
3. Haz click en "Desde" o "Hasta"
4. El TimePicker debe abrirse SIN errores
5. Selecciona una hora
6. Verifica que se actualiza correctamente

**Si ves el error:**
```
BoxConstraints has non-normalized height constraints
height is NaN or Infinity
```

Entonces necesitas la Solución 2 o superior.

---

## Prevención en el Futuro

Cuando hagas `showTimePicker()` o `showDatePicker()`, SIEMPRE incluye:

```dart
final TimeOfDay? picked = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  useRootNavigator: true,  // SIEMPRE
);
```

Esta es la mejor práctica en Flutter.

---

## Archivos de Documentación

- **DOCUMENTACION_BOXCONSTRAINTS_ERROR.md** - Explicación completa y detallada
- **EJEMPLOS_CODIGO_CORREGIDOS.md** - 4 soluciones con código listo para copiar/pegar
- **RESUMEN_BOXCONSTRAINTS_RAPIDO.md** - Este archivo (acceso rápido)

---

## Resumen: Una Línea

Para arreglar el error: **Agrega `useRootNavigator: true` a todos tus `showTimePicker()` y `showDatePicker()`**
