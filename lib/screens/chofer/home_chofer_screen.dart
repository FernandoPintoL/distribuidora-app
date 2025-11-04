import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_home_screen.dart';
import '../../models/navigation_item.dart';
import '../../providers/providers.dart';
import 'entregas_asignadas_screen.dart';
import '../perfil/perfil_screen.dart';

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
  PreferredSizeWidget get appBar => AppBar(
    title: const Text('Distribuidora Paucara - Chofer'),
    actions: [
      // Notificaciones
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          // TODO: Abrir notificaciones
        },
      ),
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

          // Estadísticas
          Consumer<EntregaProvider>(
            builder: (context, entregaProvider, _) {
              return Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Entregas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${entregaProvider.entregas.length}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Completadas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '0',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Botones de acción
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EntregasAsignadasScreen(),
                ),
              );
            },
            icon: const Icon(Icons.local_shipping),
            label: const Text('Ver Entregas Asignadas'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implementar inicio de ruta
            },
            icon: const Icon(Icons.route),
            label: const Text('Iniciar Ruta'),
          ),
        ],
      ),
    );
  }
}
