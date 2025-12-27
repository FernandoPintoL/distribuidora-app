# Diagrama Explicativo: BoxConstraints Error en TimePicker

## Problema Visual

### Escenario 1: El Problema (Tu Código Actual)

```
┌─────────────────────────────────────────┐
│          APLICACIÓN FLUTTER             │
├─────────────────────────────────────────┤
│                                         │
│  Scaffold                               │
│  ├─ AppBar (height: 56dp)              │
│  └─ Body: SingleChildScrollView        │ ← PROBLEMA
│     │   (height: indefinida/Infinity)  │
│     └─ Column                          │
│        ├─ Header Container             │
│        ├─ Card (fecha)                 │
│        ├─ Text ("Horario preferido")   │
│        └─ Row                          │
│           ├─ Expanded                  │
│           │  └─ InkWell                │
│           │     ├─ onTap: () async {   │
│           │     │    final picked =     │
│           │     │      showTimePicker() │ ← CLICK AQUÍ
│           │     │ }                    │
│           │     └─ Container           │
│           │                            │
│           └─ Expanded                  │
│              └─ InkWell                │
│                 └─ Container           │
│                                         │
├─ BottomBar (ElevatedButton)            │
└─────────────────────────────────────────┘

CUANDO HACE CLICK EN InkWell:

TimePicker intenta renderizarse:
┌─────────────────────────────┐
│    Material Dialog Layer     │ ← Se abre aquí
│   TimePicker                │
│   (necesita ~300dp alto)    │
│                             │
│  ¿QUÉ CONSTRAINTS TIENE?    │
│  Parent: SingleChildScrollView
│  Height constraint: ∞ (Infinity)
│                             │
│  ❌ ERROR:                  │
│  "BoxConstraints has        │
│   non-normalized height     │
│   constraints"              │
└─────────────────────────────┘
```

---

## Solución Visual

### Escenario 2: Solución (Con useRootNavigator: true)

```
┌─────────────────────────────────────────┐
│          APLICACIÓN FLUTTER             │
├─────────────────────────────────────────┤
│                                         │
│  NavigatorState (ROOT)                  │
│  ├─ Scaffold                            │
│  │  ├─ AppBar (height: 56dp)           │
│  │  └─ Body: SingleChildScrollView     │
│  │     └─ Column                       │
│  │        ├─ InkWell                   │
│  │        │  onTap: () async {         │
│  │        │    final picked =          │
│  │        │      showTimePicker(       │
│  │        │        useRootNavigator:   │
│  │        │          true ✅           │
│  │        │      )                     │
│  │        │  }                         │
│  │        └─ Container                 │
│  │                                     │
│  └─ Overlay                            │
│     └─ Dialog Stack                    │
│        └─ TimePicker Material Dialog   │ ← Se abre AQUÍ
│           (en el context raíz)         │
│           ✅ Constraints correctas:    │
│           Width: screen width          │
│           Height: screen height        │
│           ✅ SIN ERRORES               │
│                                         │
└─────────────────────────────────────────┘
```

---

## Comparación: Antes vs Después

### ANTES (Vulnerable):

```dart
InkWell(
  onTap: () async {
    // ❌ El context está dentro de SingleChildScrollView
    // ❌ El TimePicker hereda constraints inválidas
    // ❌ showTimePicker() intenta renderizar en el mismo nivel
    final TimeOfDay? picked = await showTimePicker(
      context: context,  // context: Build context local
      initialTime: TimeOfDay.now(),
      // ❌ Sin useRootNavigator: false (por defecto)
    );
  },
  child: Container(...),
)
```

**Flujo de rendering:**
```
1. Usuario hace click en InkWell
2. showTimePicker() se ejecuta
3. Flutter busca donde renderizar el dialog
4. Usa el context local (SingleChildScrollView)
5. Intenta aplicar constraints del ScrollView
6. ScrollView tiene altura indefinida (Infinity)
7. Dialog necesita altura específica (300dp)
8. CONFLICTO: Infinity vs 300dp ❌
9. ERROR: BoxConstraints has non-normalized height constraints
```

---

### DESPUÉS (Solución):

```dart
InkWell(
  onTap: () async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    // ✅ El context está dentro de SingleChildScrollView
    // ✅ PERO useRootNavigator: true lo saca del árbol local
    // ✅ El TimePicker se renderiza en el Navigator raíz
    final TimeOfDay? picked = await showTimePicker(
      context: context,  // context: mismo build context
      initialTime: TimeOfDay.now(),
      useRootNavigator: true,  // ✅ CLAVE
    );

    if (picked != null && mounted) {
      setState(() { ... });
    }
  },
  child: Container(...),
)
```

**Flujo de rendering:**
```
1. Usuario hace click en InkWell
2. Future.delayed() espera 50ms
3. showTimePicker() se ejecuta
4. useRootNavigator: true está presente
5. Flutter busca el Navigator RAÍZ (no el local)
6. Renderiza el dialog en la capa de Overlay del Navigator raíz
7. El dialog obtiene constraints válidos de la pantalla completa
8. Dialog se renderiza correctamente
9. ✅ SIN ERRORES
10. Usuario selecciona hora
11. setState() actualiza la UI local
```

---

## Árbol de Constraints: Visual

### Escenario Problemático:

```
Screen (MediaQuery)
│ width: 411dp, height: 866dp
│
└─ Scaffold
  │ width: 411dp, height: 866dp
  │
  ├─ AppBar (height: 56dp)
  │
  └─ Body: SingleChildScrollView
    │ width: 411dp, height: Infinity ❌ PROBLEMA
    │ (Su contenido puede ser más grande que la pantalla)
    │
    └─ Column
      │ width: 411dp, height: indefinida
      │
      ├─ Container (Header)
      │ height: 80dp
      │
      ├─ Card (Fecha)
      │ height: 100dp
      │
      └─ Row
        │ height: indefinida ❌ PROBLEMA
        │
        ├─ Expanded
        │ │ width: 195dp
        │ │ height: indefinida ❌ PROBLEMA
        │ │
        │ └─ InkWell
        │   │ onTap: showTimePicker()
        │   │ width: 195dp, height: indefinida ❌ PROBLEMA
        │   │
        │   └─ Container
        │     width: 195dp, height: indefinida ❌ PROBLEMA
        │
        └─ Expanded
          │ width: 195dp
          │ height: indefinida
          │
          └─ InkWell
            │ onTap: showTimePicker()
            │ width: 195dp, height: indefinida ❌ PROBLEMA
            │
            └─ Container
              width: 195dp, height: indefinida

CUANDO ABRE TimePicker:
┌─────────────────────────────┐
│   TimePicker Dialog         │
│   Necesita:                 │
│   width: 360dp (std)        │
│   height: 300dp (min)       │
│                             │
│   Constraints recibidas:    │
│   width: 195dp ✅           │
│   height: Infinity ❌       │
│                             │
│   ERROR: No puede satisfacer
│   ambas restricciones       │
└─────────────────────────────┘
```

### Escenario Correcto:

```
Screen (MediaQuery)
│ width: 411dp, height: 866dp
│
└─ Navigator (ROOT)
  │ width: 411dp, height: 866dp
  │ context: NavigatorState
  │
  ├─ Scaffold
  │ │ width: 411dp, height: 866dp
  │ │
  │ ├─ AppBar (height: 56dp)
  │ │
  │ └─ Body: SingleChildScrollView
  │   │ width: 411dp, height: Infinity
  │   │
  │   └─ Column
  │     └─ Row
  │       └─ Expanded
  │         └─ InkWell
  │           onTap: showTimePicker(
  │             useRootNavigator: true ✅
  │           )
  │
  └─ Overlay Stack (DIALOG LAYER)
    └─ Material Dialog
      └─ TimePicker
        │
        │ Constraints del Navigator RAÍZ:
        │ width: 411dp ✅
        │ height: 866dp ✅ (No infinito)
        │
        │ ✅ ÉXITO: Dialog se renderiza correctamente
        │
        └─ Cierra cuando el usuario selecciona hora
```

---

## ¿Qué hace `useRootNavigator: true`?

```
useRootNavigator: false (POR DEFECTO)
└─ Busca el Navigator MÁS CERCANO
   └─ Si estás en un AlertDialog → usa su Navigator interno
   └─ Si estás en SingleChildScrollView → confusión de constraints
   └─ RESULTADO: ❌ Constraints problemáticas

useRootNavigator: true ✅
└─ Busca el Navigator RAÍZ de la aplicación
   └─ Ese Navigator siempre tiene constraints válidos
   └─ El dialog se renderiza en una capa segura (Overlay)
   └─ RESULTADO: ✅ Sin conflictos de constraints
```

---

## Ejemplo Paso a Paso de Ejecución

### Timeline de lo que ocurre:

**ANTES (Error):**
```
T0: Usuario hace click en "Desde"
    ├─ onTap se dispara
    ├─ showTimePicker() se llama

T5ms: Flutter busca dónde renderizar
    ├─ context local está en SingleChildScrollView
    ├─ Obtiene constraints inválidas

T10ms: TimePicker intenta renderizarse
    ├─ Necesita height específica
    ├─ Recibe height: Infinity
    ├─ **CRASH** ❌

    ERROR EN CONSOLA:
    flutter: BoxConstraints has non-normalized height constraints:
    BoxConstraints(0.0<=w<=411.5, 0.0<=h<=Infinity)
```

**DESPUÉS (Correcto):**
```
T0: Usuario hace click en "Desde"
    ├─ onTap se dispara
    ├─ Future.delayed() espera 50ms

T50ms: showTimePicker() se llama
    ├─ useRootNavigator: true está presente
    ├─ Flutter busca el Navigator RAÍZ

T55ms: Flutter encuentra el Navigator raíz
    ├─ Obtiene constraints válidos (411dp x 866dp)
    ├─ Renderiza TimePicker en Overlay

T60ms: TimePicker aparece en pantalla
    ├─ Usuario selecciona hora (14:30)
    ├─ Presiona OK

T65ms: Dialog cierra
    ├─ Retorna TimeOfDay(hour: 14, minute: 30)
    ├─ setState() actualiza _horaInicio
    ├─ La UI se actualiza

    ✅ ÉXITO: Hora seleccionada correctamente
```

---

## Tabla de Causas y Síntomas

| Causa | Síntoma | Línea Error | Solución |
|-------|---------|-------------|----------|
| SingleChildScrollView | `height is Infinity` | media.dart | `useRootNavigator: true` |
| AlertDialog | `BoxConstraints` | dialog.dart | `useRootNavigator: true` + delay |
| SizedBox(height: ∞) | `height=Infinity` | rendering.dart | Usar altura definida |
| Column sin constraintsSize | `height is NaN` | sliver.dart | `mainAxisSize.min` |

---

## Checklist Visual: ¿Tienes el problema?

```
¿Ves este error?
└─ BoxConstraints has non-normalized height constraints
   └─ ¿Incluye "height is Infinity"?
      └─ ✅ SÍ: Usa Solución 1 (useRootNavigator: true)
      └─ ❌ NO: Revisa la consola completa

¿El error ocurre al abrir showTimePicker()?
└─ ✅ SÍ: 100% es el problema que documentamos
└─ ❌ NO: Podría ser otra causa diferente

¿El error ocurre al abrir showDatePicker()?
└─ ✅ SÍ: Misma solución, agregá useRootNavigator: true
└─ ❌ NO: Algo diferente

¿El error menciona "time_picker.dart"?
└─ ✅ SÍ: Es exactamente el problema que documentamos
└─ ❌ NO: Error diferente, necesitas otra solución
```

---

## Conclusión Visual

**El problema es de "contextos conflictivos":**

```
❌ PROBLEMA:
Dialog intenta renderi zarse en un contexto que no puede darle
restricciones válidas (SingleChildScrollView con altura infinita)

✅ SOLUCIÓN:
Decirle al dialog que se renderice en el contexto RAÍZ de la app,
donde siempre hay restricciones válidas (pantalla completa)

RESULTADO:
useRootNavigator: true = "Renderiza en la raíz, no en el local"
```
