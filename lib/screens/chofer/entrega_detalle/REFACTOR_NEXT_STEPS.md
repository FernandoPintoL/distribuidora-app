# Próximos Pasos: Refactorización de confirmar_entrega_venta_screen.dart

**Estado actual (2026-03-05)**: Widgets separados creados y listos para integración.

## Fase 2: Integración de Widgets en Archivo Principal

### 1. Actualizar el método build() principal

**Ubicación actual**: Línea ~1100 en confirmar_entrega_venta_screen.dart

**Cambio necesario**:
```dart
// ANTES: Llama directamente a _buildPasoConfirmacionCompleta()
if (_paso == 2 && _tipoEntrega == 'COMPLETA') {
  return _buildPasoConfirmacionCompleta(context, isDarkMode);
}

// DESPUÉS: Usa el widget separado
if (_paso == 2 && _tipoEntrega == 'COMPLETA') {
  return FormularioCompletaWidget(
    venta: widget.venta,
    isDarkMode: isDarkMode,
    fotosCapturadas: _fotosCapturadas,
    tiposPago: _tiposPago,
    pagos: _pagos,
    esCredito: _esCredito,
    observacionesController: _observacionesController,
    tipoNovedad: _tipoNovedad,
    onAgregarPago: () { /* callback */ },
    buildResumenMontos: _buildResumenMontos,
    buildPagoForm: _buildPagoForm,
  );
}
```

### 2. Reemplazar _buildPasoConfirmacionCompleta()

**Pasos**:
1. Buscar la definición del método (línea 1636)
2. Eliminar todo el método (1636-2088)
3. Usar FormularioCompletaWidget en su lugar

**Verificar**: Los métodos que se llaman desde el widget (`_buildResumenMontos`, `_buildPagoForm`) aún existen en el archivo principal.

---

### 3. Reemplazar _buildPasoNovedad()

**Pasos**:
1. Buscar la definición del método (línea 2091)
2. Eliminar todo el método (2091-2658)
3. Usar FormularioNovedadWidget en su lugar

```dart
return FormularioNovedadWidget(
  screenContext: context,
  isDarkMode: isDarkMode,
  tipoNovedad: _tipoNovedad,
  tiposNovedad: _tiposNovedad,
  venta: widget.venta,
  observacionesController: _observacionesController,
  fotosCapturadas: _fotosCapturadas,
  eliminarFoto: _eliminarFoto,
  capturarFoto: _capturarFoto,
  construirImagenFoto: (foto) => _construirImagenFoto(foto),
  buildTablaProductosRechazados: (ctx, dark) =>
    _buildTablaProductosRechazados(isDarkMode: dark),
  buildResumenMontos: _buildResumenMontos,
  buildPagoForm: _buildPagoForm,
  pagos: _pagos,
  tiposPago: _tiposPago,
  onTipoNovedadChanged: (value) {
    setState(() => _tipoNovedad = value);
  },
);
```

---

### 4. Reemplazar _buildTablaProductosRechazados()

**Ubicación**: Línea 2662-3115

**Reemplazo**:
```dart
return TablaProductosWidget(
  venta: widget.venta,
  isDarkMode: isDarkMode,
  productosRechazados: _productosRechazados,
  cantidadRechazadaControllers: _cantidadRechazadaControllers,
  onProductoRechazadoAgregado: (detalleId, producto) {
    setState(() => _productosRechazados.add(producto));
  },
  onProductoRechazadoRemovido: (detalleId) {
    setState(() => _productosRechazados.removeWhere(
      (p) => p.detalleVentaId == detalleId
    ));
  },
  onCantidadRechazadaChanged: (producto, nuevaCantidad) {
    setState(() => producto.cantidadRechazada = nuevaCantidad);
  },
  onStateChanged: () => setState(() {}),
);
```

---

### 5. Reemplazar _buildResumenMontos()

**Ubicación**: Línea 3118-3627

**Reemplazo**:
```dart
double montoRechazado = _tipoNovedad == 'DEVOLUCION_PARCIAL'
    ? _productosRechazados.fold(0.0, (sum, p) => sum + p.subtotalRechazado)
    : 0.0;

return ResumenMontosWidget(
  totalVenta: totalVenta,
  montoRechazado: montoRechazado,
  totalRecibido: _pagos.fold(0.0, (sum, p) => sum + p.monto),
  esCredito: _esCredito,
  pagos: _pagos,
);
```

---

### 6. Reemplazar _buildPagoForm()

**Ubicación**: Línea 769-969

**Reemplazo**:
```dart
return PagoFormWidget(
  isDarkMode: isDarkMode,
  tiposPago: _tiposPago,
  cargandoTiposPago: _cargandoTiposPago,
  tipoPagoSeleccionado: _tipoPagoSeleccionado,
  montoController: _montoController,
  referenciaController: _referenciaController,
  onTipoPagoChanged: (value) {
    setState(() => _tipoPagoSeleccionado = value);
  },
  onPagoAñadido: (pagosActualizados) {
    setState(() => _pagos = pagosActualizados);
  },
  buildSugerenciaPago: () => _buildSugerenciaPago(isDarkMode: isDarkMode),
  pagosActuales: _pagos,
  setState: setState,
);
```

---

### 7. Reemplazar _buildSugerenciaPago()

**Ubicación**: Línea 608-766

**Reemplazo**:
```dart
final sugerencia = _obtenerSugerenciaPago();
if (sugerencia == null) return const SizedBox.shrink();

return SugerenciaPagoWidget(
  sugerencia: sugerencia,
  isDarkMode: isDarkMode,
  montoController: _montoController,
  onUsarSugerencia: () {
    final saldoPendiente = sugerencia['saldo'] as double;
    _montoController.text = saldoPendiente.toStringAsFixed(2);
    setState(() {});
  },
);
```

---

### 8. Reemplazar _buildSeccionCredito()

**Ubicación**: Línea 972-991

**Reemplazo**:
```dart
return SeccionCreditoWidget(
  esCredito: _esCredito,
  onCreditoChanged: (value) {
    setState(() => _esCredito = value ?? false);
  },
);
```

---

## Fase 3: Limpieza y Validación

### Pasos finales:

1. **Eliminar métodos duplicados** del archivo principal
   - [ ] Eliminar `_buildPasoConfirmacionCompleta()`
   - [ ] Eliminar `_buildPasoNovedad()`
   - [ ] Eliminar `_buildTablaProductosRechazados()`
   - [ ] Eliminar `_buildResumenMontos()`
   - [ ] Eliminar `_buildPagoForm()`
   - [ ] Eliminar `_buildSugerenciaPago()`
   - [ ] Eliminar `_buildSeccionCredito()` (opcional)

2. **Verificar compilación**:
   ```bash
   flutter analyze lib/screens/chofer/entrega_detalle/confirmar_entrega_venta_screen.dart
   flutter build apk --no-shrink
   ```

3. **Revisar el tamaño del archivo**:
   - Antes: ~3000+ líneas
   - Después esperado: ~1500-1800 líneas

4. **Pruebas funcionales**:
   - [ ] Crear nueva entrega completa
   - [ ] Crear novedad (cliente cerrado, devolución parcial, rechazo)
   - [ ] Editar entrega existente
   - [ ] Registrar múltiples pagos
   - [ ] Verificar sugerencia inteligente
   - [ ] Marcar como crédito
   - [ ] Capturar y eliminar fotos

---

## Consolidación de Clases Auxiliares

### Crear archivo de modelos compartidos:

**Archivo**: `confirmar_entrega_widgets/models.dart`

```dart
// ✅ NUEVA 2026-02-12: Modelo para pagos múltiples
class PagoEntrega {
  int tipoPagoId;
  double monto;
  String? referencia;

  PagoEntrega({required this.tipoPagoId, required this.monto, this.referencia});

  Map<String, dynamic> toJson() => {
    'tipo_pago_id': tipoPagoId,
    'monto': monto,
    'referencia': referencia,
  };
}

// ✅ NUEVA 2026-02-15: Modelo para productos rechazados
class ProductoRechazado {
  int detalleVentaId;
  int? productoId;
  String nombreProducto;
  double cantidadOriginal;
  double cantidadRechazada;
  double precioUnitario;
  double subtotalOriginal;

  ProductoRechazado({...});

  double get subtotalRechazado => cantidadRechazada * precioUnitario;
  double get cantidadEntregada => cantidadOriginal - cantidadRechazada;
}
```

Luego actualizar imports en todos los widgets.

---

## Beneficios Esperados

✅ **Mantenibilidad**: Código más legible y modular
✅ **Reutilización**: Widgets pueden usarse en otras pantallas
✅ **Testing**: Widgets pueden probarse independientemente
✅ **Performance**: Mejor optimización de rebuilds
✅ **Colaboración**: Más fácil para múltiples desarrolladores

---

## Estimación de Esfuerzo

- **Refactorización**: 2-3 horas
- **Testing**: 1-2 horas
- **Optimizaciones**: 1 hora
- **Total**: 4-6 horas

---

## Checklist de Validación Final

- [ ] Archivo principal compila sin errores
- [ ] Todos los widgets compilan sin errores
- [ ] Lógica de estado funciona correctamente
- [ ] Fotos se capturan y eliminan correctamente
- [ ] Pagos se agregan y validan correctamente
- [ ] Sugerencia inteligente funciona
- [ ] Crédito se marca correctamente
- [ ] Novedad se registra correctamente
- [ ] Edición de entrega funciona
- [ ] No hay memory leaks (Controllers disociados)
- [ ] Rendimiento es aceptable
- [ ] Tests pasan (si existen)

---

**Última actualización**: 2026-03-05
**Estado**: Listo para Fase 2
