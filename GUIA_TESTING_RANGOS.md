# Guía de Testing - Rangos de Precios en Flutter

## 🎯 Objetivo

Validar que el sistema de rangos de precios funciona correctamente en el carrito, mostrando oportunidades de ahorro cuando corresponde y permitiendo que los clientes agreguen automáticamente cantidad para obtener mejores precios.

## 📋 Requisitos Previos

### Backend
- ✅ Tablas creadas: `precio_rango_cantidad_producto`
- ✅ Endpoints disponibles:
  - `POST /api/carrito/calcular`
  - `POST /api/productos/{id}/calcular-precio`
- ✅ Datos de prueba: productos con rangos configurados

### Flutter
- ✅ Compilación exitosa de la app
- ✅ Conexión a backend (ajustar API_URL si es necesario)
- ✅ Usuario autenticado

## 🧪 Plan de Testing

### Test 1: Carrito Vacío
**Objetivo**: Asegurar que no falla si el carrito está vacío

**Pasos**:
1. Abrir la aplicación
2. Ir a "Mi Carrito"
3. Carrito debe estar vacío

**Resultado esperado**:
- ✅ Pantalla muestra "Carrito vacío"
- ✅ No hay llamadas API innecesarias

---

### Test 2: Un Producto Dentro del Rango Mínimo
**Objetivo**: Validar que calcula correctamente y muestra oportunidad de ahorro

**Datos de prueba**:
- Producto: PEPSI 250ML (rango 1-9: Bs 10, rango 10-49: Bs 8.5, rango 50+: Bs 7)
- Cantidad agregada: 5

**Pasos**:
1. Agregar PEPSI 250ML al carrito (cantidad: 5)
2. Ir a "Mi Carrito"
3. Observar la tarjeta del producto

**Resultado esperado**:
```
✅ Precio unitario: Bs 10.00
✅ Subtotal: Bs 50.00
✅ Sección "¡Oportunidad de Ahorro!" visible
✅ Texto: "Agrega 5 más: → Rango 10-49"
✅ Ahorro mostrado: Bs 17.50 (5 unidades más * 2.5 Bs de diferencia)
✅ Botón: "Agregar 5 para ahorrar"
```

**Debug**:
- Logs en console deben mostrar:
  ```
  📊 Calculando carrito con rangos de precio...
  ✅ Carrito calculado con éxito
  Items con oportunidad de ahorro: 1
  ```

---

### Test 3: Múltiples Productos con Diferentes Rangos
**Objetivo**: Validar cálculo independiente por producto

**Datos de prueba**:
- PEPSI 250ML: cantidad 5
- GUARANA 350ML: cantidad 8
- FANTA 500ML: cantidad 50

**Pasos**:
1. Agregar tres productos diferentes
2. Ir a "Mi Carrito"
3. Observar cada tarjeta

**Resultado esperado**:
```
✅ PEPSI (5): Muestra "Agrega 5 para rango 10-49"
✅ GUARANA (8): Muestra "Agrega 2 para rango 10-49"
✅ FANTA (50): NO muestra sección de ahorro (ya en rango máximo)
```

---

### Test 4: Incrementar Cantidad Manualmente
**Objetivo**: Validar que recalcula después de cambiar cantidad

**Pasos**:
1. Tener PEPSI 250ML con cantidad 5
2. Ver "Agrega 5 más"
3. Hacer clic en botón "+" para incrementar a 6
4. Observar cambios

**Resultado esperado**:
```
✅ Cantidad actualizada a 6
✅ API recalcula automáticamente (ver logs)
✅ "Agrega 4 más" ahora (porque faltan 4 para llegar a 10)
✅ Ahorro disminuye proporcionalmente
```

**Logs esperados**:
```
🔄 Calculando carrito con rangos de precio...
✅ Carrito calculado con éxito
```

---

### Test 5: "Agregar para Ahorrar" Button
**Objetivo**: Validar que agrega automáticamente la cantidad correcta

**Pasos**:
1. Tener PEPSI 250ML con cantidad 5
2. Ver "Agrega 5 para ahorrar - Bs 17.50"
3. Hacer clic en botón "Agregar 5 para ahorrar"
4. Observar cambios inmediatos

**Resultado esperado**:
```
✅ Cantidad pasa de 5 a 10 automáticamente
✅ Precio unitario actualizado a Bs 8.50
✅ Subtotal: Bs 85.00
✅ Sección de ahorro se actualiza o desaparece (depende si hay otro rango)
✅ Se muestra nueva oportunidad: "Agrega 40 más → Rango 50+" con Bs 75.00 de ahorro
```

**Logs esperados**:
```
💾 Agregando cantidad para ahorrar...
✅ Cantidad actualizada
🔄 Calculando carrito con rangos...
```

---

### Test 6: Maximizar Cantidad (Alcanzar Rango Máximo)
**Objetivo**: Validar que no muestra ahorro si ya está en rango máximo

**Pasos**:
1. Tener PEPSI 250ML con cantidad 10
2. Hacer clic "Agregar 40 para ahorrar" (para ir a 50)
3. Observar sección de ahorro

**Resultado esperado**:
```
✅ Cantidad: 50
✅ Precio unitario: Bs 7.00 (mejor precio)
✅ Subtotal: Bs 350.00
✅ NO muestra sección de ahorro (está en rango máximo 50+)
```

---

### Test 7: Validación de Stock
**Objetivo**: Validar que no permite agregar más de lo disponible

**Precondición**: Producto con stock limitado (ej: 20 unidades disponibles)

**Pasos**:
1. Agregar producto (cantidad: 15)
2. Hacer clic "Agregar para ahorrar" (necesita 10 más = total 25)
3. Observar resultado

**Resultado esperado**:
```
✅ Se muestra error: "Stock insuficiente. Disponible: 20"
✅ Cantidad se mantiene en 15
✅ Banner de error en rojo aparece
```

**Logs esperados**:
```
❌ Error al agregar para ahorrar: Stock insuficiente
```

---

### Test 8: Decrementar Cantidad
**Objetivo**: Validar que recalcula cuando se disminuye cantidad

**Pasos**:
1. Tener PEPSI con cantidad 10
2. Ver "Agrega 40 más → Bs 75"
3. Hacer clic "-" para bajar a 9
4. Observar cambios

**Resultado esperado**:
```
✅ Cantidad: 9
✅ Precio unitario vuelve a Bs 10.00
✅ Sección de ahorro actualizada: "Agrega 1 más → Rango 10-49"
✅ Ahorro reducido: Bs 17.50
```

---

### Test 9: Eliminar Producto del Carrito
**Objetivo**: Validar que recalcula al eliminar

**Pasos**:
1. Tener 2 productos en carrito
2. Hacer clic en "X" para eliminar uno
3. Observar carrito

**Resultado esperado**:
```
✅ Producto eliminado
✅ SnackBar: "X producto eliminado del carrito"
✅ Rangos recalculan para producto restante
```

---

### Test 10: Conexión Lenta / API Lenta
**Objetivo**: Validar comportamiento con respuesta lenta

**Preparación**:
- En dev tools, throttle network a "Slow 3G"

**Pasos**:
1. Abrir carrito
2. Observar durante cálculo

**Resultado esperado**:
```
✅ Se muestra indicador de carga (spinner)
✅ Interfaz se congela gracefully (no responsive)
✅ Después de 2-3 segundos, datos aparecen
✅ Sin crashes
```

---

### Test 11: Error de API
**Objetivo**: Validar manejo de errores

**Preparación**:
- Detener backend o cambiar API_URL a URL inválida

**Pasos**:
1. Abrir carrito
2. Observar respuesta

**Resultado esperado**:
```
✅ Banner de error rojo apareceá (opcional, depende si error es silencioso)
✅ Carrito sigue siendo funcional
✅ Se pueden hacer cambios aunque no se calcule
✅ Logs muestran el error
```

**Logs esperados**:
```
❌ Error al calcular carrito: Connection refused
```

---

### Test 12: Actualización en Tiempo Real
**Objetivo**: Validar que cada cambio recalcula

**Pasos**:
1. Abrir carrito con producto
2. Observar sección de ahorro
3. Aumentar cantidad 5 veces (+5 clicks)
4. Observar cambios en tiempo real

**Resultado esperado**:
```
✅ Cada clic de "+" recalcula inmediatamente
✅ Sección de ahorro se actualiza después de cada cambio
✅ Números son consistentes (precio * cantidad = subtotal)
```

---

## 🔍 Validaciones Técnicas

### Llamadas API
```bash
# Ver en Network tab del debugger

# Request al abrir carrito:
POST /api/carrito/calcular
{
  "items": [
    { "producto_id": 1, "cantidad": 5 }
  ]
}

# Response:
{
  "success": true,
  "data": {
    "cantidad_items": 1,
    "subtotal": 50.00,
    "ahorro_total": 17.50,
    "detalles": [...]
  }
}
```

### Logs en Console
```
✅ "CarritoProvider inicializado para usuario: X"
✅ "Calculando carrito con rangos de precio..."
✅ "Carrito calculado con éxito"
✅ "Subtotal: 50.00 Bs"
✅ "Items con oportunidad de ahorro: 1"
```

### Datos en Memoria
- Verificar en debugger que `_detallesConRango` map tiene entries
- Verificar que `_carritoConRangos` tiene datos

---

## 📱 Testing en Diferentes Dispositivos

### Android
- [ ] Teléfono pequeño (< 5")
- [ ] Teléfono mediano (5-6")
- [ ] Tableta (> 7")

### iOS
- [ ] iPhone SE
- [ ] iPhone 12/13
- [ ] iPad

### Orientaciones
- [ ] Vertical (normal)
- [ ] Horizontal (landscape)

---

## 🐛 Casos de Borde

| Caso | Entrada | Esperado |
|------|---------|----------|
| Cantidad 0 | Agregar 0 items | Error "cantidad > 0" |
| Cantidad negativa | Cambio manual en DB | Error en validación |
| Precio 0 | Producto sin precio | Error o salta |
| Stock -1 | DB con stock inválido | Error de API |
| API timeout | Request > 30s | Retry automático |
| JSON inválido | API retorna HTML | Error parsed |

---

## ✅ Checklist de Aprobación

- [ ] Test 1 PASÓ - Carrito vacío
- [ ] Test 2 PASÓ - Un producto con ahorro
- [ ] Test 3 PASÓ - Múltiples productos
- [ ] Test 4 PASÓ - Incrementar cantidad
- [ ] Test 5 PASÓ - Botón "Agregar para ahorrar"
- [ ] Test 6 PASÓ - Maximizar cantidad
- [ ] Test 7 PASÓ - Validación de stock
- [ ] Test 8 PASÓ - Decrementar cantidad
- [ ] Test 9 PASÓ - Eliminar producto
- [ ] Test 10 PASÓ - Conexión lenta
- [ ] Test 11 PASÓ - Error de API
- [ ] Test 12 PASÓ - Actualización en tiempo real

---

## 📊 Reportar Resultados

### Template de Reporte
```markdown
## Testing de Rangos de Precios

**Fecha**: 2026-01-04
**Tester**: [Nombre]
**Dispositivo**: [Modelo, OS]
**Versión**: [Versión de app]

### Resultados
- Tests pasados: 12/12 ✅
- Tests fallidos: 0 ❌
- Warnings: 0 ⚠️

### Issues Encontrados
[Lista aquí]

### Observaciones
[Feedback general]

**Conclusión**: APROBADO ✅
```

---

## 📞 Soporte

Si algo no funciona:

1. **Revisar logs** - ¿Qué dice la consola?
2. **Verificar backend** - ¿Endpoints están respondiendo?
3. **Verificar datos** - ¿Hay rangos configurados para el producto?
4. **Verificar conexión** - ¿App puede alcanzar API?

---

**Último actualizado**: 2026-01-04
**Status**: Listo para testing
