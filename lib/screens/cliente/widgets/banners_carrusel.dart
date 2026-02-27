import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/banner_publicitario.dart';

/// Widget BannersCarrusel - Muestra banners publicitarios en un carrusel
///
/// Características:
/// ✓ Auto-scroll cada 4 segundos
/// ✓ Indicadores de página (dots)
/// ✓ Imagen con gradiente superpuesto
/// ✓ Responsivo y adaptable
class BannersCarrusel extends StatefulWidget {
  final List<BannerPublicitario> banners;
  final double? height;
  final Duration autoScrollDuration;

  const BannersCarrusel({
    Key? key,
    required this.banners,
    this.height = 200,
    this.autoScrollDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<BannersCarrusel> createState() => _BannersCarruselState();
}

class _BannersCarruselState extends State<BannersCarrusel> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = PageController(initialPage: _currentPage);

    // Iniciar auto-scroll solo si hay más de un banner
    if (widget.banners.length > 1) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Iniciar auto-scroll automático
  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted && widget.banners.length > 1) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Carrusel
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _BannerCard(banner: banner);
            },
          ),
        ),

        // Indicadores de página
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF2563EB) // Azul activo
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget interno para cada tarjeta de banner
class _BannerCard extends StatelessWidget {
  final BannerPublicitario banner;

  const _BannerCard({Key? key, required this.banner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarImagenAmpliada(context),
      child: Stack(
        children: [
          // Imagen de fondo
          CachedNetworkImage(
            imageUrl: banner.urlImagenCompleta,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          ),

          // Gradiente oscuro superpuesto (para mejorar legibilidad del texto)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),

          // Contenido: título y descripción
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  banner.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Descripción (si existe)
                if (banner.descripcion != null &&
                    banner.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      banner.descripcion!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar imagen ampliada en un modal fullscreen con zoom
  void _mostrarImagenAmpliada(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Imagen con zoom usando InteractiveViewer
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: banner.urlImagenCompleta,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Botón para cerrar
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Texto del banner (opcional)
            if (banner.titulo.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (banner.descripcion != null &&
                        banner.descripcion!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          banner.descripcion!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
