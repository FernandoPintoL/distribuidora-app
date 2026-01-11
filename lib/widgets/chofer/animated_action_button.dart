import 'package:flutter/material.dart';

/// Botón de acción con animación de escala (press effect)
/// Crea un efecto visual agradable al tocar
class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final Duration animationDuration;
  final bool isDarkMode;

  const AnimatedActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 600),
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.grey[200] : Colors.grey[800];

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: widget.color.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.color.withAlpha((0.3 * 255).toInt()),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha((0.2 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono con animación de entrada
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            widget.icon,
                            size: 32,
                            color: widget.color,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Texto con fade in
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.2, 1.0),
                        ),
                      ),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
