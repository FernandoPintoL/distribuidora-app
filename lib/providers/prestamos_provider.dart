import 'package:flutter/material.dart';
import '../models/prestamo_cliente.dart';
import '../models/prestamo_evento.dart';
import '../models/prestamo_proveedor.dart';
import '../models/prestamos_cliente_response.dart';
import '../models/prestamos_evento_response.dart';
import '../models/prestamos_proveedor_response.dart';
import '../services/api_service.dart';

class PrestamosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PrestamoCliente> _prestamosClientes = [];
  List<PrestamoEvento> _prestamosEventos = [];
  List<PrestamoProveedor> _prestamosProveedores = [];

  bool _loadingClientes = false;
  bool _loadingEventos = false;
  bool _loadingProveedores = false;

  String? _error;

  // Getters
  List<PrestamoCliente> get prestamosClientes => _prestamosClientes;
  List<PrestamoEvento> get prestamosEventos => _prestamosEventos;
  List<PrestamoProveedor> get prestamosProveedores => _prestamosProveedores;

  bool get loadingClientes => _loadingClientes;
  bool get loadingEventos => _loadingEventos;
  bool get loadingProveedores => _loadingProveedores;

  bool get isLoading =>
      _loadingClientes || _loadingEventos || _loadingProveedores;
  String? get error => _error;

  /// Obtener total de préstamos pendientes
  int get totalPrestamos =>
      _prestamosClientes.length +
      _prestamosEventos.length +
      _prestamosProveedores.length;

  /// Cargar préstamos - Si choferId es 0, obtiene del token JWT
  Future<void> cargarPrestamosDelChofer(int choferId) async {
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _cargarPrestamosClientes(choferId),
        _cargarPrestamosEventos(choferId),
        _cargarPrestamosProveedores(choferId),
      ]);

      debugPrint(
        '✅ Todos los préstamos cargados: C=${_prestamosClientes.length}, E=${_prestamosEventos.length}, P=${_prestamosProveedores.length}',
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando préstamos: $e';
      debugPrint('❌ Error: $e');
      notifyListeners();
    }
  }

  /// Cargar préstamos a clientes asignados al chofer
  Future<void> _cargarPrestamosClientes(int choferId) async {
    _loadingClientes = true;
    notifyListeners();

    try {
      // ✅ REFACTORIZADO: Si choferId es 0, no enviar parámetro (backend obtiene del token)
      final queryParams = choferId != 0 ? {'chofer_id': choferId} : null;
      final response = await _apiService.get(
        '/prestamos-cliente',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        try {
          final responseData = PrestamosClienteResponse.fromJson(response.data);
          _prestamosClientes = responseData.data.prestamos;
          debugPrint(
            '✅ _prestamosClientes cargados: ${_prestamosClientes.length} items',
          );
        } catch (e) {
          debugPrint('❌ Error mapeando prestamos clientes: $e');
          _prestamosClientes = [];
          _error = 'Error procesando préstamos de clientes';
        }
      } else {
        _error = 'Error cargando préstamos a clientes';
        debugPrint('❌ Error status: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ Exception: $e');
    } finally {
      _loadingClientes = false;
      notifyListeners();
    }
  }

  /// Cargar préstamos a eventos asignados al chofer
  Future<void> _cargarPrestamosEventos(int choferId) async {
    _loadingEventos = true;
    notifyListeners();

    try {
      // ✅ REFACTORIZADO: Si choferId es 0, no enviar parámetro (backend obtiene del token)
      final queryParams = choferId != 0 ? {'chofer_id': choferId} : null;
      final response = await _apiService.get(
        '/prestamos-evento',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        try {
          final responseData = PrestamosEventoResponse.fromJson(response.data);
          _prestamosEventos = responseData.data.prestamos;
          debugPrint(
            '✅ _prestamosEventos cargados: ${_prestamosEventos.length} items',
          );
        } catch (e) {
          debugPrint('❌ Error mapeando prestamos eventos: $e');
          _prestamosEventos = [];
          _error = 'Error procesando préstamos de eventos';
        }
      } else {
        _error = 'Error cargando préstamos a eventos';
        debugPrint('❌ Error status: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ Exception: $e');
    } finally {
      _loadingEventos = false;
      notifyListeners();
    }
  }

  /// Cargar préstamos a proveedores asignados al chofer
  Future<void> _cargarPrestamosProveedores(int choferId) async {
    _loadingProveedores = true;
    notifyListeners();

    try {
      // ✅ REFACTORIZADO: Si choferId es 0, no enviar parámetro (backend obtiene del token)
      final queryParams = choferId != 0 ? {'chofer_id': choferId} : null;
      final response = await _apiService.get(
        '/prestamos-proveedor',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        try {
          final responseData = PrestamosProveedorResponse.fromJson(
            response.data,
          );
          _prestamosProveedores = responseData.data.prestamos;
          debugPrint(
            '✅ _prestamosProveedores cargados: ${_prestamosProveedores.length} items',
          );
        } catch (e) {
          debugPrint('❌ Error mapeando prestamos proveedores: $e');
          _prestamosProveedores = [];
          _error = 'Error procesando préstamos de proveedores';
        }
      } else {
        _error = 'Error cargando préstamos a proveedores';
        debugPrint('❌ Error status: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ Exception: $e');
    } finally {
      _loadingProveedores = false;
      notifyListeners();
    }
  }

  /// Registrar devolución de cliente
  Future<bool> registrarDevolucionCliente(
    int prestamoId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.post(
        '/prestamos-cliente/$prestamoId/devolver',
        data: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _prestamosClientes.removeWhere((p) => p.id == prestamoId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error registrando devolución: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registrar devolución de evento
  Future<bool> registrarDevolucionEvento(
    int prestamoId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.post(
        '/prestamos-evento/$prestamoId/devolver',
        data: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _prestamosEventos.removeWhere((p) => p.id == prestamoId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error registrando devolución: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registrar devolución de proveedor
  Future<bool> registrarDevolucionProveedor(
    int prestamoId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiService.post(
        '/prestamos-proveedor/$prestamoId/devolver',
        data: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _prestamosProveedores.removeWhere((p) => p.id == prestamoId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error registrando devolución: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpiar errores
  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
