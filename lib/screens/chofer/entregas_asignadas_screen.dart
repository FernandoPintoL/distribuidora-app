import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/entrega.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class EntregasAsignadasScreen extends StatefulWidget {
  const EntregasAsignadasScreen({Key? key}) : super(key: key);

  @override
  State<EntregasAsignadasScreen> createState() =>
      _EntregasAsignadasScreenState();
}

class _EntregasAsignadasScreenState extends State<EntregasAsignadasScreen> {
  String? _filtroEstado;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _estadosFiltro = [
    'Todas',
    'ASIGNADA',
    'EN_CAMINO',
    'EN_TRANSITO',
    'LLEGO',
    'ENTREGADO',
  ];

  @override
  void initState() {
    super.initState();
    _cargarEntregas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEntregas() async {
    final provider = context.read<EntregaProvider>();
    await provider.obtenerEntregasAsignadas(
      estado: _filtroEstado != 'Todas' ? _filtroEstado : null,
    );
  }

  List<Entrega> _getEntregasFiltradas(List<Entrega> entregas) {
    return entregas.where((entrega) {
      // Filtro por búsqueda
      if (_busqueda.isNotEmpty) {
        final numero = entrega.numero?.toLowerCase() ?? '';
        final cliente = entrega.cliente?.toLowerCase() ?? '';
        final search = _busqueda.toLowerCase();

        if (!numero.contains(search) && !cliente.contains(search)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EntregaProvider>(
        builder: (context, provider, _) {
          final entregasFiltradas = _getEntregasFiltradas(provider.entregas);

          return Column(
            children: [
              // Filtros y búsqueda
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    // Barra de búsqueda
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por número o cliente...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _busqueda = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filtro por estado
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _estadosFiltro.length,
                        itemBuilder: (context, index) {
                          final estado = _estadosFiltro[index];
                          final isSelected =
                              (_filtroEstado == null && estado == 'Todas') ||
                                  _filtroEstado == estado;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(estado == 'Todas' ? 'Todas' : _getEtiquetaEstado(estado)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _filtroEstado = estado == 'Todas' ? null : estado;
                                });
                                _cargarEntregas();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de entregas
              Expanded(
                child: _buildListado(provider, entregasFiltradas),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListado(EntregaProvider provider, List<Entrega> entregas) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entregas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay entregas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _busqueda.isNotEmpty
                  ? 'No se encontraron resultados para "$_busqueda"'
                  : 'Las entregas aparecerán aquí cuando se asignen',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
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
        itemCount: entregas.length,
        itemBuilder: (context, index) {
          final entrega = entregas[index];
          return _EntregaCard(entrega: entrega);
        },
      ),
    );
  }

  String _getEtiquetaEstado(String estado) {
    const etiquetas = {
      'ASIGNADA': 'Asignadas',
      'EN_CAMINO': 'En Camino',
      'LLEGO': 'Llegó',
      'ENTREGADO': 'Entregadas',
    };
    return etiquetas[estado] ?? estado;
  }
}

class _EntregaCard extends StatefulWidget {
  final Entrega entrega;

  const _EntregaCard({Key? key, required this.entrega}) : super(key: key);

  @override
  State<_EntregaCard> createState() => _EntregaCardState();
}

class _EntregaCardState extends State<_EntregaCard> {
  bool _ventasExpandidas = false;

  Entrega get entrega => widget.entrega;

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
                    Row(
                      children: [
                        Text(
                          entrega.tipoWorkIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTituloTrabajo(entrega),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      entrega.numero ?? '#${entrega.id}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

          // Ubicación (sin mapa interactivo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrega.direccion ?? 'Dirección no disponible',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ventas asignadas (expandible)
          if (entrega.ventas.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _ventasExpandidas = !_ventasExpandidas;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 20,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 ${entrega.ventas.length} venta${entrega.ventas.length > 1 ? 's' : ''} asignada${entrega.ventas.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (entrega.ventas.isNotEmpty)
                                  Text(
                                    'Total: BS ${entrega.ventas.fold<double>(0, (sum, v) => sum + v.total).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          _ventasExpandidas
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                  // Ventas expandidas
                  if (_ventasExpandidas) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entrega.ventas.length,
                      itemBuilder: (context, index) {
                        final venta = entrega.ventas[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      venta.numero,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      venta.clienteNombre ??
                                          venta.cliente ??
                                          'Cliente desconocido',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'BS ${venta.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente
                if (entrega.cliente != null && entrega.cliente!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Cliente',
                    value: entrega.cliente!,
                  ),
                  const SizedBox(height: 8),
                ],
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
                if (entrega.observaciones != null &&
                    entrega.observaciones!.isNotEmpty) ...[
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                _BotonAccion(
                  label: 'Cómo llegar',
                  icon: Icons.map,
                  color: Colors.orange,
                  onPressed: () => _openInGoogleMaps(context),
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
    return Color(int.parse('0xff${colorHex.substring(1)}'));
  }

  String _getTituloTrabajo(Entrega entrega) {
    if (entrega.trabajoType == 'entrega') {
      return 'Entrega Directa #${entrega.id}';
    } else if (entrega.trabajoType == 'envio') {
      return 'Envío #${entrega.id}';
    }
    return 'Trabajo #${entrega.id}';
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final address = entrega.direccion ?? '';
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dirección no disponible')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/$address',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
