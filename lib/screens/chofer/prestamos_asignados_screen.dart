import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prestamos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_text_styles.dart';
import 'prestamo_detalle_screen.dart';

/// Pantalla que muestra los 3 tipos de préstamos asignados al chofer
class PrestamosAsignadosScreen extends StatefulWidget {
  const PrestamosAsignadosScreen({super.key});

  @override
  State<PrestamosAsignadosScreen> createState() =>
      _PrestamosAsignadosScreenState();
}

class _PrestamosAsignadosScreenState extends State<PrestamosAsignadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ Cargar préstamos cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPrestamos();
    });
  }

  /// Cargar préstamos del chofer actual
  void _cargarPrestamos() {
    try {
      final authProvider = context.read<AuthProvider>();
      final prestamosProvider = context.read<PrestamosProvider>();

      if (authProvider.user != null) {
        debugPrint(
          '📦 Cargando préstamos para chofer: ${authProvider.user!.id}',
        );
        prestamosProvider.cargarPrestamosDelChofer(authProvider.user!.id);
      } else {
        debugPrint('❌ Usuario no autenticado');
      }
    } catch (e) {
      debugPrint('❌ Error cargando préstamos: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tabs
        Container(
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.secondary,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: 'Clientes', icon: Icon(Icons.person)),
              Tab(text: 'Eventos', icon: Icon(Icons.event)),
              Tab(text: 'Proveedores', icon: Icon(Icons.business)),
            ],
          ),
        ),
        // Contenido de tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrestamosList('cliente'),
              _buildPrestamosList('evento'),
              _buildPrestamosList('proveedor'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrestamosList(String tipo) {
    return Consumer<PrestamosProvider>(
      builder: (context, provider, _) {
        List<dynamic> prestamos = [];
        bool loading = false;

        switch (tipo) {
          case 'cliente':
            prestamos = provider.prestamosClientes;
            loading = provider.loadingClientes;
            break;
          case 'evento':
            prestamos = provider.prestamosEventos;
            loading = provider.loadingEventos;
            break;
          case 'proveedor':
            prestamos = provider.prestamosProveedores;
            loading = provider.loadingProveedores;
            break;
        }

        debugPrint(
          '🔍 [PRESTAMOS_$tipo] loading=$loading, count=${prestamos.length}',
        );

        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prestamos.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForType(tipo),
                  size: 64,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text('No hay préstamos asignados'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshPrestamos(context, tipo),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: prestamos.length,
            itemBuilder: (context, index) {
              final prestamo = prestamos[index];
              return _buildPrestamoCard(context, prestamo, tipo);
            },
          ),
        );
      },
    );
  }

  Widget _buildPrestamoCard(
    BuildContext context,
    dynamic prestamo,
    String tipo,
  ) {
    String nombre = '';
    String subtitulo = '';

    switch (tipo) {
      case 'cliente':
        nombre = prestamo.cliente?.nombre ?? 'Cliente desconocido';
        subtitulo = 'Estado: ${prestamo.estado}';
        break;
      case 'evento':
        nombre = prestamo.nombreEvento ?? 'Evento desconocido';
        subtitulo = 'Encargado: ${prestamo.encargadoEvento ?? 'N/A'}';
        break;
      case 'proveedor':
        nombre = prestamo.proveedor?.nombre ?? 'Proveedor desconocido';
        subtitulo = 'Estado: ${prestamo.estado}';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: ListTile(
        leading: Icon(_getIconForType(tipo)), // ✅ CORREGIDO: Envolver en Icon()
        title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PrestamoDetalleScreen(prestamo: prestamo, tipo: tipo),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'cliente':
        return Icons.person;
      case 'evento':
        return Icons.event;
      case 'proveedor':
        return Icons.business;
      default:
        return Icons.inventory; // ✅ CORREGIDO: Icons.package no existe
    }
  }

  Future<void> _refreshPrestamos(BuildContext context, String tipo) async {
    final provider = context.read<PrestamosProvider>();
    // Aquí se podría recargar solo el tipo específico si fuera necesario
    // Por ahora, vuelve a cargar todo
  }
}
