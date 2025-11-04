import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';

class EntregaDetalleScreen extends StatefulWidget {
  final int entregaId;

  const EntregaDetalleScreen({
    Key? key,
    required this.entregaId,
  }) : super(key: key);

  @override
  State<EntregaDetalleScreen> createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen> {
  late EntregaProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<EntregaProvider>();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    await _provider.obtenerEntrega(widget.entregaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Entrega'),
        elevation: 0,
      ),
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.entregaActual == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  const Text('Error al cargar entrega'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarDetalle,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final entrega = provider.entregaActual!;

          return RefreshIndicator(
            onRefresh: _cargarDetalle,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estado
                _EstadoCard(entrega: entrega),
                const SizedBox(height: 16),
                // Información general
                _InformacionGeneralCard(entrega: entrega),
                const SizedBox(height: 16),
                // Fecha y tiempos
                _FechasCard(entrega: entrega),
                const SizedBox(height: 16),
                // Historial de estados
                if (provider.historialEstados.isNotEmpty) ...[
                  _HistorialEstadosCard(estados: provider.historialEstados),
                  const SizedBox(height: 16),
                ],
                // Botones de acción
                _BotonesAccion(entrega: entrega),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  final Entrega entrega;

  const _EstadoCard({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColorEstado(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado Actual',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  entrega.estadoIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entrega.estadoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado() {
    const colores = {
      'ASIGNADA': Color(0xFF3b82f6),
      'EN_CAMINO': Color(0xFFf97316),
      'LLEGO': Color(0xFFeab308),
      'ENTREGADO': Color(0xFF22c55e),
      'NOVEDAD': Color(0xFFef4444),
      'CANCELADA': Color(0xFF6b7280),
    };
    return colores[entrega.estado] ?? Colors.grey;
  }
}

class _InformacionGeneralCard extends StatelessWidget {
  final Entrega entrega;

  const _InformacionGeneralCard({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoItem(
              icon: Icons.confirmation_number,
              label: 'ID Entrega',
              value: '#${entrega.id}',
            ),
            const Divider(),
            _InfoItem(
              icon: Icons.receipt_long,
              label: 'Proforma',
              value: '#${entrega.proformaId}',
            ),
            const Divider(),
            _InfoItem(
              icon: Icons.local_shipping,
              label: 'Chofer',
              value: entrega.choferId != null ? '#${entrega.choferId}' : 'No asignado',
            ),
            const Divider(),
            _InfoItem(
              icon: Icons.directions_car,
              label: 'Vehículo',
              value: entrega.vehiculoId != null ? '#${entrega.vehiculoId}' : 'No asignado',
            ),
            if (entrega.observaciones != null && entrega.observaciones!.isNotEmpty) ...[
              const Divider(),
              _InfoItem(
                icon: Icons.notes,
                label: 'Observaciones',
                value: entrega.observaciones!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FechasCard extends StatelessWidget {
  final Entrega entrega;

  const _FechasCard({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fechas y Tiempos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (entrega.fechaAsignacion != null) ...[
              _InfoItem(
                icon: Icons.calendar_today,
                label: 'Asignada',
                value: entrega.formatFecha(entrega.fechaAsignacion),
              ),
              const Divider(),
            ],
            if (entrega.fechaInicio != null) ...[
              _InfoItem(
                icon: Icons.play_circle,
                label: 'Inicio de Ruta',
                value: entrega.formatFecha(entrega.fechaInicio),
              ),
              const Divider(),
            ],
            if (entrega.fechaEntrega != null) ...[
              _InfoItem(
                icon: Icons.check_circle,
                label: 'Entregado',
                value: entrega.formatFecha(entrega.fechaEntrega),
              ),
            ],
            if (entrega.fechaAsignacion == null && entrega.fechaInicio == null && entrega.fechaEntrega == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin fechas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorialEstadosCard extends StatelessWidget {
  final List<EntregaEstadoHistorial> estados;

  const _HistorialEstadosCard({
    Key? key,
    required this.estados,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Estados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estados.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final estado = estados[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${estado.estadoAnterior} → ${estado.estadoNuevo}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estado.createdAt.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      if (estado.comentario != null && estado.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          estado.comentario!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  final Entrega entrega;

  const _BotonesAccion({
    Key? key,
    required this.entrega,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
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
        if (entrega.puedeMarcarLlegada)
          _BotonAccion(
            label: 'Marcar Llegada',
            icon: Icons.location_on,
            color: Colors.orange,
            onPressed: () {
              // TODO: Implementar marcar llegada
            },
          ),
        if (entrega.puedeConfirmarEntrega)
          _BotonAccion(
            label: 'Confirmar Entrega',
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/chofer/confirmar-entrega',
                arguments: entrega.id,
              );
            },
          ),
        if (entrega.puedeReportarNovedad)
          _BotonAccion(
            label: 'Reportar Novedad',
            icon: Icons.warning,
            color: Colors.red,
            onPressed: () {
              // TODO: Implementar reportar novedad
            },
          ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
