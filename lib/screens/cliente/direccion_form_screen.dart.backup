import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/direccion_form_widget.dart';
import '../../widgets/widgets.dart';
import '../../config/config.dart';

class DireccionFormScreen extends StatefulWidget {
  final ClientAddress? direccion;

  const DireccionFormScreen({
    super.key,
    this.direccion,
  });

  @override
  State<DireccionFormScreen> createState() => _DireccionFormScreenState();
}

class _DireccionFormScreenState extends State<DireccionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _direccionController;
  late TextEditingController _observacionesController;
  bool _esPrincipal = false;
  bool _isSaving = false;

  // Campos de ubicación GPS
  double? _latitude;
  double? _longitude;
  int? _selectedLocalidadId;

  @override
  void initState() {
    super.initState();
    _direccionController = TextEditingController(
      text: widget.direccion?.direccion ?? '',
    );
    _observacionesController = TextEditingController(
      text: widget.direccion?.observaciones ?? '',
    );
    _esPrincipal = widget.direccion?.esPrincipal ?? false;
    _latitude = widget.direccion?.latitud;
    _longitude = widget.direccion?.longitud;
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarDireccion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // Crear el objeto ClientAddress con todos los datos
    final nuevaDireccion = ClientAddress(
      id: widget.direccion?.id,
      clienteId: widget.direccion?.clienteId,
      direccion: _direccionController.text.trim(),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      latitud: _latitude,
      longitud: _longitude,
      esPrincipal: _esPrincipal,
      activa: true,
      ciudad: null, // Ya no se usa
      departamento: null, // Ya no se usa
      codigoPostal: null, // Ya no se usa
    );

    // TODO: Implementar guardado en el backend
    // Por ahora solo simulamos el guardado
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.direccion == null
                ? 'Dirección agregada correctamente'
                : 'Dirección actualizada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Devolver la dirección creada/actualizada
      Navigator.pop(context, nuevaDireccion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.direccion != null;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: isEditing ? 'Editar Dirección' : 'Nueva Dirección',
        customGradient: AppGradients.orange,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta dirección se usará para entregas de tus pedidos',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Componente reutilizable de ubicación
            DireccionFormWidget(
              direccionController: _direccionController,
              observacionesController: _observacionesController,
              initialLatitude: _latitude,
              initialLongitude: _longitude,
              initialLocalidadId: _selectedLocalidadId,
              onLocationChanged: (lat, lng) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                });
              },
              onLocalidadChanged: (localidadId) {
                setState(() {
                  _selectedLocalidadId = localidadId;
                });
              },
            ),
            const SizedBox(height: 20),

            // Marcar como principal
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Marcar como dirección principal',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Esta será tu dirección predeterminada para entregas',
                  style: TextStyle(fontSize: 12),
                ),
                value: _esPrincipal,
                onChanged: (value) {
                  setState(() => _esPrincipal = value);
                },
                secondary: Icon(
                  _esPrincipal ? Icons.home : Icons.home_outlined,
                  color: _esPrincipal
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardarDireccion,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Guardando...'
                      : isEditing
                          ? 'Actualizar Dirección'
                          : 'Guardar Dirección',
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de cancelar
            if (!_isSaving)
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
