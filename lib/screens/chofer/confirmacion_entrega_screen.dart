import 'dart:convert' show base64Encode;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/entrega_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chofer/quick_camera_capture.dart';
import '../../config/config.dart';

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
  final List<File> _fotosCapturadas = [];

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  String _convertirFotoABase64(File foto) {
    final bytes = foto.readAsBytesSync();
    return base64Encode(bytes);
  }

  void _onFotosChanged(List<File> fotos) {
    setState(() {
      _fotosCapturadas.clear();
      _fotosCapturadas.addAll(fotos);
    });
  }

  Future<void> _confirmarEntrega() async {
    // Convertir todas las fotos capturadas a Base64
    final fotosBase64 = <String>[];
    for (final foto in _fotosCapturadas) {
      fotosBase64.add(_convertirFotoABase64(foto));
    }

    final provider = context.read<EntregaProvider>();

    final exito = await provider.confirmarEntrega(
      widget.entregaId,
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
      appBar: CustomGradientAppBar(
        title: 'Confirmar Entrega',
        customGradient: AppGradients.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de Fotos
          _SectionTitle(title: '📷 Fotografía de Entrega'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: QuickCameraCapture(
                maxPhotos: 3,
                onPhotosChanged: _onFotosChanged,
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
          const SizedBox(height: 32),

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
