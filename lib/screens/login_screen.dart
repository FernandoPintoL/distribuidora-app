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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
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
                Theme.of(context).colorScheme.secondary,
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
                  _buildBiometricAvailabilityIndicator(authProvider),
                  const SizedBox(height: 24),

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
            )
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Distribuidora Paucara',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenido de vuelta',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _loginController,
      decoration: InputDecoration(
        labelText: 'Usuario o Email',
        hintText: 'Ingresa tu usuario',
        prefixIcon: Icon(
          Icons.person_outline,
          color: Theme.of(context).primaryColor,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
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
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
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
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Text(
          'Recordar mis credenciales',
          style: TextStyle(fontSize: 14),
        ),
        const Spacer(),
        if (_biometricAvailable && _biometricEnabled)
          Icon(
            Icons.fingerprint,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildBiometricAvailabilityIndicator(AuthProvider authProvider) {
    if (!authProvider.biometricAvailable) {
      return const SizedBox.shrink();
    }

    final hasFace = authProvider.hasFaceRecognition;
    final hasFingerprint = authProvider.hasFingerprintRecognition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.blue.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Biometría disponible: ${_getBiometricTypesText(hasFace, hasFingerprint)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        ),
        child: const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
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
        ]
      ],
    );
  }

  Widget _buildBiometricOptionButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
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
                  child: Icon(
                    icon,
                    size: 28,
                    color: Theme.of(context).primaryColor,
                  ),
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
                  color: Theme.of(context).primaryColor,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Implementar recuperación de contraseña
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad en desarrollo'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: Text(
            'Recuperar',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _login() async {
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
                Expanded(
                  child: Text(authProvider.errorMessage!),
                ),
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
