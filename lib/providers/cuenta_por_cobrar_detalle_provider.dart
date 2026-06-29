import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider para gestionar detalle de una Cuenta por Cobrar con sus pagos
class CuentaPorCobrarDetalleProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado
  CuentaPorCobrar? _cuenta;
  List<Pago> _pagos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  CuentaPorCobrar? get cuenta => _cuenta;
  List<Pago> get pagos => _pagos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Cargar detalle de una cuenta por cobrar
  Future<void> loadCuentaDetalle(int cuentaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/cuentas-por-cobrar/$cuentaId', queryParameters: {});

      if (response.statusCode == 200 && response.data != null) {
        final responseBody = response.data as Map<String, dynamic>;

        if (responseBody['success'] == true && responseBody['data'] != null) {
          final data = responseBody['data'] as Map<String, dynamic>;

          // Parsear cuenta
          _cuenta = CuentaPorCobrar.fromJson(data);

          // Parsear pagos
          if (data['pagos'] is List) {
            _pagos = (data['pagos'] as List)
                .map((pago) => Pago.fromJson(pago as Map<String, dynamic>))
                .toList();
          } else {
            _pagos = [];
          }

          _errorMessage = null;
          debugPrint('✅ Cuenta por cobrar cargada: ${_cuenta?.id} con ${_pagos.length} pagos');
        } else {
          _errorMessage = responseBody['message'] as String?;
          _cuenta = null;
          _pagos = [];
          debugPrint('❌ Error: ${responseBody['message']}');
        }
      } else {
        _errorMessage = 'Error en la solicitud: ${response.statusCode}';
        _cuenta = null;
        _pagos = [];
        debugPrint('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _cuenta = null;
      _pagos = [];
      debugPrint('Error loading cuenta detalle: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar datos
  void limpiar() {
    _cuenta = null;
    _pagos = [];
    _errorMessage = null;
    notifyListeners();
  }
}
