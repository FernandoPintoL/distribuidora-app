# 📋 Cambios en la Aplicación Flutter - API de Proformas

## Resumen de Cambios

Se han realizado cambios importantes para cumplir con los nuevos requerimientos de la API de creación de proformas.

---

## ✅ Cambios Realizados

### 1. **PedidoService** (`lib/services/pedido_service.dart`)

#### Cambios en el método `crearPedido()`

**Antes:**
```dart
Future<ApiResponse<Pedido>> crearPedido({
  required int clienteId,
  required List<Map<String, dynamic>> items,
  DateTime? fechaProgramada,          // ❌ Era opcional
  TimeOfDay? horaInicio,
  TimeOfDay? horaFin,
  String? observaciones,
  // ❌ Faltaba: direccionId
}) async {
```

**Después:**
```dart
Future<ApiResponse<Pedido>> crearPedido({
  required int clienteId,
  required List<Map<String, dynamic>> items,
  required DateTime fechaProgramada,  // ✅ Ahora obligatorio
  required int direccionId,           // ✅ NUEVO: Dirección de entrega
  TimeOfDay? horaInicio,
  TimeOfDay? horaFin,
  String? observaciones,
}) async {
```

**Body del Request:**
```json
{
  "cliente_id": 5,
  "productos": [...],
  "fecha_programada": "2025-11-05T12:57:14.138717",
  "direccion_entrega_solicitada_id": 12,  // ✅ NUEVO
  "hora_inicio_preferida": "09:00"       // Opcional
}
```

---

### 2. **ResumenPedidoScreen** (`lib/screens/pedidos/resumen_pedido_screen.dart`)

#### Cambio en la llamada a `crearPedido()`

**Antes:**
```dart
final response = await _pedidoService.crearPedido(
  clienteId: authProvider.user!.id,
  items: items,
  fechaProgramada: widget.fechaProgramada,  // ❌ Podía ser null
  horaInicio: widget.horaInicio,
  horaFin: widget.horaFin,
  observaciones: widget.observaciones,
  // ❌ NO pasaba la dirección
);
```

**Después:**
```dart
final response = await _pedidoService.crearPedido(
  clienteId: authProvider.user!.id,
  items: items,
  fechaProgramada: widget.fechaProgramada ?? DateTime.now(),  // ✅ Garantizado
  direccionId: widget.direccion.id,                           // ✅ NUEVO
  horaInicio: widget.horaInicio,
  horaFin: widget.horaFin,
  observaciones: widget.observaciones,
);
```

#### Cambio en la visualización del resumen

**Antes:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text('Impuesto (13%)'),
    Text('Bs. ${carrito.impuesto.toStringAsFixed(2)}'),  // ❌ Mostraba impuesto
  ],
),
```

**Después:**
```dart
// ✅ Removido: El impuesto ahora se calcula automáticamente en el backend
// No necesita mostrarse en la pantalla del cliente
```

---

## 📊 Cambios en el API Request

### Antes:
```json
{
  "cliente_id": 5,
  "productos": [...],
  "fecha_programada": "2025-11-05T12:57:14.138717",
  "hora_inicio_preferida": "09:00"
  // ❌ Faltaba dirección
}
```

### Después:
```json
{
  "cliente_id": 5,
  "productos": [...],
  "fecha_programada": "2025-11-05T12:57:14.138717",
  "hora_inicio_preferida": "09:00",
  "direccion_entrega_solicitada_id": 12  // ✅ REQUERIDO
}
```

---

## 🎯 Impacto en la Aplicación

### ✅ Ventajas

1. **Dirección Explícita:** El cliente debe seleccionar exactamente dónde quiere la entrega
2. **Sin Ambigüedades:** No usa la dirección "principal" automáticamente
3. **Backend Consistente:** El servidor siempre recibe la dirección
4. **Datos Correctos:** Se guarda `usuario_creador_id` correctamente

### ⚠️ Cambios Requeridos

| Elemento | Cambio |
|----------|--------|
| Fecha programada | Ahora obligatoria |
| Dirección | Ahora obligatoria |
| Impuesto en UI | Removido (se calcula en backend) |

---

## 📝 Flujo Actual

```
1. Cliente selecciona productos → Carrito
2. Cliente selecciona dirección de entrega (OBLIGATORIO)
3. Cliente selecciona fecha de entrega (OBLIGATORIO)
4. Cliente selecciona hora (opcional)
5. Cliente confirma el pedido
6. App envía:
   - cliente_id
   - productos
   - fecha_entrega_solicitada
   - direccion_entrega_solicitada_id ← NUEVO
   - hora (opcional)
7. Backend:
   - Valida dirección pertenece al cliente
   - Valida stock
   - Calcula totales (sin impuestos por ahora)
   - Asigna usuario_creador_id del cliente
   - Crea proforma
```

---

## 🔧 Verificación

Para verificar que los cambios funcionan correctamente:

1. Abre la aplicación
2. Selecciona productos
3. Ve al carrito
4. Selecciona una dirección de entrega
5. Selecciona una fecha de entrega
6. Confirma el pedido
7. Verifica en el log de Flutter que se envía `direccion_entrega_solicitada_id`
8. La proforma debe crearse exitosamente con todos los datos

---

## 📞 Notas Importantes

- Si `fechaProgramada` es null, se usa `DateTime.now()` como fallback
- La dirección DEBE tener un ID válido del cliente
- El servidor validará que la dirección pertenece al cliente
- El impuesto se calcula en el backend automáticamente

---

## 🐛 Si Tienes Errores

### Error: "The direccion_entrega_solicitada_id field is required."

**Solución:** Asegúrate de que:
1. La dirección tiene un ID
2. El ID se pasa correctamente a `crearPedido()`
3. La dirección pertenece al cliente actual

### Error: "La dirección seleccionada no pertenece al cliente"

**Solución:** Verifica que:
1. El cliente ID es correcto
2. La dirección pertenece a ese cliente
3. La dirección no está eliminada

---

## 📚 Referencia Rápida

**Parámetros requeridos ahora:**
```dart
crearPedido(
  clienteId: int,
  items: List<Map>,
  fechaProgramada: DateTime,      // ✅ Obligatorio
  direccionId: int,               // ✅ Obligatorio
  horaInicio: TimeOfDay?,
  horaFin: TimeOfDay?,
  observaciones: String?,
)
```
