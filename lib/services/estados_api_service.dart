/// API Service para consumir Estados desde el backend
///
/// Maneja las llamadas HTTP a los endpoints de estados.
/// Incluye manejo de errores y logging.

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/estado.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EstadosApiService {
  final http.Client httpClient;
  final FlutterSecureStorage secureStorage;

  late String _baseUrl;
  late String _authToken;

  EstadosApiService({
    required this.httpClient,
    required this.secureStorage,
    String? baseUrl,
  }) {
    _baseUrl = baseUrl ?? _getDefaultBaseUrl();
  }

  /// Obtiene la URL base desde .env o usa default
  static String _getDefaultBaseUrl() {
    if (dotenv.env.isEmpty) {
      // Cargar si no está cargado
      try {
        dotenv.load(fileName: ".env");
      } catch (e) {
        print('[EstadosApiService] Error loading .env: $e');
      }
    }
    final url = dotenv.env['BASE_URL'] ?? 'http://192.168.100.21:8000/api';
    print('[EstadosApiService] Using BASE_URL: $url');
    return url;
  }

  /// Obtiene todas las categorías disponibles
  Future<List<String>> getCategorias() async {
    try {
      await _ensureAuth();
      final response = await httpClient.get(
        Uri.parse('$_baseUrl/api/estados/categorias'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final categorias = (data['data'] as List)
            .map((c) => (c as Map<String, dynamic>)['codigo'] as String)
            .toList();
        print('[EstadosApiService] Fetched ${categorias.length} categorías');
        return categorias;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Token may have expired.');
      } else {
        throw Exception('Failed to fetch categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('[EstadosApiService] Error fetching categorías: $e');
      rethrow;
    }
  }

  /// Obtiene todos los estados para una categoría
  Future<List<Estado>> getEstadosPorCategoria(String categoria) async {
    try {
      await _ensureAuth();
      final response = await httpClient.get(
        Uri.parse('$_baseUrl/api/estados/$categoria'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final estados = (data['data'] as List)
            .map((e) => Estado.fromJson(e as Map<String, dynamic>))
            .toList();
        print('[EstadosApiService] Fetched ${estados.length} estados for $categoria');
        return estados;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Token may have expired.');
      } else if (response.statusCode == 404) {
        print('[EstadosApiService] No estados found for $categoria');
        return [];
      } else {
        throw Exception('Failed to fetch estados: ${response.statusCode}');
      }
    } catch (e) {
      print('[EstadosApiService] Error fetching estados for $categoria: $e');
      rethrow;
    }
  }

  /// Obtiene un estado específico por código
  Future<Estado> getEstadoPorCodigo(String categoria, String codigo) async {
    try {
      await _ensureAuth();
      final response = await httpClient.get(
        Uri.parse('$_baseUrl/api/estados/$categoria/$codigo'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final estado = Estado.fromJson(data['data'] as Map<String, dynamic>);
        return estado;
      } else if (response.statusCode == 404) {
        throw Exception('Estado not found: $categoria/$codigo');
      } else {
        throw Exception('Failed to fetch estado: ${response.statusCode}');
      }
    } catch (e) {
      print('[EstadosApiService] Error fetching estado $codigo from $categoria: $e');
      rethrow;
    }
  }

  /// Obtiene todos los estados para todas las categorías
  Future<Map<String, List<Estado>>> getAllEstados() async {
    try {
      final categorias = await getCategorias();
      final result = <String, List<Estado>>{};

      for (final categoria in categorias) {
        try {
          result[categoria] = await getEstadosPorCategoria(categoria);
        } catch (e) {
          print('[EstadosApiService] Error fetching $categoria: $e');
          result[categoria] = [];
        }
      }

      return result;
    } catch (e) {
      print('[EstadosApiService] Error fetching all estados: $e');
      rethrow;
    }
  }

  /// Asegura que tenemos un token válido
  Future<void> _ensureAuth() async {
    _authToken = (await secureStorage.read(key: 'auth_token')) ?? '';
    if (_authToken.isEmpty) {
      throw Exception('No authentication token found');
    }
  }

  /// Obtiene headers para las peticiones HTTP
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }
}
