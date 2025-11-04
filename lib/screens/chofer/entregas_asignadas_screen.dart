import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';

class EntregasAsignadasScreen extends StatefulWidget {
  const EntregasAsignadasScreen({Key? key}) : super(key: key);

  @override
  State<EntregasAsignadasScreen> createState() => _EntregasAsignadasScreenState();
}

class _EntregasAsignadasScreenState extends State<EntregasAsignadasScreen> {
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _cargarEntregas();
  }

  Future<void> _cargarEntregas() async {
    final provider = context.read<EntregaProvider>();
    await provider.obtenerEntregasAsignadas(
      estado: _filtroEstado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas Asignadas'),
        elevation: 0,
      ),
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.entregas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay entregas asignadas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las entregas aparecerán aquí cuando se asignen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _cargarEntregas,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.entregas.length,
              itemBuilder: (context, index) {
                final entrega = provider.entregas[index];
                return _EntregaCard(entrega: entrega);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EntregaCard extends StatelessWidget {
  final Entrega entrega;

  const _EntregaCard({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorEstado(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrega #${entrega.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Proforma #${entrega.proformaId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de fecha
                if (entrega.fechaAsignacion != null) ...[
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Asignada',
                    value: entrega.formatFecha(entrega.fechaAsignacion),
                  ),
                  const SizedBox(height: 8),
                ],
                // Observaciones
                if (entrega.observaciones != null && entrega.observaciones!.isNotEmpty) ...[
                  const Text(
                    'Observaciones:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entrega.observaciones!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 8,
              children: [
                _BotonAccion(
                  label: 'Ver Detalles',
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/chofer/entrega-detalle',
                      arguments: entrega.id,
                    );
                  },
                ),
                if (entrega.puedeIniciarRuta)
                  _BotonAccion(
                    label: 'Iniciar Ruta',
                    icon: Icons.navigation,
                    color: Colors.green,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/chofer/iniciar-ruta',
                        arguments: entrega.id,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado() {
    final colorHex = entrega.estadoColor;
    // Convertir hex a Color
    return Color(int.parse('0xff${colorHex.substring(1)}'));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _BotonAccion({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
