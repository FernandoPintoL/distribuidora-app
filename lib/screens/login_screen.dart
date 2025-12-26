import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _savedUsername;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Verificar biometría disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricStatus();
    });
  }

  Future<void> _checkBiometricStatus() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkBiometricAvailability();

    if (!mounted) return;

    final biometricEnabled = await authProvider.isBiometricLoginEnabled();
    final savedUsername = await authProvider.getSavedUsername();

    if (mounted) {
      setState(() {
        _biometricAvailable = authProvider.biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _savedUsername = savedUsername;
        if (_savedUsername != null) {
          _loginController.text = _savedUsername!;
        }
      });
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: LoadingOverlay(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
                // Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginCard(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Título
                  _buildHeader(),
                  const SizedBox(height: 40),

                  // Campos de formulario
                  _buildUsernameField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 16),

                  // Recordar contraseña y biometría
                  _buildRememberMeRow(),
                  const SizedBox(height: 16),

                  // Indicador de métodos biométricos disponibles
                  /*  _buildBiometricAvailabilityIndicator(authProvider),
                  const SizedBox(height: 24), */

                  // Mostrar error si existe
                  if (authProvider.errorMessage != null &&
                      authProvider.errorMessage!.isNotEmpty)
                    _buildErrorMessage(authProvider.errorMessage!),

                  const SizedBox(height: 24),

                  // Botón de login
                  _buildLoginButton(authProvider),
                  const SizedBox(height: 16),

                  // Botón de autenticación biométrica
                  if (_biometricAvailable && _biometricEnabled)
                    _buildBiometricButton(authProvider),
                  const SizedBox(height: 24),

                  // Texto de ayuda
                  //_buildHelpText(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo circular con gradiente
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Image(
              image: AssetImage('assets/icons/icon.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Distribuidora Paucara',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        /* Text(
          'Bienvenido de vuelta',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ), */
      ],
    );
  }

  Widget _buildUsernameField() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _loginController,
      decoration: InputDecoration(
        labelText: 'Usuario o Email',
        hintText: 'Ingresa tu usuario',
        prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
        filled: true,
        fillColor: isDarkMode
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode
                ? colorScheme.outline.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su usuario o email';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: isDarkMode
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode
                ? colorScheme.outline.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
    );
  }

  Widget _buildRememberMeRow() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(
          'Recordar mis credenciales',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
        ),
        const Spacer(),
        if (_biometricAvailable && _biometricEnabled)
          Icon(Icons.fingerprint, color: colorScheme.primary, size: 20),
      ],
    );
  }

  Widget _buildBiometricAvailabilityIndicator(AuthProvider authProvider) {
    if (!authProvider.biometricAvailable) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasFace = authProvider.hasFaceRecognition;
    final hasFingerprint = authProvider.hasFingerprintRecognition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Biometría disponible: ${_getBiometricTypesText(hasFace, hasFingerprint)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBiometricTypesText(bool hasFace, bool hasFingerprint) {
    if (hasFace && hasFingerprint) {
      return 'Face ID + Huella';
    } else if (hasFace) {
      return 'Face ID';
    } else if (hasFingerprint) {
      return 'Huella Digital';
    }
    return 'Desconocida';
  }

  Widget _buildErrorMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        ),
        child: const Text(
          'Iniciar Sesión',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AuthProvider authProvider) {
    // Si no hay biometría disponible, no mostrar nada
    if (!authProvider.biometricAvailable) {
      return const SizedBox.shrink();
    }

    final hasFace = authProvider.hasFaceRecognition;
    final hasFingerprint = authProvider.hasFingerprintRecognition;
    final hasBoth = hasFace && hasFingerprint;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        // Si ambos métodos están disponibles, mostrar dos botones
        if (hasBoth) ...[
          _buildBiometricOptionButton(
            label: 'Usar Face ID',
            icon: Icons.face,
            isLoading: authProvider.isLoading,
            onPressed: _loginWithBiometrics,
          ),
          const SizedBox(height: 12),
          _buildBiometricOptionButton(
            label: 'Usar Huella Digital',
            icon: Icons.fingerprint,
            isLoading: authProvider.isLoading,
            onPressed: _loginWithBiometrics,
          ),
        ] else if (hasFace) ...[
          // Si solo Face ID está disponible
          _buildBiometricOptionButton(
            label: 'Usar Face ID',
            icon: Icons.face,
            isLoading: authProvider.isLoading,
            onPressed: _loginWithBiometrics,
          ),
        ] else if (hasFingerprint) ...[
          // Si solo Huella Digital está disponible
          _buildBiometricOptionButton(
            label: 'Usar Huella Digital',
            icon: Icons.fingerprint,
            isLoading: authProvider.isLoading,
            onPressed: _loginWithBiometrics,
          ),
        ],
      ],
    );
  }

  Widget _buildBiometricOptionButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(icon, size: 28, color: colorScheme.primary),
                );
              },
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Olvidaste tu contraseña?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Funcionalidad en desarrollo'),
                backgroundColor: colorScheme.tertiary,
              ),
            );
          },
          child: Text(
            'Recuperar',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _login() async {
    print('🤷‍♂️🤷‍♂️🤷‍♂️🤷‍♂️ Iniciando proceso de login...');
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      // Mostrar el LoadingOverlay
      LoadingOverlay.show(context, message: 'Iniciando sesión...');

      final success = await authProvider.login(
        _loginController.text.trim(),
        _passwordController.text,
      );

      // Ocultar el LoadingOverlay
      LoadingOverlay.hide();

      if (success && _rememberMe && _biometricAvailable) {
        // Guardar credenciales para login biométrico
        await authProvider.enableBiometricLogin(
          _loginController.text.trim(),
          _passwordController.text,
        );
      }
    }
  }

  void _loginWithBiometrics() async {
    final authProvider = context.read<AuthProvider>();

    // Mostrar el LoadingOverlay
    LoadingOverlay.show(context, message: 'Autenticando con biometría...');

    final success = await authProvider.loginWithBiometrics();

    // Ocultar el LoadingOverlay
    LoadingOverlay.hide();

    if (mounted) {
      if (!success && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text(authProvider.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
