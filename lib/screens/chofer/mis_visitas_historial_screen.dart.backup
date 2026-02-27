import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'visita_detalle_screen.dart';

class MisVisitasHistorialScreen extends StatefulWidget {
  const MisVisitasHistorialScreen({super.key});

  @override
  State<MisVisitasHistorialScreen> createState() =>
      _MisVisitasHistorialScreenState();
}

class _MisVisitasHistorialScreenState extends State<MisVisitasHistorialScreen> {
  final _scrollController = ScrollController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  EstadoVisitaPreventista? _estadoFiltro;
  TipoVisitaPreventista? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _cargarVisitas();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _cargarMasVisitas();
    }
  }

  Future<void> _cargarVisitas() async {
    final visitaProvider = context.read<VisitaProvider>();
    await visitaProvider.cargarVisitas(
      refresh: true,
      fechaInicio: _fechaInicio?.toIso8601String(),
      fechaFin: _fechaFin?.toIso8601String(),
      estadoVisita: _estadoFiltro,
      tipoVisita: _tipoFiltro,
    );
    await visitaProvider.cargarEstadisticas(
      fechaInicio: _fechaInicio?.toIso8601String(),
      fechaFin: _fechaFin?.toIso8601String(),
    );
  }

  Future<void> _cargarMasVisitas() async {
    final visitaProvider = context.read<VisitaProvider>();
    if (!visitaProvider.isLoading && visitaProvider.hasMorePages) {
      await visitaProvider.cargarVisitas(
        fechaInicio: _fechaInicio?.toIso8601String(),
        fechaFin: _fechaFin?.toIso8601String(),
        estadoVisita: _estadoFiltro,
        tipoVisita: _tipoFiltro,
      );
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFiltrosModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitaProvider = context.watch<VisitaProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Visitas'),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarVisitas,
        child: Column(
          children: [
            // Estadísticas
            if (visitaProvider.estadisticas != null)
              _buildEstadisticasCard(visitaProvider.estadisticas!),

            // Lista de visitas
            Expanded(
              child: visitaProvider.visitas.isEmpty && !visitaProvider.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: visitaProvider.visitas.length +
                          (visitaProvider.hasMorePages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == visitaProvider.visitas.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final visita = visitaProvider.visitas[index];
                        return _buildVisitaCard(visita);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(Map<String, dynamic> estadisticas) {
    final stats = estadisticas['estadisticas_generales'] ?? {};

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Resumen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '${stats['total_visitas'] ?? 0}',
                  Colors.blue,
                ),
                _buildStatItem(
                  'Exitosas',
                  '${stats['porcentaje_exitosas'] ?? 0}%',
                  Colors.green,
                ),
                _buildStatItem(
                  'Fuera Horario',
                  '${stats['porcentaje_fuera_horario'] ?? 0}%',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitaCard(VisitaPreventistaCliente visita) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitaDetalleScreen(visita: visita),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visita.cliente?.nombre ?? 'Cliente N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildEstadoBadge(visita.estadoVisita),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(visita.fechaHoraVisita),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    visita.tipoVisita.label,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (!visita.dentroVentanaHoraria) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Fuera de horario',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoVisitaPreventista estado) {
    final color = estado == EstadoVisitaPreventista.EXITOSA
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay visitas registradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Filtro de estado
              DropdownButtonFormField<EstadoVisitaPreventista>(
                value: _estadoFiltro,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...EstadoVisitaPreventista.values.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado.label),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() => _estadoFiltro = value);
                },
              ),

              const SizedBox(height: 16),

              // Filtro de tipo
              DropdownButtonFormField<TipoVisitaPreventista>(
                value: _tipoFiltro,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...TipoVisitaPreventista.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.label),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() => _tipoFiltro = value);
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _estadoFiltro = null;
                          _tipoFiltro = null;
                          _fechaInicio = null;
                          _fechaFin = null;
                        });
                        Navigator.pop(context);
                        _cargarVisitas();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cargarVisitas();
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
