/// Sincroniza eventos de WebSocket con el caché local de estados
///
/// Cuando se recibe un evento de cambio de estado, invalida el caché
/// y luego refetcha los datos de la API.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estado_event.dart';
import '../models/estado.dart';
import '../services/estados_cache_service.dart';
import '../services/estados_api_service.dart';

/// Servicio para sincronizar cambios en tiempo real con el caché local
class EstadosRealtimeCacheSync {
  final ProviderContainer providerContainer;
  final EstadosCacheService cacheService;
  final EstadosApiService apiService;

  EstadosRealtimeCacheSync({
    required this.providerContainer,
    required this.cacheService,
    required this.apiService,
  });

  /// Procesa un evento de WebSocket y actualiza el caché
  Future<void> handleEstadoEvent(EstadoEvent event) async {
    try {
      debugPrint(
        '[EstadosRealtimeCacheSync] Procesando evento: ${event.type} - ${event.categoria}/${event.codigo}',
      );

      switch (event.type) {
        case EstadoEventType.created:
        case EstadoEventType.updated:
          await _handleEstadoCreatedOrUpdated(event);
          break;
        case EstadoEventType.deleted:
          await _handleEstadoDeleted(event);
          break;
        case EstadoEventType.ordered:
          await _handleEstadoOrdered(event);
          break;
      }
    } catch (e) {
      debugPrint(
        '[EstadosRealtimeCacheSync] Error procesando evento: $e',
      );
    }
  }

  /// Maneja creación o actualización de estado
  Future<void> _handleEstadoCreatedOrUpdated(EstadoEvent event) async {
    final categoria = event.categoria;

    try {
      // 1. Invalidar caché local
      debugPrint(
        '[EstadosRealtimeCacheSync] Invalidando caché para $categoria...',
      );
      await cacheService.clearEstados(categoria);

      // 2. Refetchar desde API
      debugPrint('[EstadosRealtimeCacheSync] Refetching $categoria...');
      final estados = await apiService.getEstadosPorCategoria(categoria);

      // 3. Guardar en caché
      await cacheService.saveEstados(categoria, estados);

      debugPrint(
        '[EstadosRealtimeCacheSync] Caché sincronizado: $categoria (${estados.length} estados)',
      );

      // 4. Emit event para que los listeners actualicen
      _notifyListeners(categoria);
    } catch (e) {
      debugPrint(
        '[EstadosRealtimeCacheSync] Error en handleCreatedOrUpdated: $e',
      );
    }
  }

  /// Maneja eliminación de estado
  Future<void> _handleEstadoDeleted(EstadoEvent event) async {
    final categoria = event.categoria;

    try {
      // Mismo flujo: invalidar caché y refetchar
      await cacheService.clearEstados(categoria);

      final estados = await apiService.getEstadosPorCategoria(categoria);
      await cacheService.saveEstados(categoria, estados);

      debugPrint(
        '[EstadosRealtimeCacheSync] Estado eliminado sincronizado: $categoria',
      );

      _notifyListeners(categoria);
    } catch (e) {
      debugPrint('[EstadosRealtimeCacheSync] Error en handleDeleted: $e');
    }
  }

  /// Maneja cambio de orden de estados
  Future<void> _handleEstadoOrdered(EstadoEvent event) async {
    final categoria = event.categoria;

    try {
      // Refetchar para obtener el nuevo orden
      debugPrint(
        '[EstadosRealtimeCacheSync] Orden de estados cambió para $categoria',
      );
      await cacheService.clearEstados(categoria);

      final estados = await apiService.getEstadosPorCategoria(categoria);
      await cacheService.saveEstados(categoria, estados);

      _notifyListeners(categoria);
    } catch (e) {
      debugPrint('[EstadosRealtimeCacheSync] Error en handleOrdered: $e');
    }
  }

  /// Notifica a los listeners que una categoría cambió
  void _notifyListeners(String categoria) {
    // En un contexto real con Riverpod, necesitaríamos acceso a los providers
    // Por ahora simplemente logging
    debugPrint(
      '[EstadosRealtimeCacheSync] Notificando cambios en: $categoria',
    );
  }

  /// Invalida todo el caché de estados
  Future<void> invalidateAllEstados() async {
    debugPrint('[EstadosRealtimeCacheSync] Invalidando todo el caché...');
    await cacheService.clearAllEstados();
  }
}
