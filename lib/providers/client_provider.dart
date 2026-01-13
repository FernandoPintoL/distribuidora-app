import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/services.dart';

class ClientProvider with ChangeNotifier {
  final ClientService _clientService = ClientService();

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMorePages = true;

  // Getters
  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMorePages => _hasMorePages;

  // Helper method for safe _safeNotifyListeners
  void _safeNotifyListeners() {
    // Solo notificar si hay listeners activos
    if (hasListeners) {
      Future.delayed(Duration.zero, () {
        // Verificar nuevamente antes de notificar
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  Future<bool> loadClients({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? active,
    bool append = false,
  }) async {
    // Prevenir llamadas simultáneas
    if (_isLoading && !append) return false;

    if (!append) {
      _isLoading = true;
      _clients = [];
      _currentPage = 1;
    }
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.getClients(
        page: page,
        perPage: perPage,
        search: search,
        active: active,
      );

      debugPrint('🔄 loadClients ${response.data}');

      if (response.success && response.data != null) {
        if (append) {
          _clients.addAll(response.data!.data);
        } else {
          _clients = response.data!.data;
        }

        _currentPage = response.data!.currentPage;
        _totalPages = (response.data!.total / perPage).ceil();
        _totalItems = response.data!.total;
        _hasMorePages = _currentPage < _totalPages;
        _errorMessage = null;

        print('📋 Clientes cargados: ${_clients.length}');
        print('📋 Página actual: $_currentPage, Total páginas: $_totalPages');

        // Solo notificar una vez al final
        return true;
      } else {
        _errorMessage = response.message;
        // Solo notificar una vez al final
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // Solo notificar una vez al final
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final del método
      _safeNotifyListeners();
    }
  }

  Future<bool> loadMoreClients({String? search, bool? active}) async {
    if (!_hasMorePages || _isLoading) return false;

    return loadClients(
      page: _currentPage + 1,
      search: search,
      active: active,
      append: true,
    );
  }

  Future<List<Client>> searchClients(String query, {int limit = 10}) async {
    try {
      final response = await _clientService.searchClients(query, limit: limit);

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Client?> getClient(int id) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.getClient(id);

      if (response.success && response.data != null) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return response.data;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return null;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  /// Obtener perfil del cliente autenticado
  /// Usa el endpoint /api/clientes/mi-perfil que no requiere permisos especiales
  /// Retorna el perfil completo con direcciones, categorías y ventanas de entrega
  Future<Client?> getClientPerfil() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await _clientService.getClientPerfil();

      if (response.success && response.data != null) {
        _errorMessage = null;
        return response.data;
      } else {
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// ✅ NUEVO: Cargar datos desde las estadísticas del preventista obtenidas en el login
  /// Esto permite que el dashboard tenga datos iniciales sin hacer llamadas adicionales
  void loadClientsFromPreventistaStats(PreventistStats stats) {
    try {
      // Convertir ClienteBasico a Client
      // Nota: Esto crea clientes con datos básicos del login incluyendo crédito
      _clients = stats.clientesParaReactivar
          .map(
            (clienteBasico) => Client(
              id: clienteBasico.id,
              nombre: clienteBasico.nombre,
              razonSocial: clienteBasico.razonSocial,
              telefono: clienteBasico.telefono,
              email: clienteBasico.email,
              activo: clienteBasico.activo,
              nit: null,
              fotoPerfil: null,
              limiteCredito: clienteBasico.limiteCredito,
              puedeAtenerCredito: clienteBasico.puedeAtenerCredito,
              fechaRegistro: null,
              localidad: null,
              direcciones: [],
              ventanasEntrega: [],
              categorias: [],
            ),
          )
          .toList();

      _totalItems = stats.totalClientes;
      _currentPage = 1;
      _totalPages = 1;
      _hasMorePages = false;
      _errorMessage = null;

      print('✅ Clientes cargados desde PreventistStats: ${_clients.length}');
      print('   Total de clientes: ${stats.totalClientes}');
      print('   Clientes activos: ${stats.clientesActivos}');
      print('   Clientes inactivos: ${stats.clientesInactivos}');

      _safeNotifyListeners();
    } catch (e) {
      print('❌ Error al cargar clientes desde stats: $e');
      _errorMessage = 'Error al cargar estadísticas del preventista';
      _safeNotifyListeners();
    }
  }

  Future<bool> createClient({
    required String nombre,
    String? razonSocial,
    String? nit,
    String? email,
    String? telefono,
    double? limiteCredito,
    bool puedeAtenerCredito = false,
    int? localidadId,
    double? latitud,
    double? longitud,
    bool activo = true,
    String? observaciones,
    List<ClientAddress>? direcciones,
    List<VentanaEntregaCliente>? ventanasEntrega,
    List<int>? categoriasIds,
    bool? crearUsuario,
    String? password,
    File? fotoPerfil,
    File? ciAnverso,
    File? ciReverso,
  }) async {
    // Prevenir llamadas simultáneas
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.createClient(
        nombre: nombre,
        razonSocial: razonSocial,
        nit: nit,
        email: email,
        telefono: telefono,
        limiteCredito: limiteCredito,
        puedeAtenerCredito: puedeAtenerCredito,
        localidadId: localidadId,
        latitud: latitud,
        longitud: longitud,
        activo: activo,
        observaciones: observaciones,
        direcciones: direcciones,
        ventanasEntrega: ventanasEntrega,
        categoriasIds: categoriasIds,
        crearUsuario: crearUsuario,
        password: password,
        fotoPerfil: fotoPerfil,
        ciAnverso: ciAnverso,
        ciReverso: ciReverso,
      );

      if (response.success && response.data != null) {
        _clients.insert(0, response.data!);
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> updateClient(
    int id, {
    String? nombre,
    String? razonSocial,
    String? nit,
    String? email,
    String? telefono,
    double? limiteCredito,
    bool? puedeAtenerCredito,
    int? localidadId,
    double? latitud,
    double? longitud,
    bool? activo,
    String? observaciones,
    List<ClientAddress>? direcciones,
    List<VentanaEntregaCliente>? ventanasEntrega,
    List<int>? categoriasIds,
    bool? crearUsuario,
    File? fotoPerfil,
    File? ciAnverso,
    File? ciReverso,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.updateClient(
        id,
        nombre: nombre,
        razonSocial: razonSocial,
        nit: nit,
        email: email,
        telefono: telefono,
        limiteCredito: limiteCredito,
        puedeAtenerCredito: puedeAtenerCredito,
        localidadId: localidadId,
        latitud: latitud,
        longitud: longitud,
        activo: activo,
        observaciones: observaciones,
        direcciones: direcciones,
        ventanasEntrega: ventanasEntrega,
        categoriasIds: categoriasIds,
        crearUsuario: crearUsuario,
        fotoPerfil: fotoPerfil,
        ciAnverso: ciAnverso,
        ciReverso: ciReverso,
      );

      if (response.success && response.data != null) {
        final index = _clients.indexWhere((c) => c.id == id);
        if (index != -1) {
          _clients[index] = response.data!;
        }
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> deleteClient(int id) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.deleteClient(id);

      if (response.success) {
        _clients.removeWhere((c) => c.id == id);
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void clearClients() {
    _clients = [];
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMorePages = true;
    _errorMessage = null;
  }

  // Gestión de direcciones
  Future<List<ClientAddress>?> getClientAddresses(int clientId) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.getClientAddresses(clientId);

      if (response.success && response.data != null) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return response.data;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return null;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> createClientAddress(
    int clientId, {
    required String direccion,
    String? observaciones,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    double? latitud,
    double? longitud,
    int? localidadId,
    bool esPrincipal = false,
    bool activa = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.createClientAddress(
        clientId,
        direccion: direccion,
        observaciones: observaciones,
        ciudad: ciudad,
        departamento: departamento,
        codigoPostal: codigoPostal,
        latitud: latitud,
        longitud: longitud,
        localidadId: localidadId,
        esPrincipal: esPrincipal,
        activa: activa,
      );

      if (response.success) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> updateClientAddress(
    int clientId,
    int addressId, {
    String? direccion,
    String? observaciones,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    double? latitud,
    double? longitud,
    int? localidadId,
    bool? esPrincipal,
    bool? activa,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.updateClientAddress(
        clientId,
        addressId,
        direccion: direccion,
        observaciones: observaciones,
        ciudad: ciudad,
        departamento: departamento,
        codigoPostal: codigoPostal,
        latitud: latitud,
        longitud: longitud,
        localidadId: localidadId,
        esPrincipal: esPrincipal,
        activa: activa,
      );

      if (response.success) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> deleteClientAddress(int clientId, int addressId) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.deleteClientAddress(
        clientId,
        addressId,
      );

      if (response.success) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> setPrincipalAddress(int clientId, int addressId) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.setPrincipalAddress(
        clientId,
        addressId,
      );

      if (response.success) {
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  // Información adicional del cliente
  Future<Map<String, dynamic>?> getClientBalance(int clientId) async {
    try {
      final response = await _clientService.getClientBalance(clientId);

      if (response.success && response.data != null) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getClientSalesHistory(
    int clientId,
  ) async {
    try {
      final response = await _clientService.getClientSalesHistory(clientId);

      if (response.success && response.data != null) {
        return response.data;
      } else {
        debugPrint('Error en getClientSalesHistory: ${response.message}');
        return [];
      }
    } catch (e) {
      debugPrint('Excepción en getClientSalesHistory: ${e.toString()}');
      return [];
    }
  }

  // Catálogo de categorías de cliente
  List<CategoriaCliente> _categoriasCliente = [];
  List<CategoriaCliente> get categoriasCliente => _categoriasCliente;

  Future<bool> loadCategoriasCliente() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final response = await _clientService.getCategoriasCliente();
      if (response.success && response.data != null) {
        _categoriasCliente = response.data!;
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Gestión de localidades
  List<Localidad> _localidades = [];

  List<Localidad> get localidades => _localidades;

  Future<bool> loadLocalidades() async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.getLocalidades();

      if (response.success && response.data != null) {
        _localidades = response.data!;
        debugPrint(
          '✅ Localidades asignadas correctamente: ${_localidades.length} items',
        );
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        debugPrint('❌ Error en respuesta: ${response.message}');
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error inesperado en loadLocalidades: ${e.toString()}');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> createLocalidad({
    required String nombre,
    required String codigo,
    bool activo = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.createLocalidad(
        nombre: nombre,
        codigo: codigo,
        activo: activo,
      );

      if (response.success && response.data != null) {
        _localidades.add(response.data!);
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> updateLocalidad(
    int id, {
    String? nombre,
    String? codigo,
    bool? activo,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.updateLocalidad(
        id,
        nombre: nombre,
        codigo: codigo,
        activo: activo,
      );

      if (response.success && response.data != null) {
        final index = _localidades.indexWhere((l) => l.id == id);
        if (index != -1) {
          _localidades[index] = response.data!;
        }
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }

  Future<bool> deleteLocalidad(int id) async {
    _isLoading = true;
    _errorMessage = null;

    // No notificar al inicio, solo al final

    try {
      final response = await _clientService.deleteLocalidad(id);

      if (response.success) {
        _localidades.removeWhere((l) => l.id == id);
        _errorMessage = null;
        // No notificar aquí, se hará en finally
        return true;
      } else {
        _errorMessage = response.message;
        // No notificar aquí, se hará en finally
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      // No notificar aquí, se hará en finally
      return false;
    } finally {
      _isLoading = false;
      // Solo notificar una vez al final
      _safeNotifyListeners();
    }
  }
}
