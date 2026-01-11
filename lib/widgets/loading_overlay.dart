import 'package:flutter/material.dart';

/*
╔═══════════════════════════════════════════════════════════════════════════╗
║                   ✅ ARCHIVO CORRECTO DE LOADING OVERLAY                 ║
║                                                                            ║
║  Ruta: lib/widgets/loading_overlay.dart                                   ║
║  Estado: MEJORADO Y OPTIMIZADO PARA MODO OSCURO                           ║
║                                                                            ║
║  Si ves mensajes en la consola que dicen:                                 ║
║  - "🔄 LOADING_OVERLAY.DART - show() LLAMADO"                            ║
║  - "✅ LOADING_OVERLAY.DART - hide() LLAMADO"                            ║
║  - "🎨 LOADING_OVERLAY.DART - _LoadingWidget.build() RENDERIZADO"        ║
║                                                                            ║
║  ✅ CONFIRMA QUE ESTAMOS USANDO EL ARCHIVO CORRECTO                      ║
╚═══════════════════════════════════════════════════════════════════════════╝
*/

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
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📞 LoadingOverlay.show() CALLED STATICALLY');
    debugPrint('📝 Message: "$message"');
    debugPrint('🔑 GlobalKey state: ${_key.currentState}');
    debugPrint('═══════════════════════════════════════════════════════════');
    _key.currentState?._show(message: message, dismissible: dismissible);
  }

  static void hide() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📞 LoadingOverlay.hide() CALLED STATICALLY');
    debugPrint('🔑 GlobalKey state: ${_key.currentState}');
    debugPrint('═══════════════════════════════════════════════════════════');
    _key.currentState?._hide();
  }

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  bool _isLoading = false;
  String _message = 'Cargando...';
  bool _dismissible = false;

  @override
  void initState() {
    super.initState();
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🎬 _LoadingOverlayState INITIALIZED');
    debugPrint('🔑 GlobalKey is ready for use');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  void _show({
    required String message,
    required bool dismissible,
  }) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔄 LOADING_OVERLAY.DART - show() LLAMADO');
    debugPrint('📝 Mensaje: "$message"');
    debugPrint('🎯 Dismissible: $dismissible');
    debugPrint('═══════════════════════════════════════════════════════════');
    setState(() {
      _isLoading = true;
      _message = message;
      _dismissible = dismissible;
    });
  }

  void _hide() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('✅ LOADING_OVERLAY.DART - hide() LLAMADO');
    debugPrint('═══════════════════════════════════════════════════════════');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          // ✅ MEJORADO: Asegurar que el overlay ocupe toda la pantalla
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissible ? _hide : null,
              child: Container(
                // ✅ MEJORADO: Adaptado a modo oscuro
                color: isDarkMode
                    ? Colors.black.withAlpha((0.4 * 255).toInt())
                    : Colors.black.withAlpha((0.3 * 255).toInt()),
                child: Center(
                  child: _LoadingWidget(
                    message: _message,
                    dismissible: _dismissible,
                    onDismiss: _hide,
                  ),
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

    // ✅ DEBUG: Verificar que estamos usando el archivo correcto
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('✅ LOADING_OVERLAY.DART - _LoadingWidgetState INICIALIZADO');
    debugPrint('📝 Mensaje: "${widget.message}"');
    debugPrint('🎨 Modo Oscuro: ${Theme.of(context).brightness == Brightness.dark}');
    debugPrint('═══════════════════════════════════════════════════════════');

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
    debugPrint('🎨 LOADING_OVERLAY.DART - _LoadingWidget.build() RENDERIZADO');

    // ✅ MEJORADO: Usar colores del tema actual
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ MEJORADO: Card contenedor con mejor diseño
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              // ✅ MEJORADO: Color adaptado al tema
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              // ✅ MEJORADO: Sombras adaptadas al tema
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha((0.3 * 255).toInt())
                      : Colors.black.withAlpha((0.15 * 255).toInt()),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ MEJORADO: Logo cuadrado con bordes curvos (no circular)
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Borde giratorio cuadrado con bordes redondeados
                      _RotatingSquare(
                        size: 120,
                        primaryColor: colorScheme.primary,
                        isDarkMode: isDark,
                      ),
                      // Logo con efecto de sombra y bordes curvos
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/icons/icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: colorScheme.primaryContainer,
                                ),
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 50,
                                  color: colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ MEJORADO: Indicador de progreso personalizado
                _AnimatedLoadingBar(primaryColor: colorScheme.primary),

                const SizedBox(height: 28),

                // ✅ MEJORADO: Texto de mensaje con mejor tipografía
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ✅ MEJORADO: Subtítulo informativo
                const SizedBox(height: 8),
                Text(
                  'Por favor espera...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Botón de cancelar (opcional)
                if (widget.dismissible) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

/// ✅ MEJORADO: Borde cuadrado con bordes curvos adaptado al tema
class _RotatingSquare extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final bool isDarkMode;

  const _RotatingSquare({
    required this.size,
    required this.primaryColor,
    required this.isDarkMode,
  });

  @override
  State<_RotatingSquare> createState() => _RotatingSquareState();
}

class _RotatingSquareState extends State<_RotatingSquare>
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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          // ✅ MEJORADO: Cuadrado con bordes redondeados (no circular)
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.primaryColor.withAlpha((0.6 * 255).toInt()),
            width: 3,
          ),
        ),
      ),
    );
  }
}

/// ✅ MEJORADO: Barra de carga animada adaptada al tema
class _AnimatedLoadingBar extends StatefulWidget {
  final Color primaryColor;

  const _AnimatedLoadingBar({required this.primaryColor});

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
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ MEJORADO: Colores adaptados al tema
    final backgroundColor = isDark
        ? Colors.grey[700]!
        : Colors.grey[200]!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 180,
        height: 8,
        child: Container(
          color: backgroundColor,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Barra de fondo
                  Container(
                    color: backgroundColor,
                  ),
                  // ✅ MEJORADO: Barra de progreso con gradiente del tema
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _animation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.primaryColor.withAlpha((0.6 * 255).toInt()),
                              widget.primaryColor,
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
