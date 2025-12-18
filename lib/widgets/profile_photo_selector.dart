import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePhotoSelector extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(File?) onPhotoSelected;
  final double size;

  const ProfilePhotoSelector({
    super.key,
    this.currentPhotoUrl,
    required this.onPhotoSelected,
    this.size = 120,
  });

  @override
  State<ProfilePhotoSelector> createState() => _ProfilePhotoSelectorState();
}

class _ProfilePhotoSelectorState extends State<ProfilePhotoSelector> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void dispose() {
    super.dispose();
  }

  String? _buildFullUrl(String? url) {
    final urlEnv = dotenv.env['BASE_URL_IMG'];
    if (urlEnv == null || urlEnv.isEmpty) {
      debugPrint(
        '⚠️  Warning: BASE_URL not found in .env file, using default URL',
      );
      return 'http://192.168.100.21:8000/api';
    }
    debugPrint('🌐 Using BASE_URL from .env: $urlEnv');
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    // Asumir que es relativo a la API base
    return urlEnv + url;
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();

    if (cameraStatus.isDenied || photosStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se necesitan permisos de cámara y galería para seleccionar fotos',
            ),
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        widget.onPhotoSelected(_selectedImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || widget.currentPhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {
                      _selectedImage = null;
                    });
                  }
                  widget.onPhotoSelected(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileIconFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.blue.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 3,
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.blue.shade700,
      ),
    );
  }

  Widget _buildProfileIconContent() {
    return Icon(
      Icons.person,
      size: widget.size * 0.5,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[400]
          : Colors.blue.shade700,
    );
  }

  Widget _buildPhotoWidget() {
    final photoUrl =
        _selectedImage?.path ?? _buildFullUrl(widget.currentPhotoUrl);

    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.green.shade50,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.green.shade200,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.person_outline,
          size: widget.size * 0.5,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.green,
        ),
      );
    }

    // Verificar que el archivo existe si es un archivo local
    if (_selectedImage != null && !_selectedImage!.existsSync()) {
      debugPrint('Archivo de imagen no existe: ${_selectedImage!.path}');
      // Resetear la imagen seleccionada si el archivo no existe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedImage = null;
          });
          widget.onPhotoSelected(null);
        }
      });
      // Mostrar el fallback mientras tanto
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.orange.shade50,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.orange.shade200,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: widget.size * 0.5,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.orange,
        ),
      );
    }

    // Si es una URL de red, usar Future para manejar el error de carga
    if (_selectedImage == null) {
      return FutureBuilder<void>(
        future: precacheImage(NetworkImage(photoUrl), context)
            .catchError((e) {
          debugPrint('Error al cargar imagen de red: $e');
          // Si hay error, no hacer nada - el errorWidget lo manejará
        }),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Si hay error, mostrar icono de perfil
            return _buildProfileIconFallback();
          }

          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 3),
              image: DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('❌ Error al cargar imagen de red: $exception');
                  // No hacer nada, dejar que se muestre el errorWidget
                },
              ),
            ),
            child: snapshot.connectionState == ConnectionState.waiting
                ? null // Mostrar la imagen mientras carga
                : snapshot.hasError
                    ? _buildProfileIconContent()
                    : null,
          );
        },
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).primaryColor, width: 3),
        image: DecorationImage(
          image: FileImage(_selectedImage!),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            debugPrint('Error al cargar imagen local: $exception');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        if (!mounted) return;
        await _requestPermissions();
        if (!mounted) return;
        _showImageSourceDialog();
      },
      child: Stack(
        children: [
          _buildPhotoWidget(),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? theme.scaffoldBackgroundColor
                      : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                color: isDarkMode ? theme.colorScheme.onPrimary : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
