import 'package:flutter/material.dart';

class ImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallbackWidget;
  final Widget loadingWidget;

  const ImageWithFallback({
    super.key,
    required this.urls,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackWidget,
    required this.loadingWidget,
  });

  @override
  State<ImageWithFallback> createState() => _ImageWithFallbackState();
}

class _ImageWithFallbackState extends State<ImageWithFallback> {
  int _currentUrlIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentUrlIndex >= widget.urls.length) {
      return widget.fallbackWidget;
    }

    return Image.network(
      widget.urls[_currentUrlIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return widget.loadingWidget;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '❌ Error al cargar imagen desde: ${widget.urls[_currentUrlIndex]}',
        );
        debugPrint('❌ Error details: $error');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentUrlIndex < widget.urls.length - 1) {
            setState(() {
              _currentUrlIndex++;
            });
            debugPrint('🔄 Intentando siguiente URL...');
          } else {
            debugPrint('⚠️ No hay más URLs disponibles, mostrando fallback');
          }
        });

        if (_currentUrlIndex >= widget.urls.length - 1) {
          return widget.fallbackWidget;
        }

        return widget.loadingWidget;
      },
    );
  }
}
