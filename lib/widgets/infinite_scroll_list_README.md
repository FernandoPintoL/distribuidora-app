# InfiniteScrollList Widget

Widget reutilizable para implementar scroll infinito (paginación automática) en cualquier lista de Flutter.

## Características

✅ **Scroll infinito automático** - Carga más items al llegar al final
✅ **Pull-to-refresh** - Desliza hacia abajo para recargar
✅ **Estados manejados** - Carga inicial, vacío, error, cargando más
✅ **Completamente personalizable** - Mensajes, iconos, threshold, etc.
✅ **Genérico** - Funciona con cualquier tipo de dato
✅ **Indicadores visuales modernos** - Spinners y mensajes elegantes
✅ **Optimizado** - Solo carga cuando es necesario

## Instalación

El widget ya está disponible en `/lib/widgets/infinite_scroll_list.dart`

## Uso Básico

```dart
import 'package:distribuidora/widgets/infinite_scroll_list.dart';

InfiniteScrollList<Client>(
  // Lista de items
  items: clientProvider.clients,

  // Función para cargar más
  onLoadMore: () async {
    return await clientProvider.loadClients(
      page: clientProvider.currentPage + 1,
      perPage: 5,
      append: true,
    );
  },

  // Función para refrescar
  onRefresh: () async {
    await clientProvider.loadClients(perPage: 5);
  },

  // Estados
  hasMorePages: clientProvider.hasMorePages,
  isLoadingMore: clientProvider.isLoading,

  // Constructor de items
  itemBuilder: (context, client, index) {
    return ListTile(
      title: Text(client.nombre),
      subtitle: Text(client.email ?? ''),
    );
  },
)
```

## Parámetros

### Requeridos

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `items` | `List<T>` | Lista de items a mostrar |
| `itemBuilder` | `Function` | Función para construir cada item |
| `onLoadMore` | `Future<bool> Function()` | Función para cargar más items |
| `onRefresh` | `Future<void> Function()` | Función para refrescar la lista |
| `hasMorePages` | `bool` | Indica si hay más páginas disponibles |

### Opcionales

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `isLoadingMore` | `bool` | `false` | Indica si se está cargando más items |
| `isInitialLoading` | `bool` | `false` | Indica si es la carga inicial |
| `emptyMessage` | `String` | "No hay elementos..." | Mensaje cuando está vacío |
| `emptyIcon` | `IconData` | `Icons.inbox_outlined` | Icono cuando está vacío |
| `errorMessage` | `String?` | `null` | Mensaje de error (null si no hay) |
| `loadMoreThreshold` | `double` | `200` | Píxeles desde el final para cargar |
| `padding` | `EdgeInsets?` | `null` | Padding de la lista |
| `separator` | `Widget?` | `null` | Separador entre items |
| `header` | `Widget?` | `null` | Header de la lista |
| `footer` | `Widget?` | `null` | Footer de la lista |

## Ejemplos de Uso

### 1. Lista Simple de Clientes

```dart
InfiniteScrollList<Client>(
  items: provider.clients,
  onLoadMore: () => provider.loadMoreClients(),
  onRefresh: () => provider.refreshClients(),
  hasMorePages: provider.hasMorePages,
  isLoadingMore: provider.isLoading,

  itemBuilder: (context, client, index) {
    return ClientCard(client: client);
  },
)
```

### 2. Lista de Productos con Separador

```dart
InfiniteScrollList<Product>(
  items: provider.products,
  onLoadMore: () => provider.loadMoreProducts(),
  onRefresh: () => provider.refreshProducts(),
  hasMorePages: provider.hasMorePages,

  separator: const Divider(height: 1),

  itemBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
)
```

### 3. Lista de Pedidos con Header y Footer

```dart
InfiniteScrollList<Pedido>(
  items: provider.pedidos,
  onLoadMore: () => provider.loadMorePedidos(),
  onRefresh: () => provider.refreshPedidos(),
  hasMorePages: provider.hasMorePages,

  // Header personalizado
  header: Container(
    padding: EdgeInsets.all(16),
    child: Text('Total: ${provider.totalItems} pedidos'),
  ),

  // Footer personalizado
  footer: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Fin de la lista'),
  ),

  itemBuilder: (context, pedido, index) {
    return PedidoCard(pedido: pedido);
  },
)
```

### 4. Lista con Estados Personalizados

```dart
InfiniteScrollList<Item>(
  items: provider.items,
  onLoadMore: () => provider.loadMore(),
  onRefresh: () => provider.refresh(),
  hasMorePages: provider.hasMorePages,
  isLoadingMore: provider.isLoading && provider.items.isNotEmpty,
  isInitialLoading: provider.isLoading && provider.items.isEmpty,

  // Mensajes personalizados
  emptyMessage: 'No hay items disponibles',
  emptyIcon: Icons.shopping_bag_outlined,
  errorMessage: provider.errorMessage,

  // Threshold personalizado (300px antes del final)
  loadMoreThreshold: 300,

  itemBuilder: (context, item, index) {
    return ItemCard(item: item);
  },
)
```

## Estados del Widget

### 1. **Carga Inicial**
Cuando `isInitialLoading = true` y la lista está vacía:
- Muestra un spinner grande con mensaje "Cargando..."

### 2. **Lista Vacía**
Cuando la lista está vacía y no está cargando:
- Muestra icono y mensaje personalizable
- Indica que puede hacer pull-to-refresh

### 3. **Error**
Cuando hay un `errorMessage` y la lista está vacía:
- Muestra icono de error y mensaje
- Botón "Reintentar" para volver a cargar

### 4. **Cargando Más**
Cuando `isLoadingMore = true`:
- Muestra spinner pequeño al final de la lista
- Mensaje "Cargando más..."

### 5. **Lista Normal**
Cuando hay items y no está cargando:
- Muestra los items normalmente
- Pull-to-refresh habilitado
- Scroll infinito activo

## Integración con Providers

### Ejemplo con ClientProvider

```dart
// En tu Provider
class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;

  List<Client> get clients => _clients;
  int get currentPage => _currentPage;
  bool get hasMorePages => _currentPage < _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadClients({
    int page = 1,
    int perPage = 5,
    bool append = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.getClients(page: page, perPage: perPage);

      if (append) {
        _clients.addAll(response.data);
      } else {
        _clients = response.data;
      }

      _currentPage = page;
      _totalPages = response.totalPages;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }
}

// En tu Screen
Consumer<ClientProvider>(
  builder: (context, provider, child) {
    return InfiniteScrollList<Client>(
      items: provider.clients,

      onLoadMore: () => provider.loadClients(
        page: provider.currentPage + 1,
        perPage: 5,
        append: true,
      ),

      onRefresh: () => provider.loadClients(perPage: 5),

      hasMorePages: provider.hasMorePages,
      isLoadingMore: provider.isLoading && provider.clients.isNotEmpty,
      isInitialLoading: provider.isLoading && provider.clients.isEmpty,
      errorMessage: provider.errorMessage,

      itemBuilder: (context, client, index) {
        return ClientCard(client: client);
      },
    );
  },
)
```

## Tips y Mejores Prácticas

### 1. **Tamaño de Página Óptimo**
```dart
// Recomendado: 5-10 items por página
perPage: 5  // Bueno para listas con items complejos
perPage: 10 // Bueno para listas simples
```

### 2. **Threshold de Carga**
```dart
// Ajusta según la altura de tus items
loadMoreThreshold: 200  // Para items pequeños (altura ~50-70px)
loadMoreThreshold: 400  // Para items grandes (altura ~150-200px)
```

### 3. **Manejo de Errores**
```dart
// Siempre proporciona errorMessage del provider
errorMessage: provider.errorMessage,

// En el provider, captura y setea errores
catch (e) {
  _errorMessage = 'Error al cargar: ${e.toString()}';
  notifyListeners();
}
```

### 4. **Optimización de Rendimiento**
```dart
// Usa const donde sea posible
itemBuilder: (context, item, index) {
  return const ItemCard(key: ValueKey(item.id), item: item);
}

// Evita reconstrucciones innecesarias
final itemWidget = useMemoized(() => ItemCard(item: item), [item.id]);
```

## Troubleshooting

### Problema: No carga más items automáticamente
**Solución:** Verifica que `hasMorePages` sea `true` y que `isLoadingMore` sea `false`

### Problema: Pull-to-refresh no funciona
**Solución:** Asegúrate de que `onRefresh` retorne un `Future<void>`

### Problema: Carga duplicada de items
**Solución:** Verifica que `append: true` esté en `onLoadMore` y `append: false` en `onRefresh`

### Problema: Indicador de carga no desaparece
**Solución:** Asegúrate de setear `isLoadingMore = false` después de cargar

## Comparación: Antes vs Después

### Antes (Sin InfiniteScrollList)
```dart
// 100+ líneas de código
- ScrollController manual
- NotificationListener
- Estados de carga manuales
- Indicadores custom
- Pull-to-refresh manual
- Manejo de errores manual
```

### Después (Con InfiniteScrollList)
```dart
// 10-20 líneas de código
InfiniteScrollList<T>(
  items: provider.items,
  onLoadMore: () => provider.loadMore(),
  onRefresh: () => provider.refresh(),
  hasMorePages: provider.hasMorePages,
  itemBuilder: (context, item, index) => ItemCard(item: item),
)
```

## Archivos de Ejemplo

Ver ejemplos completos en:
- `/lib/widgets/infinite_scroll_list_example.dart` - Ejemplos de uso
- `/lib/screens/clients/client_list_screen.dart` - Implementación real

## Soporte

Para más información o reportar issues, consulta la documentación del proyecto.
