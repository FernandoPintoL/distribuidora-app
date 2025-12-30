import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para captura rápida de múltiples fotografías
/// Permite capturar hasta 3 fotos con galería de vista previa
class QuickCameraCapture extends StatefulWidget {
  final Function(List<File>) onPhotosChanged;
  final int maxPhotos;

  const QuickCameraCapture({
    Key? key,
    required this.onPhotosChanged,
    this.maxPhotos = 3,
  }) : super(key: key);

  @override
  State<QuickCameraCapture> createState() => _QuickCameraCaptureState();
}

class _QuickCameraCaptureState extends State<QuickCameraCapture> {
  final List<File> _capturedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Notificar cambios iniciales después de que el frame se complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPhotosChanged(_capturedPhotos);
      }
    });
  }

  Future<void> _capturePhoto() async {
    // Si ya alcanzó el máximo, mostrar aviso
    if (_capturedPhotos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Límite de ${widget.maxPhotos} fotos alcanzado',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedPhotos.add(File(pickedFile.path));
        });
        widget.onPhotosChanged(_capturedPhotos);

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto ${_capturedPhotos.length}/${widget.maxPhotos} capturada',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturando foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _capturedPhotos.removeAt(index);
    });
    widget.onPhotosChanged(_capturedPhotos);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto eliminada'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCapture = _capturedPhotos.length < widget.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con contador
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotos de Entrega',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: canCapture ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_capturedPhotos.length}/${widget.maxPhotos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Galería de fotos
        if (_capturedPhotos.isNotEmpty)
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedPhotos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedPhotos[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Indicador de número
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          // Botón eliminar
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _deletePhoto(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin fotos capturadas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Botón de captura rápida
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canCapture ? _capturePhoto : null,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              canCapture
                  ? 'Tomar Foto (${_capturedPhotos.length}/${widget.maxPhotos})'
                  : 'Límite de fotos alcanzado',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canCapture ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ),

        // Texto informativo
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Puedes capturar hasta ${widget.maxPhotos} fotos. Tap en la X roja para eliminar.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
