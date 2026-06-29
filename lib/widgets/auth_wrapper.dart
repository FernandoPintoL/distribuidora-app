import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/role_based_router.dart';
import 'realtime_notifications_listener.dart';
import '../screens/screens.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App se va al fondo - auto-guardar carrito
      debugPrint('📱 App paused - auto-saving cart...');
      // _autoGuardarCarrito();
    } else if (state == AppLifecycleState.resumed) {
      // App vuelve al frente
      debugPrint('📱 App resumed');
    }
  }

  Future<void> _autoGuardarCarrito() async {
    if (!mounted) return;

    try {
      final carritoProvider = context.read<CarritoProvider>();
      // Solo auto-guardar si hay items en el carrito
      if (carritoProvider.items.isNotEmpty) {
        await carritoProvider.autoGuardarCarrito();
      }
    } catch (e) {
      debugPrint('❌ Error in auto-save: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = context.read<AuthProvider>();

    try {
      // Try to load user if token exists
      // debugPrint('🔍 Checking auth status...');

      // Use timeout instead of Future.any - this ensures loadUser actually completes
      try {
        await authProvider.loadUser().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // debugPrint('⏱️ Auth load timed out after 10 seconds');
            return false;
          },
        );
      } catch (e) {
        debugPrint('❌ Error during auth load: $e');
      }

      // debugPrint('✅ Auth check completed');

      // Recuperación de carrito desactivada
      // if (mounted && authProvider.isLoggedIn && authProvider.user != null) {
      //   await _inicializarYRecuperarCarrito(authProvider.user!.id);
      // }
    } catch (e) {
      // If there's an error loading user, ensure loading state is cleared
      debugPrint('❌ Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // debugPrint(
        //   '🔄 AuthWrapper build - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}',
        // );

        // Build the appropriate screen
        late Widget screen;

        if (authProvider.isLoading) {
          // debugPrint('⏳ Loading...');
          // ✅ MEJORADO: Usar el loading profesional mejorado en lugar del CircularProgressIndicator
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final colorScheme = theme.colorScheme;

          screen = Scaffold(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withAlpha((0.3 * 255).toInt())
                          : Colors.black.withAlpha((0.15 * 255).toInt()),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ MEJORADO: Logo cuadrado con bordes curvos (no circular)
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Borde giratorio cuadrado con bordes redondeados
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(seconds: 3),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 2 * 3.141592653589793,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: colorScheme.primary.withAlpha(
                                        (0.6 * 255).toInt(),
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Logo imagen
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(
                                    (0.2 * 255).toInt(),
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/icons/icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: colorScheme.primaryContainer,
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag,
                                      size: 50,
                                      color: colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Barra de progreso
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1600),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 180,
                            height: 8,
                            child: Container(
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary.withAlpha(
                                            (0.6 * 255).toInt(),
                                          ),
                                          colorScheme.primary,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    // Mensaje
                    Text(
                      'Cargando aplicación...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor espera...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (authProvider.isLoggedIn) {
          // Use RoleBasedRouter to determine appropriate home screen
          final user = authProvider.user;
          final homeScreen = RoleBasedRouter.getHomeScreen(user);

          /* debugPrint(
            '🏠 Navegando a ${homeScreen.runtimeType} (rol: ${RoleBasedRouter.getRoleDescription(user)})',
          ); */

          // Wrap with RealtimeNotificationsListener for WebSocket notifications
          screen = RealtimeNotificationsListener(child: homeScreen);
        } else {
          /* debugPrint('🔐 Navegando a LoginScreen'); */
          screen = const LoginScreen();
        }

        // Wrap with Material and ensure it renders
        return Scaffold(body: screen);
      },
    );
  }
}
