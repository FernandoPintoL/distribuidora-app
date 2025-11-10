import 'package:flutter/material.dart';
import '../../models/models.dart';

class CarritoItemCard extends StatefulWidget {
  final CarritoItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final Function(double) onUpdateCantidad;

  const CarritoItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateCantidad,
  });

  @override
  State<CarritoItemCard> createState() => _CarritoItemCardState();
}

class _CarritoItemCardState extends State<CarritoItemCard> {
  late TextEditingController _observacionesController;
  bool _editandoObservaciones = false;
  bool _guardandoObservaciones = false;

  @override
  void initState() {
    super.initState();
    _observacionesController =
        TextEditingController(text: widget.item.observaciones ?? '');
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarObservaciones() async {
    setState(() => _guardandoObservaciones = true);

    // Simular guardado (en producción, llamaría al provider)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _editandoObservaciones = false;
        _guardandoObservaciones = false;
      });

      debugPrint('✅ Observaciones guardadas para ${widget.item.producto?.nombre}');
    }
  }

  void _cancelarEdicion() {
    _observacionesController.text = widget.item.observaciones ?? '';
    setState(() => _editandoObservaciones = false);
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.item.producto;
    final stockDisponible = producto.stockPrincipal?.cantidadDisponible ?? 0;
    final stockDispDouble = (stockDisponible as num).toDouble();
    final tieneStockSuficiente = widget.item.cantidad <= stockDispDouble;
    final excedido = widget.item.cantidadExcedida;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: excedido > 0 ? 2 : 0,
      color: excedido > 0 ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePlaceholder(),
                ),
                const SizedBox(width: 12),

                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto con badge de stock
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStockBadge(context, stockDispDouble),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Código del producto
                      Text(
                        'Código: ${producto.codigo}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Precio unitario
                      Text(
                        'Bs ${widget.item.precioUnitario.toStringAsFixed(2)} c/u',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),

                      // Controles de cantidad
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botones de cantidad
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: tieneStockSuficiente
                                    ? Colors.grey.shade300
                                    : Colors.red.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: widget.onDecrement,
                                  icon: const Icon(Icons.remove, size: 18),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    widget.item.cantidad.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: tieneStockSuficiente
                                          ? Colors.black
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onIncrement,
                                  icon: const Icon(Icons.add, size: 18),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtotal del item
                          Flexible(
                            child: Text(
                              'Bs ${widget.item.subtotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botón eliminar
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar',
                ),
              ],
            ),

            // Mostrar advertencia de stock si excede
            if (excedido > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stock insuficiente: ${excedido.toStringAsFixed(1)} unidades excedidas. Máximo disponible: ${stockDispDouble.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sección de observaciones (editable en línea)
            /*Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildObservacionesSection(),
            ),*/
          ],
        ),
      ),
    );
  }

  /// Construye la sección de observaciones con edición en línea
  Widget _buildObservacionesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _editandoObservaciones
          ? _buildObservacionesEditing()
          : _buildObservacionesViewing(),
    );
  }

  /// Vista de solo lectura (mostrar notas)
  Widget _buildObservacionesViewing() {
    return GestureDetector(
      onTap: () {
        setState(() => _editandoObservaciones = true);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.item.observaciones != null &&
                    widget.item.observaciones!.isNotEmpty)
                  Text(
                    widget.item.observaciones!,
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Agregar nota (toca para editar)',
                    style: TextStyle(
                      color: Colors.amber.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit, color: Colors.amber.shade600, size: 16),
        ],
      ),
    );
  }

  /// Vista de edición (campo de texto)
  Widget _buildObservacionesEditing() {
    return Column(
      children: [
        TextField(
          controller: _observacionesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Agregar nota para este producto...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: const TextStyle(fontSize: 13),
          onSubmitted: (_) => _guardarObservaciones(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelarEdicion,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _guardandoObservaciones ? null : _guardarObservaciones,
              icon: _guardandoObservaciones
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _guardandoObservaciones ? 'Guardando...' : 'Guardar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockBadge(BuildContext context, double stockDisponible) {
    final isLowStock = stockDisponible > 0 && stockDisponible <= 5;
    final isOutOfStock = stockDisponible <= 0;

    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Agotado',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Poco stock',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Disponible',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}
