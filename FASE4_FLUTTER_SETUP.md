# Fase 4: Flutter Mobile Integration - Setup Guide

## 📱 Resumen de Cambios

La Fase 4 implementa la integración de **Estados Centralizados** en Flutter, reemplazando valores hardcodeados con datos dinámicos desde la API Laravel.

---

## 🏗️ Arquitectura Implementada

### Nuevos Archivos Creados

#### 1. **Models** (`lib/models/estado.dart`)
- `Estado` - Modelo de dato para un estado específico
- `CategoriaEstado` - Enum para categorías (entrega, proforma, etc.)
- `FALLBACK_ESTADOS_ENTREGA` - Estados fallback para entregas
- `FALLBACK_ESTADOS_PROFORMA` - Estados fallback para proformas

#### 2. **Services**
- `estados_cache_service.dart` - Cache local con SharedPreferences (TTL: 7 días)
- `estados_api_service.dart` - HTTP client para API de estados
- `estados_helpers.dart` - Funciones helper sincrónicas

#### 3. **Providers** (`lib/providers/estados_provider.dart`)
- Riverpod FutureProviders para obtener estados
- Cache-first strategy
- Fallback automático a valores hardcodeados

#### 4. **Configuration Changes**
- `lib/main.dart` - Added `ProviderScope` wrapper para Riverpod

---

## 🚀 Cómo Usar

### Opción 1: Usar Riverpod Providers (Recomendado)

En widgets/screens que necesitan estados dinámicos:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/estados_provider.dart';

class MyEntregaWidget extends ConsumerWidget {
  final Entrega entrega;

  const MyEntregaWidget({required this.entrega});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener todos los estados para una categoría
    final estadosAsync = ref.watch(estadosPorCategoriaProvider('entrega'));

    // Obtener un estado específico
    final estadoLabelAsync = ref.watch(
      estadoLabelProvider(('entrega', entrega.estado))
    );

    return estadoLabelAsync.when(
      data: (label) => Text(label),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Opción 2: Usar Helpers Sincrónicas (Para Widgets Simples)

Para widgets que no necesitan reactive updates:

```dart
import 'services/estados_helpers.dart';

class SimpleEstadoBadge extends StatelessWidget {
  final String estadoCodigo;

  const SimpleEstadoBadge({required this.estadoCodigo});

  @override
  Widget build(BuildContext context) {
    final label = EstadosHelper.getEstadoLabel('entrega', estadoCodigo);
    final color = EstadosHelper.getEstadoColor('entrega', estadoCodigo);
    final icon = EstadosHelper.getEstadoIcon('entrega', estadoCodigo);

    return Container(
      color: Color(EstadosHelper.colorHexToInt(color)),
      child: Text('$icon $label'),
    );
  }
}
```

### Opción 3: Usar Extension Methods (Más Limpio)

```dart
// En el modelo Entrega o como extension
String label = entrega.estado.estadoLabel();
String color = entrega.estado.estadoColor();
```

---

## 🔄 Flujo de Datos

```
1. APP STARTUP
   ├─ main.dart envuelve con ProviderScope
   └─ Riverpod está listo para usar

2. PRIMERA VEZ QUE SE ACCEDE A UN ESTADO
   ├─ Riverpod Provider intenta caché (SharedPreferences)
   │  └─ Si caché es válido (< 7 días): retorna datos cacheados
   ├─ Si caché inválido o no existe:
   │  ├─ Llama a EstadosApiService
   │  └─ Guarda resultado en caché
   ├─ Si API falla:
   │  └─ Retorna FALLBACK_ESTADOS_* hardcodeados

3. ACCESOS POSTERIORES
   └─ Datos vienen del caché (muy rápido)

4. REFRESCAR DATOS
   └─ Usar: ref.watch(refreshEstadosProvider)
```

---

## 📦 Dependencias

Las siguientes dependencias ya están en `pubspec.yaml`:
- `shared_preferences` - Cache local
- `flutter_riverpod` - State management
- `http` - HTTP client
- `flutter_secure_storage` - Token storage

---

## 🔧 Configuración Inicial

### 1. Asegurar que env variables están configuradas

En `.env`:
```
API_BASE_URL=http://tu-api.com
```

### 2. Verificar que el backend devuelve estados

Endpoint esperado: `GET /api/estados/entrega`

Respuesta esperada:
```json
{
  "data": [
    {
      "id": 1,
      "categoria": "entrega",
      "codigo": "PROGRAMADO",
      "nombre": "Programado",
      "color": "#eab308",
      "icono": "📅",
      "es_estado_final": false,
      "activo": true,
      ...
    }
  ]
}
```

---

## 🧪 Testing

### Verificar que los providers funcionan:

```dart
// En un test
final container = ProviderContainer();
final estados = await container.read(
  estadosPorCategoriaProvider('entrega').future
);
expect(estados.isNotEmpty, true);
```

### Debugging - Ver estado del caché:

```dart
import 'services/estados_cache_service.dart';

// Obtener info del caché
final cache = EstadosCacheService(prefs);
final info = cache.getCacheInfo('entrega');
print(info); // Mostrará: cached, age, valid, expiresIn
```

---

## 🔄 Migración de Código Existente

### Antes (Hardcodeado):
```dart
Text(entrega.estadoLabel) // 'Programado'
Container(color: Color(int.parse(entrega.estadoColor.replaceFirst('#', '0xff'))))
```

### Después (Dinámico):
```dart
// Con Riverpod
final labelAsync = ref.watch(
  estadoLabelProvider(('entrega', entrega.estado))
);

// Con helpers
Text(EstadosHelper.getEstadoLabel('entrega', entrega.estado))
```

---

## ⚙️ Próximos Pasos (Fase 4.2+)

- [ ] Actualizar EntregaListScreen para usar estados dinámicos
- [ ] Crear EstadoBadge widget que usa Riverpod
- [ ] Agregar filtros dinámicos de estado
- [ ] Implementar suscripción a cambios de estado (WebSocket)
- [ ] Cache invalidation cuando estado cambia

---

## 🐛 Troubleshooting

### Error: "No authentication token found"
**Solución:** Asegurarse que el usuario está autenticado antes de acceder a estados
```dart
final authProvider = ref.watch(authNotifierProvider); // Verificar auth primero
```

### Cache no se actualiza
**Solución:** Limpiar cache manualmente
```dart
ref.watch(clearCategoriaProvider('entrega'));
// O limpiar todo:
ref.watch(refreshEstadosProvider);
```

### Estados muestran emoji en lugar de iconos
**Solución:** Verificar que el backend devuelve icono válido
```dart
// Ver qué devuelve el backend
final estado = await ref.read(estadoPorCodigoProvider(('entrega', 'PROGRAMADO')).future);
print(estado?.icono); // Debe mostrar emoji o nombre de ícono
```

---

## 📝 Referencias

- **Models:** `lib/models/estado.dart`
- **Services:**
  - `lib/services/estados_api_service.dart`
  - `lib/services/estados_cache_service.dart`
  - `lib/services/estados_helpers.dart`
- **Providers:** `lib/providers/estados_provider.dart`
- **Main:** `lib/main.dart` (ProviderScope wrapper)

---

## ✅ Checklist de Implementación

- [x] Crear modelos Estado
- [x] Crear cache service
- [x] Crear API service
- [x] Crear Riverpod providers
- [x] Crear helper functions
- [x] Envolver app con ProviderScope
- [x] Agregar deprecation comments a modelos
- [ ] Actualizar screens para usar providers
- [ ] Crear EstadoBadge widget con Riverpod
- [ ] Testing end-to-end
- [ ] Documentar migración para equipo
