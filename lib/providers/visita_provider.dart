import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/orden_del_dia.dart';
import '../services/visita_service.dart';

class VisitaProvider with ChangeNotifier {
  final VisitaService _visitaService = VisitaService();

  List<VisitaPreventistaCliente> _visitas = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  Map<String, dynamic>? _estadisticas;

  // ✅ NUEVAS propiedades para Vista de Semana
  ViewMode _viewMode = ViewMode.day;
  DateTime _fechaSeleccionada = DateTime.now();
  Map<String, OrdenDelDia> _ordenesCache = {};
  SemanaOrdenDelDia? _semanaCache;

  // ✅ NUEVAS propiedades para Filtro de Localidad
  int? _localidadSeleccionada;
  List<Localidad> _localidades = [];

  // Getters
  List<VisitaPreventistaCliente> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;
  Map<String, dynamic>? get estadisticas => _estadisticas;

  // ✅ NUEVOS getters para Vista de Semana
  ViewMode get viewMode => _viewMode;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  SemanaOrdenDelDia? get semanaCache => _semanaCache;

  // ✅ NUEVOS getters para Filtro de Localidad
  int? get localidadSeleccionada => _localidadSeleccionada;
  List<Localidad> get localidades => _localidades;

  /// Registrar nueva visita
  Future<bool> registrarVisita({
    required int clienteId,
    required DateTime fechaHoraVisita,
    required TipoVisitaPreventista tipoVisita,
    required EstadoVisitaPreventista estadoVisita,
    MotivoNoAtencionVisita? motivoNoAtencion,
    required double latitud,
    required double longitud,
    File? fotoLocal,
    String? observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _visitaService.registrarVisita(
        clienteId: clienteId,
        fechaHoraVisita: fechaHoraVisita,
        tipoVisita: tipoVisita,
        estadoVisita: estadoVisita,
        motivoNoAtencion: motivoNoAtencion,
        latitud: latitud,
        longitud: longitud,
        fotoLocal: fotoLocal,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        // Agregar al inicio de la lista
        _visitas.insert(0, response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al registrar visita';
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

  /// Cargar visitas (con paginación)
  Future<void> cargarVisitas({
    bool refresh = false,
    String? fechaInicio,
    String? fechaFin,
    EstadoVisitaPreventista? estadoVisita,
    TipoVisitaPreventista? tipoVisita,
    int? clienteId,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _visitas.clear();
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _visitaService.obtenerMisVisitas(
        page: _currentPage,
        perPage: 20,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estadoVisita: estadoVisita,
        tipoVisita: tipoVisita,
        clienteId: clienteId,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          _visitas = response.data!.data;
        } else {
          _visitas.addAll(response.data!.data);
        }

        final currentPage = response.data!.currentPage ?? 1;
        final lastPage = response.data!.lastPage ?? 1;
        _currentPage = currentPage + 1;
        _hasMorePages = currentPage < lastPage;
      } else {
        _errorMessage = response.message ?? 'Error al cargar visitas';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar estadísticas
  Future<void> cargarEstadisticas({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final response = await _visitaService.obtenerEstadisticas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (response.success && response.data != null) {
        _estadisticas = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
    }
  }

  /// Validar horario de cliente
  Future<Map<String, dynamic>?> validarHorarioCliente(int clienteId) async {
    try {
      final response = await _visitaService.validarHorario(clienteId);

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error al validar horario: $e');
      return null;
    }
  }

  /// ✅ MEJORADO: Obtener orden del día (con parámetro fecha opcional)
  Future<OrdenDelDia?> obtenerOrdenDelDia({DateTime? fecha}) async {
    try {
      final fechaStr = fecha?.toIso8601String().split('T')[0];
      final cacheKey = fechaStr ?? 'hoy';

      // Verificar caché primero
      if (_ordenesCache.containsKey(cacheKey)) {
        return _ordenesCache[cacheKey];
      }

      final response = await _visitaService.obtenerOrdenDelDia(fecha: fechaStr);

      if (response.success && response.data != null) {
        _ordenesCache[cacheKey] = response.data!;
        return response.data;
      } else {
        _errorMessage = response.message ?? 'Error al cargar orden del día';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      debugPrint('Error al obtener orden del día: $e');
      return null;
    }
  }

  /// ✅ NUEVO: Obtener semana completa (7 días)
  Future<SemanaOrdenDelDia?> obtenerOrdenDelDiaSemana(
      {DateTime? fechaInicio, DateTime? fechaFin}) async {
    try {
      // Si hay caché y no se especifican fechas, retornar caché
      if (_semanaCache != null && fechaInicio == null && fechaFin == null) {
        return _semanaCache;
      }

      final response = await _visitaService.obtenerOrdenDelDiaSemana(
        fechaInicio: fechaInicio?.toIso8601String().split('T')[0],
        fechaFin: fechaFin?.toIso8601String().split('T')[0],
      );

      if (response.success && response.data != null) {
        _semanaCache = response.data;
        return response.data;
      } else {
        _errorMessage =
            response.message ?? 'Error al cargar orden del día de la semana';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      debugPrint('Error al obtener orden del día semana: $e');
      return null;
    }
  }

  /// ✅ NUEVO: Cambiar fecha seleccionada
  void seleccionarFecha(DateTime fecha) {
    _fechaSeleccionada = fecha;
    notifyListeners();
  }

  /// ✅ NUEVO: Cambiar modo de vista (Día/Semana)
  void cambiarModoVista(ViewMode modo) {
    _viewMode = modo;
    notifyListeners();
  }

  /// ✅ NUEVO: Invalidar caché (después de cambios)
  void invalidarCache() {
    _ordenesCache.clear();
    _semanaCache = null;
    notifyListeners();
  }

  /// ✅ NUEVO: Cambiar localidad seleccionada
  void cambiarLocalidad(int? localidadId) {
    _localidadSeleccionada = localidadId;
    notifyListeners();
  }

  /// ✅ NUEVO: Cargar localidades desde la orden del día
  void cargarLocalidadesDesdeOrden(OrdenDelDia orden) {
    final localidadesSet = <int, Localidad>{};

    for (var cliente in orden.clientes) {
      if (cliente.localidad != null) {
        localidadesSet[cliente.localidad!.id] = cliente.localidad!;
      }
    }

    _localidades = localidadesSet.values.toList();
    _localidades.sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();
  }

  /// ✅ NUEVO: Obtener clientes filtrados por localidad
  List<ClienteOrdenDelDia> obtenerClientesFiltrados(List<ClienteOrdenDelDia> clientes) {
    if (_localidadSeleccionada == null) {
      return clientes;
    }

    return clientes
        .where((cliente) => cliente.localidad?.id == _localidadSeleccionada)
        .toList();
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// ✅ NUEVO: Enum para modo de vista
enum ViewMode { day, week, horarios }
