import 'package:flutter/widgets.dart';
import '../models/banner_publicitario.dart';
import '../models/api_response.dart';
import '../services/banner_publicitario_service.dart';

/// BannerPublicitarioProvider - Gestión de banners publicitarios
///
/// RESPONSABILIDADES:
/// ✓ Cargar banners vigentes y activos
/// ✓ Mantener lista en caché
/// ✓ Manejar estados de carga y error
/// ✓ Notificar cambios a los widgets
class BannerPublicitarioProvider with ChangeNotifier {
  final BannerPublicitarioService _bannerService = BannerPublicitarioService();

  List<BannerPublicitario> _banners = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BannerPublicitario> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBanners => _banners.isNotEmpty;

  /// Cargar banners vigentes y activos
  Future<bool> cargarBanners() async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _bannerService.obtenerBannersActivos();

      if (response.success && response.data != null) {
        _banners = response.data!;
        _errorMessage = null;

        debugPrint(
          '🎯 [BANNER_PROVIDER] Banners cargados: ${_banners.length}',
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message ?? 'Error desconocido';
        _banners = [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _banners = [];

      debugPrint('❌ [BANNER_PROVIDER] Error: $_errorMessage');

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

  /// Limpiar caché y errores
  void limpiar() {
    _banners = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
