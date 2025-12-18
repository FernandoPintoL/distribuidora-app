# Guía de Uso - Loading Screen Moderno

Este paquete proporciona varios componentes para mostrar pantallas de carga modernas y reutilizables.

## Componentes Disponibles

### 1. LoadingDialog (Recomendado)
Un diálogo de carga moderno que se puede usar en cualquier contexto.

**Importar:**
```dart
import 'package:distribuidora/widgets/loading_dialog.dart';
```

**Uso Básico:**
```dart
// Mostrar diálogo simple
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => const LoadingDialog(message: 'Cargando...'),
);
```

### 2. LoadingUtils (Forma Recomendada)
Proporciona funciones helper para manejar diálogos de carga de forma sencilla.

**Importar:**
```dart
import 'package:distribuidora/widgets/loading_utils.dart';
```

**Ejemplos de Uso:**

#### Para Login
```dart
Future<void> _login() async {
  try {
    LoadingUtils.showLogin(context);

    // Realizar petición
    await authProvider.login(email, password);

    // Éxito
    if (context.mounted) {
      LoadingUtils.hideAndShowSuccess(context, 'Sesión iniciada');
    }
  } catch (e) {
    if (context.mounted) {
      LoadingUtils.hideAndShowError(context, 'Error al iniciar sesión');
    }
  }
}
```

#### Para Proforma
```dart
Future<void> _generarProforma() async {
  try {
    LoadingUtils.showProforma(context);

    // Generar proforma
    await proformaService.generate(data);

    // Éxito
    if (context.mounted) {
      LoadingUtils.hideAndShowSuccess(context, 'Proforma generada');
    }
  } catch (e) {
    if (context.mounted) {
      LoadingUtils.hideAndShowError(context, 'Error al generar proforma');
    }
  }
}
```

#### Para Carga Masiva
```dart
Future<void> _cargaMasiva() async {
  try {
    LoadingUtils.showBulkLoad(context);

    // Cargar datos
    await productService.bulkLoad(file);

    // Éxito
    if (context.mounted) {
      LoadingUtils.hideAndShowSuccess(context, 'Datos cargados correctamente');
    }
  } catch (e) {
    if (context.mounted) {
      LoadingUtils.hideAndShowError(context, 'Error en carga de datos');
    }
  }
}
```

#### Mensaje Personalizado
```dart
LoadingUtils.show(
  context,
  'Procesando pedido...',
  subtitle: 'Por favor no cierres la app',
  dismissible: false, // true para permitir cerrar
);

// Cerrar
LoadingUtils.hide(context);
```

### 3. LoadingOverlay
Un overlay que se muestra sobre todo el contenido (menos flexible que LoadingDialog).

**Importar:**
```dart
import 'package:distribuidora/widgets/loading_overlay.dart';
```

**Uso:**
```dart
// En tu widget
@override
Widget build(BuildContext context) {
  return LoadingOverlay(
    child: Scaffold(
      // ... tu contenido
    ),
  );
}

// Para mostrar/ocultar
LoadingOverlay.show(context, message: 'Cargando...');
LoadingOverlay.hide();
```

## Ejemplos Completos

### Ejemplo 1: Login con LoadingUtils
```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    try {
      // Mostrar loading
      LoadingUtils.showLogin(context);

      // Realizar login
      await context.read<AuthProvider>().login(
            emailController.text,
            passwordController.text,
          );

      // Éxito
      if (context.mounted) {
        LoadingUtils.hideAndShowSuccess(context, 'Bienvenido');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingUtils.hideAndShowError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: passwordController),
          ElevatedButton(
            onPressed: _handleLogin,
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }
}
```

### Ejemplo 2: Operación con subtítulo y opción de cancelar
```dart
Future<void> _procesarPedido() async {
  try {
    LoadingUtils.show(
      context,
      'Procesando pedido',
      subtitle: 'Enviando datos al servidor...',
      dismissible: true,
    );

    await pedidoService.create(pedidoData);

    if (context.mounted) {
      LoadingUtils.hideAndShowSuccess(context, 'Pedido creado exitosamente');
    }
  } catch (e) {
    if (context.mounted) {
      LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
    }
  }
}
```

## Características

✅ **Moderno**: Diseño limpio y profesional
✅ **Animaciones**: Transiciones suaves y agradables
✅ **Reutilizable**: Funciona en cualquier contexto
✅ **Personalizable**: Mensajes, subtítulos y opciones
✅ **Responsive**: Se adapta a diferentes tamaños de pantalla
✅ **Temas**: Sigue el tema Material 3 de tu app
✅ **Fácil de usar**: API simple y intuitiva
✅ **Lightweight**: Sin dependencias externas

## Customización

Si deseas personalizar los colores, tamaños o estilos, puedes editar los archivos:
- `loading_dialog.dart` - Diálogo principal
- `loading_overlay.dart` - Overlay
- `loading_utils.dart` - Funciones helper

### Cambiar color principal
En `loading_dialog.dart` y `loading_overlay.dart`, busca `Colors.blue[600]` y cámbialo al color que desees.

### Cambiar tamaño del logo
Busca `width: 65, height: 65` en `loading_dialog.dart` y ajusta según necesidad.

## Integración con AuthProvider

Aquí hay un ejemplo de cómo integrar con tu `AuthProvider`:

```dart
Future<bool> login(String email, String password) async {
  try {
    isLoading = true;
    notifyListeners();

    // Tu lógica de login
    final response = await apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      isLoading = false;
      isLoggedIn = true;
      notifyListeners();
      return true;
    }
  } catch (e) {
    isLoading = false;
    notifyListeners();
    rethrow;
  }
}
```

Luego en tu LoginScreen:

```dart
ElevatedButton(
  onPressed: () async {
    try {
      LoadingUtils.showLogin(context);
      await context.read<AuthProvider>().login(email, password);
      if (context.mounted) {
        LoadingUtils.hideAndShowSuccess(context, 'Bienvenido');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingUtils.hideAndShowError(context, 'Error: $e');
      }
    }
  },
  child: const Text('Iniciar Sesión'),
)
```

## Notas Importantes

1. **Siempre verifica `context.mounted`** antes de hacer operaciones en el contexto después de operaciones asincrónicas
2. **LoadingUtils.hide()** intenta cerrar automáticamente, pero es seguro llamarlo varias veces
3. Los diálogos son no-dismissibles por defecto para evitar que usuarios cancelen operaciones críticas
4. Usa `autoCloseDuration` para auto-cerrar después de cierto tiempo

## Troubleshooting

### El diálogo no se muestra
- Asegúrate que el contexto es válido
- Verifica que `barrierDismissible: false` si quieres un loading "bloqueante"

### Error: "Navigator operation requested with a context that does not include a Navigator"
- Usa `if (context.mounted)` antes de operar con el contexto
- Asegúrate que la operación async completó antes de acceder al contexto
