# Implementación de Rangos de Precios en Flutter

## Descripción General

Se ha implementado la funcionalidad de mostrar **oportunidades de ahorro** cuando los clientes cargan productos al carrito. El sistema calcula dinámicamente los precios en función de las cantidades y muestra la cantidad de dinero que el cliente podría ahorrar si aumenta la cantidad hasta alcanzar el siguiente rango de precio.

## Componentes Implementados

### 1. Modelos de Datos

#### `RangoAplicado` (`lib/models/rango_aplicado.dart`)
Representa el rango de precio actual aplicado a un producto:
```dart
class RangoAplicado {
  final int cantidadMinima;
  final int? cantidadMaxima;      // null = sin límite
  final String rangoTexto;         // Ej: "10-49", "50+"
}
```

#### `ProximoRango` (`lib/models/proximo_rango.dart`)
Representa la siguiente oportunidad de rango disponible:
```dart
class ProximoRango {
  final int cantidadMinima;
  final int? cantidadMaxima;
  final String rangoTexto;
  final int faltaCantidad;         // Cuántas unidades faltan
}
```

#### `DetalleCarritoConRango` (`lib/models/detalle_carrito_con_rango.dart`)
Detalles completos de un item del carrito incluyendo información de rangos:
```dart
class DetalleCarritoConRango {
  final int productoId;
  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final RangoAplicado? rangoAplicado;
  final ProximoRango? proximoRango;
  final double? ahorroProximo;     // Monto en Bs a ahorrar

  bool get tieneOportunidadAhorro => proximoRango != null && ahorroProximo != null;
}
```

#### `CarritoConRangos` (`lib/models/carrito_con_rangos.dart`)
Respuesta completa del carrito con cálculos de rangos:
```dart
class CarritoConRangos {
  final int cantidadItems;
  final double subtotal;
  final double ahorroTotal;
  final List<DetalleCarritoConRango> detalles;
}
```

### 2. Servicio de API

#### `CarritoService` (actualizado en `lib/services/carrito_service.dart`)

Se agregaron dos nuevos métodos:

**`calcularCarritoConRangos()`**
```dart
Future<CarritoConRangos?> calcularCarritoConRangos(List<CarritoItem> items)
```
- Llama a: `POST /api/carrito/calcular`
- Parámetros: `{ "items": [{ "producto_id": 1, "cantidad": 5 }, ...] }`
- Retorna: `CarritoConRangos` con detalles de precio y oportunidades de ahorro

**`calcularPrecioProducto()`**
```dart
Future<Map<String, dynamic>?> calcularPrecioProducto(int productoId, double cantidad)
```
- Llama a: `POST /api/productos/{productoId}/calcular-precio`
- Parámetros: `{ "cantidad": 15 }`
- Retorna: Mapa con precios, rangos y ahorro potencial

### 3. Widget de Visualización

#### `CarritoItemAhorroSection` (`lib/widgets/carrito/carrito_item_ahorro_section.dart`)

Widget que muestra la oportunidad de ahorro de forma destacada:

```dart
CarritoItemAhorroSection(
  detalle: detalleConRango,
  onAgregarParaAhorrar: () { ... },
)
```

**Características:**
- Muestra solo si hay oportunidad de ahorro (`tieneOportunidadAhorro`)
- Diseño visual llamativo con icono y colores verdes
- Muestra:
  - Cantidad que falta agregar
  - Rango al que se llegaría
  - Monto exacto de ahorro en Bs
- Botón para agregar automáticamente la cantidad necesaria

**Ejemplo visual:**
```
┌─────────────────────────────────────┐
│ ↓ ¡Oportunidad de Ahorro!           │
├─────────────────────────────────────┤
│ Agrega 35 más: → Rango 50+          │
│ Ahorrarás: Bs 75.00                 │
├─────────────────────────────────────┤
│ [+ Agregar 35 para ahorrar]         │
└─────────────────────────────────────┘
```

### 4. Actualización de CarritoItemCard

El widget `CarritoItemCard` ahora acepta:
```dart
final DetalleCarritoConRango? detalleConRango;
final VoidCallback? onAgregarParaAhorrar;
```

Muestra automáticamente `CarritoItemAhorroSection` cuando hay ahorro disponible.

### 5. Proveedor de Estado

#### `CarritoProvider` (actualizado en `lib/providers/carrito_provider.dart`)

**Nuevas propiedades:**
```dart
CarritoConRangos? _carritoConRangos;
bool _calculandoRangos = false;
Map<int, DetalleCarritoConRango> _detallesConRango = {};
```

**Nuevos métodos públicos:**

**`calcularCarritoConRangos()` (async)**
- Llama a `CarritoService.calcularCarritoConRangos()`
- Almacena detalles en mapa para acceso rápido por `producto_id`
- Notifica listeners después de calcular
- Maneja errores y muestra mensajes al usuario

**`obtenerDetalleConRango(int productoId)`**
- Retorna `DetalleCarritoConRango?` para un producto específico
- Usado para obtener la información del widget

**`agregarParaAhorrar(int productoId, int cantidadAgregar)`**
- Valida stock disponible
- Actualiza cantidad automáticamente
- Recalcula rangos después de actualizar

### 6. Pantalla del Carrito

#### `CarritoScreen` (actualizado en `lib/screens/carrito/carrito_screen.dart`)

**Cambios principales:**
1. Convertida a `StatefulWidget` para inicializar cálculos
2. En `initState()`: Calcula rangos cuando se abre la pantalla
3. En `itemBuilder()`:
   - Obtiene `DetalleCarritoConRango` para cada item
   - Pasa `detalleConRango` y callback `onAgregarParaAhorrar` a `CarritoItemCard`
   - Recalcula rangos después de cada cambio (incremento, decremento, actualización)

```dart
final detalleConRango = carritoProvider.obtenerDetalleConRango(item.producto.id);

CarritoItemCard(
  item: item,
  detalleConRango: detalleConRango,
  onAgregarParaAhorrar: () {
    if (detalleConRango?.proximoRango != null) {
      carritoProvider.agregarParaAhorrar(
        item.producto.id,
        detalleConRango!.proximoRango!.faltaCantidad,
      );
    }
  },
  // ... otros callbacks con recalculación de rangos
)
```

## Flujo de Funcionamiento

### Cuando el usuario abre el carrito:

1. `CarritoScreen.initState()` llama a `calcularCarritoConRangos()`
2. El proveedor obtiene datos del backend via `CarritoService`
3. Se almacenan detalles en `_detallesConRango` mapa
4. Cada `CarritoItemCard` recibe su `DetalleCarritoConRango`
5. Si hay oportunidad de ahorro, se muestra `CarritoItemAhorroSection`

### Cuando el usuario cambia cantidad:

1. Se llama al callback apropiado (onIncrement, onDecrement, etc.)
2. `CarritoProvider` actualiza la cantidad del item
3. Se llama automáticamente a `calcularCarritoConRangos()`
4. Los detalles se actualizan con nuevos precios
5. La UI se refresca mostrando la nueva oportunidad de ahorro (o ninguna)

### Cuando el usuario hace clic en "Agregar para ahorrar":

1. Se llama a `agregarParaAhorrar(productoId, cantidad)`
2. Se valida que haya stock suficiente
3. Se actualiza la cantidad automáticamente
4. Se recalculan los rangos
5. Se muestra la nueva información de ahorro

## Integración con Backend

### Endpoint: `POST /api/carrito/calcular`

**Request:**
```json
{
  "items": [
    { "producto_id": 1, "cantidad": 15 },
    { "producto_id": 2, "cantidad": 5 }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "cantidad_items": 2,
    "subtotal": 127.50,
    "ahorro_total": 75.00,
    "detalles": [
      {
        "producto_id": 1,
        "nombre_producto": "PEPSI 250ML",
        "cantidad": 15,
        "precio_unitario": 8.50,
        "subtotal": 127.50,
        "rango_aplicado": {
          "cantidad_minima": 10,
          "cantidad_maxima": 49,
          "rango_texto": "10-49"
        },
        "proximo_rango": {
          "cantidad_minima": 50,
          "cantidad_maxima": null,
          "rango_texto": "50+",
          "falta_cantidad": 35
        },
        "ahorro_proximo": 75.00
      }
    ]
  }
}
```

## Manejo de Errores

- Si el cálculo falla, se muestra mensaje de error via `CarritoErrorBanner`
- Se mantiene el carrito en estado consistente
- Los reintentos se hacen automáticamente al cambiar cantidad

## Rendimiento

- **Debounce**: Se recalcula después de CADA cambio (considerar debounce en versiones futuras)
- **Caché**: Los detalles se almacenan en memoria en `_detallesConRango`
- **Lazy loading**: Se calcula solo cuando se necesita (al abrir pantalla)

## Logging

Todos los eventos incluyen logs descriptivos con emojis:
- 📊 Calculando carrito
- ✅ Éxito
- ❌ Errores
- 💾 Persistencia
- 🔄 Actualizaciones

## Testing

### Casos de prueba recomendados:

1. **Abrir carrito vacío**: No calcula, no muestra ahorro
2. **Carrito con 1 item**: Muestra oportunidad si aplica
3. **Múltiples items**: Calcula para todos, cada uno con su ahorro
4. **Cambiar cantidad**: Recalcula, actualiza ahorro
5. **Agregar para ahorrar**: Suma cantidad automáticamente
6. **Stock insuficiente**: Muestra error pero no cambia cantidad
7. **Conexión lenta**: Muestra indicador de carga durante cálculo
8. **Error de API**: Muestra banner de error y mantiene estado anterior

## Archivos Modificados/Creados

### Creados:
- `lib/models/rango_aplicado.dart`
- `lib/models/proximo_rango.dart`
- `lib/models/detalle_carrito_con_rango.dart`
- `lib/models/carrito_con_rangos.dart`
- `lib/widgets/carrito/carrito_item_ahorro_section.dart`

### Modificados:
- `lib/models/models.dart` - Agregados exports
- `lib/services/carrito_service.dart` - Agregados métodos de cálculo
- `lib/providers/carrito_provider.dart` - Agregada lógica de rangos
- `lib/screens/carrito/carrito_screen.dart` - Integración de rangos
- `lib/widgets/carrito/carrito_item_card.dart` - Parámetros de ahorro
- `lib/widgets/carrito/index.dart` - Exportado nuevo widget

## Próximas Mejoras

1. **Debounce**: Implementar debounce para evitar recálculos excesivos
2. **Caché de respuestas**: Guardar cálculos para evitar llamadas repetidas
3. **Animaciones**: Animar la aparición de la sección de ahorro
4. **Persistencia local**: Guardar detalles localmente para modo offline
5. **Historial**: Guardar ahorros generados por el usuario

## Referencias

- Documentación del servidor: `PRECIO_RANGOS_API.md`
- Documentación anterior: `FLUTTER_INTEGRACION_AHORROS.md`
