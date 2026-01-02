# Fase 5: WebSocket Real-Time Estado Updates

## 📋 Objetivo

Implementar actualizaciones en tiempo real cuando los estados cambian en la API, sin que el usuario tenga que refrescar manualmente.

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────┐
│                   Flutter App                         │
│   ┌─────────────────────────────────────────────┐   │
│   │         EstadosRealtimeService              │   │
│   │   (WebSocket connection manager)            │   │
│   └────────────┬────────────────────────────────┘   │
└───────────────┼────────────────────────────────────┘
                │ (Socket.IO connection)
                ▼
        ┌──────────────────┐
        │  Node.js Server  │  (ws://localhost:3000)
        │  (Socket.IO)     │
        └────────┬─────────┘
                 │
        ┌────────▼──────────┐
        │  Laravel App      │
        │  (Broadcasting)   │
        └─────────────────┘
```

### **Event Flow**

```
1. Estado cambia en Laravel
   └─ Broadcasta a Socket.IO: "estado:cambio"

2. Flutter escucha: "estado:cambio"
   ├─ Invalida cache local
   ├─ Re-fetch desde API
   ├─ Actualiza Riverpod providers
   └─ UI se actualiza automáticamente

3. Notificación push opcional
   └─ Alerta al usuario del cambio
```

---

## 📦 Archivos a Crear

### 1. **Riverpod Provider para WebSocket**
```
lib/providers/estados_realtime_provider.dart
- Stream<EstadoEvent> para eventos
- Connection status tracking
- Auto-reconnect logic
```

### 2. **WebSocket Service**
```
lib/services/estados_realtime_service.dart
- Socket.IO client wrapper
- Event listeners
- Reconnection strategy
```

### 3. **Event Models**
```
lib/models/estado_event.dart
- EstadoChangedEvent
- EstadoCategoryEvent
- EventType enum
```

### 4. **Integration with Cache**
```
lib/services/estados_cache_service.dart (modificar)
- invalidate() method
- invalidateCategory() method
```

---

## 🔄 Flujo de Datos Detallado

### **Escenario: Usuario observa lista de entregas**

```
1. APP STARTS
   ├─ Carga estados desde cache (normal)
   └─ Conecta WebSocket silenciosamente

2. ESTADO CAMBIA EN BACKEND
   ├─ Admin cambia entrega de PROGRAMADO a ASIGNADA
   └─ Laravel broadcast: "entrega.estado.changed" → Socket.IO

3. FLUTTER RECIBE EVENTO
   ├─ EstadosRealtimeService recibe: {
   │   event: "estado:cambio",
   │   categoria: "entrega",
   │   codigo: "ASIGNADA",
   │   timestamp: "2025-12-31T10:30:00Z"
   │  }
   └─ Dispara acción

4. CACHE INVALIDATION
   ├─ EstadosCacheService.invalidateCategory('entrega')
   └─ Limpia cache local

5. REFETCH DESDE API
   ├─ Riverpod provider automáticamente refetches
   ├─ Recibe datos frescos del servidor
   └─ Guarda en cache

6. UI UPDATES AUTOMATICALLY
   ├─ EstadoBadgeWidget reactivo se actualiza
   ├─ Lista se redibuja
   └─ Usuario ve cambios al instante
```

---

## 🚀 Implementación Step-by-Step

### **Paso 1: Event Models**
```dart
// lib/models/estado_event.dart
enum EstadoEventType { created, updated, deleted }

class EstadoEvent {
  final EstadoEventType type;
  final String categoria;
  final String codigo;
  final String nombre;
  final DateTime timestamp;
}
```

### **Paso 2: WebSocket Service**
```dart
// lib/services/estados_realtime_service.dart
class EstadosRealtimeService {
  late IO.Socket _socket;

  Future<void> connect() async {
    // Conectar a Socket.IO server
    _socket = IO.io(baseUrl, ...);
    _socket.on('estado:cambio', _onEstadoChanged);
  }

  void _onEstadoChanged(dynamic data) {
    // Manejar cambios de estado
  }
}
```

### **Paso 3: Riverpod Integration**
```dart
// lib/providers/estados_realtime_provider.dart
final estadosRealtimeProvider = FutureProvider<EstadosRealtimeService>((ref) async {
  return EstadosRealtimeService();
});

// Stream de eventos
final estadosEventStreamProvider = StreamProvider<EstadoEvent>((ref) async* {
  final service = await ref.watch(estadosRealtimeProvider.future);
  yield* service.eventStream;
});
```

### **Paso 4: Invalidación de Cache**
```dart
// En el handler del evento
ref.watch(clearCategoriaProvider(categoria)); // Riverpod refetch
```

---

## 🔌 Eventos Esperados desde Backend

El backend debe emitir eventos como:

```json
{
  "event": "estado:cambio",
  "data": {
    "categoria": "entrega",
    "codigo": "ENTREGADO",
    "nombre": "Entregado",
    "color": "#22c55e",
    "timestamp": "2025-12-31T10:30:00Z"
  }
}
```

---

## 🔐 Seguridad

1. **Autenticación**: WebSocket debe validar token Bearer
2. **Autorización**: Solo usuarios autenticados pueden recibir updates
3. **Rate Limiting**: Limitar eventos para evitar spam
4. **Validación**: Validar evento antes de actuar

---

## 🎯 Beneficios

✅ **Real-time Updates** - Sin refrescar manualmente
✅ **Better UX** - Cambios aparecen al instante
✅ **Reduced Load** - No polling constante
✅ **Two-way Sync** - Backend y Frontend siempre en sync
✅ **Notifications** - Opcional: notificar al usuario

---

## 📊 Estados a Monitorear (Prioritarios)

1. **Entregas** (`entrega`)
   - PROGRAMADO → ASIGNADA
   - ASIGNADA → EN_CAMINO
   - EN_CAMINO → ENTREGADO

2. **Proformas** (`proforma`)
   - PENDIENTE → APROBADA/RECHAZADA
   - APROBADA → CONVERTIDA

3. **Vehículos** (`vehiculo`)
   - Disponible → En Ruta
   - En Ruta → Disponible

---

## 🔄 Reconnection Logic

```
Si conexión se pierde:
├─ Intentar reconectar (exponential backoff)
├─ Mostrar indicator: "Sincronizando..."
├─ Cuando se reconecta:
│  ├─ Invalidar todos los cachés
│  ├─ Refetch todos los estados
│  └─ Mostrar: "✓ Sincronizado"
└─ Timeout: mostrar warning
```

---

## 🧪 Testing

```dart
// Unit test
test('WebSocket event invalidates cache', () async {
  // Enviar evento simulado
  // Verificar que cache fue invalidado
  // Verificar que refetch ocurrió
});

// Integration test
testWidgets('Real-time update shows in UI', (tester) async {
  // Emitir evento WebSocket
  // Esperar actualización
  // Verificar UI cambió
});
```

---

## 📱 Flutter Integration

### **En Riverpod ConsumerWidget**
```dart
class EstadoListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the realtime stream
    final eventStream = ref.watch(estadosEventStreamProvider);

    // Watch estados (se refrescará cuando hay evento)
    final estadosAsync = ref.watch(estadosPorCategoriaProvider('entrega'));

    return eventStream.when(
      data: (_) => estadosAsync.when(
        data: (estados) => _buildList(estados),
        // ...
      ),
      // ...
    );
  }
}
```

---

## 🚨 Indicadores Visuales

```dart
// Indicator en app bar
┌─────────────────────────────┐
│ Entregas  [WiFi] En vivo    │ ← Conectado
│ Entregas  [×]   Sincronizando│ ← Reconectando
│ Entregas  [!]   Sin conexión │ ← Desconectado
└─────────────────────────────┘
```

---

## ⏱️ Timeline

- **Día 1-2:** Implementar EstadosRealtimeService
- **Día 2-3:** Integrar con Riverpod providers
- **Día 3-4:** Testing y debugging
- **Día 4:** Documentación y examples

---

## 🎓 Referencias

- Socket.IO Flutter client: `socket_io_client`
- Riverpod streaming: `StreamProvider`
- Laravel Broadcasting: Config existente
