# Fase 3: Móvil (Flutter) - Renovación de Reservas Expiradas

## ✅ Cambios Backend - COMPLETADOS

```dart
// ✅ ProformaService.dart - Ya implementados:
// 1. renovarReservas(int proformaId) - Nuevo método
// 2. confirmarProforma() - Mejorado para retornar código de error
// 3. ApiResponse<T> - Agregadas propiedades: code, additionalData
```

---

## 📱 Implementación en Flutter

### **Paso 1: Crear el diálogo de confirmación de renovación**

Crear archivo: `lib/widgets/dialogs/renovacion_reservas_dialog.dart`

```dart
import 'package:flutter/material.dart';

class RenovacionReservasDialog extends StatefulWidget {
  final String proformaNumero;
  final int reservasExpiradas;
  final VoidCallback onRenovar;
  final VoidCallback onCancelar;
  final bool isLoading;

  const RenovacionReservasDialog({
    Key? key,
    required this.proformaNumero,
    required this.reservasExpiradas,
    required this.onRenovar,
    required this.onCancelar,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<RenovacionReservasDialog> createState() =>
      _RenovacionReservasDialogState();
}

class _RenovacionReservasDialogState extends State<RenovacionReservasDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.amber),
          SizedBox(width: 8),
          Text('Reservas Expiradas'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Las reservas de la proforma ${widget.proformaNumero} han expirado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(color: Colors.amber),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.reservasExpiradas} reserva(s) necesitan renovación.\n\n'
              'Renovar extenderá las reservas por 7 días más con los mismos productos y cantidades.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : widget.onCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onRenovar,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(widget.isLoading ? 'Renovando...' : 'Renovar Reservas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
```

---

### **Paso 2: Actualizar el Provider (o BLoC)**

Agregar a tu provider/bloc que maneja las proformas:

```dart
// En tu ProformaProvider o equivalente

bool _isRenovandoReservas = false;
bool get isRenovandoReservas => _isRenovandoReservas;

String? _errorCode;
String? get errorCode => _errorCode;

Map<String, dynamic>? _errorData;
Map<String, dynamic>? get errorData => _errorData;

/// Confirmar proforma y manejar error de RESERVAS_EXPIRADAS
Future<void> confirmarProforma(int proformaId) async {
  try {
    _isLoading = true;
    _errorCode = null;
    _errorData = null;
    notifyListeners();

    final response = await _proformaService.confirmarProforma(
      proformaId: proformaId,
    );

    if (response.success && response.data != null) {
      // ✅ Conversión exitosa
      debugPrint('✅ Proforma convertida a venta exitosamente');
      // Navegar a venta o actualizar lista
      notifyListeners();
    } else if (!response.success && response.code == 'RESERVAS_EXPIRADAS') {
      // ⚠️ Reservas expiradas - mostrar diálogo de renovación
      _errorCode = 'RESERVAS_EXPIRADAS';
      _errorData = response.additionalData;
      debugPrint('⚠️ Detectado error de RESERVAS_EXPIRADAS');
      notifyListeners();
    } else {
      // ❌ Otros errores
      throw Exception(response.message ?? 'Error desconocido');
    }
  } catch (e) {
    debugPrint('❌ Error al confirmar proforma: $e');
    _isLoading = false;
    notifyListeners();
    rethrow;
  } finally {
    _isLoading = false;
  }
}

/// Renovar reservas expiradas
Future<bool> renovarReservas(int proformaId) async {
  try {
    _isRenovandoReservas = true;
    notifyListeners();

    final response = await _proformaService.renovarReservas(proformaId);

    if (response.success) {
      debugPrint('✅ Reservas renovadas exitosamente');
      _errorCode = null;
      _errorData = null;
      notifyListeners();
      return true;
    } else {
      throw Exception(response.message ?? 'Error al renovar reservas');
    }
  } catch (e) {
    debugPrint('❌ Error al renovar reservas: $e');
    return false;
  } finally {
    _isRenovandoReservas = false;
    notifyListeners();
  }
}
```

---

### **Paso 3: Actualizar la Pantalla (Screen)**

Integrar el diálogo en tu pantalla de confirmación:

```dart
// En tu ProformaDetailScreen o similar

Future<void> _confirmarConversion() async {
  final provider = context.read<ProformaProvider>();

  // Intentar confirmación
  try {
    await provider.confirmarProforma(widget.proforma.id);

    // Verificar si hay error de RESERVAS_EXPIRADAS
    if (provider.errorCode == 'RESERVAS_EXPIRADAS') {
      // Mostrar diálogo de renovación
      if (!mounted) return;
      _mostrarDialogoRenovacion(provider);
    } else {
      // ✅ Éxito - Cerrar pantalla o navegar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Proforma convertida a venta')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: ${e.toString()}')),
    );
  }
}

void _mostrarDialogoRenovacion(ProformaProvider provider) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RenovacionReservasDialog(
      proformaNumero: widget.proforma.numero,
      reservasExpiradas: provider.errorData?['reservas_expiradas'] ?? 1,
      isLoading: provider.isRenovandoReservas,
      onRenovar: () async {
        final renovated = await provider.renovarReservas(widget.proforma.id);

        if (!mounted) return;

        if (renovated) {
          // Cerrar diálogo de renovación
          Navigator.pop(context);

          // Esperar 1.5 segundos y reintentar conversión automáticamente
          await Future.delayed(const Duration(milliseconds: 1500));

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reservas renovadas. Reintentando conversión...'),
            ),
          );

          // Reintentar conversión
          _confirmarConversion();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al renovar reservas'),
            ),
          );
        }
      },
      onCancelar: () {
        Navigator.pop(context);
        provider.limpiarErrores(); // Método helper para limpiar errores
      },
    ),
  );
}

// Agregar método helper al Provider
void limpiarErrores() {
  _errorCode = null;
  _errorData = null;
  notifyListeners();
}
```

---

### **Paso 4: Botón para confirmar/convertir proforma**

```dart
// En tu UI - Botón para convertir a venta

ElevatedButton.icon(
  onPressed: () => _confirmarConversion(),
  icon: const Icon(Icons.shopping_cart),
  label: const Text('Convertir a Venta'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
  ),
)
```

---

## 🔄 Flujo Completo en Móvil

```
1. Usuario hace click en "Convertir a Venta"
   ↓
2. App llama a confirmarProforma()
   ↓
3. Si error RESERVAS_EXPIRADAS:
   ✅ Mostrar RenovacionReservasDialog
   ├─ Usuario ve: "X reservas han expirado"
   ├─ Botón: "Renovar Reservas" (azul)
   └─ Botón: "Cancelar"

4. Si usuario hace click "Renovar Reservas":
   ✅ Llamar a renovarReservas()
   ✅ Mostrar spinner de carga
   ✅ Después de éxito (1.5s):
      - Cerrar diálogo
      - Reintentar confirmarProforma() automáticamente
      - Si es exitoso → mostrar éxito y cerrar pantalla
```

---

## 📋 Checklist de Implementación

- [ ] ✅ ProformaService.dart - métodos agregados
- [ ] ✅ ApiResponse<T> - propiedades agregadas
- [ ] [ ] Crear RenovacionReservasDialog
- [ ] [ ] Actualizar Provider/BLoC
- [ ] [ ] Integrar en pantalla de detalles de proforma
- [ ] [ ] Agregar botón "Convertir a Venta"
- [ ] [ ] Probar flujo completo

---

## 🧪 Prueba Manual

1. Crear una proforma APROBADA en el web
2. Esperar a que las reservas expiren (o hacer que expiren manualmente en DB)
3. Abrir la app móvil y navegar a esa proforma
4. Hacer click en "Convertir a Venta"
5. Debería mostrar el diálogo de renovación
6. Hacer click en "Renovar Reservas"
7. Debería renovar automáticamente y reintenta conversión

---

## 📞 Notas Importantes

- Los endpoints del backend ya están listos: `/proformas/{id}/renovar-reservas`
- El código `RESERVAS_EXPIRADAS` se devuelve automáticamente
- La renovación extiende las reservas 7 días más
- El flujo es automático después de renovar (no requiere más clicks del usuario)

**¡La Fase 3 está lista para implementar!** 🚀
