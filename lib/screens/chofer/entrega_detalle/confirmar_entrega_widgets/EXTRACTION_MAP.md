# Mapa de Extracción de Widgets

Este archivo documenta qué métodos del archivo original fueron extraídos a cada widget.

## Mapeo Método → Widget

### FormularioCompletaWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildPasoConfirmacionCompleta(BuildContext context, bool isDarkMode)` (líneas 1636-2088)

**Contenido extraído**:
- Icono de check circle y título "Entrega Completa"
- Container con detalles de venta (número, cliente, total)
- Llamada a `_buildResumenMontos()`
- Llamada a `_buildPagoForm()`
- Sección de pagos múltiples registrados
- Validaciones dinámicas según estado de pago (crédito vs no crédito)
- Resumen de novedad registrada (si aplica)

**Parámetros necesarios**:
- `venta: Venta`
- `isDarkMode: bool`
- `fotosCapturadas: List<dynamic>`
- `tiposPago: List<Map>`
- `pagos: List<PagoEntrega>`
- `esCredito: bool`
- `observacionesController: TextEditingController`
- `tipoNovedad: String?`
- Callbacks: `onAgregarPago`, `buildResumenMontos`, `buildPagoForm`

---

### FormularioNovedadWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildPasoNovedad(BuildContext context, bool isDarkMode)` (líneas 2091-2658)

**Contenido extraído**:
- Selector de tipo de novedad (Radio buttons con 3 opciones)
- Tabla de productos rechazados (condicional para DEVOLUCION_PARCIAL)
- Resumen de montos ajustado
- Campos de observaciones
- Sección de fotos con galería
- Sección de pagos (solo para devolución parcial y no crédito)

**Parámetros necesarios**:
- `screenContext: BuildContext`
- `isDarkMode: bool`
- `tipoNovedad: String?`
- `tiposNovedad: List<Map<String, String>>`
- `venta: Venta`
- `observacionesController: TextEditingController`
- `fotosCapturadas: List<dynamic>`
- `pagos: List<PagoEntrega>`
- `tiposPago: List<Map<String, dynamic>>`
- Callbacks múltiples

---

### TablaProductosWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildTablaProductosRechazados({bool isDarkMode = false})` (líneas 2662-3115)

**Contenido extraído**:
- Tabla DataTable con 7 columnas:
  - Checkbox (para marcar rechazos)
  - Nombre del producto
  - Cantidad original
  - Cantidad rechazada (editable)
  - Cantidad entregada (calculada)
  - Precio unitario
  - Subtotal rechazado
- Resumen desglosado de rechazos parciales
- Totales (entregado, rechazado, original)

**Parámetros necesarios**:
- `venta: Venta`
- `isDarkMode: bool`
- `productosRechazados: List<ProductoRechazado>`
- `cantidadRechazadaControllers: Map<int, TextEditingController>`
- Callbacks para eventos de cambio

---

### ResumenMontosWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildResumenMontos(double totalVenta)` (líneas 3118-3627)

**Contenido extraído**:
- Resumen total de pagos con estado dinámico
- Cálculos de:
  - Total original vs ajustado (para devolución parcial)
  - Dinero recibido
  - Crédito otorgado
  - Falta por recibir
  - Porcentaje pagado
- Estados visuales (completado, parcial, pendiente, crédito)
- Barra de progreso animada
- Cards independientes para cada monto

**Parámetros necesarios**:
- `totalVenta: double`
- `montoRechazado: double`
- `totalRecibido: double`
- `esCredito: bool`
- `pagos: List<PagoEntrega>`

---

### PagoFormWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildPagoForm({bool isDarkMode = false})` (líneas 769-969)

**Contenido extraído**:
- Sugerencia inteligente (condicional)
- Container del formulario con:
  - Selector de tipo de pago (dropdown)
  - Campo de monto
  - Campo de referencia
  - Botón "Agregar Pago"
- Validaciones de monto > 0
- SnackBars de feedback

**Parámetros necesarios**:
- `isDarkMode: bool`
- `tiposPago: List<Map<String, dynamic>>`
- `cargandoTiposPago: bool`
- `tipoPagoSeleccionado: int?`
- `montoController: TextEditingController`
- `referenciaController: TextEditingController`
- Callbacks para cambios y adición de pagos

---

### SugerenciaPagoWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildSugerenciaPago({bool isDarkMode = false})` (líneas 608-766)

**Contenido extraído**:
- Container con gradiente y borde
- Icono de bombilla (💡)
- Información de saldo pendiente
- Card con tipo de pago sugerido
- Botón "Usar Sugerencia"
- Pre-llenado automático del monto

**Parámetros necesarios**:
- `sugerencia: Map<String, dynamic>`
- `isDarkMode: bool`
- `montoController: TextEditingController`
- `onUsarSugerencia: VoidCallback`

---

### SeccionCreditoWidget
**Archivo original**: `confirmar_entrega_venta_screen.dart`
**Método original**: `_buildSeccionCredito()` (líneas 972-991)

**Contenido extraído**:
- CheckboxListTile simple
- Título: "💳 Esta venta es a Crédito"
- Subtítulo descriptivo
- Control affinity a la izquierda

**Parámetros necesarios**:
- `esCredito: bool`
- `onCreditoChanged: Function(bool?)`

---

## Métodos Auxiliares NO Extraídos (Aún en Archivo Principal)

Los siguientes métodos permanecen en el archivo principal porque contienen lógica de estado:

- `_cargarTiposPago()` - Carga inicial de tipos de pago
- `_capturarFoto()` - Captura foto con cámara
- `_eliminarFoto(int index)` - Elimina foto de la lista
- `_construirImagenFoto(dynamic foto)` - Construye widget de imagen
- `_obtenerSugerenciaPago()` - Lógica de sugerencia inteligente
- `_obtenerTiposPagoDisponibles()` - Filtra tipos ya usados
- `_validarDatos()` - Validación completa de formulario
- `_obtenerRazonError()` - Obtiene mensaje de error
- `_mostrarDialogoCorregirPagos()` - Diálogo para editar pagos
- `_guardarCambiosTipoEntrega()` - Guarda cambios en edición
- Métodos de confirmación y llamadas a API

---

## Clases Auxiliares Extraídas

### PagoEntrega
Extraída de: líneas 15-27 (archivo original)
Ubicación actual: Replicada en varios widgets para independencia
```dart
class PagoEntrega {
  int tipoPagoId;
  double monto;
  String? referencia;

  PagoEntrega({required this.tipoPagoId, required this.monto, this.referencia});

  Map<String, dynamic> toJson() => {...};
}
```

### ProductoRechazado
Extraída de: líneas 29-68 (archivo original)
Ubicación actual: `tabla_productos_widget.dart`
```dart
class ProductoRechazado {
  int detalleVentaId;
  int? productoId;
  String nombreProducto;
  double cantidadOriginal;
  double cantidadRechazada;
  double precioUnitario;
  double subtotalOriginal;

  // Getters para cálculos: subtotalRechazado, cantidadEntregada
}
```

---

## Notas sobre Refactorización Futura

1. **Consolidar clases auxiliares**: Las clases `PagoEntrega` están replicadas. Considerar crear un archivo `models.dart` en la carpeta.

2. **Callbacks vs Provider**: Actualmente usamos callbacks. Podría optimizarse usando Provider para estado compartido.

3. **Métodos de utilidad**: Algunos métodos como `_construirImagenFoto()` podrían extraerse a un servicio.

4. **Estado compartido**: El `setState()` en el archivo principal necesita ser refactorizado para los widgets StatefulWidget.

5. **Pruebas unitarias**: Cada widget puede testearse independientemente ahora.

---

## Histórico de Cambios

- **2026-03-05**: Creación inicial de estructura de widgets
  - 7 widgets separados creados
  - 2 archivos de documentación
  - Imports agregados al archivo principal
  - Sin cambios en la lógica de estado
