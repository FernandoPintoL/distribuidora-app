import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/location_selector.dart';
import '../widgets/select_search.dart';

/// Widget reutilizable para el formulario de dirección del cliente
/// Incluye: LocationSelector (GPS), Localidad, Dirección y Observaciones del lugar
class DireccionFormWidget extends StatefulWidget {
  final TextEditingController direccionController;
  final TextEditingController observacionesController;
  final double? initialLatitude;
  final double? initialLongitude;
  final int? initialLocalidadId;
  final Function(double?, double?) onLocationChanged;
  final Function(int?) onLocalidadChanged;

  const DireccionFormWidget({
    super.key,
    required this.direccionController,
    required this.observacionesController,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocalidadId,
    required this.onLocationChanged,
    required this.onLocalidadChanged,
  });

  @override
  State<DireccionFormWidget> createState() => _DireccionFormWidgetState();
}

class _DireccionFormWidgetState extends State<DireccionFormWidget> {
  List<Localidad> _localidades = [];
  bool _isLoadingLocalidades = false;
  late ClientProvider _clientProvider;

  @override
  void initState() {
    super.initState();
    _clientProvider = context.read<ClientProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLocalidades();
      }
    });
  }

  Future<void> _loadLocalidades() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocalidades = true;
    });

    try {
      await _clientProvider.loadLocalidades();
      if (mounted) {
        setState(() {
          _localidades = _clientProvider.localidades;
          _isLoadingLocalidades = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar localidades: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocalidades = false;
        });
      }
    }
  }

  /// Obtiene la localidad inicial de forma segura
  Localidad? _getInitialLocalidad() {
    // Si no hay ID inicial, retornar null
    if (widget.initialLocalidadId == null) {
      return null;
    }

    // Si la lista está vacía, retornar null
    if (_localidades.isEmpty) {
      debugPrint('⚠️ Lista de localidades vacía, no se puede preseleccionar');
      return null;
    }

    // Buscar la localidad por ID
    try {
      final localidad = _localidades.firstWhere(
        (loc) => loc.id == widget.initialLocalidadId,
        orElse: () {
          debugPrint(
            '⚠️ No se encontró localidad con ID: ${widget.initialLocalidadId}',
          );
          debugPrint(
            '📋 Localidades disponibles: ${_localidades.map((l) => '${l.id}: ${l.nombre}').join(', ')}',
          );
          throw StateError('Localidad no encontrada');
        },
      );
      debugPrint(
        '✅ Localidad preseleccionada: ${localidad.nombre} (ID: ${localidad.id})',
      );
      return localidad;
    } catch (e) {
      debugPrint('❌ Error al obtener localidad inicial: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Selector con GPS
        LocationSelector(
          initialLatitude: widget.initialLatitude,
          initialLongitude: widget.initialLongitude,
          onLocationSelected: (lat, lng, address) {
            widget.onLocationChanged(lat, lng);
            // Cargar la dirección obtenida del GPS en el campo de dirección
            if (address != null &&
                address.isNotEmpty &&
                address != 'Dirección no disponible' &&
                widget.direccionController.text.isEmpty) {
              widget.direccionController.text = address;
            }
          },
          autoGetLocation: true,
        ),
        const SizedBox(height: 16),

        // Localidad selector
        if (_isLoadingLocalidades)
          const Center(child: CircularProgressIndicator())
        else
          SelectSearch<Localidad>(
            label: 'Localidad',
            items: _localidades,
            value: _getInitialLocalidad(),
            displayString: (localidad) => localidad.nombre,
            onChanged: (localidad) {
              widget.onLocalidadChanged(localidad?.id);
            },
            hintText: 'Buscar localidad...',
            prefixIcon: const Icon(Icons.location_city),
          ),
        const SizedBox(height: 16),

        // Campo de dirección
        /*TextFormField(
          controller: widget.direccionController,
          decoration: const InputDecoration(
            labelText: 'Dirección *',
            hintText: 'Ingrese la dirección completa',
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La dirección es obligatoria';
            }
            if (value.trim().length < 5) {
              return 'La dirección debe tener al menos 5 caracteres';
            }
            return null;
          },
        ),*/
        const SizedBox(height: 16),

        // Campo para observaciones del lugar
        TextFormField(
          controller: widget.observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones del lugar',
            hintText: 'Ej: Casa color azul, portón negro, junto al mercado',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
