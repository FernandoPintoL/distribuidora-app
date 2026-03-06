import 'package:flutter/widgets.dart';
import 'dart:async';
import '../models/entrega.dart';
import '../models/estadisticas_chofer.dart';
import '../models/ubicacion_tracking.dart';
import '../models/api_response.dart';
import '../services/entrega_service.dart';
import '../services/local_notification_service.dart';
import '../services/websocket_service.dart';
import '../providers/entrega_tracking_mixin.dart';

/// EntregaProvider - Fase 5/6: Sincronización de Entregas y SLA
///
/// RESPONSABILIDADES:
/// ✓ Gestionar estado de entregas (lista y detalle)
/// ✓ Sincronizar cambios de estado automáticamente vía WebSocket
/// ✓ Mantener datos SLA (fechaEntregaComprometida, ventanaEntrega*)
/// ✓ Notificar cambios en tiempo real a la UI
/// ✓ Manejar carga de ventas (FASE 2)
/// ✓ Iniciar tracking de GPS (FASE 4)
///
/// CICLO DE VIDA SLA:
/// - obtenerEntrega() carga todos los datos incluyendo SLA
/// - WebSocket eventos actualizan automáticamente el estado
/// - _actualizarEntregaActual() sincroniza el modelo con nuevos datos SLA
/// - UI escucha cambios y reflejan SLA visuales (widgets)
class EntregaProvider with ChangeNotifier, EntregaTrackingMixin {
  final EntregaService _entregaService = EntregaService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final WebSocketService _webSocketService = WebSocketService();

  List<Entrega> _entregas = [];
  Entrega? _entregaActual;
  EstadisticasChofer? _estadisticas; // ✅ NUEVO: Estadísticas del chofer
  List<UbicacionTracking> _ubicaciones = [];
  UbicacionTracking? _ubicacionActual;
  List<EntregaEstadoHistorial> _historialEstados = [];
  int _previousEntregasCount = 0;
  bool _isFirstLoad = true; // ✅ NUEVO: Evitar notificaciones en primera carga

  bool _isLoading = false;
  String? _errorMessage;

  // ✅ NUEVO: Estados para búsqueda y filtros
  String? _search;
  int? _localidadId;

  /// Override notifyListeners para debug
  @override
  void notifyListeners() {
    debugPrint(
      '👂 [NOTIFY_LISTENERS] LLAMADO - isLoading=$_isLoading, entregas.length=${_entregas.length}, entregaActual=${_entregaActual?.id}',
    );
    if (_entregas.isNotEmpty) {
      debugPrint('👂 [NOTIFY_LISTENERS] Primera entrega: ${_entregas.first.numeroEntrega}');
    }
    super.notifyListeners();
    debugPrint('👂 [NOTIFY_LISTENERS] COMPLETADO');
  }

  // WebSocket subscriptions
  StreamSubscription? _entregaSubscription;
  StreamSubscription? _cargoSubscription;
  StreamSubscription?
  _ventaSubscription; // ✅ NUEVO: Para sincronizar estado de ventas

  // Getters
  List<Entrega> get entregas => _entregas;
  Entrega? get entregaActual => _entregaActual;
  EstadisticasChofer? get estadisticas => _estadisticas; // ✅ NUEVO: Getter para estadísticas
  List<UbicacionTracking> get ubicaciones => _ubicaciones;
  UbicacionTracking? get ubicacionActual => _ubicacionActual;
  List<EntregaEstadoHistorial> get historialEstados => _historialEstados;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get search => _search;  // ✅ NUEVO: Getter para búsqueda
  int? get localidadId => _localidadId;  // ✅ NUEVO: Getter para localidad

  // ✅ ACTUALIZADO: Obtener entregas asignadas - Rango de fechas de CREACIÓN (created_at)
  Future<bool> obtenerEntregasAsignadas({
    int page = 1,
    String? estado,
    String? createdDesde,  // ✅ ACTUALIZADO: Rango de fechas de creación (created_at)
    String? createdHasta,  // ✅ ACTUALIZADO: Rango de fechas de creación (created_at)
    String? search,  // ✅ NUEVO: búsqueda case-insensitive
    int? localidadId,  // ✅ NUEVO: filtro por localidad
  }) async {
    // ✅ NUEVO: Guardar búsqueda y localidad en estado
    _search = search;
    _localidadId = localidadId;

    _isLoading = true;
    _errorMessage = null;
    debugPrint('🔍 [ENTREGA_PROVIDER] Iniciando carga - notificando isLoading=true');
    debugPrint('🔍 [ENTREGA_PROVIDER] Parámetros: search=$search, localidad_id=$localidadId, createdDesde=$createdDesde, createdHasta=$createdHasta');
    notifyListeners();

    try {
      final response = await _entregaService.obtenerEntregasAsignadas(
        page: page,
        estado: estado,
        createdDesde: createdDesde,  // ✅ ACTUALIZADO: Pasar parámetros de created_at
        createdHasta: createdHasta,  // ✅ ACTUALIZADO: Pasar parámetros de created_at
        search: search,  // ✅ NUEVO
        localidadId: localidadId,  // ✅ NUEVO
      );

      if (response.success && response.data != null) {
        final newEntregas = response.data!;

        debugPrint('🔍 [ENTREGA_PROVIDER] Respuesta exitosa recibida');
        debugPrint('🔍 [ENTREGA_PROVIDER] newEntregas.length = ${newEntregas.length}');
        debugPrint('🔍 [ENTREGA_PROVIDER] newEntregas.isEmpty = ${newEntregas.isEmpty}');
        if (newEntregas.isNotEmpty) {
          debugPrint('🔍 [ENTREGA_PROVIDER] Primera entrega ID: ${newEntregas.first.id}, numero: ${newEntregas.first.numeroEntrega}');
        }

        // ✅ OPTIMIZADO: Detectar nuevas entregas y mostrar notificaciones
        // PERO: No mostrar notificaciones en la PRIMERA carga
        // Esto evita que lleguen 11 notificaciones de golpe al abrir entregas_asignadas_screen
        if (!_isFirstLoad && newEntregas.length > _previousEntregasCount) {
          final nuevasEntregas = newEntregas.length - _previousEntregasCount;
          for (int i = 0; i < nuevasEntregas && i < newEntregas.length; i++) {
            final entrega = newEntregas[i];
            await _notificationService.showNewDeliveryNotification(
              deliveryId: entrega.id,
              clientName: entrega.cliente ?? 'Cliente',
              address: entrega.direccion ?? 'Dirección desconocida',
            );
          }
        }

        _entregas = newEntregas;
        debugPrint('🔍 [ENTREGA_PROVIDER] _entregas asignado! Count: ${_entregas.length}');

        _previousEntregasCount = newEntregas.length;
        _isFirstLoad = false; // ✅ Marcar que ya se cargó la primera vez
        _errorMessage = null;

        debugPrint('🔍 [ENTREGA_PROVIDER] Llamando notifyListeners() DIRECTAMENTE con ${_entregas.length} entregas');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        debugPrint('🔍 [ENTREGA_PROVIDER] Error: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('🔍 [ENTREGA_PROVIDER] Exception en catch: $_errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      debugPrint('🔍 [ENTREGA_PROVIDER] finally: _isLoading = false, notificando');
      notifyListeners();
    }
  }

  // ✅ NUEVO: Obtener estadísticas rápidas (optimizado para dashboard)
  Future<bool> obtenerEstadisticas() async {
    try {
      debugPrint('📊 [ESTADISTICAS] Iniciando carga de estadísticas');

      final response = await _entregaService.obtenerEstadisticas();

      if (response.success && response.data != null) {
        _estadisticas = response.data;
        _errorMessage = null;

        debugPrint(
          '✅ [ESTADISTICAS] Estadísticas cargadas: ${_estadisticas?.totalEntregas} entregas',
        );
        debugPrint(
          '✅ [ESTADISTICAS] Valores: preparacion=${_estadisticas?.entregasEnPreparacion}, listas=${_estadisticas?.entregasListasEntrega}, ruta=${_estadisticas?.entregasEnRuta}, entregadas=${_estadisticas?.entregasEntregadas}',
        );

        // ✅ Llamar notifyListeners() directamente SIN postFrameCallback
        debugPrint('📢 [ESTADISTICAS] Llamando notifyListeners() ahora mismo');
        notifyListeners();
        debugPrint('📢 [ESTADISTICAS] notifyListeners() completado');

        // Configurar listener de WebSocket para actualizaciones en tiempo real
        _setupStatsWebSocketListener();

        return true;
      } else {
        _errorMessage = response.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al obtener estadísticas: ${e.toString()}';
      debugPrint('❌ [ESTADISTICAS] Error: $_errorMessage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  // ✅ NUEVO: Escuchar eventos de WebSocket para actualizaciones de estadísticas
  void _setupStatsWebSocketListener() {
    // Escuchar evento de estadísticas actualizadas
    _webSocketService.on('estadisticas:actualizadas', (data) {
      debugPrint('📊 [WS_STATS] Evento recibido: $data');

      if (data is Map<String, dynamic>) {
        // Actualizar estadísticas locales
        _estadisticas = EstadisticasChofer.fromJson(data);

        debugPrint(
          '✅ [WS_STATS] Estadísticas actualizadas: ${_estadisticas?.totalEntregas} entregas',
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    });
  }

  // Obtener detalle de una entrega
  Future<bool> obtenerEntrega(int entregaId) async {
    debugPrint('🔄 [OBTENER_ENTREGA] Iniciando carga de entrega #$entregaId');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('📤 [OBTENER_ENTREGA] Haciendo request al backend...');
      final response = await _entregaService.obtenerEntrega(entregaId);

      debugPrint(
        '✅ [OBTENER_ENTREGA] Respuesta recibida: success=${response.success} , data=${response.data}',
      );

      if (response.success && response.data != null) {
        debugPrint(
          '✅ [OBTENER_ENTREGA] Datos válidos, llenando _entregaActual',
        );
        _entregaActual = response.data;
        _errorMessage = null;

        // El historial de estados ya viene en la respuesta de entrega
        _historialEstados = _entregaActual?.historialEstados ?? [];

        // Cargar solo ubicaciones (el historial ya está en la entrega)
        debugPrint('📍 [OBTENER_ENTREGA] Cargando ubicaciones...');
        await obtenerUbicaciones(entregaId);
        debugPrint('✅ [OBTENER_ENTREGA] Ubicaciones cargadas');
        notifyListeners();
        debugPrint('✅ [OBTENER_ENTREGA] ¡COMPLETO! Retornando true');
        return true;
      } else {
        debugPrint(
          '❌ [OBTENER_ENTREGA] Respuesta sin éxito: ${response.message}',
        );
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [OBTENER_ENTREGA] EXCEPCIÓN: $e');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      debugPrint('❌ [OBTENER_ENTREGA] Retornando false');
      return false;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Iniciar ruta
  Future<bool> iniciarRuta(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.iniciarRuta(
        entregaId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        // Mostrar notificación de cambio de estado
        await _notificationService.showDeliveryStateChangeNotification(
          deliveryId: _entregaActual!.id,
          newState: _entregaActual!.estado,
          clientName: _entregaActual!.cliente ?? 'Cliente',
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

  // Marcar llegada
  Future<bool> marcarLlegada(
    int entregaId, {
    required double latitud,
    required double longitud,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.marcarLlegada(
        entregaId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        // Mostrar notificación de cambio de estado
        await _notificationService.showDeliveryStateChangeNotification(
          deliveryId: _entregaActual!.id,
          newState: _entregaActual!.estado,
          clientName: _entregaActual!.cliente ?? 'Cliente',
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

  // Confirmar entrega (completa o una venta específica)
  Future<bool> confirmarEntrega(
    int entregaId, {
    int? ventaId, // Si viene, confirma una venta específica
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
    // ✅ Estado de venta (ENTREGADA o CANCELADA)
    String? estadoVenta,
    // ✅ FASE 1: Confirmación de Pago
    String? estadoPago,
    double? montoRecibido,
    int? tipoPagoId,
    String? motivoNoPago,
    // ✅ FASE 2: Foto de comprobante
    String? fotoComprobanteBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.confirmarEntrega(
        entregaId,
        ventaId: ventaId,
        firmaBase64: firmaBase64,
        fotosBase64: fotosBase64,
        observaciones: observaciones,
        // ✅ Estado de venta
        estadoVenta: estadoVenta,
        // ✅ FASE 1: Pago
        estadoPago: estadoPago,
        montoRecibido: montoRecibido,
        tipoPagoId: tipoPagoId,
        motivoNoPago: motivoNoPago,
        // ✅ FASE 2: Foto de comprobante
        fotoComprobanteBase64: fotoComprobanteBase64,
      );

      // debugPrint("Response: $response");

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        // Mostrar notificación de cambio de estado
        await _notificationService.showDeliveryStateChangeNotification(
          deliveryId: _entregaActual!.id,
          newState: _entregaActual!.estado,
          clientName: _entregaActual!.cliente ?? 'Cliente',
        );

        // Si todas las entregas están completadas, mostrar notificación de finalización
        if (_entregas.every(
          (e) => e.estado == 'ENTREGADO' || e.estado == 'CANCELADA',
        )) {
          await _notificationService.showCompletionNotification();
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

  // Reportar novedad
  Future<bool> reportarNovedad(
    int entregaId, {
    required String motivo,
    String? descripcion,
    String? fotoBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.reportarNovedad(
        entregaId,
        motivo: motivo,
        descripcion: descripcion,
        fotoBase64: fotoBase64,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

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

  // Registrar ubicación
  Future<bool> registrarUbicacion(
    int entregaId, {
    required double latitud,
    required double longitud,
    double? velocidad,
    double? rumbo,
    double? altitud,
    double? precision,
    String? evento,
  }) async {
    try {
      final response = await _entregaService.registrarUbicacion(
        entregaId,
        latitud: latitud,
        longitud: longitud,
        velocidad: velocidad,
        rumbo: rumbo,
        altitud: altitud,
        precision: precision,
        evento: evento,
      );

      if (response.success && response.data != null) {
        _ubicacionActual = response.data;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener ubicaciones
  Future<bool> obtenerUbicaciones(int entregaId) async {
    try {
      debugPrint('📍 [OBTENER_UBICACIONES] Iniciando carga...');
      final response = await _entregaService.obtenerUbicaciones(entregaId);

      debugPrint(
        '✅ [OBTENER_UBICACIONES] Respuesta: success=${response.success}, count=${response.data?.length ?? 0}',
      );
      if (response.success && response.data != null) {
        _ubicaciones = response.data!;
        debugPrint(
          '✅ [OBTENER_UBICACIONES] Ubicaciones almacenadas, notifyListeners()',
        );
        notifyListeners(); // ✅ INMEDIATO
        debugPrint('✅ [OBTENER_UBICACIONES] ¡COMPLETO!');
        return true;
      } else {
        debugPrint('❌ [OBTENER_UBICACIONES] Sin datos');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [OBTENER_UBICACIONES] EXCEPCIÓN: $e');
      return false;
    }
  }

  // Obtener última ubicación
  Future<bool> obtenerUltimaUbicacion(int entregaId) async {
    try {
      final response = await _entregaService.obtenerUltimaUbicacion(entregaId);

      if (response.success && response.data != null) {
        _ubicacionActual = response.data;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Calcular ETA
  Future<bool> calcularETA(
    int entregaId, {
    required double latDestino,
    required double lngDestino,
  }) async {
    try {
      final response = await _entregaService.calcularETA(
        entregaId,
        latDestino: latDestino,
        lngDestino: lngDestino,
      );

      if (response.success && response.data != null) {
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Obtener historial de estados
  Future<bool> obtenerHistorialEstados(int entregaId) async {
    try {
      final response = await _entregaService.obtenerHistorialEstados(entregaId);

      if (response.success && response.data != null) {
        _historialEstados = response.data!;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Actualizar entrega en la lista
  void _actualizarEnListaEntregas(Entrega entrega) {
    final index = _entregas.indexWhere((e) => e.id == entrega.id);
    if (index >= 0) {
      _entregas[index] = entrega;
    }
  }

  /// Iniciar escucha de eventos WebSocket
  void iniciarEscuchaWebSocket() {
    debugPrint('🔌 EntregaProvider: Iniciando escucha WebSocket');

    // Escuchar eventos de entregas
    _entregaSubscription = _webSocketService.entregaStream.listen((event) {
      debugPrint('📦 EntregaProvider recibió evento: ${event['type']}');
      _handleEntregaEvent(event);
    });

    // Escuchar eventos de carga/confirmación
    _cargoSubscription = _webSocketService.cargoStream.listen((event) {
      debugPrint(
        '📦 EntregaProvider recibió evento de carga: ${event['type']}',
      );
      _handleCargoEvent(event);
    });

    // ✅ NUEVO: Escuchar eventos de cambio de estado de ventas
    // Cuando entrega → EN_TRANSITO, todas las ventas sincronizadas también lo harán
    _ventaSubscription = _webSocketService.ventaStream.listen((event) {
      debugPrint(
        '📊 EntregaProvider recibió evento de venta: ${event['type']}',
      );
      _handleVentaEvent(event);
    });
  }

  /// Detener escucha de eventos WebSocket
  void detenerEscuchaWebSocket() {
    debugPrint('🔌 EntregaProvider: Deteniendo escucha WebSocket');
    _entregaSubscription?.cancel();
    _cargoSubscription?.cancel();
    _ventaSubscription?.cancel(); // ✅ NUEVO: Cancelar escucha de ventas
  }

  /// Manejar eventos de entregas
  void _handleEntregaEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
      case 'asignada':
        // ✅ NUEVO: Cuando entrega consolidada se asigna al chofer
        debugPrint('🚚 ENTREGA CONSOLIDADA ASIGNADA');
        debugPrint('   Entrega: #${data['numero_entrega'] ?? 'N/A'}');
        debugPrint('   Chofer: ${data['chofer']?['nombre'] ?? 'N/A'}');
        debugPrint('   Vehículo: ${data['vehiculo']?['placa'] ?? 'N/A'}');
        debugPrint('   Peso Total: ${data['peso_kg']} kg');
        debugPrint('   Cantidad de Ventas: ${data['cantidad_ventas'] ?? 'N/A'}');

        // Mostrar notificación local al chofer
        final numeroEntrega = data['numero_entrega'] as String? ?? 'N/A';
        final nombreChofer = data['chofer']?['nombre'] as String? ?? 'Entrega asignada';
        final placaVehiculo = data['vehiculo']?['placa'] as String? ?? 'N/A';
        _notificationService.showEnvioProgramadoNotification(
          envioId: numeroEntrega.hashCode,
          cliente: 'Entrega $numeroEntrega - $placaVehiculo',
          fecha: nombreChofer,
        );

        // Actualizar entrega actual
        _actualizarEntregaActual(data);

        // Notificar listeners para que UI se actualice
        notifyListeners();
        break;

      case 'preparacion_carga':
        debugPrint('📋 Entrega en preparación de carga: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      case 'en_carga':
        debugPrint('📦 Entrega en carga: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      case 'listo_para_entrega':
        debugPrint('✅ Entrega lista para entrega: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      case 'en_transito':
        debugPrint('🚚 Entrega en tránsito: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      case 'completada':
        debugPrint('🎉 Entrega completada: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      case 'novedad':
        debugPrint('⚠️ Novedad en entrega: ${data['numero']}');
        _actualizarEntregaActual(data);
        break;
      default:
        debugPrint('❓ Evento de entrega desconocido: $type');
    }
  }

  /// Manejar eventos de carga/confirmación
  void _handleCargoEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
      case 'venta_cargada':
        debugPrint('✔️ Venta cargada: ${data['venta_numero']}');
        // Actualizar entrega actual si existe
        if (_entregaActual?.id == data['entrega_id']) {
          // Podrías recargar la entrega aquí si es necesario
          notifyListeners();
        }
        break;
      case 'progreso':
        debugPrint('📊 Progreso: ${data['confirmadas']}/${data['total']}');
        if (_entregaActual?.id == data['entrega_id']) {
          notifyListeners();
        }
        break;
      case 'confirmado':
        debugPrint('🎉 Carga confirmada: ${data['entrega_numero']}');
        _actualizarEntregaActual(data);
        break;
      default:
        debugPrint('❓ Evento de carga desconocido: $type');
    }
  }

  /// ✅ NUEVO: Manejar eventos de cambio de estado de ventas
  /// Se dispara cuando una venta cambia de estado (ej: EN_TRANSITO)
  /// Esto ocurre cuando su entrega cambió al mismo estado
  void _handleVentaEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
      case 'estado_cambio':
        debugPrint(
          '📊 Venta #${data['venta_numero']} cambió a: ${data['estado_nuevo']?['codigo']}',
        );
        // Si esta venta pertenece a la entrega actual, actualizar
        if (_entregaActual != null && _entregaActual!.ventas != null) {
          final ventaIndex = _entregaActual!.ventas!.indexWhere(
            (v) => v.id == data['venta_id'],
          );
          if (ventaIndex != -1) {
            // Actualizar estado de la venta específica
            debugPrint('✅ Sincronizado estado de venta en entrega actual');
            notifyListeners(); // Notificar UI que actualice
          }
        }
        break;

      case 'en_transito':
        debugPrint('🚚 Venta #${data['venta_numero']} está EN TRANSITO');
        // Caso especial: venta comenzó a ser entregada
        // Si pertenece a la entrega actual, notificar UI
        if (_entregaActual != null && _entregaActual!.ventas != null) {
          final ventaIndex = _entregaActual!.ventas!.indexWhere(
            (v) => v.id == data['venta_id'],
          );
          if (ventaIndex != -1) {
            debugPrint('✅ Venta en entrega actual está en tránsito');
            notifyListeners();
          }
        }
        break;

      case 'entregada':
        debugPrint('✅ Venta #${data['venta_numero']} fue ENTREGADA');
        // Venta completamente entregada
        if (_entregaActual != null && _entregaActual!.ventas != null) {
          final ventaIndex = _entregaActual!.ventas!.indexWhere(
            (v) => v.id == data['venta_id'],
          );
          if (ventaIndex != -1) {
            debugPrint('✅ Venta en entrega actual fue entregada');
            notifyListeners();
          }
        }
        break;

      case 'problema':
        debugPrint(
          '❌ Problema en venta #${data['venta_numero']}: ${data['motivo']}',
        );
        // Venta con problema (rechazo, novedad, etc)
        if (_entregaActual != null && _entregaActual!.ventas != null) {
          final ventaIndex = _entregaActual!.ventas!.indexWhere(
            (v) => v.id == data['venta_id'],
          );
          if (ventaIndex != -1) {
            debugPrint('⚠️ Problema reportado en venta de entrega actual');
            notifyListeners();
          }
        }
        break;

      case 'preparacion_carga':
        // ✅ NUEVO: Cuando venta entra en PREPARACION_CARGA
        debugPrint('📦 VENTA EN PREPARACION DE CARGA');
        debugPrint('   Cantidad de Ventas: ${data['cantidad_ventas'] ?? 'N/A'}');
        debugPrint('   Ventas: ${data['ventas_numeros']?.join(", ") ?? 'N/A'}');
        debugPrint('   Entrega: #${data['numero_entrega'] ?? 'N/A'}');
        debugPrint('   Mensaje: ${data['mensaje'] ?? 'N/A'}');

        // Mostrar notificación local al usuario
        final cantidadVentas = data['cantidad_ventas'] as int? ?? 1;
        final numeroEntrega = data['numero_entrega'] as String? ?? 'N/A';
        _notificationService.showEnvioProgramadoNotification(
          envioId: numeroEntrega.hashCode,
          cliente: 'Tu venta${cantidadVentas > 1 ? 's' : ''} (${cantidadVentas}) está en preparación',
          fecha: numeroEntrega,
        );

        // Notificar a listeners para que UI se actualice
        notifyListeners();
        break;

      case 'listo_para_entrega':
        // ✅ NUEVO: Cuando venta cambia a PENDIENTE_ENVIO (listo para entrega)
        debugPrint('✅ VENTA LISTA PARA ENTREGA');
        debugPrint('   Cantidad de Ventas: ${data['cantidad_ventas'] ?? 'N/A'}');
        debugPrint('   Ventas: ${data['ventas_numeros']?.join(", ") ?? 'N/A'}');
        debugPrint('   Entrega: #${data['numero_entrega'] ?? 'N/A'}');
        debugPrint('   Estado Anterior: ${data['estado_logistico_anterior'] ?? 'N/A'}');
        debugPrint('   Estado Nuevo: ${data['estado_logistico_nuevo'] ?? 'N/A'}');
        debugPrint('   Mensaje: ${data['mensaje'] ?? 'N/A'}');

        // Mostrar notificación local al usuario
        final cantidadVentasListo = data['cantidad_ventas'] as int? ?? 1;
        final numeroEntregaListo = data['numero_entrega'] as String? ?? 'N/A';
        _notificationService.showEnvioProgramadoNotification(
          envioId: numeroEntregaListo.hashCode + 1,
          cliente: 'Tu venta${cantidadVentasListo > 1 ? 's' : ''} (${cantidadVentasListo}) está lista para envío',
          fecha: numeroEntregaListo,
        );

        // Notificar a listeners para que UI se actualice
        notifyListeners();
        break;

      default:
        debugPrint('❓ Evento de venta desconocido: $type');
    }
  }

  /// Actualizar entrega actual desde datos WebSocket
  /// FASE 5/6: Sincroniza automáticamente datos SLA
  void _actualizarEntregaActual(Map<String, dynamic> data) {
    try {
      final entregaActualizada = Entrega.fromJson(data);
      if (_entregaActual?.id == entregaActualizada.id) {
        // Log SLA synchronization if present
        if (entregaActualizada.fechaEntregaComprometida != null) {
          debugPrint(
            '⏰ [SLA SYNC] Entrega ${entregaActualizada.id}:'
            ' Fecha comprometida: ${entregaActualizada.fechaEntregaComprometida}',
          );
          if (entregaActualizada.ventanaEntregaIni != null &&
              entregaActualizada.ventanaEntregaFin != null) {
            debugPrint(
              '⏰ [SLA SYNC] Ventana: '
              '${entregaActualizada.ventanaEntregaIni!.hour}:${entregaActualizada.ventanaEntregaIni!.minute} - '
              '${entregaActualizada.ventanaEntregaFin!.hour}:${entregaActualizada.ventanaEntregaFin!.minute}',
            );
          }
        }

        _entregaActual = entregaActualizada;
        _actualizarEnListaEntregas(entregaActualizada);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error actualizando entrega desde WebSocket: $e');
    }
  }

  // Confirmar venta cargada (FASE 2)
  Future<bool> confirmarVentaCargada(
    int entregaId,
    int ventaId, {
    String? notas,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.confirmarVentaCargada(
        entregaId,
        ventaId,
        notas: notas,
      );

      if (response.success) {
        // Actualizar la entrega si se devuelve (puede ser null si solo hubo confirmación)
        if (response.data != null) {
          _entregaActual = response.data;
          _actualizarEnListaEntregas(_entregaActual!);
        }
        // Si no hay datos, recargar la entrega para obtener los cambios
        else {
          await obtenerEntrega(entregaId);
        }
        _errorMessage = null;

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
      _errorMessage = 'Error al confirmar venta: ${e.toString()}';
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

  // Desmarcar venta cargada (FASE 2)
  Future<bool> desmarcarVentaCargada(int entregaId, int ventaId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.desmarcarVentaCargada(
        entregaId,
        ventaId,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

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
      _errorMessage = 'Error al desmarcar venta: ${e.toString()}';
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

  // Confirmar cargo completo (FASE 2)
  Future<bool> confirmarCargoCompleto(int entregaId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.confirmarCargoCompleto(entregaId);

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        // Mostrar notificación de cambio de estado
        await _notificationService.showDeliveryStateChangeNotification(
          deliveryId: _entregaActual!.id,
          newState: _entregaActual!.estado,
          clientName: _entregaActual!.cliente ?? 'Cliente',
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
      _errorMessage = 'Error al confirmar cargo: ${e.toString()}';
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

  // Confirmar venta entregada (FASE 3: Entrega Individual)
  Future<bool> confirmarVentaEntregada(
    int entregaId,
    int ventaId, {
    required Function(String) onSuccess,
    required Function(String) onError,
    List<String>? fotosBase64,
    String? observaciones,
    String? observacionesLogistica,  // ✅ NUEVO: Observaciones logísticas (estado entrega, incidentes)
    double? montoRecibido,  // ✅ NUEVO: Monto que pagó el cliente (backward compatible)
    int? tipoPagoId,  // ✅ NUEVO: ID del tipo de pago (backward compatible)
    // ✅ NUEVA 2026-02-12: Múltiples pagos
    List<Map<String, dynamic>>? pagos,  // Array de {tipo_pago_id, monto, referencia}
    bool? esCredito,  // ✅ CAMBIO: Si es promesa de pago (no dinero real)
    String? tipoConfirmacion,  // COMPLETA o CON_NOVEDAD
    // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
    List<Map<String, dynamic>>? productosRechazados,  // Array de {detalle_venta_id, nombre_producto, cantidad, precio_unitario, subtotal}
    // ✅ NUEVA 2026-03-05: Campos de novedad
    String? tipoNovedad,  // CLIENTE_CERRADO, DEVOLUCION_PARCIAL, RECHAZADO, NO_CONTACTADO
    bool? tiendaAbierta,
    bool? clientePresente,
    String? motivoRechazo,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint(
        '✅ Confirmando venta #$ventaId entregada en entrega #$entregaId',
      );

      final response = await _entregaService.confirmarVentaEntregada(
        entregaId,
        ventaId,
        fotosBase64: fotosBase64,
        observaciones: observaciones,
        observacionesLogistica: observacionesLogistica,  // ✅ NUEVO: Pasar observaciones logísticas
        montoRecibido: montoRecibido,  // ✅ NUEVO: Pasar monto (backward compatible)
        tipoPagoId: tipoPagoId,  // ✅ NUEVO: Pasar tipo de pago (backward compatible)
        // ✅ NUEVA 2026-02-12: Múltiples pagos
        pagos: pagos,  // Array de pagos múltiples
        esCredito: esCredito,  // ✅ CAMBIO: Si es promesa de pago
        tipoConfirmacion: tipoConfirmacion,  // COMPLETA o CON_NOVEDAD
        // ✅ NUEVA 2026-02-15: Productos rechazados en devolución parcial
        productosRechazados: productosRechazados,  // Array de productos rechazados
        // ✅ NUEVA 2026-03-05: Campos de novedad
        tipoNovedad: tipoNovedad,
        tiendaAbierta: tiendaAbierta,
        clientePresente: clientePresente,
        motivoRechazo: motivoRechazo,
      );

      if (response.success) {
        _errorMessage = null;

        // Llamar callback de éxito
        onSuccess(response.message ?? 'Venta entregada correctamente');

        // Recargar la entrega para obtener datos actualizados
        await obtenerEntrega(entregaId);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;

        // Llamar callback de error
        onError(_errorMessage ?? 'Error desconocido');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      onError(_errorMessage!);

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

  // Finalizar entrega (FASE 3: Entrega Completada)
  Future<bool> finalizarEntrega(
    int entregaId, {
    required Function(String) onSuccess,
    required Function(String) onError,
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
    double? montoRecolectado,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('✅ Finalizando entrega #$entregaId');

      final response = await _entregaService.finalizarEntrega(
        entregaId,
        firmaBase64: firmaBase64,
        fotosBase64: fotosBase64,
        observaciones: observaciones,
        montoRecolectado: montoRecolectado,
      );

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _actualizarEnListaEntregas(_entregaActual!);
        _errorMessage = null;

        // Mostrar notificación de cambio de estado
        await _notificationService.showDeliveryStateChangeNotification(
          deliveryId: _entregaActual!.id,
          newState: _entregaActual!.estado,
          clientName: _entregaActual!.cliente ?? 'Cliente',
        );

        // Llamar callback de éxito
        onSuccess(response.message ?? 'Entrega finalizada correctamente');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = response.message;

        // Llamar callback de error
        onError(_errorMessage ?? 'Error desconocido');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      onError(_errorMessage!);

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

  // Obtener progreso de entrega (FASE 2)
  Future<Map<String, dynamic>?> obtenerProgresoEntrega(int entregaId) async {
    try {
      final response = await _entregaService.obtenerProgresoEntrega(entregaId);

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error al obtener progreso: ${e.toString()}';
      return null;
    }
  }

  /// FASE 4: Iniciar entrega y tracking de GPS
  ///
  /// FLUJO:
  /// 1. Valida que estado actual sea LISTO_PARA_ENTREGA
  /// 2. Cambia estado a EN_RUTA en el backend
  /// 3. Inicia tracking de GPS automáticamente
  ///
  /// CALLBACKS:
  /// - onSuccess: Se llama cuando todo se completó correctamente
  /// - onError: Se llama si hay algún error en el proceso
  Future<bool> iniciarEntrega(
    int entregaId, {
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Validar que el estado actual sea LISTO_PARA_ENTREGA
      if (_entregaActual == null) {
        _errorMessage = 'Entrega no cargada';
        onError('Entrega no cargada');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      final estadoActual =
          _entregaActual!.estadoEntregaCodigo ?? _entregaActual!.estado;
      debugPrint('🔍 [INICIAR_ENTREGA] Estado actual: $estadoActual');

      if (estadoActual != 'LISTO_PARA_ENTREGA') {
        _errorMessage =
            'La entrega debe estar en estado LISTO_PARA_ENTREGA. Estado actual: $estadoActual';
        onError(_errorMessage!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      debugPrint('✅ [INICIAR_ENTREGA] Validación OK, iniciando proceso...');

      // Cambiar estado a EN_RUTA (usando iniciarRuta con ubicación dummy)
      // En la práctica, el GPS tracking iniciará el registro de ubicaciones reales
      // pero primero necesitamos que el estado esté en EN_RUTA
      debugPrint('📤 [INICIAR_ENTREGA] Cambiando estado a EN_RUTA...');

      // Para cambiar el estado, usaremos el endpoint de iniciarRuta
      // (que en el backend debería cambiar LISTO_PARA_ENTREGA → EN_RUTA)
      final respuestaEstado = await _entregaService.iniciarRuta(
        entregaId,
        latitud: _entregaActual!.latitudeDestino ?? 0,
        longitud: _entregaActual!.longitudeDestino ?? 0,
      );

      if (!respuestaEstado.success) {
        _errorMessage = 'Error cambiando estado: ${respuestaEstado.message}';
        onError(_errorMessage!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      // Actualizar la entrega actual con la respuesta
      _entregaActual = respuestaEstado.data;
      _actualizarEnListaEntregas(_entregaActual!);

      debugPrint('✅ [INICIAR_ENTREGA] Estado actualizado a EN_RUTA');

      // Mostrar notificación de cambio de estado
      await _notificationService.showDeliveryStateChangeNotification(
        deliveryId: _entregaActual!.id,
        newState: _entregaActual!.estado,
        clientName: _entregaActual!.cliente ?? 'Cliente',
      );

      // ✅ Estado actualizado a EN_RUTA - Sin GPS tracking
      debugPrint('✅ [INICIAR_ENTREGA] Entrega iniciada sin GPS tracking');
      onSuccess('Entrega iniciada correctamente');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ [INICIAR_ENTREGA] Excepción: $e');
      onError(_errorMessage!);
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

  /// ✅ NUEVO: Confirmar carga lista
  /// Cambia estado de PREPARACION_CARGA a LISTO_PARA_ENTREGA
  Future<bool> confirmarCargaLista(
    int entregaId, {
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Validar que el estado actual sea PREPARACION_CARGA
      if (_entregaActual == null) {
        _errorMessage = 'Entrega no cargada';
        onError('Entrega no cargada');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      final estadoActual =
          _entregaActual!.estadoEntregaCodigo ?? _entregaActual!.estado;
      debugPrint('🔍 [CONFIRMAR_CARGA] Estado actual: $estadoActual');

      if (estadoActual != 'PREPARACION_CARGA') {
        _errorMessage =
            'La entrega debe estar en estado PREPARACION_CARGA. Estado actual: $estadoActual';
        onError(_errorMessage!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      debugPrint('✅ [CONFIRMAR_CARGA] Validación OK, confirmando carga...');

      // Confirmar cargo completo (cambia estado a LISTO_PARA_ENTREGA)
      final response = await confirmarCargoCompleto(entregaId);

      if (response) {
        debugPrint('✅ [CONFIRMAR_CARGA] Carga confirmada correctamente');
        onSuccess('Carga confirmada. Listo para iniciar entrega.');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return true;
      } else {
        _errorMessage = errorMessage ?? 'Error al confirmar carga';
        onError(_errorMessage!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ [CONFIRMAR_CARGA] Excepción: $e');
      onError(_errorMessage!);
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

  /// Reintentar tracking GPS sin cambiar el estado
  /// Se usa cuando el GPS falló pero el estado ya está EN_TRANSITO
  Future<bool> reintentarTracking({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      if (_entregaActual == null) {
        _errorMessage = 'Entrega no cargada';
        onError('Entrega no cargada');
        return false;
      }

      final estadoActual =
          _entregaActual!.estadoEntregaCodigo ?? _entregaActual!.estado;
      debugPrint('🔄 [REINTENTAR_TRACKING] Estado actual: $estadoActual');

      // Verificar que esté en estado EN_TRANSITO o similar
      if (estadoActual != 'EN_TRANSITO' &&
          estadoActual != 'EN_CAMINO' &&
          estadoActual != 'LLEGO') {
        _errorMessage =
            'Solo se puede reintentar tracking en estado EN_TRANSITO. Estado actual: $estadoActual';
        onError(_errorMessage!);
        return false;
      }

      debugPrint('✅ [REINTENTAR_TRACKING] Validación OK, reiniciando GPS...');

      // Detener tracking anterior si existe
      if (isTracking) {
        await detenerTracking();
      }

      debugPrint('🚀 [REINTENTAR_TRACKING] Iniciando GPS tracking...');

      // Iniciar tracking nuevamente
      await iniciarTracking(
        entregaId: _entregaActual!.id,
        onSuccess: (mensaje) {
          debugPrint('✅ [REINTENTAR_TRACKING] GPS reactivado: $mensaje');
          onSuccess(mensaje);
        },
        onError: (error) {
          debugPrint('❌ [REINTENTAR_TRACKING] Error: $error');
          onError(error);
        },
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ [REINTENTAR_TRACKING] Excepción: $e');
      onError(_errorMessage!);
      return false;
    }
  }

  /// Marcar carga como entregada (cambiar estado a ENTREGADO)
  /// Se usa cuando el estado está EN_TRANSITO y el chofer ha entregado la carga
  Future<bool> marcarCargaEntregada(int entregaId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      // Validar que la entrega esté cargada
      if (_entregaActual == null) {
        _errorMessage = 'Entrega no cargada';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      final estadoActual =
          _entregaActual!.estadoEntregaCodigo ?? _entregaActual!.estado;
      debugPrint('🔍 [MARCAR_ENTREGADA] Estado actual: $estadoActual');

      // Validar que esté en estado LLEGO
      if (estadoActual != 'LLEGO') {
        _errorMessage =
            'La entrega debe estar en estado LLEGO. Estado actual: $estadoActual';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      debugPrint('✅ [MARCAR_ENTREGADA] Validación OK, marcando como entregada...');

      // Cambiar estado a ENTREGADO
      final respuestaEstado = await _entregaService.actualizarEstado(
        entregaId,
        estado: 'ENTREGADO',
      );

      if (!respuestaEstado.success) {
        _errorMessage =
            'Error marcando como entregada: ${respuestaEstado.message}';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }

      // Actualizar la entrega actual con la respuesta
      _entregaActual = respuestaEstado.data;
      _actualizarEnListaEntregas(_entregaActual!);

      debugPrint('✅ [MARCAR_ENTREGADA] Carga marcada como entregada');

      // Detener tracking si está activo
      if (isTracking) {
        await detenerTracking();
      }

      // Mostrar notificación de cambio de estado
      await _notificationService.showDeliveryStateChangeNotification(
        deliveryId: _entregaActual!.id,
        newState: _entregaActual!.estado,
        clientName: _entregaActual!.cliente ?? 'Cliente',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      debugPrint('❌ [MARCAR_ENTREGADA] Excepción: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  // Limpiar
  void limpiar() {
    _entregas = [];
    _entregaActual = null;
    _ubicaciones = [];
    _ubicacionActual = null;
    _historialEstados = [];
    _isLoading = false;
    _errorMessage = null;
    detenerEscuchaWebSocket();
    notifyListeners();
  }

  // ✅ FASE 2: Obtener tipos de pago desde la API (sin hardcoding)
  Future<ApiResponse<List>> obtenerTiposPago() async {
    try {
      final response = await _entregaService.obtenerTiposPago();
      return response;
    } catch (e) {
      debugPrint('Error en obtenerTiposPago provider: $e');
      return ApiResponse<List>(
        success: false,
        message: 'Error al obtener tipos de pago: ${e.toString()}',
      );
    }
  }

  // ✅ NUEVO: Métodos para gestionar búsqueda y filtros
  void setSearch(String? search) {
    _search = search;
    debugPrint('🔍 [ENTREGA_PROVIDER] setSearch: $_search');
    notifyListeners();
  }

  void setLocalidad(int? localidadId) {
    _localidadId = localidadId;
    debugPrint('🏘️ [ENTREGA_PROVIDER] setLocalidad: $_localidadId');
    notifyListeners();
  }

  void limpiarFiltros() {
    _search = null;
    _localidadId = null;
    debugPrint('🗑️ [ENTREGA_PROVIDER] Filtros limpios');
    notifyListeners();
  }

  // ✅ NUEVO: Obtener localidades únicas de todas las entregas
  List<Map<String, dynamic>> obtenerLocalidadesUnicas() {
    final localidadesMap = <int, Map<String, dynamic>>{};

    for (var entrega in _entregas) {
      for (var venta in entrega.ventas) {
        if (venta.clienteLocalidadObj != null) {
          final locId = venta.clienteLocalidadObj!.id;
          if (!localidadesMap.containsKey(locId)) {
            localidadesMap[locId] = {
              'id': locId,
              'nombre': venta.clienteLocalidadObj!.nombre,
              'codigo': venta.clienteLocalidadObj!.codigo,
            };
          }
        }
      }
    }

    // Retornar lista ordenada por nombre
    final localidades = localidadesMap.values.toList();
    localidades.sort((a, b) =>
        (a['nombre'] as String).compareTo(b['nombre'] as String));

    debugPrint(
        '🏘️ [ENTREGA_PROVIDER] Localidades únicas encontradas: ${localidades.length}');
    return localidades;
  }

  // ✅ NUEVO 2026-02-21: Cambiar tipo de entrega de una venta
  Future<void> cambiarTipoEntrega({
    required int entregaId,
    required int ventaId,
    required String tipoEntrega, // COMPLETA o CON_NOVEDAD
    String? tipoNovedad,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _entregaService.cambiarTipoEntrega(
        entregaId: entregaId,
        ventaId: ventaId,
        tipoEntrega: tipoEntrega,
        tipoNovedad: tipoNovedad,
      );

      if (response.success) {
        // Recargar la entrega actual para reflejar los cambios
        await obtenerEntrega(entregaId);
      } else {
        _errorMessage = response.message;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NUEVO 2026-03-05: Método para obtener resumen de pagos de una entrega
  Future<ApiResponse<Map<String, dynamic>>> obtenerResumenPagos(int entregaId) async {
    return await _entregaService.obtenerResumenPagos(entregaId);
  }
}
