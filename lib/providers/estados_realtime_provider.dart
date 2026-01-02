/// Riverpod providers para integrar el servicio de tiempo real de estados
///
/// Proporciona acceso al servicio WebSocket y streams de eventos de estado.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/estado_event.dart';
import '../services/estados_realtime_service.dart';

/// Provider singleton para el servicio de tiempo real
final estadosRealtimeServiceProvider =
    FutureProvider<EstadosRealtimeService>((ref) async {
  const secureStorage = FlutterSecureStorage();

  final service = EstadosRealtimeService(
    secureStorage: secureStorage,
  );

  // Conectar automáticamente cuando se cree el servicio
  try {
    await service.connect();
  } catch (e) {
    print('[estadosRealtimeServiceProvider] Error connecting: $e');
    // Continue anyway - el servicio intentará reconectar automáticamente
  }

  // Asegurar limpieza cuando se disponga
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream de eventos de estado cambios
final estadosEventStreamProvider =
    StreamProvider<EstadoEvent>((ref) async* {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);
  yield* service.eventStream;
});

/// Stream de estado de conexión
final estadosConnectionStateStreamProvider =
    StreamProvider<EstadoConnectionState>((ref) async* {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);
  yield* service.connectionStateStream;
});

/// Proveedor que combina todas las categorías de estados que cambian
/// Útil para invalidar todos los cachés cuando hay cambios
final estadosCategoryChangedProvider =
    StreamProvider<String>((ref) async* {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);

  yield* service.eventStream
      .map((event) => event.categoria)
      .asBroadcastStream()
      .distinct();
});

/// Provider que detecta si hay conexión y emite cambios
final estadosIsConnectedProvider = StreamProvider<bool>((ref) async* {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);

  yield* service.connectionStateStream
      .map((state) => state.isConnected)
      .asBroadcastStream()
      .distinct();
});

/// Provider de utilidad para forzar reconexión manual
final estadosForceReconnectProvider = FutureProvider<void>((ref) async {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);

  // Desconectar y reconectar
  service.disconnect();
  await Future.delayed(const Duration(seconds: 1));
  await service.connect();
});

/// Provider que invalida el caché de una categoría cuando hay cambios
/// Se usa junto con invalidate() en los providers de estado
final estadosInvalidateOnChangeProvider =
    StreamProvider<String>((ref) async* {
  final service = await ref.watch(estadosRealtimeServiceProvider.future);

  yield* service.eventStream
      .map((event) => event.categoria)
      .asBroadcastStream()
      .distinct();
});
