import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../models/models.dart';

class ComboItemList extends StatelessWidget {
  final List<Map<String, dynamic>> comboItems;
  final int comboCantidad;
  final List<ComboItem>? comboItemsDelProducto;
  final Map<int, Product>? productosMap;

  const ComboItemList({
    super.key,
    required this.comboItems,
    required this.comboCantidad,
    this.comboItemsDelProducto,
    this.productosMap,
  });

  ComboItem? obtenerComboItemPorId(int comboItemId) {
    try {
      return comboItemsDelProducto?.firstWhere((c) => c.id == comboItemId);
    } catch (e) {
      return null;
    }
  }

  Product? obtenerProducto(int productoId) {
    return productosMap?[productoId];
  }

  Widget _buildProductImage(Product? producto) {
    if (producto?.imagenes != null && producto!.imagenes!.isNotEmpty) {
      final imagenPrincipal = producto.imagenes!.firstWhere(
        (img) => img.esPrincipal,
        orElse: () => producto.imagenes!.first,
      );

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imagenPrincipal.url,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImagePlaceholder();
          },
        ),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: Colors.grey.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: comboItems.asMap().entries.map((entry) {
        final index = entry.key;
        final comboItem = entry.value;
        final cantidadRaw = comboItem['cantidad'] ?? 1;
        final cantidad = cantidadRaw is int
            ? cantidadRaw
            : (cantidadRaw as num).toInt();
        final isLast = index == comboItems.length - 1;
        final cantidadTotal = cantidad * comboCantidad;

        // Obtener producto del objeto si existe, si no, buscar en productosMap
        Product? producto;
        if (comboItem['producto'] is Map) {
          try {
            producto = Product.fromJson(comboItem['producto']);
          } catch (e) {
            debugPrint('Error parseando producto: $e');
          }
        } else if (comboItem['producto_id'] != null) {
          producto = obtenerProducto(comboItem['producto_id']);
        }

        final nombreProducto =
            producto?.nombre ?? comboItem['producto_nombre'] ?? 'Producto';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.amber.shade100)),
          ),
          child: Row(
            children: [
              if (producto != null) _buildProductImage(producto),
              if (producto != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreProducto,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (producto?.descripcion != null &&
                        producto!.descripcion!.isNotEmpty)
                      Text(
                        producto.descripcion!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${cantidadTotal}x',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
