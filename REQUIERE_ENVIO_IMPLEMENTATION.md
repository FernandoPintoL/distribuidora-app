# Implementación: requiere_envio para DELIVERY

## 📋 Resumen
Se ha implementado correctamente el envío del atributo `requiere_envio=true` cuando el tipo de entrega es **DELIVERY** en todas las llamadas a la API.

---

## 🔄 Cambios Realizados

### 1. **PedidoService** (`lib/services/pedido_service.dart`)

#### Método: `crearPedido()`
**Línea:** 33-38

**Antes:**
```dart
final Map<String, dynamic> requestBody = {
  'cliente_id': clienteId,
  'productos': items,
  'tipo_entrega': tipoEntrega,
  'fecha_programada': fechaProgramada.toIso8601String(),
};
```

**Después:**
```dart
final Map<String, dynamic> requestBody = {
  'cliente_id': clienteId,
  'productos': items,
  'tipo_entrega': tipoEntrega,
  'fecha_programada': fechaProgramada.toIso8601String(),
  'requiere_envio': tipoEntrega == 'DELIVERY', // ✅ Nuevo
};
```

#### Método: `actualizarProforma()`
**Línea:** 142-148

Aplicado el mismo cambio para mantener consistencia cuando se actualiza una proforma.

**Debug Output Mejorado:**
```
📋 Creando proforma con 3 productos
   Cliente ID: 123
   Tipo de entrega: DELIVERY
   Requiere envío: true  // ← Nuevo
   Fecha programada: 2026-06-15T00:00:00.000Z
   Dirección ID: 45
   Política de pago: CONTRA_ENTREGA
```

---

### 2. **ProformaService** (`lib/services/proforma_service.dart`)

#### Método: `crearProforma()`
**Línea:** 305-312

Aplicado el mismo patrón para crear proformas desde preventistas.

#### Método: `actualizarProforma()`
**Línea:** 572-579

Aplicado para actualizar proformas existentes.

---

## 📊 Comportamiento del Atributo

### Lógica de Asignación

```dart
'requiere_envio': tipoEntrega == 'DELIVERY'
```

| Tipo de Entrega | requiere_envio | Enviar Dirección |
|-----------------|----------------|------------------|
| **DELIVERY** | `true` | ✅ Sí (direccion_entrega_solicitada_id) |
| **PICKUP** | `false` | ❌ No (null) |

---

## 🔍 Ejemplo de Request Completo

### Cuando es DELIVERY:
```json
{
  "cliente_id": 123,
  "productos": [
    {
      "producto_id": 456,
      "cantidad": 2,
      "precio_unitario": 50.00
    }
  ],
  "tipo_entrega": "DELIVERY",
  "fecha_programada": "2026-06-15T00:00:00.000Z",
  "requiere_envio": true,
  "direccion_entrega_solicitada_id": 789,
  "hora_inicio_preferida": "08:00",
  "hora_fin_preferida": "08:00",
  "observaciones": "Entregar en recepción",
  "politica_pago": "CONTRA_ENTREGA"
}
```

### Cuando es PICKUP:
```json
{
  "cliente_id": 123,
  "productos": [
    {
      "producto_id": 456,
      "cantidad": 2,
      "precio_unitario": 50.00
    }
  ],
  "tipo_entrega": "PICKUP",
  "fecha_programada": "2026-06-15T00:00:00.000Z",
  "requiere_envio": false,
  "hora_inicio_preferida": "08:00",
  "hora_fin_preferida": "08:00",
  "politica_pago": "CONTRA_ENTREGA"
}
```

---

## ✅ Flujo de Datos

```
┌─────────────────────────────────────┐
│  ResumenPedidoScreen                │
│  _tipoEntrega = "DELIVERY"          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  _confirmarPedido()                 │
│  ├─ tipoEntrega: "DELIVERY"         │
│  └─ direccionId: 789                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  PedidoService.crearPedido()        │
│  ProformaService.crearProforma()    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  requestBody['requiere_envio']      │
│  = tipoEntrega == 'DELIVERY'        │
│  = true ✅                          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  POST /proformas                    │
│  Content: {requiere_envio: true}    │
└─────────────────────────────────────┘
```

---

## 🔧 Archivos Modificados

| Archivo | Métodos | Cambios |
|---------|---------|---------|
| `pedido_service.dart` | `crearPedido()` | ✅ Agregado `requiere_envio` |
| `pedido_service.dart` | `actualizarProforma()` | ✅ Agregado `requiere_envio` |
| `proforma_service.dart` | `crearProforma()` | ✅ Agregado `requiere_envio` |
| `proforma_service.dart` | `actualizarProforma()` | ✅ Agregado `requiere_envio` |

---

## 📝 Debug Logs

Ahora podrás ver en los logs de desarrollo:

```
I/flutter (12345): 📋 Creando proforma con 3 productos
I/flutter (12345):    Cliente ID: 123
I/flutter (12345):    Tipo de entrega: DELIVERY
I/flutter (12345):    Requiere envío: true
I/flutter (12345):    Fecha programada: 2026-06-15T00:00:00.000Z
I/flutter (12345):    Dirección ID: 789
I/flutter (12345):    Política de pago: CONTRA_ENTREGA
I/flutter (12345):    Cuerpo de la petición: {cliente_id: 123, productos: [...], tipo_entrega: DELIVERY, requiere_envio: true, ...}
```

---

## ✨ Ventajas

✅ **Backend sabe automáticamente** si debe procesar envío  
✅ **Consistente** en todas las operaciones (crear, actualizar)  
✅ **Lógica clara** y fácil de mantener  
✅ **Evita errores** de no enviar el parámetro cuando es DELIVERY  
✅ **Trazable** con logs mejorados

---

## 🚀 Próximos Pasos (Opcionales)

Si quieres mejorar aún más:

1. **Crear una constante** para el atributo:
   ```dart
   static const String ATTR_REQUIERE_ENVIO = 'requiere_envio';
   static const String TIPO_DELIVERY = 'DELIVERY';
   static const String TIPO_PICKUP = 'PICKUP';
   ```

2. **Validación en el Screen:**
   ```dart
   if (_tipoEntrega == 'DELIVERY' && _direccionSeleccionada == null) {
     // Mostrar error
   }
   ```

3. **Usar un método helper:**
   ```dart
   bool _requiereEnvio() => _tipoEntrega == 'DELIVERY';
   ```

---

## ✅ Estado del Proyecto
- ✅ Compilación sin errores
- ✅ Atributo `requiere_envio` enviado correctamente
- ✅ Logs mejorados para debugging
- ✅ Funcionamiento listo para producción
