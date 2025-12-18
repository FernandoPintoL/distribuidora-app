# 🎯 Sistema de Loading Widgets - Distribuidora Paucara

Hemos creado un sistema completo de widgets de carga moderno, reutilizable y fácil de usar para tu aplicación Flutter.

## 📦 Archivos Creados

```
lib/widgets/
├── loading_dialog.dart          # Diálogo de carga moderno
├── loading_overlay.dart         # Overlay de carga (alternativa)
├── loading_utils.dart           # Funciones helper (RECOMENDADO)
├── LOADING_GUIDE.md            # Guía completa de uso
├── INTEGRATION_EXAMPLES.dart   # Ejemplos de integración
└── LOADING_WIDGETS_README.md   # Este archivo
```

## 🚀 Inicio Rápido

### Opción 1: Usando LoadingUtils (RECOMENDADO)

La forma más simple y moderna de usar los loading widgets:

```dart
import 'package:distribuidora/widgets/loading_utils.dart';

// Para Login
Future<void> _login() async {
  try {
    LoadingUtils.showLogin(context);
    await authProvider.login(email, password);
    LoadingUtils.hideAndShowSuccess(context, 'Bienvenido');
  } catch (e) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}

// Para Proforma
LoadingUtils.showProforma(context);

// Para Carga Masiva
LoadingUtils.showBulkLoad(context);

// Personalizado
LoadingUtils.show(context, 'Mi mensaje personalizado', subtitle: 'Detalle');
LoadingUtils.hide(context);
```

### Opción 2: Usando LoadingDialog Directamente

Para más control:

```dart
import 'package:distribuidora/widgets/loading_dialog.dart';

showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => const LoadingDialog(
    message: 'Procesando...',
    subtitle: 'Por favor espera',
  ),
);
```

## ✨ Características

### Diseño Moderno
- ✅ Card con sombras suaves
- ✅ Animación de entrada (scale con bounce)
- ✅ Logo que rota con círculo animado
- ✅ Indicador de progreso con puntos pulsantes
- ✅ Colores acordes al tema Material 3

### Fácil de Usar
- ✅ API simple: `show()`, `hide()`, `hideAndShowSuccess()`, `hideAndShowError()`
- ✅ Mensajes y subtítulos personalizables
- ✅ Métodos específicos: `showLogin()`, `showProforma()`, `showBulkLoad()`
- ✅ Manejo seguro del contexto

### Reutilizable
- ✅ Funciona en cualquier pantalla
- ✅ No requiere wrappear el árbol de widgets
- ✅ Compatible con Provider, Riverpod y otros estado managers
- ✅ Sin dependencias externas

## 📋 Casos de Uso

### 1. Login
```dart
LoadingUtils.showLogin(context);
await authProvider.login(email, password);
LoadingUtils.hideAndShowSuccess(context, 'Sesión iniciada');
```

### 2. Generar Proforma
```dart
LoadingUtils.showProforma(context);
final proforma = await proformaService.generate(data);
LoadingUtils.hideAndShowSuccess(context, 'Proforma generada');
```

### 3. Carga Masiva
```dart
LoadingUtils.showBulkLoad(context);
await productService.bulkLoad(file);
LoadingUtils.hideAndShowSuccess(context, 'Datos cargados');
```

### 4. Operación Genérica
```dart
LoadingUtils.show(
  context,
  'Procesando pedido',
  subtitle: 'Validando datos...',
  dismissible: true, // Permitir cancelar
);
// ... operación
LoadingUtils.hide(context);
```

## 🎨 Personalización

### Cambiar Color Principal
Edita `loading_dialog.dart` y `loading_overlay.dart`:
```dart
// Busca: Colors.blue[600]
// Reemplaza con tu color, por ejemplo:
Colors.green[600]
Colors.red[600]
Theme.of(context).primaryColor
```

### Cambiar Tamaño del Logo
En `loading_dialog.dart`:
```dart
// Busca:
Image.asset(
  'assets/icons/icon.png',
  width: 65,   // ← Cambiar este valor
  height: 65,  // ← Cambiar este valor
)
```

### Cambiar Animaciones
- **Velocidad de rotación**: Busca `duration: const Duration(seconds: 3)`
- **Velocidad de entrada**: Busca `duration: const Duration(milliseconds: 500)`
- **Velocidad de puntos**: Busca `duration: const Duration(milliseconds: 1400)`

## 🔧 Integración Paso a Paso

### Paso 1: Actualizar login_screen.dart

Reemplaza el método `_login()`:

```dart
import 'package:distribuidora/widgets/loading_utils.dart';

void _login() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      LoadingUtils.showLogin(context);

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _loginController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        LoadingUtils.hideAndShowSuccess(context, 'Sesión iniciada');

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
      }
    }
  }
}
```

También actualiza `_loginWithBiometrics()`:

```dart
void _loginWithBiometrics() async {
  try {
    LoadingUtils.show(
      context,
      'Autenticando',
      subtitle: 'Verifica tu identidad',
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithBiometrics();

    if (mounted) {
      if (success) {
        LoadingUtils.hideAndShowSuccess(context, 'Autenticación exitosa');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (authProvider.errorMessage != null) {
        LoadingUtils.hideAndShowError(context, authProvider.errorMessage!);
      }
    }
  } catch (e) {
    if (mounted) {
      LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
    }
  }
}
```

### Paso 2: Implementar en Otros Servicios

Para cualquier servicio que necesite loading:

```dart
// En pedido_service.dart, proforma_service.dart, etc.
Future<T> operacionLarga() async {
  try {
    LoadingUtils.show(context, 'Procesando...');
    final result = await _doSomething();
    LoadingUtils.hideAndShowSuccess(context, 'Completado');
    return result;
  } catch (e) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}
```

## 🛡️ Manejo de Errores

### Pattern Seguro
```dart
try {
  LoadingUtils.showLogin(context);
  await operation();

  if (context.mounted) {
    LoadingUtils.hideAndShowSuccess(context, 'Éxito');
  }
} catch (e) {
  if (context.mounted) {
    LoadingUtils.hideAndShowError(context, 'Error: $e');
  }
}
```

### Puntos Clave
1. **Siempre verifica `context.mounted`** después de operaciones async
2. **LoadingUtils.hide()** es seguro llamar aunque no haya diálogo
3. Los diálogos son **non-dismissible por defecto**
4. Usa `dismissible: true` solo cuando sea seguro cancelar

## 📱 Ejemplos Visuales

### LoadingDialog Estándar
```
┌─────────────────────┐
│                     │
│     🔄 (rotando)    │  ← Logo con círculo rotativo
│                     │
│  ●  ●  ●           │  ← Indicador de progreso
│                     │
│  Cargando...        │  ← Mensaje principal
│  Por favor espera   │  ← Subtítulo (opcional)
│                     │
│   [ Cancelar ]      │  ← Botón (si dismissible=true)
│                     │
└─────────────────────┘
```

## 🎯 Checklist de Integración

- [ ] Importar `LoadingUtils` en las pantallas necesarias
- [ ] Reemplazar loading methods con `LoadingUtils.show*`
- [ ] Agregar `if (context.mounted)` después de operaciones async
- [ ] Probar en diferentes resoluciones de pantalla
- [ ] Validar que los mensajes son claros y útiles
- [ ] Considerar agregar subtítulos para operaciones largas
- [ ] Personalizar colores si deseas (opcional)

## 🐛 Troubleshooting

### El diálogo no se muestra
- Verifica que `barrierDismissible` sea `false` para diálogos bloqueantes
- Asegúrate que `context` es válido

### "Navigator operation requested with a context that does not include a Navigator"
- Usa `if (context.mounted)` después de operaciones async
- Verifica que el context no ha sido destruido

### Diálogo no cierra
- Usa `LoadingUtils.hide(context)` explícitamente
- Verifica que no hay múltiples diálogos abiertos

## 📚 Documentación Adicional

- `LOADING_GUIDE.md` - Guía completa y detallada
- `INTEGRATION_EXAMPLES.dart` - Ejemplos de código comentados

## 🔗 Uso con Provider

```dart
// Con context.read
final authProvider = context.read<AuthProvider>();
await authProvider.login(email, password);

// Con Consumer
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return ElevatedButton(
      onPressed: () async {
        LoadingUtils.showLogin(context);
        await authProvider.login(email, password);
        // ...
      },
      child: const Text('Login'),
    );
  },
)
```

## 💡 Tips y Mejores Prácticas

1. **Usa mensajes claros y concisos**
   ```dart
   // ✅ Bien
   LoadingUtils.show(context, 'Iniciando sesión...');

   // ❌ Evitar
   LoadingUtils.show(context, 'Cargando datos del sistema...');
   ```

2. **Agrega subtítulos para operaciones largas**
   ```dart
   LoadingUtils.show(
     context,
     'Procesando...',
     subtitle: 'Esto puede tomar 30 segundos',
   );
   ```

3. **Usa métodos específicos cuando sea posible**
   ```dart
   // ✅ Mejor (más descriptivo)
   LoadingUtils.showLogin(context);

   // En lugar de:
   LoadingUtils.show(context, 'Cargando...');
   ```

4. **Maneja errores de forma amigable**
   ```dart
   // ✅ Bien
   LoadingUtils.hideAndShowError(
     context,
     'Error de conexión. Verifica tu internet',
   );
   ```

## 🎓 Próximos Pasos

1. Integrar en `login_screen.dart`
2. Integrar en servicios de pedidos y proformas
3. Considerar agregar: progreso percentual para cargas masivas
4. Considerar agregar: animaciones más personalizadas

---

**Creado:** Diciembre 2024
**Versión:** 1.0.0
**Compatible con:** Flutter 3.9.0+, Material 3

¡Listo para usar! 🚀
