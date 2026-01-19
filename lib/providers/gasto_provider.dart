import 'package:flutter/widgets.dart';
import '../models/gasto.dart';
import '../models/api_response.dart';
import '../services/gasto_service.dart';

/// GastoProvider - Gestión de gastos/cajas chicas del chofer
///
/// RESPONSABILIDADES:
/// ✓ Registrar nuevos gastos
/// ✓ Mantener lista de gastos del día
/// ✓ Cargar estadísticas de gastos
/// ✓ Eliminar gastos
/// ✓ Filtrar gastos por categoría o fecha
class GastoProvider with ChangeNotifier {
  final GastoService _gastoService = GastoService();

  List<Gasto> _gastos = [];
  Map<String, dynamic> _estadisticas = {
    'total_gasto': 0.0,
    'cantidad_gastos': 0,
    'por_categoria': {},
  };

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Gasto> get gastos => _gastos;
  Map<String, dynamic> get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalGastos =>
      (_estadisticas['total_gasto'] as num?)?.toDouble() ?? 0.0;
  int get cantidadGastos =>
      (_estadisticas['cantidad_gastos'] as num?)?.toInt() ?? 0;

  /// Registrar un nuevo gasto
  Future<bool> registrarGasto({
    required double monto,
    required String descripcion,
    required String categoria,
    String? numeroComprobante,
    String? proveedor,
    String? observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _gastoService.registrarGasto(
        monto: monto,
        descripcion: descripcion,
        categoria: categoria,
        numeroComprobante: numeroComprobante,
        proveedor: proveedor,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        // Agregar el gasto a la lista
        _gastos.insert(0, response.data!);

        // Actualizar estadísticas
        _estadisticas['total_gasto'] =
            totalGastos + monto;
        _estadisticas['cantidad_gastos'] = cantidadGastos + 1;

        _errorMessage = null;

        debugPrint(
          '✅ [GASTO_PROVIDER] Gasto registrado: ${response.data!.categoria}',
        );

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
      debugPrint('❌ [GASTO_PROVIDER] Error: $_errorMessage');
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

  /// Cargar gastos del día
  Future<bool> cargarGastos({
    int page = 1,
    String? fechaDesde,
    String? fechaHasta,
    String? categoria,
    String? q,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _gastoService.obtenerGastos(
        page: page,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        categoria: categoria,
        q: q,
      );

      if (response.success && response.data != null) {
        _gastos = response.data!;
        _errorMessage = null;

        debugPrint(
          '📋 [GASTO_PROVIDER] Gastos cargados: ${_gastos.length}',
        );

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
      debugPrint('❌ [GASTO_PROVIDER] Error cargando gastos: $_errorMessage');
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

  /// Cargar estadísticas de gastos
  Future<bool> cargarEstadisticas({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      final response = await _gastoService.obtenerEstadisticasGastos(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      if (response.success && response.data != null) {
        _estadisticas = response.data!;
        _errorMessage = null;

        debugPrint(
          '📊 [GASTO_PROVIDER] Estadísticas cargadas - Total: $totalGastos Bs',
        );

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
      debugPrint(
        '❌ [GASTO_PROVIDER] Error cargando estadísticas: $_errorMessage',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Eliminar un gasto
  Future<bool> eliminarGasto(int gastoId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _gastoService.eliminarGasto(gastoId);

      if (response.success) {
        // Buscar y eliminar el gasto de la lista
        final gasto = _gastos.firstWhere(
          (g) => g.id == gastoId,
          orElse: () => null as dynamic,
        );

        if (gasto != null) {
          final montoEliminado = gasto.monto as double;
          _gastos.removeWhere((g) => g.id == gastoId);

          // Actualizar estadísticas
          _estadisticas['total_gasto'] = totalGastos - montoEliminado;
          _estadisticas['cantidad_gastos'] = cantidadGastos - 1;
        }

        _errorMessage = null;

        debugPrint(
          '🗑️ [GASTO_PROVIDER] Gasto eliminado: ID $gastoId',
        );

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
      debugPrint('❌ [GASTO_PROVIDER] Error eliminando gasto: $_errorMessage');
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

  /// Refrescar todos los datos de gastos
  Future<bool> refrescar({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      await Future.wait([
        cargarGastos(
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
        ),
        cargarEstadisticas(
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
        ),
      ]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'Error al refrescar: ${e.toString()}';
      return false;
    }
  }

  /// Filtrar gastos por categoría
  List<Gasto> gastosPorCategoria(String categoria) {
    return _gastos.where((g) => g.categoria == categoria).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
