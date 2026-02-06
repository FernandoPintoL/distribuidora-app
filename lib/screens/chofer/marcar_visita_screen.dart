import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/gps_service.dart';
import '../../services/image_compression_service.dart';
import '../../widgets/widgets.dart';

class MarcarVisitaScreen extends StatefulWidget {
  final Client cliente;

  const MarcarVisitaScreen({super.key, required this.cliente});

  @override
  State<MarcarVisitaScreen> createState() => _MarcarVisitaScreenState();
}

class _MarcarVisitaScreenState extends State<MarcarVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _gpsService = GpsService();
  final _imagePicker = ImagePicker();

  TipoVisitaPreventista _tipoVisitaSeleccionado =
      TipoVisitaPreventista.TOMA_PEDIDO;
  EstadoVisitaPreventista _estadoVisitaSeleccionado =
      EstadoVisitaPreventista.EXITOSA;
  MotivoNoAtencionVisita? _motivoNoAtencionSeleccionado;

  Position? _ubicacionActual;
  File? _fotoLocal;
  bool _cargandoUbicacion = false;
  bool _dentroVentanaHoraria = true;
  String? _mensajeAdvertenciaHorario;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _validarHorarioCliente();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);

    try {
      await _gpsService.initialize();
      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _ubicacionActual = position;
        _cargandoUbicacion = false;
      });
    } catch (e) {
      setState(() => _cargandoUbicacion = false);
      _mostrarError('Error al obtener ubicación GPS: ${e.toString()}');
    }
  }

  Future<void> _validarHorarioCliente() async {
    final visitaProvider = context.read<VisitaProvider>();
    final resultado = await visitaProvider.validarHorarioCliente(
      widget.cliente.id,
    );

    if (resultado != null && mounted) {
      setState(() {
        _dentroVentanaHoraria = resultado['dentro_ventana'] ?? true;
        _mensajeAdvertenciaHorario = resultado['advertencia'];
      });
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imagen != null) {
        final fotoOriginal = File(imagen.path);
        debugPrint('📸 Comprimiendo imagen...');

        try {
          final fotoComprimida =
              await ImageCompressionService.comprimirYValidarImagen(
                fotoOriginal,
              );

          setState(() {
            _fotoLocal = fotoComprimida;
          });

          debugPrint('✅ Imagen comprimida exitosamente');
        } catch (e) {
          _mostrarError('Error al comprimir imagen: ${e.toString()}');
        }
      }
    } catch (e) {
      _mostrarError('Error al capturar foto: ${e.toString()}');
    }
  }

  Future<void> _registrarVisita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ubicacionActual == null) {
      _mostrarError('Esperando ubicación GPS...');
      return;
    }

    // Validar motivo de no atención
    if (_estadoVisitaSeleccionado == EstadoVisitaPreventista.NO_ATENDIDO &&
        _motivoNoAtencionSeleccionado == null) {
      _mostrarError('Debes seleccionar un motivo de no atención');
      return;
    }

    final visitaProvider = context.read<VisitaProvider>();

    final exito = await visitaProvider.registrarVisita(
      clienteId: widget.cliente.id,
      fechaHoraVisita: DateTime.now(),
      tipoVisita: _tipoVisitaSeleccionado,
      estadoVisita: _estadoVisitaSeleccionado,
      motivoNoAtencion: _motivoNoAtencionSeleccionado,
      latitud: _ubicacionActual!.latitude,
      longitud: _ubicacionActual!.longitude,
      fotoLocal: _fotoLocal,
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );

    if (!mounted) return;

    if (exito) {
      _mostrarExito('Visita registrada correctamente');
      Navigator.pop(context, true);
    } else {
      _mostrarError(visitaProvider.errorMessage ?? 'Error al registrar visita');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visitaProvider = context.watch<VisitaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Visita'),
        backgroundColor: colorScheme.primary,
      ),
      body: visitaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info del cliente
                    _buildClienteInfo(),
                    const SizedBox(height: 16),

                    // Advertencia horario
                    if (!_dentroVentanaHoraria &&
                        _mensajeAdvertenciaHorario != null)
                      _buildAdvertenciaHorario(),

                    const SizedBox(height: 16),

                    // Tipo de visita
                    _buildTipoVisitaSelector(),
                    const SizedBox(height: 16),

                    // Estado de visita
                    _buildEstadoVisitaSelector(),
                    const SizedBox(height: 16),

                    // Motivo de no atención (condicional)
                    if (_estadoVisitaSeleccionado ==
                        EstadoVisitaPreventista.NO_ATENDIDO)
                      _buildMotivoNoAtencionSelector(),

                    const SizedBox(height: 16),

                    // Ubicación GPS
                    /* _buildUbicacionGPS(),
                    const SizedBox(height: 16), */

                    // Foto
                    _buildFotoSection(),
                    const SizedBox(height: 16),

                    // Observaciones
                    _buildObservacionesField(),
                    const SizedBox(height: 32),

                    // Botón registrar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: visitaProvider.isLoading
                            ? null
                            : _registrarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                        ),
                        child: const Text(
                          'Registrar Visita',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClienteInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del cliente
                if (widget.cliente.fotoPerfil != null &&
                    widget.cliente.fotoPerfil!.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.cliente.fotoPerfil!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(width: 16),
                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cliente',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cliente.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.cliente.codigoCliente != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${widget.cliente.codigoCliente}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (widget.cliente.telefono != null &&
                          widget.cliente.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.cliente.telefono!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertenciaHorario() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _mensajeAdvertenciaHorario!,
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoVisitaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Visita *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipoVisitaPreventista>(
          value: _tipoVisitaSeleccionado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: TipoVisitaPreventista.values.map((tipo) {
            return DropdownMenuItem(value: tipo, child: Text(tipo.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _tipoVisitaSeleccionado = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildEstadoVisitaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado de Visita *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<EstadoVisitaPreventista>(
          value: _estadoVisitaSeleccionado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: EstadoVisitaPreventista.values.map((estado) {
            return DropdownMenuItem(value: estado, child: Text(estado.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _estadoVisitaSeleccionado = value;
                if (value == EstadoVisitaPreventista.EXITOSA) {
                  _motivoNoAtencionSeleccionado = null;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMotivoNoAtencionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motivo de No Atención *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MotivoNoAtencionVisita>(
          value: _motivoNoAtencionSeleccionado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: MotivoNoAtencionVisita.values.map((motivo) {
            return DropdownMenuItem(value: motivo, child: Text(motivo.label));
          }).toList(),
          onChanged: (value) {
            setState(() => _motivoNoAtencionSeleccionado = value);
          },
        ),
      ],
    );
  }

  Widget _buildUbicacionGPS() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación GPS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_cargandoUbicacion)
              const Center(child: CircularProgressIndicator())
            else if (_ubicacionActual != null)
              Text(
                'Lat: ${_ubicacionActual!.latitude.toStringAsFixed(6)}\n'
                'Lng: ${_ubicacionActual!.longitude.toStringAsFixed(6)}\n'
                'Precisión: ${_ubicacionActual!.accuracy.toStringAsFixed(1)}m',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Row(
                children: [
                  const Text('No disponible'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _obtenerUbicacion,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del Local (Opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_fotoLocal != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _fotoLocal!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => setState(() => _fotoLocal = null),
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _tomarFoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar Foto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
      ],
    );
  }

  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones (Opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacionesController,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Escribe notas adicionales sobre la visita...',
          ),
        ),
      ],
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }
}
