import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_home_screen.dart';
import '../../models/navigation_item.dart';
import '../../providers/providers.dart';
import 'entregas_asignadas_screen.dart';
import 'tracking_screen.dart';
import '../perfil/perfil_screen.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/dashboard_stats_card.dart';
import '../../widgets/chofer/mini_tracking_map.dart';
import '../../widgets/chofer/quick_actions_panel.dart';
import '../../config/config.dart';

/// Pantalla principal para usuarios con rol CHOFER
///
/// Muestra:
/// - Dashboard con estadísticas de entregas
/// - Entregas asignadas
/// - Rutas activas
/// - Perfil del chofer
class HomeChoferScreen extends BaseHomeScreen {
  const HomeChoferScreen({super.key});

  @override
  State<HomeChoferScreen> createState() => _HomeChoferScreenState();
}

class _HomeChoferScreenState extends BaseHomeScreenState<HomeChoferScreen> {
  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      icon: Icons.home,
      label: 'Inicio',
    ),
    NavigationItem(
      icon: Icons.local_shipping,
      label: 'Entregas',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  List<Widget> get screens => [
    const _DashboardTab(),
    const EntregasAsignadasScreen(),
    const PerfilScreen(),
  ];

  @override
  PreferredSizeWidget get appBar => CustomGradientAppBar(
    title: 'Mis Entregas',
    userRole: 'chofer',
    actions: [
      NotificationBadgeAction(),
    ],
  );

  @override
  Future<void> loadInitialData() async {
    if (!mounted) return;

    try {
      final entregaProvider = context.read<EntregaProvider>();

      // Cargar entregas asignadas
      await entregaProvider.obtenerEntregasAsignadas();
    } catch (e) {
      debugPrint('❌ Error cargando datos iniciales: $e');
    }
  }
}
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _isMapVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bienvenida mejorada
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;
              return Card(
                color: cardColor,
                elevation: 4,
                shadowColor: isDarkMode
                    ? Colors.black.withAlpha((0.5 * 255).toInt())
                    : Colors.grey.withAlpha((0.3 * 255).toInt()),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha((0.15 * 255).toInt()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.waving_hand,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Bienvenido!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.user?.name ?? 'Chofer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Card de Estadísticas Visuales
          Consumer<EntregaProvider>(
            builder: (context, entregaProvider, _) {
              final totalEntregas = entregaProvider.entregas.length;
              final entregasCompletadas = entregaProvider.entregas
                  .where((e) => e.estado == 'ENTREGADO')
                  .length;
              final entregasPendientes = totalEntregas - entregasCompletadas;

              return DashboardStatsCard(
                totalEntregas: totalEntregas,
                entregasCompletadas: entregasCompletadas,
                entregasPendientes: entregasPendientes,
              );
            },
          ),
          const SizedBox(height: 20),

          // Botón para mostrar/ocultar mapa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.blue.withAlpha((0.8 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isMapVisible = !_isMapVisible;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMapVisible
                              ? Icons.location_off_rounded
                              : Icons.location_on_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isMapVisible ? 'Ocultar Mapa' : 'Mostrar Mapa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isMapVisible ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mini Mapa de Tracking - Visible solo si está activado
          if (_isMapVisible)
            Consumer<EntregaProvider>(
              builder: (context, entregaProvider, _) {
                return MiniTrackingMap(
                  entregas: entregaProvider.entregas,
                  onMapTap: () {
                    // Navegar a vista ampliada del mapa
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TrackingScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          if (_isMapVisible) const SizedBox(height: 16),

          // Panel de Acciones Rápidas mejorado
          QuickActionsPanel(
            onInitializeRoute: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TrackingScreen(),
                ),
              );
            },
            onViewAllDeliveriesMap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TrackingScreen(),
                ),
              );
            },
            onScanQR: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de QR próximamente')),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
