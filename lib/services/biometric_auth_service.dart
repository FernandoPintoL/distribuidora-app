import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para gestionar la autenticación biométrica (huella digital, Face ID, etc.)
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys para almacenamiento seguro
  static const String _keyUsername = 'biometric_username';
  static const String _keyPassword = 'biometric_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  /// Verifica si el dispositivo tiene capacidades biométricas
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      _debugPrint('Error checking biometrics: ${e.message}');
      return false;
    }
  }

  /// Verifica si el dispositivo está inscrito con biometría
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      _debugPrint('Error checking device support: ${e.message}');
      return false;
    }
  }

  /// Obtiene la lista de biometrías disponibles (huella, cara, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      _debugPrint('Error getting available biometrics: ${e.message}');
      return [];
    }
  }

  /// Intenta autenticar usando biometría
  Future<bool> authenticate({
    String localizedReason = 'Por favor autentícate para iniciar sesión',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        _debugPrint('Usuario no tiene biometría configurada');
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        _debugPrint('Autenticación bloqueada temporalmente');
      } else {
        _debugPrint('Error durante autenticación: ${e.message}');
      }
      return false;
    }
  }

  /// Guarda las credenciales de forma segura para login biométrico
  Future<bool> saveCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _keyUsername, value: username);
      await _secureStorage.write(key: _keyPassword, value: password);
      await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');
      return true;
    } catch (e) {
      _debugPrint('Error saving credentials: $e');
      return false;
    }
  }

  /// Obtiene las credenciales guardadas (requiere autenticación biométrica)
  Future<Map<String, String>?> getCredentials() async {
    try {
      final username = await _secureStorage.read(key: _keyUsername);
      final password = await _secureStorage.read(key: _keyPassword);

      if (username != null && password != null) {
        return {
          'username': username,
          'password': password,
        };
      }
      return null;
    } catch (e) {
      _debugPrint('Error getting credentials: $e');
      return null;
    }
  }

  /// Verifica si el login biométrico está habilitado
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _keyBiometricEnabled);
      return enabled == 'true';
    } catch (e) {
      _debugPrint('Error checking biometric enabled: $e');
      return false;
    }
  }

  /// Obtiene el nombre de usuario guardado (para mostrar en UI)
  Future<String?> getSavedUsername() async {
    try {
      return await _secureStorage.read(key: _keyUsername);
    } catch (e) {
      _debugPrint('Error getting saved username: $e');
      return null;
    }
  }

  /// Deshabilita el login biométrico y elimina las credenciales
  Future<bool> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _keyUsername);
      await _secureStorage.delete(key: _keyPassword);
      await _secureStorage.delete(key: _keyBiometricEnabled);
      return true;
    } catch (e) {
      _debugPrint('Error disabling biometric: $e');
      return false;
    }
  }

  /// Obtiene un mensaje descriptivo del tipo de biometría disponible
  Future<String> getBiometricTypeMessage() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'Autenticación biométrica';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Huella Digital';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Autenticación biométrica';
    }
  }

  /// Obtiene el icono apropiado según el tipo de biometría
  String getBiometricIcon() {
    // Este método puede ser expandido para retornar diferentes iconos
    // según el tipo de biometría disponible
    return 'fingerprint'; // Por defecto huella
  }

  /// Función de debug privada
  void _debugPrint(String message) {
    // ignore: avoid_print
    print('[BiometricAuth] $message');
  }
}
