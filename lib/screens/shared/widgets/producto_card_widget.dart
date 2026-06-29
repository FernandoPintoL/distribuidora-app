import 'package:flutter/material.dart';
import '../../../config/app_urls.dart';
import '../../../config/app_text_styles.dart';
import '../../../screens/ventas/venta_detalle/producto_avatar_widget.dart';

class ProductoCardWidget extends StatelessWidget {
  final String? imagenUrl;
  final String? nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final bool mostrarAvatarWidget;
  final List<Map<String, dynamic>>? comboItemsSeleccionados;
  final dynamic comboItems; // Lista de ComboItem del producto
  final BuildContext? parentContext;

  const ProductoCardWidget({
    super.key,
    required this.imagenUrl,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.mostrarAvatarWidget = true,
    this.comboItemsSeleccionados,
    this.comboItems,
    this.parentContext,
  });

  String? _obtenerNombreComboItem(int comboItemId) {
    if (comboItems == null) {
      debugPrint('⚠️ [ProductoCard] comboItems es null para _obtenerNombreComboItem');
      return null;
    }
    try {
      final comboItemsList = comboItems as List;
      final comboItem = comboItemsList.firstWhere((c) => c.id == comboItemId);

      // Intentar productoNombre primero, luego producto.nombre
      final nombre = comboItem.productoNombre ?? comboItem.producto?.nombre;
      debugPrint('🏷️ [ProductoCard] _obtenerNombreComboItem($comboItemId): productoNombre="${comboItem.productoNombre}" → Usando: "$nombre"');
      return nombre;
    } catch (e) {
      debugPrint('❌ [ProductoCard] Error en _obtenerNombreComboItem($comboItemId): $e');
      return null;
    }
  }

  // Obtener URL de imagen del producto del combo item
  String? _obtenerImagenComboItem(int comboItemId) {
    if (comboItems == null) {
      debugPrint('⚠️ [ProductoCard] comboItems es null para combo item $comboItemId');
      return null;
    }
    try {
      final comboItemsList = comboItems as List;
      debugPrint('📊 [ProductoCard] Buscando combo item $comboItemId en lista de ${comboItemsList.length} items');

      final comboItem = comboItemsList.firstWhere((c) => c.id == comboItemId);
      debugPrint('✅ [ProductoCard] ComboItem encontrado: ${comboItem.producto?.nombre}');

      if (comboItem.producto == null) {
        debugPrint('⚠️ [ProductoCard] comboItem.producto es null');
        return null;
      }

      debugPrint('✅ [ProductoCard] Producto existe: ${comboItem.producto?.nombre}');

      if (comboItem.producto?.imagenes == null) {
        debugPrint('⚠️ [ProductoCard] producto.imagenes es null');
      } else {
        debugPrint('📷 [ProductoCard] Imágenes disponibles: ${comboItem.producto?.imagenes?.length}');
      }

      final imagenPrincipal = comboItem.producto?.imagenPrincipal;
      debugPrint('🖼️ [ProductoCard] imagenPrincipal: ${imagenPrincipal?.url ?? "null"}');

      final imagenUrl = imagenPrincipal?.url;
      debugPrint('✅ [ProductoCard] Combo item $comboItemId - Producto: ${comboItem.producto?.nombre} - Imagen: ${imagenUrl != null ? "✓" : "✗"}');
      return imagenUrl;
    } catch (e) {
      debugPrint('❌ [ProductoCard] Error obteniendo imagen para combo item $comboItemId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagen = imagenUrl != null && imagenUrl!.isNotEmpty;
    final tieneCombo = comboItemsSeleccionados != null && comboItemsSeleccionados!.isNotEmpty;
    final ctx = parentContext ?? context;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar a la izquierda
                if (tieneImagen && mostrarAvatarWidget)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ProductoAvatarWidget(
                      imageUrl: imagenUrl!,
                      nombreProducto: nombreProducto,
                      radius: 28,
                    ),
                  )
                else if (tieneImagen)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imagenUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  ),
                // Información a la derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nombreProducto ?? 'Producto desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'x${cantidad.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Bs. ${precioUnitario.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Sub.: Bs. ${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.greenAccent
                                    : Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Mostrar componentes del combo si existen
        if (tieneCombo) ...[
          if (comboItems == null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade50,
              child: Text(
                '⚠️ comboItems es null',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Componentes - ${cantidad.toInt()} combo${cantidad > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: parentContext != null
                                ? AppTextStyles.bodySmall(parentContext!)
                                    .fontSize!
                                : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.blue.shade200)),
                  ),
                  child: Column(
                    children: comboItemsSeleccionados!
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final comboItem = entry.value;
                          final cantidadRaw = comboItem['cantidad'] ?? 1;
                          final cantidadComponente = cantidadRaw is int
                              ? cantidadRaw
                              : (cantidadRaw as num).toInt();
                          final comboItemId = comboItem['combo_item_id'] ?? 0;
                          final nombreProductoCombo =
                              _obtenerNombreComboItem(comboItemId) ?? 'Producto';
                          debugPrint('🏷️ [ProductoCard] Nombre para mostrar: "$nombreProductoCombo" (comboItemId: $comboItemId)');
                          final isLast =
                              index == comboItemsSeleccionados!.length - 1;
                          final cantidadTotal = cantidadComponente * cantidad.toInt();
                          final imagenUrl = _obtenerImagenComboItem(comboItemId);
                          final tieneImagen = imagenUrl != null && imagenUrl.isNotEmpty;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom:
                                          BorderSide(color: Colors.blue.shade100),
                                    ),
                            ),
                            child: Row(
                              children: [
                                // Imagen del componente
                                if (tieneImagen)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        imagenUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.image,
                                            size: 24,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (nombreProductoCombo.isEmpty)
                                        Container(
                                          color: Colors.red.shade100,
                                          child: Text(
                                            'ERROR: Nombre vacío',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          nombreProductoCombo,
                                          style: TextStyle(
                                            fontSize: parentContext != null
                                                ? AppTextStyles.bodySmall(
                                                        parentContext!)
                                                    .fontSize!
                                                : 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade900,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Producto ID: ${comboItem['producto_id'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: parentContext != null
                                              ? AppTextStyles.labelSmall(
                                                      parentContext!)
                                                  .fontSize!
                                              : 10,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${cantidadTotal}x',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                          fontSize: parentContext != null
                                              ? AppTextStyles.bodySmall(
                                                      parentContext!)
                                                  .fontSize!
                                              : 12,
                                        ),
                                      ),
                                    ),
                                    if (cantidad > 1)
                                      Text(
                                        '($cantidadComponente×${cantidad.toInt()})',
                                        style: TextStyle(
                                          fontSize: parentContext != null
                                              ? AppTextStyles.labelSmall(
                                                      parentContext!)
                                                  .fontSize!
                                              : 10,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
