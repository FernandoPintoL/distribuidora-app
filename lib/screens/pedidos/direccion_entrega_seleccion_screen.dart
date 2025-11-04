import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class DireccionEntregaSeleccionScreen extends StatefulWidget {
  const DireccionEntregaSeleccionScreen({super.key});

  @override
  State<DireccionEntregaSeleccionScreen> createState() =>
      _DireccionEntregaSeleccionScreenState();
}

class _DireccionEntregaSeleccionScreenState
    extends State<DireccionEntregaSeleccionScreen> {
  ClientAddress? _direccionSeleccionada;
  bool _isLoading = true;
  Client? _cliente;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    final authProvider = context.read<AuthProvider>();
    final clientProvider = context.read<ClientProvider>();

    if (authProvider.user?.id != null) {
      // Obtener el perfil completo del cliente autenticado usando /api/clientes/mi-perfil
      // Este endpoint no requiere permisos especiales y retorna todas las direcciones
      final cliente = await clientProvider.getClientPerfil();

      setState(() {
        _cliente = cliente;
        _errorMessage = clientProvider.errorMessage;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'No se pudo identificar al usuario';
        _isLoading = false;
      });
    }
  }

  void _continuarAlSiguientePaso() {
    if (_direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una dirección de entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegar a la pantalla de selección de fecha/hora
    Navigator.pushNamed(
      context,
      '/fecha-hora-entrega',
      arguments: _direccionSeleccionada,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirección de Entrega'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cliente == null
              ? Center(
                  child: Text(_errorMessage ?? 'No se pudo cargar la información del cliente'),
                )
              : Builder(
                  builder: (context) {
                    final cliente = _cliente!;
                    final direcciones = cliente.direcciones ?? [];

                if (direcciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes direcciones registradas',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navegar a pantalla de agregar dirección
                            Navigator.pushNamed(context, '/add-address');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Dirección'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header con información
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona dónde deseas recibir tu pedido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Elige una de tus direcciones guardadas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de direcciones
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: direcciones.length,
                        itemBuilder: (context, index) {
                          final direccion = direcciones[index];
                          final isSelected = _direccionSeleccionada?.id == direccion.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _direccionSeleccionada = direccion;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icono de selección
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 16),

                                    // Información de la dirección
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  direccion.direccion,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (direccion.ciudad != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ciudad: ${direccion.ciudad}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],

                                          if (direccion.departamento != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              direccion.departamento!,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],

                                          if (direccion.observaciones != null &&
                                              direccion.observaciones!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Obs: ${direccion.observaciones}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Botón continuar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _direccionSeleccionada != null
                                ? _continuarAlSiguientePaso
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
