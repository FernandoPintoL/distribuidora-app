import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget de shimmer effect para mostrar mientras cargan datos
/// Imita la estructura del contenido real con animación de brillo
class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const LoadingShimmer({
    Key? key,
    this.height = 20,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Widget para mostrar líneas de shimmer apiladas
class LoadingShimmerLines extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;

  const LoadingShimmerLines({
    Key? key,
    this.lines = 3,
    this.lineHeight = 16,
    this.spacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        lines,
        (index) => Column(
          children: [
            LoadingShimmer(height: lineHeight),
            if (index < lines - 1) SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }
}

/// Placeholder animado para imágenes/mapas mientras cargan
class LoadingShimmerCard extends StatelessWidget {
  final double height;
  final double? width;

  const LoadingShimmerCard({
    Key? key,
    this.height = 200,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Placeholder para card completa con título y contenido
class LoadingShimmerFullCard extends StatelessWidget {
  final double height;

  const LoadingShimmerFullCard({
    Key? key,
    this.height = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            LoadingShimmer(height: 20, width: 150),
            const SizedBox(height: 12),

            // Contenido (3 líneas)
            LoadingShimmerLines(
              lines: 3,
              lineHeight: 16,
              spacing: 8,
            ),
          ],
        ),
      ),
    );
  }
}
