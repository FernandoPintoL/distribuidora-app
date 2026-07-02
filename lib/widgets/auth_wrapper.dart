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

  Future<void> _checkAuthStatus() async {
    final authProvider = context.read<AuthProvider>();

    try {
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
            body: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
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
                                        color: colorScheme.secondary.withAlpha(
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
                                    color: colorScheme.secondary.withAlpha(
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
                                        color: colorScheme.secondaryContainer,
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        size: 50,
                                        color: colorScheme.secondary,
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
                                            colorScheme.secondary.withAlpha(
                                              (0.6 * 255).toInt(),
                                            ),
                                            colorScheme.secondary,
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
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
