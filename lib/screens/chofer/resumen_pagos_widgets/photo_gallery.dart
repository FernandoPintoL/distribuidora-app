import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Widget para mostrar galería de fotos en grid
class PhotoGallery extends StatelessWidget {
  final List<dynamic> photos;
  final Function(dynamic) buildPhoto; // Función para construir la imagen
  final int crossAxisCount;
  final double spacing;
  final bool isDarkMode;

  const PhotoGallery({
    Key? key,
    required this.photos,
    required this.buildPhoto,
    this.crossAxisCount = 3,
    this.spacing = 8,
    required this.isDarkMode,
  }) : super(key: key);

  /// Decodificar base64 a Uint8List
  Uint8List _decodificarBase64(String base64String) {
    String cleanBase64 = base64String
        .replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '');

    try {
      return base64Decode(cleanBase64);
    } catch (_) {
      try {
        return base64Decode(base64String);
      } catch (__) {
        return Uint8List(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: buildPhoto(photos[index]),
        );
      },
    );
  }
}
