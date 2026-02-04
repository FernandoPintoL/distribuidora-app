import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/role_based_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'providers/theme_provider.dart';
import 'providers/estados_provider.dart';
import 'providers/visita_provider.dart';
import 'screens/screens.dart';
import 'screens/carrito/carrito_abandonado_list_screen.dart';
import 'screens/cliente/mis_direcciones_screen.dart';
import 'screens/cliente/direccion_form_screen.dart';
import 'screens/chofer/iniciar_ruta_screen.dart';
import 'screens/ventas/mis_ventas_screen.dart';
import 'screens/visitas/orden_del_dia_screen.dart';
import 'screens/cliente/credito_cliente_screen.dart';
import 'widgets/realtime_notifications_listener.dart';
import 'config/app_themes.dart';
import 'services/local_notification_service.dart';
import 'services/background_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🌍 App starting...');

  // Initialize SharedPreferences BEFORE any service that uses it
  try {
    await SharedPreferences.getInstance();
    // debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('⚠️ Error initializing SharedPreferences: $e');
  }

  // Load environment variables before initializing services/UI
  await dotenv.load(fileName: ".env");
  // debugPrint('✅ .env loaded');

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize notification service
  final notificationService = LocalNotificationService();
  await notificationService.initialize();
  debugPrint('✅ LocalNotificationService initialized');

  // Print service status for debugging
  await notificationService.printServiceStatus();

  // Initialize background notification service (para polling periódico)
  await BackgroundNotificationService.initialize();
  debugPrint('✅ BackgroundNotificationService initialized');

  runApp(
    riverpod.ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => ClientProvider()),
          ChangeNotifierProvider(create: (_) => CarritoProvider()),
          ChangeNotifierProvider(create: (_) => PedidoProvider()),
          ChangeNotifierProvider(create: (_) => VentasProvider()),
          ChangeNotifierProvider(create: (_) => TrackingProvider()),
          ChangeNotifierProvider(create: (_) => EntregaProvider()),
          ChangeNotifierProvider(create: (_) => EntregaEstadosProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => EstadosProvider()),
          ChangeNotifierProvider(create: (_) => VisitaProvider()),
          ChangeNotifierProvider(create: (_) => ClienteCreditoProvider()),
          ChangeNotifierProvider(create: (_) => CajaProvider()),
          ChangeNotifierProvider(create: (_) => GastoProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Distribuidora Paucara',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          // Add localization delegates to support Material date/time pickers
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), // Spanish - Spain
            Locale('es', ''), // Spanish - Default
            Locale('en', ''), // English - Default
          ],
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/home-cliente': (context) => const HomeClienteScreen(),
            '/home-chofer': (context) => const HomeChoferScreen(),
            '/products': (context) => const ProductListScreen(),
            '/clients': (context) => const ClientListScreen(),
            '/carrito': (context) => const CarritoScreen(),
            '/carrito-abandonados': (context) =>
                const CarritoAbandonadoListScreen(),
            '/tipo-entrega-seleccion': (context) =>
                const TipoEntregaSeleccionScreen(),
            '/direccion-entrega-seleccion': (context) =>
                const DireccionEntregaSeleccionScreen(),
            '/mis-pedidos': (context) => const PedidosHistorialScreen(),
            '/orden-del-dia': (context) => const OrdenDelDiaScreen(),
            '/mis-ventas': (context) => const MisVentasScreen(),
            '/mis-direcciones': (context) => const MisDireccionesScreen(),
            '/notifications': (context) => const NotificationsScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle routes with arguments
            switch (settings.name) {
              case '/client-form':
                final client = settings.arguments as Client?;
                return MaterialPageRoute(
                  builder: (context) => ClientFormScreen(client: client),
                );

              case '/direccion-form':
                final direccion = settings.arguments as ClientAddress?;
                return MaterialPageRoute(
                  builder: (context) =>
                      DireccionFormScreen(direccion: direccion),
                );

              case '/fecha-hora-entrega':
                // La dirección puede ser null para PICKUP, o ClientAddress para DELIVERY
                final direccion = settings.arguments as ClientAddress?;
                return MaterialPageRoute(
                  builder: (context) =>
                      FechaHoraEntregaScreen(direccion: direccion),
                );

              case '/resumen-pedido':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: Parámetros no encontrados'),
                      ),
                    ),
                  );
                }

                // Extraer tipoEntrega (requerido)
                final tipoEntrega =
                    args['tipoEntrega'] as String? ?? 'DELIVERY';

                return MaterialPageRoute(
                  builder: (context) => ResumenPedidoScreen(
                    tipoEntrega: tipoEntrega,
                    direccion:
                        args['direccion']
                            as ClientAddress?, // Nullable para PICKUP
                    fechaProgramada: args['fechaProgramada'] as DateTime?,
                    horaInicio: args['horaInicio'] as TimeOfDay?,
                    horaFin: args['horaFin'] as TimeOfDay?,
                    observaciones: args['observaciones'] as String?,
                  ),
                );

              case '/pedido-creado':
                // ✅ NUEVO: Manejar argumentos como Map o Pedido directo (compatibilidad)
                Pedido? pedido;
                bool esActualizacion = false;

                if (settings.arguments is Map<String, dynamic>) {
                  final args = settings.arguments as Map<String, dynamic>;
                  pedido = args['pedido'] as Pedido?;
                  esActualizacion = args['esActualizacion'] as bool? ?? false;
                } else if (settings.arguments is Pedido) {
                  pedido = settings.arguments as Pedido?;
                }

                if (pedido == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(child: Text('Error: Pedido no encontrado')),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => PedidoCreadoScreen(
                    pedido: pedido!,  // ✅ Usar ! para indicar que no es null
                    esActualizacion: esActualizacion,
                  ),
                );

              case '/pedido-detalle':
                final pedidoId = settings.arguments as int?;
                if (pedidoId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de pedido no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => PedidoDetalleScreen(pedidoId: pedidoId),
                );

              // ✅ NUEVO: Ruta para detalles de VENTA (no proforma)
              case '/venta-detalle':
                final ventaId = settings.arguments as int?;
                if (ventaId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de venta no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => VentaDetalleScreen(ventaId: ventaId),
                );

              case '/pedido-tracking':
                final pedido = settings.arguments as Pedido?;
                if (pedido == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(child: Text('Error: Pedido no encontrado')),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => PedidoTrackingScreen(pedido: pedido),
                );

              case '/chofer/entrega-detalle':
                final entregaId = settings.arguments as int?;
                if (entregaId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de entrega no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) =>
                      EntregaDetalleScreen(entregaId: entregaId),
                );

              case '/chofer/confirmar-entrega':
                // Manejar tanto argumentos antiguos (int) como nuevos (Map)
                int? entregaId;
                int? ventaId;

                if (settings.arguments is Map<String, dynamic>) {
                  // Nuevos argumentos: diccionario con entrega_id y venta_id
                  final args = settings.arguments as Map<String, dynamic>;
                  entregaId = args['entrega_id'] as int?;
                  ventaId = args['venta_id'] as int?;
                } else if (settings.arguments is int) {
                  // Argumentos antiguos: solo int (entrega_id)
                  entregaId = settings.arguments as int?;
                }

                if (entregaId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de entrega no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => ConfirmacionEntregaScreen(
                    entregaId: entregaId!,
                    ventaId: ventaId,
                  ),
                );

              case '/chofer/iniciar-ruta':
                final entregaId = settings.arguments as int?;
                if (entregaId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de entrega no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => IniciarRutaScreen(entregaId: entregaId),
                );

              case '/credito':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: Parámetros no encontrados'),
                      ),
                    ),
                  );
                }
                final clienteId = args['clienteId'] as int?;
                final clienteNombre = args['clienteNombre'] as String?;
                if (clienteId == null || clienteNombre == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: Cliente no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => CreditoClienteScreen(
                    clienteId: clienteId,
                    clienteNombre: clienteNombre,
                  ),
                );

              default:
                return null;
            }
          },
        );
      },
    );
  }
}

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
      debugPrint('🔍 Checking auth status...');

      // Use timeout instead of Future.any - this ensures loadUser actually completes
      try {
        await authProvider.loadUser().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏱️ Auth load timed out after 10 seconds');
            return false;
          },
        );
      } catch (e) {
        debugPrint('❌ Error during auth load: $e');
      }

      debugPrint('✅ Auth check completed');

      // Recuperación de carrito desactivada
      // if (mounted && authProvider.isLoggedIn && authProvider.user != null) {
      //   await _inicializarYRecuperarCarrito(authProvider.user!.id);
      // }
    } catch (e) {
      // If there's an error loading user, ensure loading state is cleared
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> _inicializarYRecuperarCarrito(int usuarioId) async {
    if (!mounted) return;

    try {
      final carritoProvider = context.read<CarritoProvider>();

      // Inicializar usuario en el provider
      carritoProvider.inicializarUsuario(usuarioId);
      debugPrint('✅ CarritoProvider initialized with user ID: $usuarioId');

      // Intentar recuperar carrito guardado
      final carritoRecuperado = await carritoProvider.recuperarCarrito();

      if (carritoRecuperado && mounted) {
        // Mostrar diálogo de recuperación
        _mostrarDialogoRecuperacionCarrito();
      }
    } catch (e) {
      debugPrint('❌ Error recovering cart: $e');
    }
  }

  void _mostrarDialogoRecuperacionCarrito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Carrito Guardado'),
        content: const Text(
          '¿Deseas recuperar tu carrito anterior con los productos que dejaste?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Limpiar carrito y cerrar diálogo
              context.read<CarritoProvider>().limpiarCarrito();
              Navigator.of(context).pop();
              debugPrint('❌ Carrito descartado');
            },
            child: const Text('No, empezar nuevo'),
          ),
          ElevatedButton(
            onPressed: () {
              // Carrito ya está recuperado, solo cerrar diálogo
              Navigator.of(context).pop();
              debugPrint('✅ Carrito recuperado y disponible');

              // Mostrar snackbar de confirmación
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Carrito restaurado correctamente'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Sí, recuperar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint(
          '🔄 AuthWrapper build - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}',
        );

        // Build the appropriate screen
        late Widget screen;

        if (authProvider.isLoading) {
          debugPrint('⏳ Loading...');
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
                  color: isDark ? theme.cardColor : Colors.white,
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

          debugPrint(
            '🏠 Navegando a ${homeScreen.runtimeType} (rol: ${RoleBasedRouter.getRoleDescription(user)})',
          );

          // Wrap with RealtimeNotificationsListener for WebSocket notifications
          screen = RealtimeNotificationsListener(child: homeScreen);
        } else {
          debugPrint('🔐 Navegando a LoginScreen');
          screen = const LoginScreen();
        }

        // Wrap with Material and ensure it renders
        return Scaffold(body: screen);
      },
    );
  }
}
