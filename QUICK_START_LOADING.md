# ⚡ Quick Start - Loading Widgets

## 5 Pasos para Empezar

### 1️⃣ Importar en tu Pantalla

```dart
import 'package:distribuidora/widgets/loading_utils.dart';
```

### 2️⃣ Envolver tu Operación

```dart
try {
  LoadingUtils.showLogin(context);  // O showProforma, showBulkLoad, etc.

  // Tu operación aquí
  await authProvider.login(email, password);

  // Éxito
  LoadingUtils.hideAndShowSuccess(context, 'Mensaje de éxito');
} catch (e) {
  // Error
  LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
}
```

### 3️⃣ Verificar Context Mounted

```dart
// Siempre usa esto después de operaciones async
if (context.mounted) {
  LoadingUtils.hideAndShowSuccess(context, 'Éxito');
}
```

### 4️⃣ Probar

Ejecuta tu app y prueba la funcionalidad. Deberías ver:
- Card blanca en el centro
- Logo rotando
- Puntos animados
- Tu mensaje personalizado

### 5️⃣ Personalizar (Opcional)

```dart
// Mensaje y subtítulo
LoadingUtils.show(
  context,
  'Mi Operación',
  subtitle: 'Esto puede tomar unos segundos',
);

// Con opción de cancelar
LoadingUtils.show(
  context,
  'Procesando...',
  dismissible: true,  // ← Permite cerrar
);

// Auto cerrar después de tiempo
showDialog(
  context: context,
  builder: (context) => const LoadingDialog(
    message: 'Éxito',
    autoCloseDuration: Duration(seconds: 2),
  ),
);
```

## Métodos Disponibles

```dart
LoadingUtils.showLogin(context);          // Para login
LoadingUtils.showProforma(context);       // Para proforma
LoadingUtils.showBulkLoad(context);       // Para carga masiva
LoadingUtils.show(context, 'mensaje');    // Personalizado
LoadingUtils.hide(context);                // Cerrar
LoadingUtils.hideAndShowSuccess(context, 'mensaje');
LoadingUtils.hideAndShowError(context, 'mensaje');
```

## Casos de Uso Rápidos

### Login
```dart
void _login() async {
  try {
    LoadingUtils.showLogin(context);
    await authProvider.login(email, password);
    LoadingUtils.hideAndShowSuccess(context, 'Bienvenido');
  } catch (e) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}
```

### Crear Pedido
```dart
void _crearPedido() async {
  try {
    LoadingUtils.show(context, 'Creando pedido...');
    await pedidoService.create(data);
    LoadingUtils.hideAndShowSuccess(context, 'Pedido creado');
  } catch (e) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}
```

### Generar Proforma
```dart
void _generarProforma() async {
  try {
    LoadingUtils.showProforma(context);
    await proformaService.generate(data);
    LoadingUtils.hideAndShowSuccess(context, 'Proforma generada');
  } catch (e) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}
```

## Lo Que Obtienes

✅ Dialog moderno con:
- Logo que rota
- Círculo animado
- Puntos pulsantes
- Mensajes personalizables
- Subtítulos opcionales
- Botón de cancelar (opcional)

✅ Animaciones suaves:
- Entrada con bounce
- Rotación continua
- Pulsación de puntos

✅ Manejo seguro:
- Comprobación de context.mounted
- Manejo de errores
- Mensajes amigables

## Archivos Importantes

| Archivo | Uso |
|---------|-----|
| `loading_utils.dart` | **USAR ESTE** - API simple |
| `loading_dialog.dart` | Widget principal |
| `loading_overlay.dart` | Alternativa (menos recomendado) |
| `LOADING_GUIDE.md` | Documentación completa |
| `INTEGRATION_EXAMPLES.dart` | Ejemplos de código |

## Cosas a NO Hacer

❌ No olvides `if (context.mounted)`
```dart
// MAL:
LoadingUtils.hideAndShowSuccess(context, 'Éxito'); // Puede fallar

// BIEN:
if (context.mounted) {
  LoadingUtils.hideAndShowSuccess(context, 'Éxito');
}
```

❌ No abras múltiples diálogos sin cerrar
```dart
// MAL:
LoadingUtils.show(context, '1');
LoadingUtils.show(context, '2');

// BIEN:
LoadingUtils.hide(context);
LoadingUtils.show(context, '2');
```

❌ No uses nombres genéricos
```dart
// MAL:
LoadingUtils.show(context, 'Cargando...');

// MEJOR:
LoadingUtils.showLogin(context);
LoadingUtils.showProforma(context);
```

## Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| No se ve el dialog | Verificar que context es válido |
| Dialog no cierra | Usar `LoadingUtils.hide()` |
| Error de Navigator | Usar `if (context.mounted)` |
| Múltiples diálogos | Cerrar el anterior antes de abrir nuevo |
| Icono no se ve | Verificar que `assets/icons/icon.png` existe |

## Siguiente Paso

Lee `LOADING_GUIDE.md` para documentación completa y ejemplos avanzados.

---

**¡Listo para usar!** Copia y pega el código, importa `loading_utils.dart` y listo. 🚀
