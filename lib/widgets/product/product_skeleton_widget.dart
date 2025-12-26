import 'package:flutter/material.dart';
import '../../extensions/theme_extension.dart';

/// Widget de skeleton loading para productos
class ProductSkeletonWidget extends StatefulWidget {
  final bool isGridView;

  const ProductSkeletonWidget({
    super.key,
    this.isGridView = false,
  });

  @override
  State<ProductSkeletonWidget> createState() => _ProductSkeletonWidgetState();
}

class _ProductSkeletonWidgetState extends State<ProductSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = isDark
            ? colorScheme.surfaceContainerHighest.withAlpha((255 * _animation.value).toInt())
            : colorScheme.surfaceContainerHighest.withAlpha((255 * _animation.value).toInt());

        if (widget.isGridView) {
          return _buildGridSkeleton(shimmerColor, colorScheme, isDark);
        } else {
          return _buildListSkeleton(shimmerColor, colorScheme, isDark);
        }
      },
    );
  }

  Widget _buildListSkeleton(
      Color shimmerColor, ColorScheme colorScheme, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isDark ? 2 : 1,
      color: isDark ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Acciones
            Column(
              children: [
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSkeleton(
      Color shimmerColor, ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: isDark ? 2 : 1,
      color: isDark ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // Nombre
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Precio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 50,
                  height: 24,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
