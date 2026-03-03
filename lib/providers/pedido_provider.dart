import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/services.dart';

class PedidoProvider with ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();
  final ProformaService _proformaService = ProformaService();
  final VentaService _ventaService = VentaService();
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
  Venta? _ventaActual;
  ProformaStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingStats = false;
  bool _isLoadingVenta = false;
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
  String? _filtroEstado;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String? _filtroBusqueda;

  // ✅ NUEVO: Filtros específicos para fechas de vencimiento y entrega
  DateTime? _filtroFechaVencimientoDesde;
  DateTime? _filtroFechaVencimientoHasta;
  DateTime? _filtroFechaEntregaSolicitadaDesde;
  DateTime? _filtroFechaEntregaSolicitadaHasta;

  // Getters
  List<Pedido> get pedidos => _pedidos;
  Pedido? get pedidoActual => _pedidoActual;
  Venta? get ventaActual => _ventaActual;
  ProformaStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingVenta => _isLoadingVenta;
  bool get isConverting => _isConverting;
  bool get isRenovandoReservas => _isRenovandoReservas;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  Map<String, dynamic>? get errorData => _errorData;
  bool get hasMorePages => _hasMorePages;
  int get totalItems => _totalItems;
  String? get filtroEstado => _filtroEstado;
  DateTime? get filtroFechaDesde => _filtroFechaDesde;
  DateTime? get filtroFechaHasta => _filtroFechaHasta;
  String? get filtroBusqueda => _filtroBusqueda;

  // ✅ NUEVO: Getters para filtros específicos
  DateTime? get filtroFechaVencimientoDesde => _filtroFechaVencimientoDesde;
  DateTime? get filtroFechaVencimientoHasta => _filtroFechaVencimientoHasta;
  DateTime? get filtroFechaEntregaSolicitadaDesde => _filtroFechaEntregaSolicitadaDesde;
  DateTime? get filtroFechaEntregaSolicitadaHasta => _filtroFechaEntregaSolicitadaHasta;

  /// Cargar historial de pedidos (página 1)
  /// ✅ ACTUALIZADO: Parámetro estado es ahora String? (código del estado)
  /// ✅ ACTUALIZADO 2026-02-21: Cambiar 'cliente' por 'search' para búsqueda unificada
  Future<void> loadPedidos({
    String? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? search,
    DateTime? fechaVencimientoDesde,
    DateTime? fechaVencimientoHasta,
    DateTime? fechaEntregaSolicitadaDesde,
    DateTime? fechaEntregaSolicitadaHasta,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _filtroEstado = estado;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroBusqueda = search;
    _filtroFechaVencimientoDesde = fechaVencimientoDesde;
    _filtroFechaVencimientoHasta = fechaVencimientoHasta;
    _filtroFechaEntregaSolicitadaDesde = fechaEntregaSolicitadaDesde;
    _filtroFechaEntregaSolicitadaHasta = fechaEntregaSolicitadaHasta;

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
        search: search,
        fechaVencimientoDesde: fechaVencimientoDesde,
        fechaVencimientoHasta: fechaVencimientoHasta,
        fechaEntregaSolicitadaDesde: fechaEntregaSolicitadaDesde,
        fechaEntregaSolicitadaHasta: fechaEntregaSolicitadaHasta,
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
        search: _filtroBusqueda,  // ✅ ACTUALIZADO: Usar 'search' para búsqueda unificada
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
    print("Cargando detalle de pedido ID: $id");

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _pedidoService.getPedido(id);

      print(response.data);

      if (response.success && response.data != null) {
        _pedidoActual = response.data;
        _errorMessage = null;

        // Actualizar pedido en la lista si existe
        final index = _pedidos.indexWhere((p) => p.id == id);
        if (index != -1) {
          _pedidos[index] = response.data!;
        }

        // ✅ Si es una venta, cargar datos completos de la venta
        if (_pedidoActual!.estadoCategoria == 'venta') {
          await loadVentaForPedido(id);
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

  /// Cargar datos completos de la venta asociada a un pedido
  ///
  /// Este método obtiene la información completa de la venta incluida:
  /// - Estado de pago (PAGADO, PARCIAL, PENDIENTE)
  /// - Montos pagado y pendiente
  /// - Estado logístico actualizado
  /// - Datos de entrega
  ///
  /// Parámetros:
  /// - pedidoId: ID del pedido (que es una venta)
  Future<void> loadVentaForPedido(int pedidoId) async {
    try {
      // Solo cargar si el pedido actual es una venta
      if (_pedidoActual?.estadoCategoria != 'venta') {
        return;
      }

      _isLoadingVenta = true;
      notifyListeners();

      debugPrint('📦 Cargando datos de venta para pedido #$pedidoId');

      final response = await _ventaService.getVentaByProformaId(pedidoId);

      if (response.success && response.data != null) {
        _ventaActual = response.data;
        debugPrint(
            '✅ Venta cargada: ${_ventaActual!.numero} - Estado pago: ${_ventaActual!.estadoPago}');
      } else {
        debugPrint('❌ Error cargando venta: ${response.message}');
        _ventaActual = null;
      }
    } catch (e) {
      debugPrint('Error loading venta data: $e');
      _ventaActual = null;
    } finally {
      _isLoadingVenta = false;
      notifyListeners();
    }
  }

  /// Refrescar solo el estado de un pedido (lightweight)
  /// ✅ ACTUALIZADO: Usar códigos de estado String en lugar de enum
  Future<void> refreshEstadoPedido(int id) async {
    try {
      final response = await _pedidoService.getEstadoPedido(id);

      if (response.success && response.data != null) {
        // ✅ ACTUALIZADO: Extraer códigos String del estado
        final estadoObj = response.data!['estado'];
        String nuevoEstadoCodigo = 'PENDIENTE';
        String nuevoEstadoCategoria = 'proforma';
        Map<String, dynamic>? nuevoEstadoData;

        if (estadoObj is Map<String, dynamic>) {
          nuevoEstadoCodigo = estadoObj['codigo'] as String? ?? 'PENDIENTE';
          nuevoEstadoCategoria = estadoObj['categoria'] as String? ?? 'proforma';
          nuevoEstadoData = estadoObj;
        } else if (estadoObj is String) {
          nuevoEstadoCodigo = estadoObj;
        }

        // Actualizar en la lista
        final index = _pedidos.indexWhere((p) => p.id == id);
        if (index != -1) {
          _pedidos[index] = _pedidos[index].copyWith(
            estadoCodigo: nuevoEstadoCodigo,
            estadoCategoria: nuevoEstadoCategoria,
            estadoData: nuevoEstadoData,
          );
        }

        // Actualizar pedido actual si es el mismo
        if (_pedidoActual?.id == id) {
          _pedidoActual = _pedidoActual!.copyWith(
            estadoCodigo: nuevoEstadoCodigo,
            estadoCategoria: nuevoEstadoCategoria,
            estadoData: nuevoEstadoData,
          );
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

  /// Filtrar pedidos localmente por estado (usando código string)
  List<Pedido> getPedidosPorEstado(String estadoCodigo) {
    return _pedidos.where((p) => p.estadoCodigo == estadoCodigo).toList();
  }

  /// Obtener pedidos pendientes
  List<Pedido> get pedidosPendientes {
    return getPedidosPorEstado('PENDIENTE');
  }

  /// Obtener pedidos aprobados
  List<Pedido> get pedidosAprobados {
    return getPedidosPorEstado('APROBADA');
  }

  /// Obtener pedidos en proceso (preparando, en camión, en ruta)
  List<Pedido> get pedidosEnProceso {
    return _pedidos
        .where(
          (p) =>
              p.estadoCodigo == 'PREPARANDO' ||
              p.estadoCodigo == 'EN_CAMION' ||
              p.estadoCodigo == 'EN_RUTA' ||
              p.estadoCodigo == 'LLEGO',
        )
        .toList();
  }

  /// Obtener pedidos entregados
  List<Pedido> get pedidosEntregados {
    return getPedidosPorEstado('ENTREGADO');
  }

  /// Obtener pedidos con novedad
  List<Pedido> get pedidosConNovedad {
    return getPedidosPorEstado('NOVEDAD');
  }

  /// Aplicar filtro de estado
  Future<void> aplicarFiltroEstado(String? estadoCodigo) async {
    await loadPedidos(
      estado: estadoCodigo,
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
      search: _filtroBusqueda,
      fechaVencimientoDesde: _filtroFechaVencimientoDesde,
      fechaVencimientoHasta: _filtroFechaVencimientoHasta,
      fechaEntregaSolicitadaDesde: _filtroFechaEntregaSolicitadaDesde,
      fechaEntregaSolicitadaHasta: _filtroFechaEntregaSolicitadaHasta,
    );
  }

  // ✅ NUEVO: Aplicar filtro de fecha de vencimiento
  Future<void> aplicarFiltroFechaVencimiento(
    DateTime? desde,
    DateTime? hasta,
  ) async {
    await loadPedidos(
      estado: _filtroEstado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      search: _filtroBusqueda,
      fechaVencimientoDesde: desde,
      fechaVencimientoHasta: hasta,
      fechaEntregaSolicitadaDesde: _filtroFechaEntregaSolicitadaDesde,
      fechaEntregaSolicitadaHasta: _filtroFechaEntregaSolicitadaHasta,
    );
  }

  // ✅ NUEVO: Aplicar filtro de fecha de entrega solicitada
  Future<void> aplicarFiltroFechaEntregaSolicitada(
    DateTime? desde,
    DateTime? hasta,
  ) async {
    await loadPedidos(
      estado: _filtroEstado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      search: _filtroBusqueda,
      fechaVencimientoDesde: _filtroFechaVencimientoDesde,
      fechaVencimientoHasta: _filtroFechaVencimientoHasta,
      fechaEntregaSolicitadaDesde: desde,
      fechaEntregaSolicitadaHasta: hasta,
    );
  }

  /// Aplicar búsqueda
  // ✅ CAMBIO: De 'aplicarBusqueda' a 'aplicarBusquedaCliente' para mayor claridad
  // ✅ ACTUALIZADO 2026-02-21: Cambiar parámetro a 'search' para búsqueda unificada
  Future<void> aplicarBusquedaCliente(String? search) async {
    await loadPedidos(
      estado: _filtroEstado,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      search: search,
    );
  }

  // Mantener método anterior para compatibilidad
  @Deprecated('Usar aplicarBusquedaCliente en su lugar')
  Future<void> aplicarBusqueda(String? busqueda) async {
    await aplicarBusquedaCliente(busqueda);
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

    // ✅ Escuchar eventos de ventas (estado logístico cambió)
    _ventaSubscription = _webSocketService.ventaStream.listen((event) {
      final type = event['type'] as String;
      final data = event['data'] as Map<String, dynamic>;

      debugPrint('📊 PedidoProvider: Evento venta recibido: $type');

      switch (type) {
        case 'estado_cambio':
          _handleVentaEstadoCambio(data);
          break;
        case 'en_transito':
          _handleVentaEnTransito(data);
          break;
        case 'entregada':
          _handleVentaEntregada(data);
          break;
        case 'problema':
          _handleVentaProblema(data);
          break;
      }
    });
  }

  // Suscripción para eventos de venta
  StreamSubscription? _ventaSubscription;

  /// Detener escucha de eventos WebSocket
  void detenerEscuchaWebSocket() {
    debugPrint('🔌 PedidoProvider: Deteniendo escucha WebSocket');
    _proformaSubscription?.cancel();
    _envioSubscription?.cancel();
    _ubicacionSubscription?.cancel();
    _ventaSubscription?.cancel();
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
    // ✅ ACTUALIZADO: Usar código de estado String en lugar de enum
    final index = _pedidos.indexWhere((p) => p.id == proformaId);
    if (index != -1) {
      _pedidos[index] = _pedidos[index].copyWith(estadoCodigo: 'APROBADA');
      notifyListeners();
    }

    // Actualizar pedido actual si es el mismo
    if (_pedidoActual?.id == proformaId) {
      _pedidoActual = _pedidoActual!.copyWith(estadoCodigo: 'APROBADA');
      notifyListeners();
    }
  }

  void _handleProformaRejected(Map<String, dynamic> data) {
    // La proforma fue rechazada
    final proformaId = data['proforma_id'] as int;
    final motivo = data['motivo_rechazo'] as String?;
    debugPrint('❌ Proforma #$proformaId rechazada: $motivo');

    // ✅ ACTUALIZADO: Usar códigos de estado String
    // Actualizar estado
    final index = _pedidos.indexWhere((p) => p.id == proformaId);
    if (index != -1) {
      _pedidos[index] = _pedidos[index].copyWith(
        estadoCodigo: 'RECHAZADA',
        comentariosAprobacion: motivo,
      );
      notifyListeners();
    }

    if (_pedidoActual?.id == proformaId) {
      _pedidoActual = _pedidoActual!.copyWith(
        estadoCodigo: 'RECHAZADA',
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

    // ✅ CORREGIDO: Recargar usando proformaId (pedido), no ventaId
    // El pedido con ID=proformaId ahora tiene estadoCategoria='venta'
    // loadPedido() luego llamará a loadVentaForPedido() para cargar los datos completos
    if (proformaId != null) {
      loadPedido(proformaId);
    }
  }

  void _handleEnvioProgramado(Map<String, dynamic> data) {
    // Envío fue programado
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final fechaProgramada = data['fecha_programada'] as String?;
    debugPrint('📅 Envío programado: $ventaId para $fechaProgramada');

    // ✅ ACTUALIZADO: Usar código correcto para venta_logistica
    // Actualizar pedido relacionado
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'PROGRAMADO',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }

      // Actualizar pedido actual si es el mismo
      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'PROGRAMADO',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }
    }
  }

  void _handleEnvioEnPreparacion(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    debugPrint('📦 Envío en preparación: $ventaId');

    // ✅ ACTUALIZADO: Usar código correcto EN_PREPARACION (no PREPARANDO)
    // Actualizar estado del pedido
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'EN_PREPARACION',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'EN_PREPARACION',
          estadoCategoria: 'venta_logistica',
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

    // ✅ ACTUALIZADO: Usar código correcto EN_TRANSITO (no EN_RUTA)
    // Actualizar estado del pedido a EN_TRANSITO
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'EN_TRANSITO',
          estadoCategoria: 'venta_logistica',
          choferId: choferId,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'EN_TRANSITO',
          estadoCategoria: 'venta_logistica',
          choferId: choferId,
        );
        notifyListeners();
      }
    }
  }

  void _handleChoferLlego(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    debugPrint('📍 Chofer llegó: $ventaId');

    // ✅ ACTUALIZADO: Usar estado EN_TRANSITO para venta (LLEGO es para entrega)
    // Actualizar estado - el chofer llegó al destino
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'EN_TRANSITO',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'EN_TRANSITO',
          estadoCategoria: 'venta_logistica',
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

    // ✅ ACTUALIZADO: Usar código correcto ENTREGADA (no ENTREGADO)
    // Actualizar estado del pedido a ENTREGADA
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'ENTREGADA',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'ENTREGADA',
          estadoCategoria: 'venta_logistica',
        );
        notifyListeners();
      }
    }
  }

  void _handleEntregaRechazada(Map<String, dynamic> data) {
    final ventaId = data['venta_id'] ?? data['proforma_id'] ?? data['envio_id'];
    final motivo = data['motivo'] as String?;
    debugPrint('❌ Entrega rechazada: $ventaId - $motivo');

    // ✅ ACTUALIZADO: Usar código correcto PROBLEMAS (no NOVEDAD)
    // Actualizar estado del pedido con problemas
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'PROBLEMAS',
          estadoCategoria: 'venta_logistica',
          comentariosAprobacion: motivo,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'PROBLEMAS',
          estadoCategoria: 'venta_logistica',
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

  void _handleVentaEstadoCambio(Map<String, dynamic> data) {
    // La venta cambió de estado logístico
    final ventaId = data['venta_id'] ?? data['venta_numero'];
    final estadoNuevo = data['estado_nuevo'] as Map<String, dynamic>?;
    final codigo = estadoNuevo?['codigo'] as String? ?? 'DESCONOCIDO';
    final nombre = estadoNuevo?['nombre'] as String? ?? 'Estado desconocido';

    debugPrint('📊 Venta #$ventaId cambió estado: $codigo - $nombre');

    // Actualizar estado del pedido en la lista
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        // ✅ Usar datos dinámicos del estado directamente
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: codigo,
          estadoCategoria: estadoNuevo?['categoria'] ?? 'venta_logistica',
          estadoData: estadoNuevo,
        );
        notifyListeners();
      }

      // Actualizar pedido actual si es el mismo
      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: codigo,
          estadoCategoria: estadoNuevo?['categoria'] ?? 'venta_logistica',
          estadoData: estadoNuevo,
        );
        notifyListeners();
      }
    }
  }

  void _handleVentaEnTransito(Map<String, dynamic> data) {
    // La venta está en tránsito (chofer en ruta)
    final ventaId = data['venta_id'] ?? data['venta_numero'];
    final choferId = data['chofer_id'] as int?;
    final vehiculoPlaca = data['vehiculo']?['placa'] as String?;

    debugPrint('🚛 Venta #$ventaId en tránsito - Chofer: $choferId, Placa: $vehiculoPlaca');

    // ✅ Actualizar estado del pedido a EN_RUTA (usando estadoCodigo)
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'EN_RUTA',
          choferId: choferId,
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'EN_RUTA',
          choferId: choferId,
        );
        notifyListeners();
      }
    }
  }

  void _handleVentaEntregada(Map<String, dynamic> data) {
    // La venta fue entregada al cliente
    final ventaId = data['venta_id'] ?? data['venta_numero'];
    final fechaEntrega = data['fecha_entrega'] as String?;
    final recibidoPor = data['recibido_por'] as String?;

    debugPrint('✅ Venta #$ventaId entregada - Recibido por: $recibidoPor en $fechaEntrega');

    // ✅ Actualizar estado del pedido a ENTREGADO (usando estadoCodigo)
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'ENTREGADO',
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'ENTREGADO',
        );
        notifyListeners();
      }
    }
  }

  void _handleVentaProblema(Map<String, dynamic> data) {
    // Hubo un problema con la entrega
    final ventaId = data['venta_id'] ?? data['venta_numero'];
    final tipoProblema = data['tipo_problema'] as String? ?? 'Problema desconocido';
    final descripcion = data['descripcion'] as String?;

    debugPrint('❌ Venta #$ventaId con problema: $tipoProblema - $descripcion');

    // ✅ Actualizar estado del pedido a NOVEDAD (usando estadoCodigo)
    if (ventaId != null) {
      final index = _pedidos.indexWhere((p) => p.id == ventaId);
      if (index != -1) {
        _pedidos[index] = _pedidos[index].copyWith(
          estadoCodigo: 'NOVEDAD',
          comentariosAprobacion: '$tipoProblema: $descripcion',
        );
        notifyListeners();
      }

      if (_pedidoActual?.id == ventaId) {
        _pedidoActual = _pedidoActual!.copyWith(
          estadoCodigo: 'NOVEDAD',
          comentariosAprobacion: '$tipoProblema: $descripcion',
        );
        notifyListeners();
      }
    }
  }

  /// ✅ NUEVO: Anular una proforma pendiente o aprobada
  ///
  /// Parámetros:
  /// - proformaId: ID de la proforma a anular
  /// - motivo: Motivo de la anulación
  ///
  /// Retorna:
  /// - true si la anulación fue exitosa
  /// - false si hay error
  Future<bool> anularProforma(int proformaId, String motivo) async {
    try {
      _errorMessage = null;

      final response = await _proformaService.anularProforma(
        proformaId: proformaId,
        motivo: motivo,
      );

      if (response.success && response.data != null) {
        // Actualizar el pedido en la lista si existe
        final index = _pedidos.indexWhere((p) => p.id == proformaId);
        if (index != -1) {
          _pedidos[index] = response.data!;
        }

        // Actualizar pedido actual si es el mismo
        if (_pedidoActual?.id == proformaId) {
          _pedidoActual = response.data;
        }

        debugPrint('✅ Proforma #$proformaId anulada exitosamente');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        debugPrint('❌ Error al anular proforma: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado al anular: ${e.toString()}';
      debugPrint('❌ Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// ✅ NUEVO: Actualizar detalles de una proforma con detalles del carrito
  Future<bool> actualizarDetallesProforma({
    required int proformaId,
    required List<Map<String, dynamic>> detalles,
  }) async {
    if (detalles.isEmpty) {
      _errorMessage = 'El carrito no puede estar vacío';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('📝 Actualizando proforma #$proformaId con ${detalles.length} items');

      // Llamar servicio para actualizar detalles
      final response = await _proformaService.actualizarDetalles(
        proformaId: proformaId,
        detalles: detalles,
      );

      if (response.success && response.data != null) {
        // Actualizar el pedido actual con los nuevos datos
        _pedidoActual = response.data;

        // Actualizar en la lista también
        final index = _pedidos.indexWhere((p) => p.id == proformaId);
        if (index >= 0) {
          _pedidos[index] = response.data!;
        }

        debugPrint('✅ Proforma #$proformaId actualizada exitosamente');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error al actualizar proforma';
        debugPrint('❌ Error: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ Error al actualizar: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resetear provider
  void reset() {
    detenerEscuchaWebSocket();
    _pedidos = [];
    _pedidoActual = null;
    _ventaActual = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isLoadingVenta = false;
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
