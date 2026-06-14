import 'package:flutter/material.dart';

class ImagenViewerModal extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;
  final Function(String) onDescargar;

  const ImagenViewerModal({
    Key? key,
    required this.imagenes,
    required this.indiceInicial,
    required this.onDescargar,
  }) : super(key: key);

  @override
  State<ImagenViewerModal> createState() => _ImagenViewerModalState();
}

class _ImagenViewerModalState extends State<ImagenViewerModal> {
  late int _indiceActual;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irAlAnterior() {
    if (_indiceActual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _irAlSiguiente() {
    if (_indiceActual < widget.imagenes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          'Imagen ${_indiceActual + 1} de ${widget.imagenes.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              widget.onDescargar(widget.imagenes[_indiceActual]);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView para navegar entre imágenes
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _indiceActual = index;
              });
            },
            itemCount: widget.imagenes.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(80),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  widget.imagenes[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 80,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              );
            },
          ),

          // Botones de navegación
          if (widget.imagenes.length > 1) ...[
            // Botón anterior (izquierda)
            if (_indiceActual > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _irAlAnterior,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

            // Botón siguiente (derecha)
            if (_indiceActual < widget.imagenes.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _irAlSiguiente,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
