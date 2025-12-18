import 'package:flutter/material.dart';

/// Wrapper que anima la entrada suave del NavigationPanel
/// Usa FadeTransition y SlideTransition para un efecto elegante
class AnimatedNavigationCard extends StatefulWidget {
  final String clientName;
  final String address;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final VoidCallback? onOpenInAppNavigation;
  final Widget child;

  const AnimatedNavigationCard({
    Key? key,
    required this.clientName,
    required this.address,
    this.destinationLatitude,
    this.destinationLongitude,
    this.onOpenInAppNavigation,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedNavigationCard> createState() => _AnimatedNavigationCardState();
}

class _AnimatedNavigationCardState extends State<AnimatedNavigationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
