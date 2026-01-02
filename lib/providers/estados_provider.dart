/// Riverpod Providers para Estados centralizados
///
/// Implementa una estrategia cache-first con fallback a hardcoded values.
/// Los providers son responsables de obtener datos desde cache o API.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/estado.dart';
import '../models/estado_event.dart';
import '../services/estados_cache_service.dart';
import '../services/estados_api_service.dart';
import '../services/estados_realtime_cache_sync.dart';

// ==========================================
// BASE PROVIDERS (Dependencies)
// ==========================================

/// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// HTTP Client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Secure Storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Cache Service provider
final estadosCacheServiceProvider = FutureProvider<EstadosCacheService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return EstadosCacheService(prefs);
});

/// API Service provider
final estadosApiServiceProvider = FutureProvider<EstadosApiService>((ref) async {
  final httpClient = ref.watch(httpClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return EstadosApiService(
    httpClient: httpClient,
    secureStorage: secureStorage,
  );
});

// ==========================================
// MAIN PROVIDERS (Estados por categoría)
// ==========================================

/// Estados para una categoría específica - implementa cache-first
///
/// Flujo:
/// 1. Intenta obtener del cache (si válido)
/// 2. Si cache inválido, obtiene de API
/// 3. Si API falla, usa fallback hardcodeado
final estadosPorCategoriaProvider = FutureProvider.family<List<Estado>, String>(
  (ref, categoria) async {
    try {
      final cacheService = await ref.watch(estadosCacheServiceProvider.future);
      final apiService = await ref.watch(estadosApiServiceProvider.future);

      // Intento 1: Caché
      final cachedEstados = cacheService.getEstados(categoria);
      if (cachedEstados != null && cachedEstados.isNotEmpty) {
        print('[EstadosProvider] Using cached estados for $categoria');
        return cachedEstados;
      }

      // Intento 2: API
      print('[EstadosProvider] Fetching estados from API for $categoria');
      final apiEstados = await apiService.getEstadosPorCategoria(categoria);

      if (apiEstados.isNotEmpty) {
        // Guardar en caché para usos futuros
        await cacheService.saveEstados(categoria, apiEstados);
        return apiEstados;
      }

      // Intento 3: Fallback hardcodeado
      print('[EstadosProvider] Using fallback estados for $categoria');
      switch (categoria.toLowerCase()) {
        case 'entrega':
          return FALLBACK_ESTADOS_ENTREGA;
        case 'proforma':
          return FALLBACK_ESTADOS_PROFORMA;
        default:
          return [];
      }
    } catch (e) {
      print('[EstadosProvider] Error fetching estados for $categoria: $e');
      // Si hay error, intentar usar fallback
      switch (categoria.toLowerCase()) {
        case 'entrega':
          print('[EstadosProvider] Error caught, using fallback for entrega');
          return FALLBACK_ESTADOS_ENTREGA;
        case 'proforma':
          print('[EstadosProvider] Error caught, using fallback for proforma');
          return FALLBACK_ESTADOS_PROFORMA;
        default:
          return [];
      }
    }
  },
);

/// Obtiene un estado específico por código
final estadoPorCodigoProvider = FutureProvider.family<Estado?, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    final estados = await ref.watch(estadosPorCategoriaProvider(categoria).future);

    try {
      return estados.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      print('[EstadosProvider] Estado not found: $codigo in $categoria');
      return null;
    }
  },
);

// ==========================================
// HELPER PROVIDERS (Computed values)
// ==========================================

/// Retorna el label de un estado por código
final estadoLabelProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    final estado = await ref.watch(estadoPorCodigoProvider((categoria, codigo)).future);
    return estado?.nombre ?? codigo;
  },
);

/// Retorna el color de un estado por código (como hex string)
final estadoColorProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    final estado = await ref.watch(estadoPorCodigoProvider((categoria, codigo)).future);
    return estado?.color ?? '#000000';
  },
);

/// Retorna el ícono de un estado por código
final estadoIconProvider = FutureProvider.family<String, (String, String)>(
  (ref, params) async {
    final (categoria, codigo) = params;
    final estado = await ref.watch(estadoPorCodigoProvider((categoria, codigo)).future);
    return estado?.icono ?? '❓';
  },
);

// ==========================================
// UTILITY PROVIDERS
// ==========================================

/// Información del caché para debugging
final estadosCacheInfoProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, categoria) async {
    final cacheService = await ref.watch(estadosCacheServiceProvider.future);
    return cacheService.getCacheInfo(categoria);
  },
);

/// Refresca todos los estados de todas las categorías
final refreshEstadosProvider = FutureProvider<void>((ref) async {
  final cacheService = await ref.watch(estadosCacheServiceProvider.future);
  await cacheService.clearAllEstados();

  // Re-fetch todas las categorías
  await ref.refresh(estadosPorCategoriaProvider('entrega').future);
  await ref.refresh(estadosPorCategoriaProvider('proforma').future);

  print('[EstadosProvider] Refreshed all estados');
});

/// Provider para limpiar caché de una categoría
final clearCategoriaProvider = FutureProvider.family<void, String>(
  (ref, categoria) async {
    final cacheService = await ref.watch(estadosCacheServiceProvider.future);
    await cacheService.clearEstados(categoria);
    print('[EstadosProvider] Cleared cache for $categoria');
  },
);

// ==========================================
// REAL-TIME INTEGRATION (WebSocket)
// ==========================================

/// Realtime Cache Sync Service provider
final estadosRealtimeCacheSyncProvider =
    FutureProvider<EstadosRealtimeCacheSync>((ref) async {
  final cacheService = await ref.watch(estadosCacheServiceProvider.future);
  final apiService = await ref.watch(estadosApiServiceProvider.future);

  return EstadosRealtimeCacheSync(
    providerContainer: ref.container,
    cacheService: cacheService,
    apiService: apiService,
  );
});

/// Escucha eventos de WebSocket y sincroniza caché automáticamente
///
/// Cuando se recibe un evento de cambio de estado:
/// 1. Invalida el caché local
/// 2. Refetcha desde API
/// 3. Guarda en caché
/// 4. Notifica a componentes interesados
final estadosWebSocketSyncProvider = StreamProvider<EstadoEvent>((ref) async* {
  // Importar el provider realtime (evitar circular imports)
  // Por ahora este provider escucha eventos pero no los maneja aquí
  // Los maneja directamente EstadosBadgeWidget y otros consumers
  print('[EstadosProvider] WebSocket sync provider initialized');
  yield* const Stream.empty(); // Placeholder
});

/// Provider que invalida estados cuando cambios de WebSocket se detectan
/// Los consumers pueden usar ref.watch() en este para suscribirse a cambios
final estadosCategoryInvalidateProvider =
    StreamProvider<String>((ref) async* {
  // Este provider emitiría el nombre de la categoría que cambió
  // Los consumers pueden luego llamar ref.refresh() en los providers relevantes
  yield* const Stream.empty(); // Placeholder
});
