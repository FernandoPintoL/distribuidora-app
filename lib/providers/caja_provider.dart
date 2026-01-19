import 'package:flutter/widgets.dart';
import '../models/caja.dart';
import '../models/movimiento_caja.dart';
import '../models/api_response.dart';
import '../services/caja_service.dart';

/// CajaProvider - Gestión de cajas diarias del chofer
///
/// RESPONSABILIDADES:
/// ✓ Cargar estado actual de caja (abierta/cerrada)
/// ✓ Abrir/cerrar cajas
/// ✓ Mantener lista de movimientos del día
/// ✓ Calcular resumen financiero
/// ✓ Sincronizar con backend en tiempo real
class CajaProvider with ChangeNotifier {
  final CajaService _cajaService = CajaService();

  Caja? _cajaActual;
  List<MovimientoCaja> _movimientos = [];
  Map<String, dynamic> _resumen = {
    'total_ingresos': 0.0,
    'total_egresos': 0.0,
    'saldo_actual': 0.0,
  };

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Caja? get cajaActual => _cajaActual;
  List<MovimientoCaja> get movimientos => _movimientos;
  Map<String, dynamic> get resumen => _resumen;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get estaCajaAbierta => _cajaActual?.estaAbierta ?? false;
  bool get estaCajaCerrada => _cajaActual?.estaCerrada ?? false;

  // Cálculos derivados
  double get totalIngresos =>
      (_resumen['total_ingresos'] as num?)?.toDouble() ?? 0.0;
  double get totalEgresos =>
      (_resumen['total_egresos'] as num?)?.toDouble() ?? 0.0;
  double get saldoActual =>
      (_resumen['saldo_actual'] as num?)?.toDouble() ?? 0.0;

  /// Cargar estado actual de caja
  Future<bool> cargarEstadoCaja() async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _cajaService.obtenerEstadoCaja();

      if (response.success) {
        _cajaActual = response.data;
        _errorMessage = null;

        debugPrint(
          '📦 [CAJA_PROVIDER] Estado caja cargado: ${_cajaActual?.estado}',
        );

        // Si hay caja abierta, cargar también los movimientos y resumen
        if (_cajaActual != null) {
          await Future.wait([cargarMovimientosCaja(), cargarResumenCaja()]);
        }

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
      debugPrint('❌ [CAJA_PROVIDER] Error: $_errorMessage');
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

  /// Abrir una caja nueva
  Future<bool> abrirCaja({double montoApertura = 0.0}) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _cajaService.abrirCaja(
        montoApertura: montoApertura,
      );
      debugPrint('📍 [CAJA_PROVIDER] Respuesta abrirCaja: success=${response.success}, message=${response.message}, data=${response.data}');

      if (response.success && response.data != null) {
        _cajaActual = response.data;
        _movimientos = [];
        _resumen = {
          'total_ingresos': 0.0,
          'total_egresos': 0.0,
          'saldo_actual': montoApertura,
        };
        _errorMessage = null;

        debugPrint('✅ [CAJA_PROVIDER] Caja abierta: ID ${_cajaActual?.id}');

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
      debugPrint('❌ [CAJA_PROVIDER] Error abriendo caja: $_errorMessage');
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

  /// Cerrar la caja abierta
  Future<bool> cerrarCaja({double? montosCierre, String? observaciones}) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _cajaService.cerrarCaja(
        montosCierre: montosCierre,
        observaciones: observaciones,
      );

      if (response.success && response.data != null) {
        _cajaActual = response.data;
        _errorMessage = null;

        debugPrint(
          '🔐 [CAJA_PROVIDER] Caja cerrada con diferencia: ${_cajaActual?.diferencia}',
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
      debugPrint('❌ [CAJA_PROVIDER] Error cerrando caja: $_errorMessage');
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

  /// Cargar movimientos de caja
  Future<bool> cargarMovimientosCaja({
    int page = 1,
    String? fechaDesde,
    String? fechaHasta,
    String? tipo,
  }) async {
    try {
      final response = await _cajaService.obtenerMovimientosCaja(
        page: page,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        tipo: tipo,
      );

      if (response.success && response.data != null) {
        _movimientos = response.data!;
        _errorMessage = null;

        debugPrint(
          '📋 [CAJA_PROVIDER] Movimientos cargados: ${_movimientos.length}',
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
        '❌ [CAJA_PROVIDER] Error cargando movimientos: $_errorMessage',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Cargar resumen financiero de caja
  Future<bool> cargarResumenCaja() async {
    try {
      final response = await _cajaService.obtenerResumenCaja();

      if (response.success && response.data != null) {
        _resumen = response.data!;
        _errorMessage = null;

        debugPrint(
          '💰 [CAJA_PROVIDER] Resumen cargado - Ingresos: ${totalIngresos}, Egresos: ${totalEgresos}',
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
      debugPrint('❌ [CAJA_PROVIDER] Error cargando resumen: $_errorMessage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Refrescar todos los datos de caja
  Future<bool> refrescar() async {
    if (_cajaActual == null) {
      return cargarEstadoCaja();
    }

    try {
      await Future.wait([cargarMovimientosCaja(), cargarResumenCaja()]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'Error al refrescar: ${e.toString()}';
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
