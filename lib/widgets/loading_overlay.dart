import 'package:flutter/material.dart';

/// Widget que muestra un overlay de carga sobre el contenido actual
/// Úsalo con LoadingOverlay.show() y LoadingOverlay.hide()
class LoadingOverlay extends StatefulWidget {
  final Widget child;

  static final GlobalKey<_LoadingOverlayState> _key =
      GlobalKey<_LoadingOverlayState>();

  LoadingOverlay({
    required this.child,
  }) : super(key: _key);

  static void show(
    BuildContext context, {
    String message = 'Cargando...',
    bool dismissible = false,
  }) {
    _key.currentState?._show(message: message, dismissible: dismissible);
  }

  static void hide() {
    _key.currentState?._hide();
  }

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  bool _isLoading = false;
  String _message = 'Cargando...';
  bool _dismissible = false;

  void _show({
    required String message,
    required bool dismissible,
  }) {
    debugPrint('🔄 LoadingOverlay.show() called with message: "$message"');
    setState(() {
      _isLoading = true;
      _message = message;
      _dismissible = dismissible;
    });
  }

  void _hide() {
    debugPrint('✅ LoadingOverlay.hide() called');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          GestureDetector(
            onTap: _dismissible ? _hide : null,
            child: Container(
              color: Colors.black.withAlpha((0.3 * 255).toInt()),
              child: Center(
                child: _LoadingWidget(
                  message: _message,
                  dismissible: _dismissible,
                  onDismiss: _hide,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget privado que muestra el contenido del loading
class _LoadingWidget extends StatefulWidget {
  final String message;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const _LoadingWidget({
    required this.message,
    required this.dismissible,
    this.onDismiss,
  });

  @override
  State<_LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<_LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar colores del tema actual
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card contenedor
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.15 * 255).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo con animación de rotación
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo de fondo animado
                      _RotatingCircle(),
                      // Logo
                      Image.asset(
                        'assets/icons/icon.png',
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_cart,
                            size: 60,
                            color: theme.primaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Indicador de progreso personalizado
                _AnimatedLoadingBar(),

                const SizedBox(height: 24),

                // Texto de mensaje - SIN especificar fontFamily para usar la fuente por defecto
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color ??
                           (isDark ? Colors.white : Colors.black87),
                  ),
                  textAlign: TextAlign.center,
                ),

                // Botón de cancelar (opcional)
                if (widget.dismissible) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo rotativo que sirve como fondo del logo
class _RotatingCircle extends StatefulWidget {
  @override
  State<_RotatingCircle> createState() => _RotatingCircleState();
}

class _RotatingCircleState extends State<_RotatingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blue[300]!,
            width: 3,
          ),
        ),
      ),
    );
  }
}

/// Barra de carga animada
class _AnimatedLoadingBar extends StatefulWidget {
  @override
  State<_AnimatedLoadingBar> createState() => _AnimatedLoadingBarState();
}

class _AnimatedLoadingBarState extends State<_AnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.ease),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 150,
        height: 6,
        child: Container(
          color: Colors.grey[200],
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Barra de fondo
                  Container(
                    color: Colors.grey[200],
                  ),
                  // Barra de progreso animada
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[400]!,
                              Colors.blue[600]!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
