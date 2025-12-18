# 🎨 Vista Previa Visual - Loading Widgets

## Loading Dialog - Vista General

```
╔═════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║                   📱 PANTALLA DEL DISPOSITIVO                        ║
║                                                                       ║
║  ┌───────────────────────────────────────────────────────────────┐  ║
║  │                                                               │  ║
║  │             Fondo Oscuro (semi-transparente)                 │  ║
║  │                                                               │  ║
║  │              ╔════════════════════════╗                       │  ║
║  │              ║       WHITE CARD      ║                       │  ║
║  │              ║   (Card con Sombras)  ║                       │  ║
║  │              ║                        ║                       │  ║
║  │              ║      ┌─────────┐      ║                       │  ║
║  │              ║      │    🔄    │      ║  ← Círculo rotativo  ║  ║
║  │              ║      │ 🏪 LOGO  │      ║  ← Logo en el centro ║  ║
║  │              ║      │    🔄    │      ║  ← Rotación continua ║  ║
║  │              ║      └─────────┘      ║                       │  ║
║  │              ║                        ║                       │  ║
║  │              ║    ●  ●  ●            ║  ← Puntos pulsantes   ║  ║
║  │              ║                        ║                       │  ║
║  │              ║   Cargando...          ║  ← Mensaje principal  ║  ║
║  │              ║   Por favor espera     ║  ← Subtítulo opcional ║  ║
║  │              ║                        ║                       │  ║
║  │              ║                        ║                       │  ║
║  │              ╚════════════════════════╝                       │  ║
║  │                                                               │  ║
║  │             Fondo Oscuro (semi-transparente)                 │  ║
║  │                                                               │  ║
║  └───────────────────────────────────────────────────────────────┘  ║
║                                                                       ║
╚═════════════════════════════════════════════════════════════════════╝
```

## Componentes Individuales

### 1. Logo con Círculo Rotativo

```
Animación continua (3 segundos por vuelta):

  Segundo 0        Segundo 1.5      Segundo 3

    ▲                              ▲
    │                            /   \
   / \                          |     |
  |   |  🏪                    |  🏪  |
  |   |                        |     |
   \ /                          \   /
    │                            │

  Círculo fijo            Logo rotando      Vuelve a posición
  Logo en centro          con el círculo    original
```

### 2. Indicador de Progreso (Puntos Pulsantes)

```
Animación sincronizada:

Ciclo: 1400 milisegundos

0ms:     ●  ○  ○     (Primer punto opaco, otros transparentes)
470ms:   ○  ●  ○     (Segundo punto opaco)
940ms:   ○  ○  ●     (Tercer punto opaco)
1400ms:  ●  ○  ○     (Reinicia)

La opacidad de cada punto va: 0% → 100% → 0%
```

### 3. Barra de Progreso Lineal (En LoadingOverlay)

```
Animación de llenado de barra:

Estado inicial:
┌─────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  (Gris claro)
└─────────────────────────────┘

A mitad:
┌─────────────────────────────┐
│███████████░░░░░░░░░░░░░░░░░│  (Gradiente azul)
└─────────────────────────────┘

Completa:
┌─────────────────────────────┐
│███████████████████████████│  (Completamente azul)
└─────────────────────────────┘

Duración: 1500 milisegundos por ciclo
```

## Animaciones Detalladas

### Entrada del Dialog (Scale)

```
Frame 0       Frame 25      Frame 50      Frame 75      Frame 100
(0ms)         (125ms)       (250ms)       (375ms)       (500ms)

  ░░░░         ░▒▒░░         ▒▒▒▒▒         ████░         ████
  ░░░░         ▒▒▒▒░         ▒███▒         ████░         ████
  ░░░░         ░▒▒░░         ▒▒▒▒▒         ████░         ████

Escala: 0.8   Escala: 0.9   Escala: 0.95  Escala: 0.99  Escala: 1.0
Curva: easeOutBack (rebote suave)
```

## Paleta de Colores

### Colores Utilizados

```
┌─────────────────────────────────────────────────────┐
│ ELEMENTO                    │ COLOR                 │
├─────────────────────────────────────────────────────┤
│ Fondo de Pantalla          │ Transparente (negra)  │
│ Opacidad del Fondo         │ 30% (0.3 alpha)       │
│                             │                       │
│ Card de Loading             │ Blanco (#FFFFFF)      │
│ Sombra de Card              │ Negro con 15% opacidad│
│ Radio de bordes             │ 20 dp                 │
│                             │                       │
│ Círculo Rotativo            │ Azul Claro            │
│ (Border)                    │ Colors.blue[300]      │
│ Grosor del borde            │ 3 dp                  │
│                             │                       │
│ Logo                        │ Original (imagen)     │
│ Tamaño                      │ 65x65 dp              │
│                             │                       │
│ Puntos Pulsantes            │ Azul Oscuro           │
│ (Color base)                │ Colors.blue[600]      │
│ Variación de opacidad       │ 0% a 100%            │
│ Tamaño                      │ 10x10 dp              │
│                             │                       │
│ Barra de Progreso           │ Azul Claro → Azul     │
│ (Gradiente)                 │ Colors.blue[400-600]  │
│                             │                       │
│ Texto Principal             │ Negro Oscuro          │
│ Color                       │ Colors.black87        │
│ Tamaño                      │ 18 dp (Bold)          │
│ Fuente                      │ Poppins (semibold)    │
│                             │                       │
│ Subtítulo                   │ Gris                  │
│ Color                       │ Colors.grey[600]      │
│ Tamaño                      │ 14 dp (Regular)       │
│ Fuente                      │ Poppins               │
│                             │                       │
│ Botón Cancelar              │ Gris claro (outline)  │
│ Borde                       │ Colors.grey[300]      │
│                             │                       │
└─────────────────────────────────────────────────────┘
```

## Respuestas a Diferentes Tamaños

### Pantalla Pequeña (320dp)

```
┌─────────────────────────┐
│ Fondo Oscuro            │
│   ╔═══════════════╗    │
│   ║   [CARD]      ║    │
│   ║   Compacta    ║    │
│   ║   Adaptada    ║    │
│   ╚═══════════════╝    │
│ Fondo Oscuro            │
└─────────────────────────┘
Padding ajustado, card se adapta
```

### Pantalla Normal (375dp)

```
┌──────────────────────────────┐
│ Fondo Oscuro                 │
│   ╔═════════════════════╗   │
│   ║      [CARD]         ║   │
│   ║      Normal         ║   │
│   ║      (Como se ve)   ║   │
│   ╚═════════════════════╝   │
│ Fondo Oscuro                 │
└──────────────────────────────┘
Tamaño estándar
```

### Pantalla Grande (600dp)

```
┌────────────────────────────────────┐
│ Fondo Oscuro                       │
│                                    │
│   ╔════════════════════════╗      │
│   ║        [CARD]          ║      │
│   ║       Ampliada         ║      │
│   ║    Con más espacio     ║      │
│   ║      para leer         ║      │
│   ╚════════════════════════╝      │
│                                    │
│ Fondo Oscuro                       │
└────────────────────────────────────┘
Ajuste automático, maxWidth: 400dp
```

## Estados del Widget

### 1. Estado Inicial (Oculto)

```
[Pantalla Normal del Usuario]
↓
Ningún diálogo visible
Usuario puede interactuar normalmente
```

### 2. Estado de Carga (Visible)

```
[Pantalla Oscurecida]
Diálogo visible en el centro
Fondo no interactivo
Usuario ve animaciones
```

### 3. Estado de Cerrado

```
[Pantalla Normal del Usuario]
Diálogo desaparece con animación inversa
SnackBar aparece (éxito o error)
```

## Flujos de Animación Completos

### Flujo de Login Exitoso

```
┌─────────────────┐
│ 1. Usuario toca │
│    "Iniciar"    │
└─────────────────┘
         ↓
┌──────────────────────┐
│ 2. LoadingUtils.show │
│    Dialog aparece    │
│    (Escala 0.8→1.0)  │
└──────────────────────┘
         ↓ (200ms después)
┌──────────────────────┐
│ 3. Animaciones inicio│
│    - Logo rotando    │
│    - Puntos pulsando │
│    - Barra llenándose│
└──────────────────────┘
         ↓ (cuando completa)
┌──────────────────────┐
│ 4. hideAndShowSuccess│
│    Dialog desaparece │
│    SnackBar aparece  │
│    "Sesión iniciada" │
└──────────────────────┘
         ↓ (2 segundos)
┌──────────────────────┐
│ 5. Navega a /home    │
│    SnackBar desaparece
└──────────────────────┘
```

## Características de Accesibilidad

```
✅ Alto contraste (blanco sobre fondo oscuro)
✅ Texto legible (Poppins, 18dp bold)
✅ Tamaño de tap mínimo respetado
✅ Mensajes claros en español
✅ No depende solo de color (formas distintas)
```

## Performance

```
Animaciones simultáneas:
- Rotación del círculo (Continua)
- Pulsación de puntos (Sincronizada)
- Barra de progreso (Sincronizada)
- Card visible (Estática)

Frame rate: 60 FPS
Consumo de memoria: < 5MB
Duración: Variable según operación
```

---

**Nota:** Las visualizaciones ASCII son aproximadas. El widget real tiene:
- Animaciones suaves (no por pasos)
- Colores graduales y sombras
- Bordes redondeados suavemente
- Anti-aliasing para texto y elementos
