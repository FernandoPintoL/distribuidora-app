import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class MisDireccionesScreen extends StatefulWidget {
  const MisDireccionesScreen({super.key});

  @override
  State<MisDireccionesScreen> createState() => _MisDireccionesScreenState();
}

class _MisDireccionesScreenState extends State<MisDireccionesScreen> {
  bool _isLoading = true;
  Client? _cliente;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() => _isLoading = true);

    final clientProvider = context.read<ClientProvider>();
    final cliente = await clientProvider.getClientPerfil();

    setState(() {
      _cliente = cliente;
      _errorMessage = clientProvider.errorMessage;
      _isLoading = false;
    });
  }

  Future<void> _marcarComoPrincipal(ClientAddress direccion) async {
    // TODO: Implementar lógica para marcar como principal en el backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _eliminarDireccion(ClientAddress direccion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: Text('¿Estás seguro de eliminar esta dirección?\n\n${direccion.direccion}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // TODO: Implementar eliminación en el backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad en desarrollo'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _agregarDireccion() {
    Navigator.pushNamed(context, '/direccion-form').then((result) {
      if (result == true) {
        _cargarDirecciones();
      }
    });
  }

  void _editarDireccion(ClientAddress direccion) {
    Navigator.pushNamed(
      context,
      '/direccion-form',
      arguments: direccion,
    ).then((result) {
      if (result == true) {
        _cargarDirecciones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Direcciones'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDireccionesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarDireccion,
        icon: const Icon(Icons.add_location),
        label: const Text('Agregar Dirección'),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error al cargar direcciones',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDirecciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDireccionesList() {
    final direcciones = _cliente?.direcciones ?? [];

    if (direcciones.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarDirecciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: direcciones.length,
        itemBuilder: (context, index) {
          final direccion = direcciones[index];
          return _buildDireccionCard(direccion);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes direcciones registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera dirección de entrega',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _agregarDireccion,
              icon: const Icon(Icons.add_location),
              label: const Text('Agregar Primera Dirección'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDireccionCard(ClientAddress direccion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _editarDireccion(direccion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y badge principal
              Row(
                children: [
                  Icon(
                    direccion.esPrincipal ? Icons.home : Icons.location_on,
                    color: direccion.esPrincipal
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      direccion.direccion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (direccion.esPrincipal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: Text(
                        'Principal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Detalles de ubicación GPS
              if (direccion.latitud != null && direccion.longitud != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicación GPS registrada',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              // Observaciones
              if (direccion.observaciones != null && direccion.observaciones!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccion.observaciones!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 24),

              // Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!direccion.esPrincipal)
                    TextButton.icon(
                      onPressed: () => _marcarComoPrincipal(direccion),
                      icon: const Icon(Icons.star_border, size: 18),
                      label: const Text('Marcar como principal'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _editarDireccion(direccion),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _eliminarDireccion(direccion),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
