import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/services.dart';

class PedidoProvider with ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _proformaSubscription;
  StreamSubscription? _envioSubscription;

  // Constructor: iniciar escucha WebSocket automáticamente
  PedidoProvider() {
    // Iniciar escucha WebSocket cuando se crea el provider
    iniciarEscuchaWebSocket();
  }

  // Estado
  List<Pedido> _pedidos = [];
  Pedido? _pedidoActual;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Paginación
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalItems = 0;
  final int _perPage = 15;

  // Filtros
  EstadoPedido? _filtroEstado;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;

  // Getters
  List<Pedido> get pedidos => _pedidos;
  Pedido? get pedidoActual => _pedidoActual;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;
  int get totalItems => _totalItems;
  EstadoPedido? get filtroEstado => _filtroEstado;
  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;

  /// Cargar historial de pedidos (página 1)
  Future<void> loadPedidos({
    EstadoPedido? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _filtroEstado = estado;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;

    if (refresh) {
      // Si es refresh, no mostramos loading inicial
      _isLoading = false;
    }

    notifyListeners();

    try {
      final response = await _pedidoService.getPedidosCliente(
        page: _currentPage,
        perPage: _perPage,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      if (response.success && response.data != null) {
        _pedidos = response.data!.data;
        _hasMorePages = response.data!.hasMorePages;
        _totalItems = response.data!.total;
        _errorMessage = null;
      } else {
        _errorMessage = response.message;
        _pedidos = [];
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _pedidos = [];
      debugPrint('Error loading pedidos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar más pedidos (siguiente página)
  Future<void> loadMorePedidos() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;

      final response = await _pedidoService.getPedidosCliente(
        page: nextPage,
        perPage: _perPage,
        estado: _filtroEstado,
        fechaDesde: _filtroFechaDesde,
        fechaHasta: _filtroFechaHasta,
      );

      if (response.success && response.data != null) {
        // Agregar nuevos pedidos a la lista existente
        _pedidos.addAll(response.data!.data);
        _hasMorePages = response.data!.hasMorePages;
        _currentPage = nextPage;
        _errorMessage = null;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('Error loading more pedidos: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Obtener detalle completo de un pedido
  Future<void> loadPedido(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _pedidoService.getPedido(id);

      if (response.success && response.data != null) {
        _pedidoActual = response.data;
        _errorMessage = null;

        // Actualizar pedido en la lista si existe
        final index = _pedidos.indexWhere((p) => p.id == id);
        if (index != -1) {
          _pedidos[index] = response.data!;
        }
      } else {
        _errorMessage = response.message;
        _pedidoActual = null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _pedidoActual = null;
      debugPrint('Error loading pedido detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refrescar solo el estado de un pedido (lightweight)
  Future<void> refreshEstadoPedido(int id) async {
    try {
      final response = await _pedidoService.getEstadoPedido(id);

      if (response.success && response.data != null) {
        final nuevoEstado = EstadoInfo.fromString(
          response.data!['estado'] as String,
        );

        // Actualizar en la lista
        final index = _pedidos.indexWhere((p) => p.id == id);
        if (index != -1) {
          _pedidos[index] = _pedidos[index].copyWith(estado: nuevoEstado);
        }

        // Actualizar pedido actual si es el mismo
        if (_pedidoActual?.id == id) {
          _pedidoActual = _pedidoActual!.copyWith(estado: nuevoEstado);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing estado: $e');
    }
  }

  /// Extender reservas de stock de un pedido
  Future<bool> extenderReserva(int pedidoId) async {
    try {
      _errorMessage = null;

      final response = await _pedidoService.extenderReservas(pedidoId);

      if (response.success) {
        // Recargar el pedido para obtener las nuevas fechas de expiración
        await loadPedido(pedidoId);
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      debugPrint('Error extending reserva: $e');
      return false;
    }
  }

  /// Filtrar pedidos localmente por estado
  List<Pedido> getPedidosPorEstado(EstadoPedido estado) {
    return _pedidos.where((p) => p.estado == estado).toList();
  }

  /// Obtener pedidos pendientes
  List<Pedido> get pedidosPendientes {
    return getPedidosPorEstado(EstadoPedido.PENDIENTE);
  }

  /// Obtener pedidos aprobados
  List<Pedido> get pedidosAprobados {
    return getPedidosPorEstado(EstadoPedido.APROBADA);
  }

  /// Obtener pedidos en proceso (preparando, en camión, en ruta)
  List<Pedido> get pedidosEnProceso {
    return _pedidos
        .where(
          (p) =>
              p.estado == EstadoPedido.PREPARANDO ||
              p.estado == EstadoPedido.EN_CAMION ||
              p.estado == EstadoPedido.EN_RUTA ||
              p.estado == EstadoPedido.LLEGO,
        )
        .toList();
  }

  /// Obtener pedidos entregados
  List<Pedido> get pedidosEntregados {
    return getPedidosPorEstado(EstadoPedido.ENTREGADO);
  }

  /// Obtener pedidos con novedad
  List<Pedido> get pedidosConNovedad {
    return getPedidosPorEstado(EstadoPedido.NOVEDAD);
  }

  /// Aplicar filtro de estado
  Future<void> aplicarFiltroEstado(EstadoPedido? estado) async {
    await loadPedidos(
      estado: estado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
    );
  }

  /// Aplicar filtro de fechas
  Future<void> aplicarFiltroFechas(DateTime? desde, DateTime? hasta) async {
    await loadPedidos(
      estado: _filtroEstado,
      fechaDesde: desde,
      fechaHasta: hasta,
    );
  }

  /// Limpiar filtros
  Future<void> limpiarFiltros() async {
    await loadPedidos();
  }

  /// Limpiar error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar pedido actual
  void limpiarPedidoActual() {
    _pedidoActual = null;
    notifyListeners();
  }

  /// Iniciar escucha de eventos WebSocket
  void iniciarEscuchaWebSocket() {
    debugPrint('🔌 PedidoProvider: Iniciando escucha WebSocket');

    // Escuchar eventos de proformas
    _proformaSubscription = _webSocketService.proformaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('📦 PedidoProvider: Evento proforma recibido: $type');

      switch (type) {
        case 'created':
          _handleProformaCreated(data);
          break;
        case 'approved':
          _handleProformaApproved(data);
          break;
        case 'rejected':
          _handleProformaRejected(data);
          break;
        case 'converted':
          _handleProformaConverted(data);
          break;
      }
    });

    // Escuchar eventos de envíos
    _envioSubscription = _webSocketService.envioStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('🚛 PedidoProvider: Evento envío recibido: $type');

      switch (type) {
        case 'programado':
          _handleEnvioProgramado(data);
          break;
        case 'en_preparacion':
          _handleEnvioEnPreparacion(data);
          break;
        case 'en_ruta':
          _handleEnvioEnRuta(data);
          break;
        case 'proximo':
          _handleEnvioProximo(data);
          break;
        case 'entregado':
          _handleEnvioEntregado(data);
          break;
        case 'rechazada':
          _handleEntregaRechazada(data);
          break;
      }
    });
  }

  /// Detener escucha de eventos WebSocket
  void detenerEscuchaWebSocket() {
    debugPrint('🔌 PedidoProvider: Deteniendo escucha WebSocket');
    _proformaSubscription?.cancel();
    _envioSubscription?.cancel();
  }

  // Handlers de eventos WebSocket

  void _handleProformaCreated(Map<String, dynamic> data) {
    // La proforma fue creada, refrescar lista si estamos en ella
    debugPrint('✅ Proforma creada: ${data['numero']}');
    // Opcional: Recargar lista de pedidos
  }

  void _handleProformaApproved(Map<String, dynamic> data) {
    // La proforma fue aprobada
    final proformaId = data['id'] as int;
    debugPrint('✅ Proforma #$proformaId aprobada');

    // Actualizar estado si el pedido está en la lista
    final index = _pedidos.indexWhere((p) => p.id == proformaId);
    if (index != -1) {
      _pedidos[index] = _pedidos[index].copyWith(estado: EstadoPedido.APROBADA);
      notifyListeners();
    }

    // Actualizar pedido actual si es el mismo
    if (_pedidoActual?.id == proformaId) {
      _pedidoActual = _pedidoActual!.copyWith(estado: EstadoPedido.APROBADA);
      notifyListeners();
    }
  }

  void _handleProformaRejected(Map<String, dynamic> data) {
    // La proforma fue rechazada
    final proformaId = data['id'] as int;
    final motivo = data['motivo_rechazo'] as String?;
    debugPrint('❌ Proforma #$proformaId rechazada: $motivo');

    // Actualizar estado
    final index = _pedidos.indexWhere((p) => p.id == proformaId);
    if (index != -1) {
      _pedidos[index] = _pedidos[index].copyWith(
        estado: EstadoPedido.RECHAZADA,
        comentariosAprobacion: motivo,
      );
      notifyListeners();
    }

    if (_pedidoActual?.id == proformaId) {
      _pedidoActual = _pedidoActual!.copyWith(
        estado: EstadoPedido.RECHAZADA,
        comentariosAprobacion: motivo,
      );
      notifyListeners();
    }
  }

  void _handleProformaConverted(Map<String, dynamic> data) {
    // La proforma fue convertida a venta
    final proformaId = data['proforma_id'] as int?;
    final ventaId = data['venta_id'] as int;
    debugPrint('🔄 Proforma #$proformaId convertida a venta #$ventaId');

    // Recargar el pedido para obtener la data actualizada
    if (proformaId != null) {
      loadPedido(ventaId);
    }
  }

  void _handleEnvioProgramado(Map<String, dynamic> data) {
    // Envío fue programado
    final envioId = data['envio_id'] as int?;
    final fechaProgramada = data['fecha_programada'] as String?;
    debugPrint('📅 Envío programado: $envioId para $fechaProgramada');

    // Actualizar pedido relacionado
    // Nota: necesitaríamos el venta_id en el evento para actualizar correctamente
    notifyListeners();
  }

  void _handleEnvioEnPreparacion(Map<String, dynamic> data) {
    debugPrint('📦 Envío en preparación');
    // Actualizar estado del pedido
  }

  void _handleEnvioEnRuta(Map<String, dynamic> data) {
    debugPrint('🚛 Envío en ruta');
    // Actualizar estado del pedido a EN_RUTA
  }

  void _handleEnvioProximo(Map<String, dynamic> data) {
    final tiempoEstimado = data['tiempo_estimado_min'] as int?;
    debugPrint('⏰ Envío próximo: $tiempoEstimado minutos');
    // Mostrar notificación urgente al usuario
  }

  void _handleEnvioEntregado(Map<String, dynamic> data) {
    final envioId = data['envio_id'] as int?;
    debugPrint('✅ Envío #$envioId entregado');
    // Actualizar estado del pedido a ENTREGADO
  }

  void _handleEntregaRechazada(Map<String, dynamic> data) {
    final motivo = data['motivo'] as String?;
    debugPrint('❌ Entrega rechazada: $motivo');
    // Actualizar estado del pedido con la novedad
  }

  /// Resetear provider
  void reset() {
    detenerEscuchaWebSocket();
    _pedidos = [];
    _pedidoActual = null;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = true;
    _totalItems = 0;
    _filtroEstado = null;
    _filtroFechaDesde = null;
    _filtroFechaHasta = null;
    notifyListeners();
  }

  @override
  void dispose() {
    detenerEscuchaWebSocket();
    super.dispose();
  }
}
