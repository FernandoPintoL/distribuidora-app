import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/ruta.dart';
import '../models/ruta_detalle.dart';
import '../services/websocket_service.dart';

class RutaProvider with ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();

  List<Ruta> _rutas = [];
  Ruta? _rutaActual;
  List<RutaDetalle> _detallesRutaActual = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _ultimoEventoRuta;

  // Getters
  List<Ruta> get rutas => _rutas;
  Ruta? get rutaActual => _rutaActual;
  List<RutaDetalle> get detallesRutaActual => _detallesRutaActual;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get ultimoEventoRuta => _ultimoEventoRuta;

  /// Inicializar escuchadores de WebSocket para Rutas
  void inicializarListenersRutas({
    required VoidCallback onRutaNueva,
    required VoidCallback onRutaModificada,
    required VoidCallback onParadaActualizada,
  }) {
    debugPrint('🎯 Inicializando listeners de rutas...');

    // Escuchar stream de rutas del WebSocket
    _wsService.rutaStream.listen((event) {
      final type = event['type'];
      final data = event['data'];

      debugPrint('📡 Evento de ruta recibido: $type');

      switch (type) {
        case 'planificada':
          _handleRutaPlanificada(data);
          _ultimoEventoRuta = 'Nueva ruta planificada: ${data['codigo']}';
          onRutaNueva();
          break;

        case 'modificada':
          _handleRutaModificada(data);
          _ultimoEventoRuta = 'Ruta modificada: ${data['codigo']}';
          onRutaModificada();
          break;

        case 'detalle_actualizado':
          _handleRutaDetalleActualizado(data);
          _ultimoEventoRuta = 'Parada actualizada: ${data['cliente_nombre']}';
          onParadaActualizada();
          break;

        default:
          debugPrint('⚠️ Tipo de evento desconocido: $type');
      }

      notifyListeners();
    }, onError: (error) {
      debugPrint('❌ Error en stream de rutas: $error');
      _errorMessage = 'Error en notificaciones de rutas: $error';
      notifyListeners();
    });
  }

  /// Manejar evento: Ruta Planificada
  void _handleRutaPlanificada(Map<String, dynamic> data) {
    debugPrint('📍 Nueva ruta planificada: ${data['codigo']}');

    final nuevaRuta = Ruta.fromJson(data);

    // Agregar a la lista si no existe
    if (!_rutas.any((r) => r.id == nuevaRuta.id)) {
      _rutas.insert(0, nuevaRuta); // Insertar al inicio
      debugPrint('✅ Ruta agregada a la lista: ${nuevaRuta.codigo}');
    }
  }

  /// Manejar evento: Ruta Modificada
  void _handleRutaModificada(Map<String, dynamic> data) {
    final rutaId = data['ruta_id'];
    final nuevoEstado = data['estado'];
    final tipoCambio = data['tipo_cambio'];

    debugPrint('📝 Actualizando ruta $rutaId - Cambio: $tipoCambio -> $nuevoEstado');

    // Actualizar en la lista
    final indice = _rutas.indexWhere((r) => r.id == rutaId);
    if (indice != -1) {
      _rutas[indice] = _rutas[indice].copyWith(estado: nuevoEstado);
    }

    // Si es la ruta actual, actualizar también
    if (_rutaActual?.id == rutaId) {
      _rutaActual = _rutaActual!.copyWith(estado: nuevoEstado);
    }
  }

  /// Manejar evento: Ruta Detalle Actualizado (Parada)
  void _handleRutaDetalleActualizado(Map<String, dynamic> data) {
    final detalleId = data['detalle_id'];
    final nuevoEstado = data['estado_actual'];
    final clienteNombre = data['cliente_nombre'];

    debugPrint('📦 Parada actualizada: $clienteNombre -> $nuevoEstado');

    // Actualizar en la lista de detalles de la ruta actual
    final indice =
        _detallesRutaActual.indexWhere((d) => d.id == detalleId);
    if (indice != -1) {
      _detallesRutaActual[indice] =
          _detallesRutaActual[indice].copyWith(estado: nuevoEstado);
    }
  }

  /// Establecer ruta actual y sus detalles
  Future<void> establecerRutaActual(
    Ruta ruta, {
    List<RutaDetalle>? detalles,
  }) async {
    _rutaActual = ruta;
    _detallesRutaActual = detalles ?? [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtener rutas por chofer (del API si es necesario)
  Future<void> obtenerRutasDelChofer({
    required int choferId,
    String? estado,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar llamada a API para obtener rutas del chofer
      // Por ahora, filtramos la lista actual
      if (estado != null) {
        final rutasFiltradas =
            _rutas.where((r) => r.estado == estado).toList();
        debugPrint('📋 Rutas filtradas por estado $estado: ${rutasFiltradas.length}');
      }

      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error obteniendo rutas: $e';
      debugPrint('❌ Error: $_errorMessage');
    }

    notifyListeners();
  }

  /// Limpiar estado
  void limpiar() {
    _rutas = [];
    _rutaActual = null;
    _detallesRutaActual = [];
    _errorMessage = null;
    _ultimoEventoRuta = null;
    notifyListeners();
  }

  /// Obtener estadísticas de rutas
  Map<String, int> obtenerEstadisticas() {
    return {
      'total': _rutas.length,
      'planificadas': _rutas.where((r) => r.estaPlanificada).length,
      'enProgreso': _rutas.where((r) => r.estaEnProgreso).length,
      'completadas': _rutas.where((r) => r.estaCompletada).length,
    };
  }

  /// Obtener progreso de entregas de la ruta actual
  Map<String, int> obtenerProgresRutaActual() {
    if (_rutaActual == null) {
      return {
        'total': 0,
        'entregadas': 0,
        'pendientes': 0,
        'noEntregadas': 0,
      };
    }

    return {
      'total': _detallesRutaActual.length,
      'entregadas':
          _detallesRutaActual.where((d) => d.estaEntregado).length,
      'pendientes': _detallesRutaActual.where((d) => d.estaPendiente).length,
      'noEntregadas':
          _detallesRutaActual.where((d) => d.noEstaEntregado).length,
    };
  }
}
