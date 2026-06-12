import 'package:flutter/foundation.dart';
import '../models/localidad.dart';
import '../services/localidad_service.dart';

class LocalidadProvider extends ChangeNotifier {
  final LocalidadService _localidadService = LocalidadService();

  List<Localidad> _localidades = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Localidad> get localidades => _localidades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtener todas las localidades
  Future<bool> obtenerLocalidades() async {
    _isLoading = true;
    _errorMessage = null;
    debugPrint('🔍 [LOCALIDAD_PROVIDER] Cargando localidades');
    notifyListeners();

    try {
      final response = await _localidadService.obtenerLocalidades();

      if (response.success && response.data != null) {
        _localidades = response.data!;
        debugPrint('🔍 [LOCALIDAD_PROVIDER] Localidades cargadas: ${_localidades.length}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error desconocido';
        debugPrint('❌ [LOCALIDAD_PROVIDER] Error: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ [LOCALIDAD_PROVIDER] Excepción: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
