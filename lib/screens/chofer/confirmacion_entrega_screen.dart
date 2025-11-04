import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';

class ConfirmacionEntregaScreen extends StatefulWidget {
  final int entregaId;

  const ConfirmacionEntregaScreen({
    Key? key,
    required this.entregaId,
  }) : super(key: key);

  @override
  State<ConfirmacionEntregaScreen> createState() => _ConfirmacionEntregaScreenState();
}

class _ConfirmacionEntregaScreenState extends State<ConfirmacionEntregaScreen> {
  final _observacionesController = TextEditingController();
  File? _fotoSeleccionada;
  final _imagePicker = ImagePicker();
  bool _consentimientoLectura = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _fotoSeleccionada = File(pickedFile.path);
      });
    }
  }

  String _convertirFotoABase64(File foto) {
    final bytes = foto.readAsBytesSync();
    return base64Encode(bytes);
  }

  Future<void> _confirmarEntrega() async {
    if (!_consentimientoLectura) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe aceptar la lectura de datos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generar firma placeholder (en producción, usar SignaturePad)
    final firmaBase64 = base64Encode(utf8.encode('Firma digital - ${DateTime.now()}'));

    final fotosBase64 = <String>[];
    if (_fotoSeleccionada != null) {
      fotosBase64.add(_convertirFotoABase64(_fotoSeleccionada!));
    }

    final provider = context.read<EntregaProvider>();

    final exito = await provider.confirmarEntrega(
      widget.entregaId,
      firmaBase64: firmaBase64,
      fotosBase64: fotosBase64.isNotEmpty ? fotosBase64 : null,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Entrega confirmada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Entrega'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Instrucción
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete la confirmación de entrega con firma y fotos',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Firma
          _SectionTitle(title: '📝 Firma Digital'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pan_tool,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Área de firma (placeholder)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'En producción: Usar SignaturePad',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nota: La firma se capturará automáticamente',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Fotos
          _SectionTitle(title: '📷 Fotografía de Entrega'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fotoSeleccionada != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _fotoSeleccionada!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _seleccionarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cambiar Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin foto seleccionada',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _seleccionarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Recomendado: Una foto del producto entregado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Observaciones
          _SectionTitle(title: '📝 Observaciones (Opcional)'),
          const SizedBox(height: 12),
          TextField(
            controller: _observacionesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ingrese cualquier observación adicional',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Consentimiento
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consentimientoLectura,
                    onChanged: (value) {
                      setState(() {
                        _consentimientoLectura = value ?? false;
                      });
                    },
                    title: const Text(
                      'Autorizo la lectura de mis datos de ubicación',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Al confirmar, acepto el almacenamiento y procesamiento de datos según la política de privacidad',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botones
          Consumer<EntregaProvider>(
            builder: (context, provider, _) {
              return Column(
                spacing: 8,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _confirmarEntrega,
                      icon: const Icon(Icons.check_circle),
                      label: Text(provider.isLoading ? 'Confirmando...' : 'Confirmar Entrega'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
