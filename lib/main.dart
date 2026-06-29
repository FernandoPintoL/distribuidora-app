import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/role_based_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'screens/carrito/carrito_abandonado_list_screen.dart';
import 'screens/cliente/mis_direcciones_screen.dart';
import 'screens/cliente/direccion_form_screen.dart';
import 'widgets/realtime_notifications_listener.dart';
import 'widgets/auth_wrapper.dart';
import 'config/app_themes.dart';
import 'config/app_urls.dart';
import 'services/local_notification_service.dart';
import 'services/background_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint('🌍 App starting...');

  // Initialize SharedPreferences BEFORE any service that uses it
  try {
    await SharedPreferences.getInstance();
    // debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('⚠️ Error initializing SharedPreferences: $e');
  }

  // ✅ FIX: Cargar .env desde assets (funciona en Debug Y Release/Play Store)
  try {
    final envString = await rootBundle.loadString('.env');
    // Parsear manualmente el contenido del .env
    final lines = envString.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim().replaceAll('"', '');
        dotenv.env[key] = value;
      }
    }
    // debugPrint('✅ .env cargado desde assets');
  } catch (e) {
    debugPrint('⚠️ Error cargando .env desde assets: $e');
    // Intenta fallback al método antiguo (solo funciona en debug)
    try {
      await dotenv.load(fileName: ".env");
      // debugPrint('✅ .env cargado desde archivo (fallback)');
    } catch (e2) {
      debugPrint('❌ CRÍTICO: No se pudo cargar .env: $e2');
    }
  }

  // ✅ NUEVO: Inicializar URLs centralizadas
  try {
    AppUrls.initialize();
    // debugPrint('✅ AppUrls inicializadas');
  } catch (e) {
    debugPrint('⚠️ Error inicializando AppUrls: $e');
  }

  // Inicializar Theme Provider
  late ThemeProvider themeProvider;
  try {
    themeProvider = ThemeProvider();
    await themeProvider.init();
    // debugPrint('✅ ThemeProvider inicializado');
  } catch (e) {
    debugPrint(
      '⚠️ Error inicializando ThemeProvider, usando valores por defecto: $e',
    );
    themeProvider = ThemeProvider(); // Usar valores por defecto
  }

  // ✅ CRÍTICO: Solicitar permiso de notificaciones ANTES de inicializar
  try {
    final notificationStatus = await Permission.notification.request();
    // debugPrint('📲 Estado de permiso de notificaciones: $notificationStatus');

    if (notificationStatus.isDenied) {
      debugPrint('⚠️ Permiso de notificaciones denegado por usuario');
    } else if (notificationStatus.isGranted) {
      // debugPrint('✅ Permiso de notificaciones OTORGADO');
    } else if (notificationStatus.isPermanentlyDenied) {
      debugPrint(
        '🚫 Permiso de notificaciones permanentemente denegado (openAppSettings requerido)',
      );
    }
  } catch (e) {
    debugPrint('⚠️ Error solicitando permiso de notificaciones: $e');
  }

  // Inicializar servicio de notificaciones locales
  try {
    final notificationService = LocalNotificationService();
    await notificationService.initialize();
    debugPrint('✅ LocalNotificationService inicializado');

    // Print service status for debugging
    await notificationService.printServiceStatus();
  } catch (e) {
    debugPrint('⚠️ Error inicializando LocalNotificationService: $e');
  }

  // Inicializar background notification service
  try {
    await BackgroundNotificationService.initialize();
    // debugPrint('✅ BackgroundNotificationService inicializado');
  } catch (e) {
    debugPrint('⚠️ Error inicializando BackgroundNotificationService: $e');
  }

  // ✅ SEGURIDAD: Envolver en ErrorBoundary en caso de crash
  runApp(
    riverpod.ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider ?? ThemeProvider(),
          ),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => FiltrosProductoProvider()),
          ChangeNotifierProvider(create: (_) => ClientProvider()),
          ChangeNotifierProvider(create: (_) => CarritoProvider()),
          ChangeNotifierProvider(create: (_) => PedidoProvider()),
          ChangeNotifierProvider(create: (_) => VentasProvider()),
          ChangeNotifierProvider(
            create: (_) => CuentasPorCobrarProvider(),
          ), // ✅ NUEVO: Provider de cuentas por cobrar
          ChangeNotifierProvider(
            create: (_) => CuentaPorCobrarDetalleProvider(),
          ), // ✅ NUEVO: Provider de detalle de cuenta
          ChangeNotifierProvider(create: (_) => TrackingProvider()),
          ChangeNotifierProvider(create: (_) => EntregaProvider()),
          ChangeNotifierProvider(create: (_) => EntregaEstadosProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => EstadosProvider()),
          ChangeNotifierProvider(create: (_) => VisitaProvider()),
          ChangeNotifierProvider(create: (_) => ClienteCreditoProvider()),
          ChangeNotifierProvider(create: (_) => CajaProvider()),
          ChangeNotifierProvider(create: (_) => GastoProvider()),
          ChangeNotifierProvider(create: (_) => ProductosAgrupadsProvider()),
          ChangeNotifierProvider(
            create: (_) => ReporteProductoDanadoProvider(),
          ),
          ChangeNotifierProvider(create: (_) => BannerPublicitarioProvider()),
          ChangeNotifierProvider(create: (_) => ReporteVentasProvider()),
          ChangeNotifierProvider(create: (_) => PrestamosProvider()),
          ChangeNotifierProvider(create: (_) => EstadoLogisticoProvider()),
          ChangeNotifierProvider(create: (_) => LocalidadProvider()),
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
            '/ventas-list': (context) =>
                const VentasListScreen(), // ✅ NUEVO: Listado de ventas para preventistas/admins
            '/cuentas-por-cobrar-list': (context) =>
                const CuentasPorCobrarListScreen(), // ✅ NUEVO: Cuentas por cobrar
            '/mis-direcciones': (context) => const MisDireccionesScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/resumen-pedido': (context) =>
                const ResumenPedidoScreen(), // ✅ Clientes y Preventistas
            '/reportes-productos-danados': (context) =>
                const ReportesProductosDanadosScreen(), // ✅ NUEVO: Pantalla de reportes dañados
            '/reporte-productos-vendidos': (context) =>
                const ReporteVentasScreen(), // ✅ NUEVO: Pantalla de reporte de productos vendidos
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
                    pedido: pedido!, // ✅ Usar ! para indicar que no es null
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

              // ✅ NUEVO: Ruta para detalle de CUENTA POR COBRAR
              case '/cuenta-por-cobrar-detalle':
                final cuentaId = settings.arguments as int?;
                if (cuentaId == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Error: ID de cuenta no encontrado'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) =>
                      CuentaPorCobrarDetalleScreen(cuentaId: cuentaId),
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
                // ✅ CAMBIO 2026-03-05: Usar ConfirmarEntregaVentaScreen en lugar de ConfirmacionEntregaScreen (eliminado)
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: Text(
                        'Abrir desde resumen de entregas o tarjeta de ventas asignadas',
                      ),
                    ),
                  ),
                );

              /*case '/chofer/iniciar-ruta':
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
                );*/

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
                      body: Center(child: Text('Error: Cliente no encontrado')),
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
