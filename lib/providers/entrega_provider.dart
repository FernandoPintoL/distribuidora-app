import 'package:flutter/widgets.dart';
import '../models/entrega.dart';
import '../models/ubicacion_tracking.dart';
import '../services/entrega_service.dart';

class EntregaProvider with ChangeNotifier {
  final EntregaService _entregaService = EntregaService();

  List<Entrega> _entregas = [];
  Entrega? _entregaActual;
  List<UbicacionTracking> _ubicaciones = [];
  UbicacionTracking? _ubicacionActual;
  List<EntregaEstadoHistorial> _historialEstados = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Entrega> get entregas => _entregas;
  Entrega? get entregaActual => _entregaActual;
  List<UbicacionTracking> get ubicaciones => _ubicaciones;
  UbicacionTracking? get ubicacionActual => _ubicacionActual;
  List<EntregaEstadoHistorial> get historialEstados => _historialEstados;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtener entregas asignadas
  Future<bool> obtenerEntregasAsignadas({
    int page = 1,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.obtenerEntregasAsignadas(
        page: page,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      if (response.success && response.data != null) {
        _entregas = response.data!;
        _errorMessage = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Obtener detalle de una entrega
  Future<bool> obtenerEntrega(int entregaId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.obtenerEntrega(entregaId);

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _errorMessage = null;

        // Cargar ubicaciones y historial
        await Future.wait([
          obtenerUbicaciones(entregaId),
          obtenerHistorialEstados(entregaId),
        ]);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Iniciar ruta
  Future<bool> iniciarRuta(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.iniciarRuta(
        entregaId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Marcar llegada
  Future<bool> marcarLlegada(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.marcarLlegada(
        entregaId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Confirmar entrega
  Future<bool> confirmarEntrega(
    int entregaId, {
    required String firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.confirmarEntrega(
        entregaId,
        firmaBase64: firmaBase64,
        fotosBase64: fotosBase64,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Reportar novedad
  Future<bool> reportarNovedad(
    int entregaId, {
    required String motivo,
    String? descripcion,
    String? fotoBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.reportarNovedad(
        entregaId,
        motivo: motivo,
        descripcion: descripcion,
        fotoBase64: fotoBase64,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Registrar ubicación
  Future<bool> registrarUbicacion(
    int entregaId, {
    required double latitud,
    required double longitud,
    double? velocidad,
    double? rumbo,
    double? altitud,
    double? precision,
    String? evento,
  }) async {
    try {
      final response = await _entregaService.registrarUbicacion(
        entregaId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        rumbo: rumbo,
        altitud: altitud,
        precision: precision,
        evento: evento,
      );

      if (response.success && response.data != null) {
        _ubicacionActual = response.data;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener ubicaciones
  Future<bool> obtenerUbicaciones(int entregaId) async {
    try {
      final response = await _entregaService.obtenerUbicaciones(entregaId);

      if (response.success && response.data != null) {
        _ubicaciones = response.data!;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener última ubicación
  Future<bool> obtenerUltimaUbicacion(int entregaId) async {
    try {
      final response = await _entregaService.obtenerUltimaUbicacion(entregaId);

      if (response.success && response.data != null) {
        _ubicacionActual = response.data;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Calcular ETA
  Future<bool> calcularETA(
    int entregaId, {
    required double latDestino,
    required double lngDestino,
  }) async {
    try {
      final response = await _entregaService.calcularETA(
        entregaId,
        latDestino: latDestino,
        lngDestino: lngDestino,
      );

      if (response.success && response.data != null) {
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener historial de estados
  Future<bool> obtenerHistorialEstados(int entregaId) async {
    try {
      final response = await _entregaService.obtenerHistorialEstados(entregaId);

      if (response.success && response.data != null) {
        _historialEstados = response.data!;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Actualizar entrega en la lista
  void _actualizarEnListaEntregas(Entrega entrega) {
    final index = _entregas.indexWhere((e) => e.id == entrega.id);
    if (index >= 0) {
      _entregas[index] = entrega;
    }
  }

  // Limpiar
  void limpiar() {
    _entregas = [];
    _entregaActual = null;
    _ubicaciones = [];
    _ubicacionActual = null;
    _historialEstados = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
