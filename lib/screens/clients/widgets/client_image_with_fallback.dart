import 'package:flutter/material.dart';

class ClientImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallbackWidget;
  final Widget loadingWidget;

  const ClientImageWithFallback({
    super.key,
    required this.urls,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackWidget,
    required this.loadingWidget,
  });

  @override
  State<ClientImageWithFallback> createState() => _ClientImageWithFallbackState();
}

class _ClientImageWithFallbackState extends State<ClientImageWithFallback> {
  int _currentUrlIndex = 0;
  bool _hasError = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🖼️ Inicializando ClientImageWithFallback con ${widget.urls.length} URLs',
    );
  }

  @override
  void didUpdateWidget(ClientImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) {
      debugPrint('🔄 URLs cambiadas, reseteando estado');
      setState(() {
        _currentUrlIndex = 0;
        _hasError = false;
        _imageLoaded = false;
      });
    }
  }

  void _tryNextUrl() {
    if (!mounted) return;

    if (_currentUrlIndex < widget.urls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        debugPrint(
          '🔄 Intentando URL ${_currentUrlIndex + 1}/${widget.urls.length}: ${widget.urls[_currentUrlIndex]}',
        );
      });
    } else {
      setState(() {
        _hasError = true;
        debugPrint('❌ Todas las URLs fallaron, mostrando fallback');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _currentUrlIndex >= widget.urls.length) {
      return widget.fallbackWidget;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.width / 2),
        color: Colors.green.shade50,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.width / 2),
        child: Image.network(
          widget.urls[_currentUrlIndex],
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (!_imageLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _imageLoaded = true);
                    debugPrint(
                      '✅ Imagen cargada exitosamente desde: ${widget.urls[_currentUrlIndex]}',
                    );
                  }
                });
              }
              return child;
            }
            return widget.loadingWidget;
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              '❌ Error cargando imagen desde: ${widget.urls[_currentUrlIndex]}',
            );
            debugPrint('❌ Error: $error');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _tryNextUrl();
            });

            return widget.fallbackWidget;
          },
        ),
      ),
    );
  }
}
