import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/cliente_credito_service.dart';

class ClienteCreditoProvider with ChangeNotifier {
  final ClienteCreditoService _clienteCreditoService =
      ClienteCreditoService();

  DetallesCreditoCliente? _detallesCreditoCliente;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DetallesCreditoCliente? get detallesCreditoCliente =>
      _detallesCreditoCliente;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get tieneError => _errorMessage != null;

  /// ✅ NUEVO: Cargar detalles de crédito del cliente
  Future<void> cargarDetallesCreditoCliente(int clienteId) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final response = await _clienteCreditoService
          .obtenerDetallesCreditoCliente(clienteId);

      if (response.success && response.data != null) {
        _detallesCreditoCliente = response.data;
        _isLoading = false;
        _errorMessage = null;
      } else {
        _isLoading = false;
        _errorMessage =
            response.message ?? 'Error al cargar detalles de crédito';
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
    }

    Future.microtask(() => notifyListeners());
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }

  /// Limpiar datos
  void clearData() {
    _detallesCreditoCliente = null;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }
}
