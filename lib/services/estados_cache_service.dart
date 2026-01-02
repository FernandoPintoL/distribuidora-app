/// Cache service para Estados usando SharedPreferences
///
/// Implementa una estrategia cache-first con TTL de 7 días.
/// Guarda y recupera estados desde almacenamiento local.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/estado.dart';

class EstadosCacheService {
  static const String _cacheKeyPrefix = 'estados_cache_';
  static const String _timestampKeySuffix = '_timestamp';
  static const int _cacheTtlDays = 7;

  final SharedPreferences _prefs;

  EstadosCacheService(this._prefs);

  /// Guarda un conjunto de estados para una categoría
  Future<void> saveEstados(String categoria, List<Estado> estados) async {
    try {
      final key = _getCacheKey(categoria);
      final jsonList = estados.map((e) => jsonEncode(e.toJson())).toList();

      await Future.wait([
        _prefs.setStringList(key, jsonList),
        _prefs.setInt(_getTimestampKey(categoria), DateTime.now().millisecondsSinceEpoch),
      ]);

      print('[EstadosCacheService] Saved ${estados.length} estados for $categoria');
    } catch (e) {
      print('[EstadosCacheService] Error saving estados: $e');
      rethrow;
    }
  }

  /// Obtiene estados en caché para una categoría
  List<Estado>? getEstados(String categoria) {
    try {
      final key = _getCacheKey(categoria);
      final jsonList = _prefs.getStringList(key);

      if (jsonList == null) return null;

      // Verificar si el caché es válido (no expirado)
      if (!_isCacheValid(categoria)) {
        // Cache expirado, limpiar
        _prefs.remove(key);
        _prefs.remove(_getTimestampKey(categoria));
        return null;
      }

      return jsonList
          .map((json) => Estado.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[EstadosCacheService] Error retrieving estados: $e');
      return null;
    }
  }

  /// Verifica si el caché para una categoría es válido
  bool isCacheValid(String categoria) => _isCacheValid(categoria);

  bool _isCacheValid(String categoria) {
    try {
      final timestampKey = _getTimestampKey(categoria);
      final timestamp = _prefs.getInt(timestampKey);

      if (timestamp == null) return false;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cachedTime);

      return difference.inDays < _cacheTtlDays;
    } catch (e) {
      print('[EstadosCacheService] Error validating cache: $e');
      return false;
    }
  }

  /// Limpia el caché para una categoría específica
  Future<void> clearEstados(String categoria) async {
    try {
      final key = _getCacheKey(categoria);
      await Future.wait([
        _prefs.remove(key),
        _prefs.remove(_getTimestampKey(categoria)),
      ]);
      print('[EstadosCacheService] Cleared cache for $categoria');
    } catch (e) {
      print('[EstadosCacheService] Error clearing cache: $e');
    }
  }

  /// Limpia TODOS los cachés de estados
  Future<void> clearAllEstados() async {
    try {
      final keys = _prefs.getKeys();
      final estadosKeys = keys.where((k) => k.startsWith(_cacheKeyPrefix)).toList();

      for (final key in estadosKeys) {
        await _prefs.remove(key);
      }
      print('[EstadosCacheService] Cleared all estado caches');
    } catch (e) {
      print('[EstadosCacheService] Error clearing all caches: $e');
    }
  }

  /// Obtiene información del caché (para debugging)
  Map<String, dynamic> getCacheInfo(String categoria) {
    try {
      final timestampKey = _getTimestampKey(categoria);
      final timestamp = _prefs.getInt(timestampKey);

      if (timestamp == null) {
        return {
          'cached': false,
          'categoria': categoria,
        };
      }

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cachedTime);
      final isValid = difference.inDays < _cacheTtlDays;

      return {
        'cached': true,
        'categoria': categoria,
        'cachedAt': cachedTime.toIso8601String(),
        'age': '${difference.inDays}d ${difference.inHours.remainder(24)}h',
        'valid': isValid,
        'expiresIn': '${_cacheTtlDays - difference.inDays} days',
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  String _getCacheKey(String categoria) => '$_cacheKeyPrefix$categoria';
  String _getTimestampKey(String categoria) => '$_cacheKeyPrefix$categoria$_timestampKeySuffix';
}
