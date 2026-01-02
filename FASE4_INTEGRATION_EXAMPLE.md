# Fase 4 - Ejemplo de Integración

## Cómo Usar los Nuevos Widgets de Estados

Este documento muestra ejemplos prácticos de cómo integrar los widgets dinámicos de estados en tu código existente.

---

## 📋 Ejemplo 1: Mostrar Badge de Estado (Simple)

### Antes (Hardcodeado)
```dart
// lib/screens/chofer/entregas_screen.dart
class EntregaListItem extends StatelessWidget {
  final Entrega entrega;

  const EntregaListItem({required this.entrega});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Entrega #${entrega.id}'),
      subtitle: Text(entrega.estadoLabel), // ❌ Hardcodeado
      trailing: Container(
        color: Color(int.parse(entrega.estadoColor.replaceFirst('#', '0xff'))),
        child: Text(entrega.estadoIcon),
      ),
    );
  }
}
```

### Después (Dinámico - Recomendado)
```dart
// lib/screens/chofer/entregas_screen.dart
import '../widgets/estado_badge_widget.dart';

class EntregaListItem extends StatelessWidget {
  final Entrega entrega;

  const EntregaListItem({required this.entrega});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Entrega #${entrega.id}'),
      subtitle: Text(entrega.cliente ?? 'N/A'),
      trailing: EstadoBadgeWidget(
        categoria: 'entrega',
        estadoCodigo: entrega.estado,
      ),
    );
  }
}
```

---

## 🔍 Ejemplo 2: Filtro por Estado en Lista

### Antes (Hardcodeado)
```dart
class EntregasListPage extends StatefulWidget {
  @override
  _EntregasListPageState createState() => _EntregasListPageState();
}

class _EntregasListPageState extends State<EntregasListPage> {
  String? _filtroEstado;

  final _estadoOptions = ['PROGRAMADO', 'ASIGNADA', 'EN_CAMINO', 'ENTREGADO'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String?>(
          value: _filtroEstado,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
            ..._estadoOptions.map((e) => DropdownMenuItem<String?>(
              value: e,
              child: Text(e),
            )),
          ],
          onChanged: (value) => setState(() => _filtroEstado = value),
        ),
        // List items...
      ],
    );
  }
}
```

### Después (Dinámico - Recomendado)
```dart
import '../widgets/estado_filter_widget.dart';

class EntregasListPage extends StatefulWidget {
  @override
  _EntregasListPageState createState() => _EntregasListPageState();
}

class _EntregasListPageState extends State<EntregasListPage> {
  String? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EstadoFilterDropdown(
          categoria: 'entrega',
          selectedEstadoCodigo: _filtroEstado,
          onChanged: (value) => setState(() => _filtroEstado = value),
          incluyeTodos: true,
        ),
        // List items...
      ],
    );
  }
}
```

---

## 🏷️ Ejemplo 3: Filter Chips (Multi-selección)

```dart
import '../widgets/estado_filter_widget.dart';

class EntregasFilterPage extends StatefulWidget {
  @override
  _EntregasFilterPageState createState() => _EntregasFilterPageState();
}

class _EntregasFilterPageState extends State<EntregasFilterPage> {
  Set<String> _filtrosEstado = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Filtrar por Estado:'),
        const SizedBox(height: 8),
        EstadoFilterChips(
          categoria: 'entrega',
          selectedEstadoCodigos: _filtrosEstado,
          onChanged: (nuevos) => setState(() => _filtrosEstado = nuevos),
          direction: Axis.horizontal,
        ),
        // Lista filtrada...
      ],
    );
  }
}
```

---

## 🔘 Ejemplo 4: Filter Buttons (Interfaz Más Visual)

```dart
import '../widgets/estado_filter_widget.dart';

class EntregasViewerPage extends StatefulWidget {
  @override
  _EntregasViewerPageState createState() => _EntregasViewerPageState();
}

class _EntregasViewerPageState extends State<EntregasViewerPage> {
  String? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EstadoFilterButtons(
          categoria: 'entrega',
          selectedEstadoCodigo: _filtroEstado,
          onChanged: (value) => setState(() => _filtroEstado = value),
        ),
        const SizedBox(height: 16),
        // Lista filtrada por _filtroEstado...
      ],
    );
  }
}
```

---

## 🎨 Ejemplo 5: BuilderWidget (Control Total)

Para casos donde necesitas acceso completo a la información del estado:

```dart
import '../widgets/estado_badge_widget.dart';

class CustomEstadoDisplay extends StatelessWidget {
  final Entrega entrega;

  const CustomEstadoDisplay({required this.entrega});

  @override
  Widget build(BuildContext context) {
    return EstadoBuilder(
      categoria: 'entrega',
      estadoCodigo: entrega.estado,
      builder: (context, label, color, icon) {
        final colorInt = int.parse(color.replaceFirst('#', '0xff'));
        final bgColor = Color(colorInt);

        return Card(
          color: bgColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: bgColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
```

---

## 🧪 Ejemplo 6: Usarlo con Riverpod ConsumerWidget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/estado_badge_widget.dart';

class EntregaDetailScreen extends ConsumerWidget {
  final Entrega entrega;

  const EntregaDetailScreen({required this.entrega});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acceder a datos del estado si lo necesitas
    final estadoAsync = ref.watch(
      estadoPorCodigoProvider(('entrega', entrega.estado))
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega #${entrega.id}'),
      ),
      body: Column(
        children: [
          // Badge con datos dinámicos
          EstadoBadgeWidget(
            categoria: 'entrega',
            estadoCodigo: entrega.estado,
            fontSize: 16,
          ),
          const SizedBox(height: 16),

          // Acceder a más detalles si es necesario
          estadoAsync.when(
            data: (estado) => estado != null ? Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descripción: ${estado.descripcion ?? 'N/A'}'),
                    Text('Es estado final: ${estado.esEstadoFinal}'),
                    Text('Permite edición: ${estado.permiteEdicion}'),
                  ],
                ),
              ),
            ) : const SizedBox.shrink(),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📱 Ejemplo 7: Integración Completa en EntregasEnTransito

```dart
// lib/screens/chofer/entregas_en_transito.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entrega.dart';
import '../../widgets/estado_badge_widget.dart';
import '../../widgets/estado_filter_widget.dart';

class EntregasEnTransitoScreen extends ConsumerStatefulWidget {
  @override
  _EntregasEnTransitoScreenState createState() =>
      _EntregasEnTransitoScreenState();
}

class _EntregasEnTransitoScreenState
    extends ConsumerState<EntregasEnTransitoScreen> {
  String? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    // Obtener entregas del provider existente
    // ... (usando tu entrega_provider actual)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas en Tránsito'),
      ),
      body: Column(
        children: [
          // Filtro dinámico de estados
          Padding(
            padding: const EdgeInsets.all(16),
            child: EstadoFilterButtons(
              categoria: 'entrega',
              selectedEstadoCodigo: _filtroEstado,
              onChanged: (value) {
                setState(() => _filtroEstado = value);
              },
            ),
          ),

          // Lista de entregas con badges dinámicos
          Expanded(
            child: ListView.builder(
              itemCount: filteredEntregas.length,
              itemBuilder: (context, index) {
                final entrega = filteredEntregas[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('Entrega #${entrega.id}'),
                    subtitle: Text(entrega.cliente ?? 'N/A'),
                    trailing: EstadoBadgeWidget(
                      categoria: 'entrega',
                      estadoCodigo: entrega.estado,
                    ),
                    onTap: () {
                      // Navegar a detalles
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🚀 Pasos para Migrar Existentes Screens

1. **Importar los widgets**
   ```dart
   import 'path/to/estado_badge_widget.dart';
   import 'path/to/estado_filter_widget.dart';
   ```

2. **Reemplazar badges hardcodeados**
   ```dart
   // Antes
   Text(entrega.estadoLabel)

   // Después
   EstadoBadgeWidget(
     categoria: 'entrega',
     estadoCodigo: entrega.estado,
   )
   ```

3. **Reemplazar filtros hardcodeados**
   ```dart
   // Antes
   DropdownButton(items: [..._hardcodedItems...])

   // Después
   EstadoFilterDropdown(
     categoria: 'entrega',
     selectedEstadoCodigo: _filtro,
     onChanged: (value) => setState(() => _filtro = value),
   )
   ```

4. **Testear**
   - Verificar que los estados se cargan dinámicamente
   - Verificar que los colores/iconos se muestran correctamente
   - Verificar fallback a hardcoded si API falla

---

## 📚 Referencia Rápida

| Widget | Uso | Async | Reactivo |
|--------|-----|-------|----------|
| `EstadoBadgeWidget` | Mostrar estado con badge | Sí | Sí |
| `SimpleEstadoBadgeWidget` | Mostrar estado rápido | No | No |
| `EstadoChipWidget` | Mostrar estado como chip | Sí | Sí |
| `EstadoBuilder` | Control total | Sí | Sí |
| `EstadoFilterDropdown` | Filtrar con dropdown | Sí | No |
| `EstadoFilterChips` | Multi-seleccionar | Sí | No |
| `EstadoFilterButtons` | Botones visuales | Sí | No |

---

## 🐛 Troubleshooting

### Widget muestra loading infinito
**Solución:** Verificar que el usuario está autenticado
```dart
// En el widget
final authProvider = ref.watch(authNotifierProvider);
if (!authProvider.isAuthenticated) {
  return const Text('Debe autenticarse');
}
```

### Colores no se ven correctamente
**Solución:** Verificar formato hexadecimal del backend
```dart
// El backend debe devolver: "color": "#3B82F6"
// No: color: 0xFF3B82F6 (esto es Dart, no JSON)
```

### Estados no aparecen en dropdown
**Solución:** Verificar que el backend devuelve estados con `activo: true`
