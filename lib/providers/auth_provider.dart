import 'package:flutter/widgets.dart';
import '../models/models.dart';
import '../models/permissions_response.dart';
import '../services/services.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final WebSocketService _wsService = WebSocketService();
  final BiometricAuthService _biometricService = BiometricAuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricAvailable = false;
  bool _hasFaceRecognition = false;
  bool _hasFingerprintRecognition = false;

  // ✅ NUEVO: Caché de permisos con TTL
  DateTime? _permissionsUpdatedAt;
  int? _cacheTTL;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get biometricAvailable => _biometricAvailable;
  bool get hasFaceRecognition => _hasFaceRecognition;
  bool get hasFingerprintRecognition => _hasFingerprintRecognition;

  // ✅ NUEVO: Getters para caché de permisos
  bool get _isPermissionsCacheValid {
    if (_permissionsUpdatedAt == null || _cacheTTL == null) return false;
    final now = DateTime.now();
    final expiry = _permissionsUpdatedAt!.add(Duration(seconds: _cacheTTL!));
    return now.isBefore(expiry);
  }

  int get minutosRestantesCache {
    if (!_isPermissionsCacheValid) return 0;
    final now = DateTime.now();
    final expiry = _permissionsUpdatedAt!.add(Duration(seconds: _cacheTTL!));
    final diferencia = expiry.difference(now);
    return (diferencia.inSeconds / 60).ceil();
  }

  Future<bool> login(String login, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(login, password);
      debugPrint(
        'Login response: success=${response.success}, data=${response.data != null ? 'not null' : 'null'}',
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        debugPrint('✅ User assigned in login: $_user');
        debugPrint('isLoggedIn: $isLoggedIn');
        _errorMessage = null;

        // ✅ NUEVO: Guardar cache TTL desde la respuesta
        _cacheTTL = response.data!.cacheTtl;
        _permissionsUpdatedAt = DateTime.now();
        debugPrint('✅ Cache TTL guardado: ${_cacheTTL} segundos (${minutosRestantesCache} minutos)');

        // Conectar al WebSocket después de login exitoso
        _connectWebSocket(response.data!.token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        debugPrint('❌ Login failed: ${response.message}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String usernick,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        usernick: usernick,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _errorMessage = null;

        // ✅ NUEVO: Guardar cache TTL desde la respuesta
        _cacheTTL = response.data!.cacheTtl;
        _permissionsUpdatedAt = DateTime.now();
        debugPrint('✅ Cache TTL guardado en registro: ${_cacheTTL} segundos (${minutosRestantesCache} minutos)');

        // Conectar al WebSocket después de registro exitoso
        _connectWebSocket(response.data!.token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadUser() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      debugPrint('🚫 No token found, user not logged in');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📡 Loading user from API...');
      final response = await _authService.getUser();

      if (response.success && response.data != null) {
        _user = response.data;
        _errorMessage = null;

        // Conectar al WebSocket si el usuario se cargó exitosamente
        final token = await _authService.getToken();
        if (token != null) {
          _connectWebSocket(token);
        }

        // ✅ NUEVO: Refrescar permisos si es necesario
        await refreshPermissionsIfNeeded();

        debugPrint('✅ User loaded successfully: ${_user?.name}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        debugPrint('❌ Failed to load user: ${response.message}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('💥 Exception loading user: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      // Asegurar que isLoading siempre se establece a false
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
        debugPrint('🔄 Load user completed, isLoading set to false in finally');
      }
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refreshToken();

      if (response.success) {
        // Token refreshed successfully
        return true;
      } else {
        // Token refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Desconectar del WebSocket antes de hacer logout
      _wsService.disconnect();

      await _authService.logout();
    } catch (e) {
      // Even if logout fails, we clear local data
      debugPrint('❌ Error during logout: $e');
    } finally {
      _user = null;
      _errorMessage = null;
      _isLoading = false;
      // ✅ NUEVO: Limpiar cache TTL al logout
      _permissionsUpdatedAt = null;
      _cacheTTL = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ NUEVO: Refrescar permisos si el caché ha expirado
  /// Útil para mantener permisos actualizados sin hacer logout
  Future<void> refreshPermissionsIfNeeded() async {
    // Si el caché aún es válido, no hacer nada
    if (_isPermissionsCacheValid) {
      debugPrint(
        '✅ Permisos en caché aún válidos (${minutosRestantesCache} minutos restantes)',
      );
      return;
    }

    try {
      debugPrint('🔄 Refrescando permisos desde servidor...');
      final response = await _authService.refreshPermissions();

      if (response.success) {
        // Actualizar permisos del usuario
        if (_user != null) {
          _user!.permissions = response.permissions;
          _user!.roles = response.roles;
          _cacheTTL = response.cacheTtl;
          _permissionsUpdatedAt = DateTime.now();

          debugPrint('✅ Permisos refrescados correctamente');
          debugPrint('   - Permisos: ${response.permissions.length}');
          debugPrint('   - Roles: ${response.roles.length}');
          debugPrint('   - TTL: ${_cacheTTL} segundos');

          notifyListeners();
        }
      } else {
        debugPrint('⚠️ Error refrescando permisos: ${response}');
      }
    } catch (e) {
      debugPrint('⚠️ Excepción refrescando permisos: $e');
      // No lanzar excepción, solo registrar el error
      // El usuario seguirá siendo válido pero con permisos potencialmente desactualizados
    }
  }

  /// Conectar al WebSocket después de autenticación exitosa
  /// Utiliza validación de token Sanctum contra BD de Laravel
  void _connectWebSocket(String token) {
    if (_user == null) {
      debugPrint('⚠️ No se puede conectar al WebSocket sin usuario');
      return;
    }

    // Determinar userType basado en roles del usuario
    final userType = _mapRoleToUserType(_user!.roles);

    debugPrint('🔌 Conectando WebSocket:');
    debugPrint('   - userId: ${_user!.id}');
    debugPrint('   - userName: ${_user!.name}');
    debugPrint('   - userType: $userType');
    debugPrint('   - token: ${token.substring(0, 10)}...');

    // Conectar en segundo plano, no bloquear la UI
    // El servidor validará el token Sanctum contra la BD de PostgreSQL
    _wsService
        .connect(
          token: token, // ⭐ Token Sanctum - Validado en servidor
          userId: _user!.id,
          userType: userType,
        )
        .then((_) {
          debugPrint('✅ WebSocket conectado para usuario ${_user!.name}');
          debugPrint('   Autenticación validada contra BD de Laravel');
        })
        .catchError((error) {
          debugPrint('❌ Error conectando WebSocket: $error');
          // No fallar el login si el WebSocket no se conecta
          // El usuario sigue siendo válido en la app
        });
  }

  /// Mapear roles de Laravel a userType de WebSocket
  String _mapRoleToUserType(List<String>? roles) {
    if (roles == null || roles.isEmpty) {
      return 'client'; // Default
    }

    // Definir jerarquía de roles
    const roleHierarchy = {
      'admin': 'admin',
      'manager': 'manager',
      'manager_de_ruta': 'manager',
      'cobrador': 'cobrador',
      'chofer': 'chofer',
      'client': 'client',
      'cliente': 'client',
    };

    // Buscar el rol de mayor jerarquía
    for (final role in roles) {
      final normalized = role.toLowerCase();
      if (roleHierarchy.containsKey(normalized)) {
        return roleHierarchy[normalized]!;
      }
    }

    return 'client'; // Default si no hay rol conocido
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (_user?.permissions == null) return false;
    return _user!.permissions!.contains(permission);
  }

  // Check if user has specific role
  bool hasRole(String role) {
    if (_user?.roles == null) return false;
    return _user!.roles!.contains(role);
  }

  // Check if user is admin
  bool get isAdmin => hasRole('admin');

  // Check if user can manage products
  bool get canManageProducts =>
      hasPermission('productos.precios.gestionar') ||
      hasPermission('productos.precios.calcular-ganancias') ||
      hasPermission('productos.configuracion-ganancias') ||
      hasRole('admin');

  // Check if user can manage clients (using compras permissions as proxy)
  bool get canManageClients =>
      hasPermission('compras.index') ||
      hasPermission('compras.create') ||
      hasPermission('compras.store') ||
      hasRole('admin');

  // Check if user can create products
  bool get canCreateProducts =>
      hasPermission('productos.precios.gestionar') ||
      hasPermission('productos.configuracion-ganancias') ||
      hasRole('admin');

  // Check if user can create clients
  bool get canCreateClients =>
      hasPermission('compras.create') ||
      hasPermission('compras.store') ||
      hasRole('admin');

  // ========== MÉTODOS DE AUTENTICACIÓN BIOMÉTRICA ==========

  /// Verifica si la autenticación biométrica está disponible en el dispositivo
  Future<void> checkBiometricAvailability() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    _biometricAvailable = canCheck && isSupported;

    debugPrint('🔐 Verificación de biometría:');
    debugPrint('   - canCheckBiometrics: $canCheck');
    debugPrint('   - isDeviceSupported: $isSupported');
    debugPrint('   - _biometricAvailable: $_biometricAvailable');

    if (_biometricAvailable) {
      _hasFaceRecognition = await _biometricService.hasFaceRecognition();
      _hasFingerprintRecognition = await _biometricService.hasFingerprintRecognition();

      debugPrint('✅ Biometría disponible:');
      debugPrint('   - Face ID/Facial: $_hasFaceRecognition');
      debugPrint('   - Huella Digital: $_hasFingerprintRecognition');
    } else {
      debugPrint('⚠️ Biometría NO disponible');
      _hasFaceRecognition = false;
      _hasFingerprintRecognition = false;
    }

    notifyListeners();
  }

  /// Verifica si el login biométrico está habilitado
  Future<bool> isBiometricLoginEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  /// Obtiene el nombre de usuario guardado para mostrar en UI
  Future<String?> getSavedUsername() async {
    return await _biometricService.getSavedUsername();
  }

  /// Habilita el login biométrico guardando las credenciales
  Future<bool> enableBiometricLogin(String username, String password) async {
    return await _biometricService.saveCredentials(
      username: username,
      password: password,
    );
  }

  /// Deshabilita el login biométrico
  Future<bool> disableBiometricLogin() async {
    return await _biometricService.disableBiometric();
  }

  /// Login usando autenticación biométrica
  Future<bool> loginWithBiometrics() async {
    try {
      // Primero verificar si hay credenciales guardadas
      final credentials = await _biometricService.getCredentials();
      if (credentials == null) {
        _errorMessage = 'No hay credenciales guardadas';
        notifyListeners();
        return false;
      }

      // Autenticar con biometría
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Inicia sesión con tu biometría',
      );

      if (!authenticated) {
        _errorMessage = 'Autenticación biométrica fallida';
        notifyListeners();
        return false;
      }

      // Si la autenticación fue exitosa, hacer login normal
      return await login(credentials['username']!, credentials['password']!);
    } catch (e) {
      _errorMessage = 'Error en autenticación biométrica: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el mensaje descriptivo del tipo de biometría
  Future<String> getBiometricTypeMessage() async {
    return await _biometricService.getBiometricTypeMessage();
  }
}
