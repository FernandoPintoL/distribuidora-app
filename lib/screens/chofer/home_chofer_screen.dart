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
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bienvenida
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.user?.name ?? 'Chofer',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Card de Estadísticas Visuales con Gráfico Circular
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
          const SizedBox(height: 16),

          // Mini Mapa de Tracking en Vivo
          Consumer<EntregaProvider>(
            builder: (context, entregaProvider, _) {
              return MiniTrackingMap(
                entregas: entregaProvider.entregas,
                onMapTap: () {
                  // TODO: Navegar a vista ampliada del mapa
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Panel de Acciones Rápidas
          QuickActionsPanel(
            onInitializeRoute: () {
              // Navegar a pantalla de tracking en vivo
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TrackingScreen(),
                ),
              );
            },
            onViewAllDeliveriesMap: () {
              // Navegar a vista completa del mapa con todas las entregas
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TrackingScreen(),
                ),
              );
            },
            onScanQR: () {
              // TODO: Abrir escáner de QR
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
