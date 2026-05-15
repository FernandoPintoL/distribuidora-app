import 'package:flutter/material.dart';

class CustomLoadingWidget extends StatelessWidget {
  final String mensaje;
  final IconData? icono;
  final Color? color;
  final double? tamanioIcono;

  const CustomLoadingWidget({
    super.key,
    required this.mensaje,
    this.icono,
    this.color,
    this.tamanioIcono = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorPrincipal = color ?? colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Contenedor con el icono animado
          Container(
            width: tamanioIcono! + 20,
            height: tamanioIcono! + 20,
            decoration: BoxDecoration(
              color: colorPrincipal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Indicador de progreso circular
                SizedBox(
                  width: tamanioIcono,
                  height: tamanioIcono,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorPrincipal),
                    strokeWidth: 3,
                  ),
                ),
                // Icono en el centro
                if (icono != null)
                  Icon(
                    icono,
                    size: tamanioIcono! * 0.6,
                    color: colorPrincipal,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mensaje de carga
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          // Punto animado (efecto de espera)
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedDot(
                delay: Duration(milliseconds: 0),
                color: colorPrincipal,
              ),
              const SizedBox(width: 4),
              _AnimatedDot(
                delay: Duration(milliseconds: 200),
                color: colorPrincipal,
              ),
              const SizedBox(width: 4),
              _AnimatedDot(
                delay: Duration(milliseconds: 400),
                color: colorPrincipal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para animar puntos de espera
class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _AnimatedDot({
    required this.delay,
    required this.color,
  });

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Aplicar delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      ),
    );
  }
}
