import 'package:flutter/material.dart';

/// Widget que anima un contador numérico
/// Útil para mostrar cambios en estadísticas de forma visual
class AnimatedCounter extends StatefulWidget {
  final int endValue;
  final Duration duration;
  final TextStyle textStyle;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    Key? key,
    required this.endValue,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    this.prefix = '',
    this.suffix = '',
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation =
        IntTween(begin: 0, end: widget.endValue).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _animation =
          IntTween(begin: 0, end: widget.endValue).animate(_controller);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}${widget.suffix}',
          style: widget.textStyle,
        );
      },
    );
  }
}
