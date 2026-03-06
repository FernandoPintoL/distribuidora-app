# Widgets de Confirmación de Entrega

Esta carpeta contiene los widgets separados para la pantalla de confirmación de entrega (`confirmar_entrega_venta_screen.dart`). La separación de widgets permite un código más mantenible y reutilizable.

## Estructura de Archivos

### 1. **formulario_completa_widget.dart**
Widget para mostrar el formulario de **Entrega Completa**.
- Detalles de la venta (número, cliente, total)
- Resumen de montos
- Registro de pagos múltiples
- Fotos opcionales

**Clase principal**: `FormularioCompletaWidget extends StatelessWidget`

---

### 2. **formulario_novedad_widget.dart**
Widget para mostrar el formulario de **Novedad/Incidencia**.
- Selector de tipo de novedad (Cliente Cerrado, Devolución Parcial, Rechazo Total)
- Tabla de productos rechazados (solo para devolución parcial)
- Resumen de montos ajustados
- Observaciones
- Captura de fotos
- Registro de pagos (solo para devolución parcial y no crédito)

**Clase principal**: `FormularioNovedadWidget extends StatelessWidget`

---

### 3. **tabla_productos_widget.dart**
Widget para mostrar la **tabla editable de productos rechazados**.
- Tabla con checkbox para marcar productos rechazados
- Campos editables para cantidad rechazada
- Cálculos automáticos de montos entregados y rechazados
- Resumen desglosado de rechazos parciales

**Clase principal**: `TablaProductosWidget extends StatelessWidget`
**Clase auxiliar**: `ProductoRechazado` (modelo de datos)

---

### 4. **resumen_montos_widget.dart**
Widget para mostrar el **resumen de pagos y montos de la venta**.
- Total de la venta (original y ajustado para devolución parcial)
- Dinero recibido
- Crédito otorgado (si aplica)
- Falta por recibir (si aplica)
- Barra de progreso de pago
- Estados visuales (completado, parcial, pendiente, crédito)

**Clase principal**: `ResumenMontosWidget extends StatelessWidget`
**Clase auxiliar**: `PagoEntrega` (modelo de pago)

---

### 5. **pago_form_widget.dart**
Widget con el **formulario para agregar nuevos pagos**.
- Selector de tipo de pago (efectivo, transferencia, cheque, etc.)
- Campo de monto
- Campo de referencia (opcional)
- Validaciones
- Integración con sugerencia inteligente

**Clase principal**: `PagoFormWidget extends StatefulWidget`
**Clase auxiliar**: `PagoEntrega` (modelo de pago)

---

### 6. **sugerencia_pago_widget.dart**
Widget con **sugerencia inteligente de pago**.
- Muestra el saldo pendiente por recibir
- Sugiere tipo de pago basado en historial
- Botón para aplicar automáticamente la sugerencia

**Clase principal**: `SugerenciaPagoWidget extends StatelessWidget`

---

### 7. **seccion_credito_widget.dart**
Widget para **checkbox de crédito**.
- Opción para marcar la venta como a crédito
- Oculta campos de pago cuando es crédito

**Clase principal**: `SeccionCreditoWidget extends StatelessWidget`

---

### 8. **index.dart**
Archivo de índice que **exporta todos los widgets** para facilitar las importaciones en la pantalla principal.

```dart
export 'formulario_completa_widget.dart';
export 'formulario_novedad_widget.dart';
export 'tabla_productos_widget.dart';
export 'resumen_montos_widget.dart';
export 'pago_form_widget.dart';
export 'sugerencia_pago_widget.dart';
export 'seccion_credito_widget.dart';
```

## Cómo Usar

### Importar un widget individual:
```dart
import 'confirmar_entrega_widgets/formulario_completa_widget.dart';
```

### Importar todos usando el índice:
```dart
import 'confirmar_entrega_widgets/index.dart';
```

## Próximos Pasos

1. **Actualizar `confirmar_entrega_venta_screen.dart`** para usar estos widgets
2. **Eliminar métodos duplicados** del archivo principal que ya están en los widgets
3. **Pruebas completas** para asegurar que todo funciona correctamente
4. **Optimizaciones de rendimiento** si es necesario

## Notas Importantes

- Los widgets importan todo lo necesario de `app_text_styles.dart`, `venta.dart`, etc.
- Las clases auxiliares (`PagoEntrega`, `ProductoRechazado`) están definidas en los archivos de widgets
- El archivo principal debe mantener la lógica de estado y control de flujo
- Los widgets son principalmente `StatelessWidget` para mayor eficiencia

## Estado de Implementación

- ✅ Estructura de carpetas creada
- ✅ Todos los widgets creados
- ✅ Imports agregados al archivo principal
- ⏳ Pendiente: Refactorizar `confirmar_entrega_venta_screen.dart` para usar los widgets
- ⏳ Pendiente: Pruebas exhaustivas
