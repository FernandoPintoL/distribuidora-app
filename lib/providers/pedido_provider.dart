import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/services.dart';

class PedidoProvider with ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();
  final ProformaService _proformaService = ProformaService();
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _proformaSubscription;
  StreamSubscription? _envioSubscription;
  StreamSubscription? _ubicacionSubscription;

  // Constructor: iniciar escucha WebSocket automáticamente
  PedidoProvider() {
    // Iniciar escucha WebSocket cuando se crea el provider
    iniciarEscuchaWebSocket();
  }

  // Estado
  List<Pedido> _pedidos = [];
  Pedido? _pedidoActual;
  ProformaStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingStats = false;
  bool _isConverting = false;
  bool _isRenovandoReservas = false;
  String? _errorMessage;
  String? _errorCode;
  Map<String, dynamic>? _errorData;

  // Paginación
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalItems = 0;
  final int _perPage = 15;

  // Filtros
  EstadoPedido? _filtroEstado;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String? _filtroBusqueda;

  // Getters
  List<Pedido> get pedidos => _pedidos;
  Pedido? get pedidoActual => _pedidoActual;
  ProformaStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingStats => _isLoadingStats;
  bool get isConverting => _isConverting;
  bool get isRenovandoReservas => _isRenovandoReservas;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get errorData => _errorData;
  bool get hasMorePages => _hasMorePages;
  int get totalItems => _totalItems;
  EstadoPedido? get filtroEstado => _filtroEstado;
  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;
  String? get filtroBusqueda => _filtroBusqueda;

  /// Cargar historial de pedidos (página 1)
  Future<void> loadPedidos({
    EstadoPedido? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _filtroEstado = estado;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroBusqueda = busqueda;

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
        busqueda: busqueda,
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

  /// Cargar estadísticas de proformas (ligero y rápido)
  ///
  /// Este método solo carga contadores y métricas sin traer
  /// todas las proformas completas. Ideal para mostrar en
  /// el dashboard inicial.
  ///
  /// Ventajas:
  /// - Rápido (~100ms vs 1-3 segundos)
  /// - Ligero (~2KB vs ~500KB-2MB)
  /// - Datos listos para mostrar
  Future<void> loadStats({bool refresh = false}) async {
    if (_isLoadingStats && !refresh) return;

    _isLoadingStats = true;
    if (!refresh) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final response = await _proformaService.getStats();

      if (response.success && response.data != null) {
        _stats = response.data;
        _errorMessage = null;
        debugPrint('✅ Estadísticas cargadas: ${_stats!.total} proformas');
      } else {
        _errorMessage = response.message;
        _stats = null;
        debugPrint('❌ Error cargando estadísticas: ${response.message}');
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _stats = null;
      debugPrint('❌ Error loading stats: $e');
    } finally {
      _isLoadingStats = false;
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
        busqueda: _filtroBusqueda,
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
      busqueda: _filtroBusqueda,
    );
  }

  /// Aplicar búsqueda
  Future<void> aplicarBusqueda(String? busqueda) async {
    await loadPedidos(
      estado: _filtroEstado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: busqueda,
    );
  }

  /// Limpiar filtros
  Future<void> limpiarFiltros() async {
    await loadPedidos();
  }

  /// Confirmar una proforma aprobada y convertirla en venta
  ///
  /// Este método intenta convertir una proforma en venta. Si la proforma
  /// tiene reservas expiradas, retorna un error RESERVAS_EXPIRADAS y guarda
  /// los datos de error para que la UI pueda mostrar opciones de renovación.
  ///
  /// Retorna:
  /// - true si la conversión fue exitosa
  /// - false si hay error (puede ser RESERVAS_EXPIRADAS u otro)
  Future<bool> confirmarProforma({
    required int proformaId,
    String politicaPago = 'MEDIO_MEDIO',
  }) async {
    try {
      _isConverting = true;
      _errorMessage = null;
      _errorCode = null;
      _errorData = null;
      notifyListeners();

      debugPrint('🔄 Confirmando proforma #$proformaId');

      final response = await _proformaService.confirmarProforma(
        proformaId: proformaId,
        politicaPago: politicaPago,
      );

      if (response.success && response.data != null) {
        // ✅ Conversión exitosa
        debugPrint('✅ Proforma convertida a venta exitosamente');
        _errorCode = null;
        _errorData = null;
        notifyListeners();
        return true;
      } else if (!response.success && response.code == 'RESERVAS_EXPIRADAS') {
        // ⚠️ Reservas expiradas - guardar información para que la UI maneje renovación
        _errorCode = 'RESERVAS_EXPIRADAS';
        _errorData = response.additionalData;
        _errorMessage = response.message;
        debugPrint('⚠️ Detectado error de RESERVAS_EXPIRADAS');
        notifyListeners();
        return false;
      } else {
        // ❌ Otros errores
        _errorMessage = response.message;
        _errorCode = response.code;
        _errorData = response.additionalData;
        debugPrint('❌ Error al confirmar proforma: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error inesperado al confirmar proforma: $e');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isConverting = false;
      notifyListeners();
      return false;
    } finally {
      _isConverting = false;
    }
  }

  /// Renovar reservas expiradas de una proforma
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma cuyas reservas necesitan renovación
  ///
  /// Retorna:
  /// - true si las reservas fueron renovadas exitosamente
  /// - false si hay error
  Future<bool> renovarReservas(int proformaId) async {
    try {
      _isRenovandoReservas = true;
      notifyListeners();

      debugPrint('🔄 Renovando reservas para proforma #$proformaId');

      final response = await _proformaService.renovarReservas(proformaId);

      if (response.success) {
        debugPrint('✅ Reservas renovadas exitosamente');
        _errorCode = null;
        _errorData = null;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        debugPrint('❌ Error al renovar reservas: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error inesperado al renovar reservas: $e');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isRenovandoReservas = false;
    }
  }

  /// Limpiar errores
  void limpiarErrores() {
    _errorMessage = null;
    _errorCode = null;
    _errorData = null;
    notifyListeners();
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
        case 'chofer_llego':
          _handleChoferLlego(data);
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

    // Escuchar eventos de ubicación (tracking en tiempo real)
    _ubicacionSubscription = _webSocketService.ubicacionStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('📍 PedidoProvider: Evento ubicación recibido: $type');

      // Las ubicaciones se actualizan principalmente en TrackingProvider
      // Aquí solo sincronizamos si es necesario
      if (type == 'ubicacion') {
        _handleUbicacionActualizada(data);
      }
    });
  }

  /// Detener escucha de eventos WebSocket
  void detenerEscuchaWebSocket() {
    debugPrint('🔌 PedidoProvider: Deteniendo escucha WebSocket');
    _proformaSubscription?.cancel();
    _envioSubscription?.cancel();
    _ubicacionSubscription?.cancel();
  }

  // Handlers de eventos WebSocket

  void _handleProformaCreated(Map<String, dynamic> data) {
    // La proforma fue creada, refrescar lista si estamos en ella
    debugPrint('✅ Proforma creada: ${data['numero']}');
    // Opcional: Recargar lista de pedidos
  }

  void _handleProformaApproved(Map<String, dynamic> data) {
    // La proforma fue aprobada
    final proformaId = data['proforma_id'] as int;
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
    final proformaId = data['proforma_id'] as int;
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
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final fechaProgramada = data['fecha_programada'] as String?;
    debugPrint('📅 Envío programado: $ventaId para $fechaProgramada');

    // Actualizar pedido relacionado
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.PREPARANDO,
        );
        notifyListeners();
      }

      // Actualizar pedido actual si es el mismo
      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.PREPARANDO,
        );
        notifyListeners();
      }
    }
  }

  void _handleEnvioEnPreparacion(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    debugPrint('📦 Envío en preparación: $ventaId');

    // Actualizar estado del pedido
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.PREPARANDO,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.PREPARANDO,
        );
        notifyListeners();
      }
    }
  }

  void _handleEnvioEnRuta(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final choferId = data['chofer_id'] as int?;
    final vehiculoPlaca = data['vehiculo_placa'] as String?;
    debugPrint('🚛 Envío en ruta: $ventaId');

    // Actualizar estado del pedido a EN_RUTA
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.EN_RUTA,
          choferId: choferId,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.EN_RUTA,
          choferId: choferId,
        );
        notifyListeners();
      }
    }
  }

  void _handleChoferLlego(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    debugPrint('📍 Chofer llegó: $ventaId');

    // Actualizar estado - el chofer llegó al destino
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.LLEGO,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.LLEGO,
        );
        notifyListeners();
      }
    }
  }

  void _handleEnvioProximo(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final tiempoEstimado = data['eta_minutos'] ?? data['tiempo_estimado_min'] as int?;
    final distanciaKm = data['distancia_km'] as double?;
    debugPrint('⏰ Envío próximo: $tiempoEstimado minutos, distancia: $distanciaKm km');

    // Mostrar notificación urgente al usuario - solo actualizar display info
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        // No cambiar estado, solo guardar info de distancia/ETA para tracking
        debugPrint('✅ Pedido $ventaId próximo a llegar');
        notifyListeners();
      }
    }
  }

  void _handleEnvioEntregado(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    debugPrint('✅ Envío entregado: $ventaId');

    // Actualizar estado del pedido a ENTREGADO
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.ENTREGADO,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.ENTREGADO,
        );
        notifyListeners();
      }
    }
  }

  void _handleEntregaRechazada(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final motivo = data['motivo'] as String?;
    debugPrint('❌ Entrega rechazada: $ventaId - $motivo');

    // Actualizar estado del pedido con la novedad
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estado: EstadoPedido.NOVEDAD,
          comentariosAprobacion: motivo,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estado: EstadoPedido.NOVEDAD,
          comentariosAprobacion: motivo,
        );
        notifyListeners();
      }
    }
  }

  void _handleUbicacionActualizada(Map<String, dynamic> data) {
    // Las ubicaciones se manejan principalmente en TrackingProvider
    // Pero aquí sincronizamos datos si es necesario
    final entregaId = data['entrega_id'] as int?;
    final ventaId = data['venta_id'] as int?;
    debugPrint('📍 Ubicación actualizada: entrega=$entregaId, venta=$ventaId');

    // Sincronización adicional si es necesario
    // Por ahora solo registramos el evento
    notifyListeners();
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
    _filtroBusqueda = null;
    notifyListeners();
  }

  @override
  void dispose() {
    detenerEscuchaWebSocket();
    super.dispose();
  }
}
