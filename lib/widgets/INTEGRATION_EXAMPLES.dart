// EJEMPLOS DE INTEGRACIÓN DE LOADING WIDGETS
// Este archivo contiene ejemplos de cómo integrar los widgets de carga
// en diferentes pantallas de la aplicación

// ============================================================================
// EJEMPLO 1: Login Screen (con LoadingUtils)
// ============================================================================
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'loading_utils.dart';
import '../providers/auth_provider.dart';

class LoginScreenWithLoading extends StatefulWidget {
  const LoginScreenWithLoading({super.key});

  @override
  State<LoginScreenWithLoading> createState() => _LoginScreenWithLoadingState();
}

class _LoginScreenWithLoadingState extends State<LoginScreenWithLoading> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Mostrar loading
        LoadingUtils.showLogin(context);

        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.login(
          _loginController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          // Éxito - mostrar mensaje y navegar
          LoadingUtils.hideAndShowSuccess(context, 'Sesión iniciada correctamente');

          // Opcional: esperar un poco antes de navegar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _loginController),
              TextFormField(controller: _passwordController),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

// ============================================================================
// EJEMPLO 2: Generar Proforma (con LoadingUtils)
// ============================================================================
/*
class ProformaScreenExample {
  Future<void> generarProforma(
    BuildContext context,
    Map<String, dynamic> proformaData,
  ) async {
    try {
      // Mostrar loading específico para proforma
      LoadingUtils.showProforma(context);

      // Simular petición a API
      final response = await proformaService.generate(proformaData);

      if (mounted) {
        // Éxito
        LoadingUtils.hideAndShowSuccess(
          context,
          'Proforma generada exitosamente',
        );

        // Navegar a pantalla de éxito o detalle de proforma
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushNamed('/proforma-detalle', arguments: response);
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingUtils.hideAndShowError(
          context,
          'Error al generar proforma: ${e.toString()}',
        );
      }
    }
  }
}
*/

// ============================================================================
// EJEMPLO 3: Carga Masiva de Productos (con LoadingUtils)
// ============================================================================
/*
class BulkLoadExampleWithProgress {
  Future<void> cargarProductosMasivos(
    BuildContext context,
    File csvFile,
  ) async {
    try {
      // Mostrar loading para carga masiva
      LoadingUtils.showBulkLoad(context);

      // Realizar carga
      final result = await productService.bulkLoadFromCSV(csvFile);

      if (mounted) {
        // Mostrar resumen de carga
        LoadingUtils.hideAndShowSuccess(
          context,
          'Se cargaron ${result.successCount} productos',
        );
      }
    } on BulkLoadException catch (e) {
      if (mounted) {
        LoadingUtils.hideAndShowError(
          context,
          'Error en carga masiva: ${e.message}\n${e.failedItems.length} errores',
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
      }
    }
  }
}
*/

// ============================================================================
// EJEMPLO 4: Crear Pedido (con mensaje personalizado)
// ============================================================================
/*
class PedidoScreenExample {
  Future<void> crearPedido(
    BuildContext context,
    Map<String, dynamic> pedidoData,
  ) async {
    try {
      // Loading personalizado con subtítulo
      LoadingUtils.show(
        context,
        'Procesando pedido',
        subtitle: 'Validando datos y enviando al servidor...',
        dismissible: false, // No permitir cerrar
      );

      final pedido = await pedidoService.create(pedidoData);

      if (mounted) {
        LoadingUtils.hideAndShowSuccess(
          context,
          'Pedido #${pedido.id} creado exitosamente',
        );

        // Navegar con delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushNamed('/pedido-detalle', arguments: pedido.id);
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
      }
    }
  }
}
*/

// ============================================================================
// EJEMPLO 5: Con Biometría (modificación de _loginWithBiometrics)
// ============================================================================
/*
void _loginWithBiometrics() async {
  try {
    // Usar LoadingUtils en lugar de SnackBar
    LoadingUtils.show(
      context,
      'Autenticando',
      subtitle: 'Verifica tu identidad biométrica',
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithBiometrics();

    if (mounted) {
      if (success) {
        LoadingUtils.hideAndShowSuccess(context, 'Autenticación exitosa');

        // Navegar al home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (authProvider.errorMessage != null) {
          LoadingUtils.hideAndShowError(
            context,
            authProvider.errorMessage!,
          );
        }
      }
    }
  } catch (e) {
    if (mounted) {
      LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
    }
  }
}
*/

// ============================================================================
// EJEMPLO 6: Usando LoadingOverlay (alternativa)
// ============================================================================
/*
import 'loading_overlay.dart';

class MyScreenWithOverlay extends StatefulWidget {
  const MyScreenWithOverlay({super.key});

  @override
  State<MyScreenWithOverlay> createState() => _MyScreenWithOverlayState();
}

class _MyScreenWithOverlayState extends State<MyScreenWithOverlay> {
  Future<void> _someAsyncOperation() async {
    try {
      LoadingOverlay.show(context, message: 'Procesando...');

      await someService.doSomething();

      LoadingOverlay.hide();
    } catch (e) {
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi Pantalla')),
        body: Center(
          child: ElevatedButton(
            onPressed: _someAsyncOperation,
            child: const Text('Presiona'),
          ),
        ),
      ),
    );
  }
}
*/

// ============================================================================
// EJEMPLO 7: Patrón completo para cualquier operación
// ============================================================================
/*
Future<void> _operacionGenerica(
  BuildContext context,
  String loadingMessage,
  String successMessage,
  Future<T> Function() operation,
) async {
  try {
    LoadingUtils.show(context, loadingMessage);

    final result = await operation();

    if (context.mounted) {
      LoadingUtils.hideAndShowSuccess(context, successMessage);
    }

    return result;
  } catch (e) {
    if (context.mounted) {
      LoadingUtils.hideAndShowError(context, 'Error: ${e.toString()}');
    }
  }
}

// Uso:
await _operacionGenerica(
  context,
  'Actualizando perfil...',
  'Perfil actualizado correctamente',
  () => userService.updateProfile(newData),
);
*/

// ============================================================================
// NOTAS IMPORTANTES:
// ============================================================================
// 1. SIEMPRE usar if (mounted) o if (context.mounted) antes de operaciones
//    en el contexto después de operaciones asincrónicas
//
// 2. LoadingUtils.hide() es seguro llamarlo aunque no haya diálogo abierto
//
// 3. Los diálogos son NO-DISMISSIBLES por defecto para evitar que usuarios
//    cancelen operaciones críticas. Usa dismissible: true solo cuando sea seguro
//
// 4. Use LoadingUtils.show() con auto-close para operaciones que siempre
//    completarán exitosamente
//
// 5. Manejo de errores:
//    - Errores esperados: hideAndShowError()
//    - Errores inesperados: show custom dialog o snackbar
//
// 6. Para operaciones muy largas, considere agregar subtítulo con info de progreso
