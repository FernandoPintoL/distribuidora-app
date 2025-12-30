import 'package:flutter/widgets.dart';
import 'dart:async';
import '../models/entrega.dart';
import '../models/ubicacion_tracking.dart';
import '../services/entrega_service.dart';
import '../services/local_notification_service.dart';
import '../services/websocket_service.dart';

class EntregaProvider with ChangeNotifier {
  final EntregaService _entregaService = EntregaService();
  final LocalNotificationService _notificationService = LocalNotificationService();
  final WebSocketService _webSocketService = WebSocketService();

  List<Entrega> _entregas = [];
  Entrega? _entregaActual;
  List<UbicacionTracking> _ubicaciones = [];
  UbicacionTracking? _ubicacionActual;
  List<EntregaEstadoHistorial> _historialEstados = [];
  int _previousEntregasCount = 0;

  bool _isLoading = false;
  String? _errorMessage;

  // WebSocket subscriptions
  StreamSubscription? _entregaSubscription;
  StreamSubscription? _cargoSubscription;

  // Getters
  List<Entrega> get entregas => _entregas;
  Entrega? get entregaActual => _entregaActual;
  List<UbicacionTracking> get ubicaciones => _ubicaciones;
  UbicacionTracking? get ubicacionActual => _ubicacionActual;
  List<EntregaEstadoHistorial> get historialEstados => _historialEstados;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtener entregas asignadas
  Future<bool> obtenerEntregasAsignadas({
    int page = 1,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.obtenerEntregasAsignadas(
        page: page,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      if (response.success && response.data != null) {
        final newEntregas = response.data!;

        // Detectar nuevas entregas y mostrar notificaciones
        if (newEntregas.length > _previousEntregasCount) {
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
        _previousEntregasCount = newEntregas.length;
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

  // Obtener detalle de una entrega
  Future<bool> obtenerEntrega(int entregaId) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.obtenerEntrega(entregaId);

      if (response.success && response.data != null) {
        _entregaActual = response.data;
        _errorMessage = null;

        // El historial de estados ya viene en la respuesta de entrega
        _historialEstados = _entregaActual?.historialEstados ?? [];

        // Cargar solo ubicaciones (el historial ya está en la entrega)
        await obtenerUbicaciones(entregaId);

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

  // Confirmar entrega
  Future<bool> confirmarEntrega(
    int entregaId, {
    String? firmaBase64,
    List<String>? fotosBase64,
    String? observaciones,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _entregaService.confirmarEntrega(
        entregaId,
        firmaBase64: firmaBase64,
        fotosBase64: fotosBase64,
        observaciones: observaciones,
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

        // Si todas las entregas están completadas, mostrar notificación de finalización
        if (_entregas.every((e) => e.estado == 'ENTREGADO' || e.estado == 'CANCELADA')) {
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
      final response = await _entregaService.obtenerUbicaciones(entregaId);

      if (response.success && response.data != null) {
        _ubicaciones = response.data!;
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
      debugPrint('📦 EntregaProvider recibió evento de carga: ${event['type']}');
      _handleCargoEvent(event);
    });
  }

  /// Detener escucha de eventos WebSocket
  void detenerEscuchaWebSocket() {
    debugPrint('🔌 EntregaProvider: Deteniendo escucha WebSocket');
    _entregaSubscription?.cancel();
    _cargoSubscription?.cancel();
  }

  /// Manejar eventos de entregas
  void _handleEntregaEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
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

  /// Actualizar entrega actual desde datos WebSocket
  void _actualizarEntregaActual(Map<String, dynamic> data) {
    try {
      final entregaActualizada = Entrega.fromJson(data);
      if (_entregaActual?.id == entregaActualizada.id) {
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
  Future<bool> desmarcarVentaCargada(
    int entregaId,
    int ventaId,
  ) async {
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
}
