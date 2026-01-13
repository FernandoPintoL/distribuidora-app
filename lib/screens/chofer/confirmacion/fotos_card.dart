import 'dart:io';
import 'package:flutter/material.dart';
import '../../../widgets/chofer/quick_camera_capture.dart';

class FotosCard extends StatelessWidget {
  final String title;
  final String? description;
  final int maxPhotos;
  final List<File> fotos;
  final Function(List<File>) onFotosChanged;
  final Color? accentColor;

  const FotosCard({
    Key? key,
    required this.title,
    this.description,
    required this.maxPhotos,
    required this.fotos,
    required this.onFotosChanged,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColorEffective = accentColor ?? colorScheme.primary;

    return Card(
      color: isDarkMode
          ? colorScheme.surfaceContainerHigh
          : accentColorEffective.withValues(alpha: 0.06),
      elevation: isDarkMode ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.2)
              : accentColorEffective.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            // Título con contador
            Text(
              '$title (${fotos.length}/$maxPhotos)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // Descripción opcional
            if (description != null)
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            // Widget de captura
            QuickCameraCapture(
              maxPhotos: maxPhotos,
              onPhotosChanged: onFotosChanged,
            ),
          ],
        ),
      ),
    );
  }
}
